//
//  LiveRoomViewModel+RoomEvent.swift
//  LiveRoomDemo
//
//  Created by 天亮了 on 2026/6/10.
//

import Foundation

// MARK: - 直播间业务事件入口

extension LiveRoomViewModel {

    // MARK: - 实时事件源

    // 开始接收直播间实时事件。
    // SupabaseRealtimeService 会统一推送聊天、礼物、在线人数等事件，ViewModel 只负责分发事件。
    func startReceivingRoomEvents() {
        updateIMState(.connecting)

        roomEventSource.onConnectionStateChanged = { [weak self] state in
            guard let self else { return }
            self.updateIMState(state)
        }

        roomEventSource.onEvent = { [weak self] event in
            guard let self else { return }
            self.routeRoomEvent(event)
        }

        roomEventSource.start(roomID: activeRoom.id)
    }

    // MARK: - 礼物事件

    // 处理礼物事件。
    // 礼物先进入聊天区；如果 shouldPlayAnimation 为 true，再通知动画层播放。
    private func handleGiftEvent(_ event: GiftEvent) {
        guard event.roomID == activeRoom.id else { return }

        let giftContent = "送出 \(event.giftName) x\(event.giftCount)"
        let message = ChatMessage(
            id: UUID().uuidString,
            type: .gift,
            userName: event.senderName,
            content: giftContent,
            timestamp: Date()
        )

        routeRoomEvent(.chat(message))

        if event.shouldPlayAnimation {
            onGiftAnimationRequested?(event)
        }
    }

    // MARK: - 在线人数事件

    // 处理在线人数事件，更新页面状态并通知 HeaderView 刷新。
    private func handleAudienceEvent(_ event: AudienceEvent) {
        guard event.roomID == activeRoom.id else { return }

        onlineCount = event.onlineCount
        onAudienceChanged?(event.onlineCount)
    }

    // MARK: - IM 状态

    // 更新 IM 连接状态。
    func updateIMState(_ state: IMConnectionState) {
        imState = state
        onIMStateChanged?(state)
    }

    // MARK: - RoomEvent 分发

    // 直播间业务事件统一入口。
    // Realtime 事件源推来的 Chat / Audience / Gift 统一在这里分发。
    private func routeRoomEvent(_ event: LiveRoomBusinessEvent) {
        switch event {
        case .chat(let message):
            handleChatMessage(message)

        case .audience(let audienceEvent):
            handleAudienceEvent(audienceEvent)

        case .gift(let giftEvent):
            handleGiftEvent(giftEvent)
        }
    }

    // 处理聊天消息事件，统一追加到聊天列表并刷新页面。
    private func handleChatMessage(_ message: ChatMessage) {
        if hasHandledMessageID(message.id) {
            print("忽略重复消息 messageID = \(message.id)")
            return
        }

        markMessageIDHandled(message.id)
        chatMessages.append(message)
        onChatMessagesChanged?()
    }
}
