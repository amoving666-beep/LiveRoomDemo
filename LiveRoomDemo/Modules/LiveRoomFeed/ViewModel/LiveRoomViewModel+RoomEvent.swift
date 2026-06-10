//
//  LiveRoomViewModel+RoomEvent.swift
//  LiveRoomDemo
//
//  Created by 天亮了 on 2026/6/10.
//

import Foundation

// MARK: - RoomEvent 统一事件入口

extension LiveRoomViewModel {

    // MARK: - 礼物事件流

    // 开始接收礼物事件。
    // 当前 Demo 用 MockGiftService 模拟服务端推送，先把礼物转成聊天区消息展示。
    func startReceivingGiftEvents() {
        giftService.onGiftReceived = { [weak self] event in
            guard let self else { return }
            self.handleRoomEvent(.gift(event))
        }

        giftService.startGiftEvents(roomID: liveRoom.id)
    }

    // 处理礼物事件。
    // 礼物先进入聊天区；如果 shouldPlayAnimation 为 true，再通知动画层播放。
    private func handleGiftEvent(_ event: GiftEvent) {
        let giftContent = "送出 \(event.giftName) x\(event.giftCount)"
        let message = ChatMessage(
            id: UUID().uuidString,
            type: .gift,
            userName: event.senderName,
            content: giftContent,
            timestamp: Date()
        )

        handleRoomEvent(.chat(message))

        if event.shouldPlayAnimation {
            onGiftAnimationRequested?(event)
        }
    }

    // MARK: - 在线人数事件流

    // 开始接收在线人数变化事件。
    // 当前 Demo 用 MockAudienceService 模拟服务端持续推送，未来可替换为真实长连接事件。
    func startReceivingAudienceEvents() {
        audienceService.onAudienceChanged = { [weak self] event in
            guard let self else { return }
            self.handleRoomEvent(.audience(event))
        }

        // 使用当前房间的真实基础数据启动在线人数流，避免不同房间共用 mock_room / 1000。
        audienceService.startAudience(roomID: liveRoom.id, initialCount: liveRoom.viewerCount)
    }

    // 处理在线人数事件，更新页面状态并通知 HeaderView 刷新。
    private func handleAudienceEvent(_ event: AudienceEvent) {
        onlineCount = event.onlineCount
        onAudienceCountChanged?(event.onlineCount)
    }

    // MARK: - 聊天事件流

    // 开始接收聊天事件。
    func startReceivingChatEvents() {
        updateIMConnectionState(.connecting)

        chatService.startReceivingMessages { [weak self] event in
            guard let self else { return }

            if self.imConnectionState != .connected {
                self.updateIMConnectionState(.connected)
            }

            self.convertChatEventToRoomEvent(event)
        }
    }

    // 将聊天服务事件转换成直播间统一事件，再交给 handleRoomEvent 处理。
    private func convertChatEventToRoomEvent(_ event: ChatEvent) {
        switch event {
        case let .receiveUserMessage(userName, content):
            let message = ChatMessage(
                id: UUID().uuidString,
                type: .user,
                userName: userName,
                content: content,
                timestamp: Date()
            )
            handleRoomEvent(.chat(message))

        case let .receiveSystemMessage(content):
            // 服务端系统事件先只打日志，不进入聊天列表，避免系统消息影响真实聊天内容。
            print("收到系统事件：\(content)")

        case let .userEnterRoom(userName):
            let message = ChatMessage(
                id: UUID().uuidString,
                type: .enterRoom,
                userName: userName,
                content: "",
                timestamp: Date()
            )
            handleRoomEvent(.chat(message))

        case let .userLeaveRoom(userName):
            let message = ChatMessage(
                id: UUID().uuidString,
                type: .leaveRoom,
                userName: userName,
                content: "",
                timestamp: Date()
            )
            handleRoomEvent(.chat(message))

        case let .roomStateChanged(oldState, newState):
            // 房间状态变化由 roomStateLabel 和控制台承接，不作为聊天消息展示。
            print("房间状态变化：\(oldState.displayText) -> \(newState.displayText)")
        }
    }

    // MARK: - IM 状态

    // 更新 IM 连接状态。
    func updateIMConnectionState(_ state: IMConnectionState) {
        imConnectionState = state
        onIMConnectionStateChanged?(state)
    }

    // MARK: - RoomEvent 分发

    // 直播间业务事件统一入口。
    // Chat / Audience / Gift 等 Service 事件先统一包装成 RoomEvent，
    // 再由这里分发到具体处理方法，避免 ViewModel 里散落多套事件入口。
    private func handleRoomEvent(_ event: LiveRoomBusinessEvent) {
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
        chatMessages.append(message)
        onChatMessagesChanged?()
    }
}
