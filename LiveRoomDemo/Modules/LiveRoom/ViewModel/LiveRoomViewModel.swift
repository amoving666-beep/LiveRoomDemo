//
//  LiveRoomViewModel.swift
//  LiveRoomDemo
//
//  Created by 天亮了 on 2026/6/1.
//

import Foundation

final class LiveRoomViewModel {
    private let chatService: ChatServiceProtocol
    private let liveStreamService: LiveStreamServiceProtocol

    private(set) var messages: [ChatMessage] = []
    private(set) var streamState: LiveStreamState = .idle

    var onMessagesChanged: (() -> Void)?
    var onStreamStateChanged: ((LiveStreamState) -> Void)?

    init(
        chatService: ChatServiceProtocol = MockChatService(),
        liveStreamService: LiveStreamServiceProtocol = MockLiveStreamService()
    ) {
        self.chatService = chatService
        self.liveStreamService = liveStreamService
    }

    func prepareStream() {
        liveStreamService.prepareStream { [weak self] state in
            guard let self else { return }

            self.streamState = state
            self.onStreamStateChanged?(state)
        }
    }

    func sendMessage(_ text: String) {
        let trimmedText = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedText.isEmpty else { return }

        chatService.sendMessage(trimmedText) { [weak self] result in
            guard let self else { return }

            switch result {
            case .success(let message):
                self.messages.append(message)
                self.onMessagesChanged?()

            case .failure(let error):
                print("发送消息失败：\(error.localizedDescription)")
            }
        }
    }

    func message(at index: Int) -> ChatMessage? {
        guard messages.indices.contains(index) else { return nil }
        return messages[index]
    }
}
