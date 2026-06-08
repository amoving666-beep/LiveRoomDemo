//
//  MockChatService.swift
//  LiveRoomDemo
//
//  Created by 天亮了 on 2026/6/1.
//

import Foundation

final class MockChatService: ChatServiceProtocol {
    private var timer: Timer?
    private var mockMessageIndex = 0
    private var mockEventIndex = 0

    private let mockMessages = [
        "主播讲得不错",
        "666",
        "这个直播间有点意思",
        "弱网重连这里很关键",
        "Swift UIKit 也能做直播间骨架"
    ]

    func sendMessage(_ text: String, completion: @escaping (Result<ChatMessage, Error>) -> Void) {
        let message = ChatMessage(
            id: UUID().uuidString,
            type: .user,
            userName: "我",
            content: text,
            timestamp: Date()
        )

        completion(.success(message))
    }

    // 模拟服务端持续推送聊天事件
    // 真实项目中这里会替换成 WebSocket / IM SDK 的事件回调
    func startReceivingMessages(onReceive: @escaping (ChatEvent) -> Void) {
        stopReceivingMessages()

        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            guard let self else { return }
            let event = self.makeNextMockEvent()
            onReceive(event)
        }
    }

    // 生成下一条模拟聊天事件
    // Phase3 用于模拟真实 IM 服务端可能推送的不同类型事件
    // 当前只模拟：进房、普通聊天、离房，避免系统消息刷屏
    private func makeNextMockEvent() -> ChatEvent {
        let eventType = mockEventIndex % 3
        mockEventIndex += 1
        
        switch eventType {
        case 0:
            return .userEnterRoom(userName: "游客\(mockEventIndex)")

        case 1:
            let content = mockMessages[mockMessageIndex % mockMessages.count]
            mockMessageIndex += 1
            return .receiveUserMessage(
                userName: "游客\(mockEventIndex)",
                content: content
            )
//        case 2:
//            return .receiveSystemMessage(content: "系统提示：直播间消息流正常")
        default:
            return .userLeaveRoom(userName: "游客\(mockEventIndex)")
        }
    }

    // 停止模拟服务端消息推送
    func stopReceivingMessages() {
        timer?.invalidate()
        timer = nil
    }
}
