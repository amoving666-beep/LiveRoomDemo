
//
//  SupabaseRealtimeService.swift
//  LiveRoomDemo
//
//  Created by 天亮了 on 2026/6/12.
//

import Foundation
import Supabase

final class SupabaseRealtimeService: RoomEventSourceProtocol {
    var onEvent: ((LiveRoomBusinessEvent) -> Void)?
    var onConnectionStateChanged: ((IMConnectionState) -> Void)?

    private let supabaseClient: SupabaseClient
    private var realtimeTask: Task<Void, Never>?
    private var currentRoomID: String?

    init(
        supabaseURL: URL = SupabaseConfig.url,
        supabaseKey: String = SupabaseConfig.anonKey
    ) {
        self.supabaseClient = SupabaseClient(
            supabaseURL: supabaseURL,
            supabaseKey: supabaseKey
        )
    }

    func start(roomID: String) {
        stop()

        currentRoomID = roomID
        onConnectionStateChanged?(.connecting)

        realtimeTask = Task { [weak self] in
            guard let self else { return }

            do {
                let channel = self.supabaseClient.channel("live_room_events_\(roomID)")

                let changes = channel.postgresChange(
                    InsertAction.self,
                    schema: "public",
                    table: "live_room_events",
                    filter: "room_id=eq.\(roomID)"
                )

                await channel.subscribe()

                await MainActor.run {
                    self.onConnectionStateChanged?(.connected)
                }

                for await change in changes {
                    await self.handleInsertRecord(change.record)
                }
            } catch {
                await MainActor.run {
                    self.onConnectionStateChanged?(.disconnected)
                    print("Supabase Realtime 连接失败：\(error.localizedDescription)")
                }
            }
        }
    }

    func stop() {
        realtimeTask?.cancel()
        realtimeTask = nil
        currentRoomID = nil
        onEvent = nil
        onConnectionStateChanged?(.disconnected)
    }

    @MainActor
    private func handleInsertRecord(_ record: [String: AnyJSON]) {
        guard let roomID = record["room_id"]?.stringValue,
              let currentRoomID,
              roomID == currentRoomID else {
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
            print("未处理的实时事件类型：\(eventType)")
        }
    }

    @MainActor
    private func handleChatPayload(_ payload: AnyJSON) {
        guard let userName = payload.objectValue?["userName"]?.stringValue,
              let content = payload.objectValue?["content"]?.stringValue else {
            return
        }

        let message = ChatMessage(
            id: UUID().uuidString,
            type: .user,
            userName: userName,
            content: content,
            timestamp: Date()
        )

        onEvent?(.chat(message))
    }

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
}
