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
    
    // 状态机负责根据事件计算直播间的下一个生命周期状态
    private let stateMachine = LiveRoomStateMachine()

    // MARK: - 聊天状态
    
    // 当前聊天消息列表，属于页面状态
    private(set) var messages: [ChatMessage] = [
        ChatMessage(
            id: UUID().uuidString,
            userName: "系统",
            content: "输入“断线 / 重连 / 失败 / 结束”时，可以模拟外部事件",
            timestamp: Date()
        )
    ]
    
    // MARK: - 播放器状态
    
    // 当前模拟播放器状态，例如连接中、播放中、失败
    private(set) var streamState: LiveStreamState = .idle
    
    // MARK: - 房间生命周期状态
    
    // 当前直播间生命周期状态，例如进入中、连接中、播放中、重连中
    private(set) var roomState: LiveRoomState = .idle
   
    // 房间结束后通知 VC 退出直播间页面
    var onRoomEnded: (() -> Void)?
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
        dispatchRoomEvent(.enterRoom)
        dispatchRoomEvent(.roomInfoLoaded)
        prepareStream()
    }

    // 准备模拟直播流
    // MockLiveStreamService 会先回调 connecting，再回调 playing
    func prepareStream() {
        liveStreamService.prepareStream { [weak self] state in
            guard let self else { return }

            self.updateStreamState(state)

            switch state {
            case .idle:
                break

            case .connecting:
                self.dispatchRoomEvent(.streamConnecting)

            case .playing:
                self.dispatchRoomEvent(.streamPlaying)

            case .reconnecting:
                self.dispatchRoomEvent(.networkLost)

            case .failed(let message):
                self.dispatchRoomEvent(.reconnectFailed(message))
            }
        }
    }

    // 更新播放器状态，并通知 VC 刷新播放器区域
    private func updateStreamState(_ state: LiveStreamState) {
        streamState = state
        onStreamStateChanged?(state)
    }

    // 模拟网络断开：playing -> reconnecting
    // 由用户输入“断线”手动触发
    private func simulateNetworkLost() {
        dispatchRoomEvent(.networkLost)
        updateStreamState(.reconnecting)
    }

    // 模拟重连成功：reconnecting -> playing
    // 由用户输入“重连”手动触发
    private func simulateReconnectSuccess() {
        dispatchRoomEvent(.reconnectSuccess)
        updateStreamState(.playing)
    }

    // 模拟播放失败：playing / reconnecting -> failed
    // 由用户输入“失败”手动触发
    private func simulateFailure() {
        let message = "模拟播放失败"
        dispatchRoomEvent(.reconnectFailed(message))
        updateStreamState(.failed(message))
    }

    // 用户离开直播间：任意状态 -> ended
    // 由用户输入“结束”手动触发
    private func leaveRoom() {
        dispatchRoomEvent(.leaveRoom)
        updateStreamState(.idle)
        liveStreamService.stopStream()
        onRoomEnded?()
    }

    // 输入“断线 / 重连 / 失败 / 结束”时，不发送聊天消息，而是模拟外部事件
    // 同样的提示文案已作为默认系统消息展示在聊天列表第一行
    // 注意：这里不是直接设置状态，最终能否切换由 LiveRoomStateMachine 决定
    private func handleDebugCommand(_ text: String) -> Bool {
        switch text {
        case "断线":
            simulateNetworkLost()
            return true

        case "重连":
            simulateReconnectSuccess()
            return true

        case "失败":
            simulateFailure()
            return true

        case "结束":
            leaveRoom()
            return true

        default:
            return false
        }
    }

    // 分发直播间事件
    // ViewModel 只负责把外部行为转换成事件，真正的状态流转交给 LiveRoomStateMachine
    func dispatchRoomEvent(_ event: LiveRoomEvent) {
        let oldState = roomState
        let nextState = stateMachine.transition(by: event)
        roomState = nextState
        print("状态流转：\(oldState.displayText) -- \(event) --> \(nextState.displayText)")
        onRoomStateChanged?(nextState)
       
    }

    // 发送聊天消息
    // 当前通过 ChatServiceProtocol 发送，成功后更新 messages
    func sendMessage(_ text: String) {
        let trimmedText = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedText.isEmpty else { return }

        if handleDebugCommand(trimmedText) {
            return
        }

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
