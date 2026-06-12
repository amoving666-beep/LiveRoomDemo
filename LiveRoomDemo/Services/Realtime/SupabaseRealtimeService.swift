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
    // 实时事件回调，通知 ViewModel 分发。
    var onEvent: ((LiveRoomBusinessEvent) -> Void)?
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
        onEvent = nil
        onConnectionStateChanged?(.disconnected)
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

        switch eventType {
        case "chat":
            handleChatPayload(payload)

        case "gift":
            handleGiftPayload(payload, roomID: roomID)

        case "audience":
            handleAudiencePayload(payload, roomID: roomID)

        default:
            log("未处理的实时事件类型：\(eventType)")
        }
    }

    // 解析聊天 payload，转成 ChatMessage。
    @MainActor
    private func handleChatPayload(_ payload: AnyJSON) {
        
        guard let userName = payload.objectValue?["userName"]?.stringValue,
              let content = payload.objectValue?["content"]?.stringValue else {
            log("chat payload 解析失败")
            return
            
        }
        log("chat 解析成功 userName=\(userName), content=\(content)")
        
        let message = ChatMessage(
            id: UUID().uuidString,
            type: .user,
            userName: userName,
            content: content,
            timestamp: Date()
        )

        onEvent?(.chat(message))
    }

    // 解析礼物 payload，转成 GiftEvent。
    @MainActor
    private func handleGiftPayload(_ payload: AnyJSON, roomID: String) {
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

        onEvent?(.gift(event))
    }

    // 解析在线人数 payload，转成 AudienceEvent。
    @MainActor
    private func handleAudiencePayload(_ payload: AnyJSON, roomID: String) {
        guard let onlineCount = payload.objectValue?["onlineCount"]?.intValue else {
            return
        }

        let event = AudienceEvent(
            roomID: roomID,
            onlineCount: onlineCount,
            changeCount: 0
        )

        onEvent?(.audience(event))
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
            let userName = payload?.objectValue?["userName"]?.stringValue ?? "nil"
            let content = payload?.objectValue?["content"]?.stringValue ?? "nil"
            log("收到 chat | roomID=\(roomID) | userName=\(userName) | content=\(content)")

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
