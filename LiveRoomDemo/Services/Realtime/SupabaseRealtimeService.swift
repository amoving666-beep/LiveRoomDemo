//
//  SupabaseRealtimeService.swift
//  LiveRoomDemo
//
//  Created by 天亮了 on 2026/6/12.
//

import Foundation
import Supabase

// 监听 Supabase Realtime，把数据库事件转换成直播间业务事件。
final class SupabaseRealtimeService: RoomEventSourceProtocol {
    // 收到带 seq 的实时事件，通知 ViewModel 分发。
    var onRoomEventEnvelopeReceived: ((RoomEventEnvelope) -> Void)?
    // Realtime 连接状态回调。
    var onConnectionStateChanged: ((IMConnectionState) -> Void)?

    // Supabase 客户端，负责和 Supabase 后端通信。
    private let supabaseClient: SupabaseClient
    // 持续监听任务，stop 时 cancel。
    private var realtimeTask: Task<Void, Never>?
    // 当前监听房间 ID，用来防止串房。
    private var currentRoomID: String?

    init(
        supabaseURL: URL = SupabaseConfig.url,
        supabaseKey: String = SupabaseConfig.anonKey
    ) {
        self.supabaseClient = SupabaseClient(
            supabaseURL: supabaseURL,
            supabaseKey: supabaseKey,
            options: SupabaseClientOptions(
                auth: .init(
                    emitLocalSessionAsInitialSession: true
                )
            )
        )
    }

    // 开始监听指定房间的实时事件。
    func start(roomID: String) {
        // 切换监听时只取消旧任务，保留外部回调。
        cancelRealtimeTaskKeepingCallbacks()

        currentRoomID = roomID
        log("开始监听 roomID = \(roomID)")
        onConnectionStateChanged?(.connecting)

        // 用 Task 承载 Realtime 的异步监听。
        realtimeTask = Task { [weak self] in
            guard let self else { return }

            do {
                // 创建当前房间的 Realtime channel。
                let channel = self.supabaseClient.channel("live_room_events_\(roomID)")

                // 监听 live_room_events 表新增事件。
                let changes = channel.postgresChange(
                    InsertAction.self,
                    schema: "public",
                    table: "live_room_events",
                    filter: .eq("room_id", value: roomID)
                )

                // 发起订阅，失败进入 catch。
                try await channel.subscribeWithError()

                await MainActor.run {
                    self.log("已连接 roomID = \(roomID)")
                    self.onConnectionStateChanged?(.connected)
                }

                // 持续接收服务端推来的 insert 事件。
                for await change in changes {
                    self.logInsertRecord(change.record)
                    await self.handleInsertRecord(change.record)
                }
            } catch {
                await MainActor.run {
                    self.onConnectionStateChanged?(.disconnected)
                    self.log("连接失败：\(error.localizedDescription)")
                }
            }
        }
    }

    // 只取消旧监听任务，保留回调。
    private func cancelRealtimeTaskKeepingCallbacks() {
        realtimeTask?.cancel()
        realtimeTask = nil
        currentRoomID = nil
    }

    // 停止监听并清空回调，防止旧房间继续刷新 UI。
    func stop() {
        realtimeTask?.cancel()
        realtimeTask = nil
        currentRoomID = nil
        onRoomEventEnvelopeReceived = nil
        onConnectionStateChanged?(.disconnected)
    }

    // 拉取最近聊天历史，进入房间时先补一屏旧消息。
    func fetchRecentChatMessages(roomID: String, limit: Int, completion: @escaping ([ChatMessage]) -> Void) {
        Task { [weak self] in
            guard let self else { return }

            do {
                let records: [LiveRoomEventRecord] = try await supabaseClient
                    .from("live_room_events")
                    .select("id, room_id, event_type, payload, created_at, seq")
                    .eq("room_id", value: roomID)
                    .eq("event_type", value: "chat")
                    .order("seq", ascending: false)
                    .limit(limit)
                    .execute()
                    .value

                let messages = records
                    .reversed()
                    .compactMap { record -> ChatMessage? in
                        guard let userName = record.payload.userName,
                              let content = record.payload.content else {
                            return nil
                        }

                        return ChatMessage(
                            id: record.payload.messageID ?? record.id,
                            type: .user,
                            userName: userName,
                            content: content,
                            timestamp: record.createdAt
                        )
                    }

                await MainActor.run {
                    self.log("拉取历史消息成功 roomID=\(roomID), count=\(messages.count)")
                    completion(messages)
                }
            } catch {
                await MainActor.run {
                    self.log("拉取历史消息失败：\(error.localizedDescription)")
                    completion([])
                }
            }
        }
    }

    // 重连后补拉漏掉的事件。
    func fetchMissedRoomEventEnvelopes(roomID: String, afterSeq: Int, completion: @escaping ([RoomEventEnvelope]) -> Void) {
        Task { [weak self] in
            guard let self else { return }

            do {
                let records: [LiveRoomEventRecord] = try await supabaseClient
                    .from("live_room_events")
                    .select("id, room_id, event_type, payload, created_at, seq")
                    .eq("room_id", value: roomID)
                    .gt("seq", value: afterSeq)
                    .order("seq", ascending: true)
                    .execute()
                    .value

                let envelopes = records.compactMap { self.makeRoomEventEnvelope(from: $0) }

                await MainActor.run {
                    self.log("补拉漏掉事件成功 roomID=\(roomID), afterSeq=\(afterSeq), count=\(envelopes.count)")
                    completion(envelopes)
                }
            } catch {
                await MainActor.run {
                    self.log("补拉漏掉事件失败：\(error.localizedDescription)")
                    completion([])
                }
            }
        }
    }

    // 发送聊天文本到 Supabase，写入后会通过 Realtime 推回客户端。
    func sendChatText(roomID: String, userName: String, content: String) {
        Task { [weak self] in
            guard let self else { return }

            do {
                // 生成客户端消息 ID，用于 Realtime 重复推送时去重。
                let messageID = UUID().uuidString

                // payload 对应 live_room_events.payload 字段，只放聊天内容本身。
                let payload = ChatInsertPayload(
                    messageID: messageID,
                    userName: userName,
                    content: content
                )

                // event 对应 live_room_events 表的一整行数据。
                let event = LiveRoomEventInsertPayload(
                    roomID: roomID,
                    eventType: "chat",
                    payload: payload
                )

                // 写入 Supabase 表；insert 成功后 Realtime 会再把这条事件推回客户端。
                try await supabaseClient
                    .from("live_room_events")
                    .insert(event)
                    .execute()

                log("发送 chat 成功 | roomID=\(roomID) | messageID=\(messageID) | userName=\(userName) | content=\(content)")
            } catch {
                log("发送 chat 失败：\(error.localizedDescription)")
            }
        }
    }

    // 处理数据库 insert 记录，按 event_type 分发。
    @MainActor
    private func handleInsertRecord(_ record: [String: AnyJSON]) {
        guard let roomID = record["room_id"]?.stringValue,
              let currentRoomID,
              roomID == currentRoomID else {
            log("忽略非当前房间事件 | recordRoomID=\(record["room_id"]?.stringValue ?? "nil") | currentRoomID=\(currentRoomID ?? "nil")")
            return
        }

        guard let eventType = record["event_type"]?.stringValue,
              let payload = record["payload"] else {
            return
        }

        let eventID = record["id"]?.stringValue ?? UUID().uuidString
        let seq = record["seq"]?.intValue ?? 0

        switch eventType {
        case "chat":
            handleChatPayload(payload, eventID: eventID, seq: seq)

        case "gift":
            handleGiftPayload(payload, roomID: roomID, eventID: eventID, seq: seq)

        case "audience":
            handleAudiencePayload(payload, roomID: roomID, eventID: eventID, seq: seq)

        default:
            log("未处理的实时事件类型：\(eventType)")
        }
    }

    // 解析聊天 payload，转成 ChatMessage。
    @MainActor
    private func handleChatPayload(_ payload: AnyJSON, eventID: String, seq: Int) {
        
        guard let userName = payload.objectValue?["userName"]?.stringValue,
              let content = payload.objectValue?["content"]?.stringValue else {
            log("chat payload 解析失败")
            return
        }

        let messageID = payload.objectValue?["messageID"]?.stringValue ?? UUID().uuidString
        log("chat 解析成功 messageID=\(messageID), userName=\(userName), content=\(content)")
        
        let message = ChatMessage(
            id: messageID,
            type: .user,
            userName: userName,
            content: content,
            timestamp: Date()
        )

        let envelope = RoomEventEnvelope(
            eventID: eventID,
            seq: seq,
            event: .chat(message)
        )

        onRoomEventEnvelopeReceived?(envelope)
    }

    // 解析礼物 payload，转成 GiftEvent。
    @MainActor
    private func handleGiftPayload(_ payload: AnyJSON, roomID: String, eventID: String, seq: Int) {
        guard let senderName = payload.objectValue?["senderName"]?.stringValue,
              let giftName = payload.objectValue?["giftName"]?.stringValue else {
            return
        }

        let giftCount = payload.objectValue?["giftCount"]?.intValue ?? 1
        let shouldPlayAnimation = payload.objectValue?["shouldPlayAnimation"]?.boolValue ?? true

        let event = GiftEvent(
            roomID: roomID,
            senderName: senderName,
            giftName: giftName,
            giftCount: giftCount,
            shouldPlayAnimation: shouldPlayAnimation
        )

        let envelope = RoomEventEnvelope(
            eventID: eventID,
            seq: seq,
            event: .gift(event)
        )

        onRoomEventEnvelopeReceived?(envelope)
    }

    // 解析在线人数 payload，转成 AudienceEvent。
    @MainActor
    private func handleAudiencePayload(_ payload: AnyJSON, roomID: String, eventID: String, seq: Int) {
        guard let onlineCount = payload.objectValue?["onlineCount"]?.intValue else {
            return
        }

        let event = AudienceEvent(
            roomID: roomID,
            onlineCount: onlineCount,
            changeCount: 0
        )

        let envelope = RoomEventEnvelope(
            eventID: eventID,
            seq: seq,
            event: .audience(event)
        )

        onRoomEventEnvelopeReceived?(envelope)
    }

    // 把数据库查询记录转换成 RoomEventEnvelope。
    private func makeRoomEventEnvelope(from record: LiveRoomEventRecord) -> RoomEventEnvelope? {
        switch record.eventType {
        case "chat":
            guard let userName = record.payload.userName,
                  let content = record.payload.content else {
                return nil
            }

            let message = ChatMessage(
                id: record.payload.messageID ?? record.id,
                type: .user,
                userName: userName,
                content: content,
                timestamp: record.createdAt
            )

            return RoomEventEnvelope(
                eventID: record.id,
                seq: record.seq,
                event: .chat(message)
            )

        case "gift":
            guard let senderName = record.payload.senderName,
                  let giftName = record.payload.giftName else {
                return nil
            }

            let giftEvent = GiftEvent(
                roomID: record.roomID,
                senderName: senderName,
                giftName: giftName,
                giftCount: record.payload.giftCount ?? 1,
                shouldPlayAnimation: record.payload.shouldPlayAnimation ?? true
            )

            return RoomEventEnvelope(
                eventID: record.id,
                seq: record.seq,
                event: .gift(giftEvent)
            )

        case "audience":
            guard let onlineCount = record.payload.onlineCount else {
                return nil
            }

            let audienceEvent = AudienceEvent(
                roomID: record.roomID,
                onlineCount: onlineCount,
                changeCount: 0
            )

            return RoomEventEnvelope(
                eventID: record.id,
                seq: record.seq,
                event: .audience(audienceEvent)
            )

        default:
            return nil
        }
    }

    // MARK: - 调试日志

    private func log(_ message: String) {
        print("[Realtime] \(message)")
    }

    private func logInsertRecord(_ record: [String: AnyJSON]) {
        let roomID = record["room_id"]?.stringValue ?? "nil"
        let eventType = record["event_type"]?.stringValue ?? "nil"
        let payload = record["payload"]

        switch eventType {
        case "chat":
            let messageID = payload?.objectValue?["messageID"]?.stringValue ?? "nil"
            let userName = payload?.objectValue?["userName"]?.stringValue ?? "nil"
            let content = payload?.objectValue?["content"]?.stringValue ?? "nil"
            log("收到 chat | roomID=\(roomID) | messageID=\(messageID) | userName=\(userName) | content=\(content)")

        case "gift":
            let senderName = payload?.objectValue?["senderName"]?.stringValue ?? "nil"
            let giftName = payload?.objectValue?["giftName"]?.stringValue ?? "nil"
            let giftCount = payload?.objectValue?["giftCount"]?.intValue ?? 0
            log("收到 gift | roomID=\(roomID) | sender=\(senderName) | gift=\(giftName) x\(giftCount)")

        case "audience":
            let onlineCount = payload?.objectValue?["onlineCount"]?.intValue ?? 0
            log("收到 audience | roomID=\(roomID) | onlineCount=\(onlineCount)")

        default:
            log("收到 unknown | roomID=\(roomID) | eventType=\(eventType)")
        }
    }
}

// MARK: - Supabase Insert Models

private struct LiveRoomEventInsertPayload: Encodable {
    let roomID: String
    let eventType: String
    let payload: ChatInsertPayload

    enum CodingKeys: String, CodingKey {
        case roomID = "room_id"
        case eventType = "event_type"
        case payload
    }
}

private struct ChatInsertPayload: Encodable {
    let messageID: String
    let userName: String
    let content: String
}

// MARK: - Supabase Query Models

private struct LiveRoomEventRecord: Decodable {
    let id: String
    let roomID: String
    let eventType: String
    let payload: ChatRecordPayload
    let createdAt: Date
    let seq: Int
    

    enum CodingKeys: String, CodingKey {
        case id
        case roomID = "room_id"
        case eventType = "event_type"
        case payload
        case createdAt = "created_at"
        case seq
    }
}

private struct ChatRecordPayload: Decodable {
    let messageID: String?
    let userName: String?
    let content: String?
    let senderName: String?
    let giftName: String?
    let giftCount: Int?
    let shouldPlayAnimation: Bool?
    let onlineCount: Int?
}
