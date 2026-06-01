//
//  MockChatService.swift
//  LiveRoomDemo
//
//  Created by 天亮了 on 2026/6/1.
//

import Foundation

final class MockChatService: ChatServiceProtocol {
    func sendMessage(_ text: String, completion: @escaping (Result<ChatMessage, Error>) -> Void) {
        let message = ChatMessage(
            id: UUID().uuidString,
            userName: "我",
            content: text,
            timestamp: Date()
        )

        completion(.success(message))
    }
}
