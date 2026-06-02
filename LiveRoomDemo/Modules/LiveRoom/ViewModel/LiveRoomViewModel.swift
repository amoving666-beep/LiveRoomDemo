//
//  LiveRoomViewModel.swift
//  LiveRoomDemo
//
//  Created by 天亮了 on 2026/6/1.
//

import Foundation

final class LiveRoomViewModel {
    
    // MARK: - 服务层依赖
    
    private let chatService: ChatServiceProtocol
    private let liveStreamService: LiveStreamServiceProtocol
    
    // MARK: - 直播间状态机
    
    // 统一处理直播间事件，并根据规则产出新的房间状态
    private let stateMachine = LiveRoomStateMachine()
    // MARK: - 聊天状态
    
    // 当前聊天消息列表，属于页面状态
    private(set) var messages: [ChatMessage] = []
    
    // MARK: - 播放器状态
    
    // 当前模拟播放器状态，例如连接中、播放中、失败
    private(set) var streamState: LiveStreamState = .idle
    
    // MARK: - 房间生命周期状态
    
    // 当前直播间生命周期状态，例如进入中、连接中、播放中、重连中
    private(set) var roomState: LiveRoomState = .idle

    // 聊天消息变化后通知 VC 刷新聊天列表
    var onMessagesChanged: (() -> Void)?
    // 播放器状态变化后通知 VC 刷新播放器区域
    var onStreamStateChanged: ((LiveStreamState) -> Void)?
    // 房间生命周期状态变化后通知 VC 做整体状态渲染
    var onRoomStateChanged: ((LiveRoomState) -> Void)?

    init(
        chatService: ChatServiceProtocol = MockChatService(),
        liveStreamService: LiveStreamServiceProtocol = MockLiveStreamService()
    ) {
        self.chatService = chatService
        self.liveStreamService = liveStreamService
    }

    // 用户进入直播间
    // 当前 Phase2 先模拟：进入房间 -> 房间信息加载完成 -> 准备直播流
    func enterRoom() {
        handle(event: .enterRoom)
        handle(event: .roomInfoLoaded)
        prepareStream()
    }

    // 准备模拟直播流
    // MockLiveStreamService 会先回调 connecting，再回调 playing
    func prepareStream() {
        liveStreamService.prepareStream { [weak self] state in
            guard let self else { return }

            self.streamState = state
            self.onStreamStateChanged?(state)

            switch state {
            case .idle:
                break

            case .connecting:
                self.handle(event: .streamConnecting)

            case .playing:
                self.handle(event: .streamPlaying)

            case .failed(let message):
                self.handle(event: .reconnectFailed(message))
            }
        }
    }

    // 所有直播间事件统一从这里进入
    // Event -> StateMachine -> LiveRoomState -> 通知 VC
    func handle(event: LiveRoomEvent) {
        let nextState = stateMachine.handle(event: event)
        roomState = nextState
        onRoomStateChanged?(nextState)
    }

    // 发送聊天消息
    // 当前通过 ChatServiceProtocol 发送，成功后更新 messages
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

    // 根据下标安全获取聊天消息，避免数组越界
    func message(at index: Int) -> ChatMessage? {
        guard messages.indices.contains(index) else { return nil }
        return messages[index]
    }
}
