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

        timer = Timer.scheduledTimer(withTimeInterval: 3.0, repeats: true) { [weak self] _ in
            guard let self else { return }
            let content = self.mockMessages[self.mockMessageIndex % self.mockMessages.count]
            self.mockMessageIndex += 1

            let event = ChatEvent.receiveUserMessage(
                userName: "游客\(self.mockMessageIndex)",
                content: content
            )

            onReceive(event)
        }
    }

    // 停止模拟服务端消息推送
    func stopReceivingMessages() {
        timer?.invalidate()
        timer = nil
    }
}
