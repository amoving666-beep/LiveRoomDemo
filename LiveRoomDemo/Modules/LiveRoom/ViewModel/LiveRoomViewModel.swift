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
            type: .system,
            userName: "系统",
            content: "输入“断线 / 重试 / 成功 / 失败 / 结束”时，可以模拟直播间事件",
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
        appendSystemMessage("欢迎进入直播间，Phase3 开始模拟聊天消息流")
        appendEnterRoomMessage(userName: "游客001")

        startReceivingMessages()

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
        guard dispatchRoomEvent(.networkLost) else { return }
        updateStreamState(.reconnecting)
    }

    // 模拟失败后重试重连：failed -> reconnecting
    // 由用户输入“重试”手动触发
    private func simulateRetryReconnect() {
        guard dispatchRoomEvent(.retryReconnect) else { return }
        updateStreamState(.reconnecting)
    }

    // 模拟重连成功：reconnecting -> playing
    // 由用户输入“成功”手动触发
    private func simulateReconnectSuccess() {
        guard dispatchRoomEvent(.reconnectSuccess) else { return }
        updateStreamState(.playing)
    }

    // 模拟播放失败：playing / reconnecting -> failed
    // 由用户输入“失败”手动触发
    private func simulateFailure() {
        let message = "模拟播放失败"

        guard dispatchRoomEvent(.reconnectFailed(message)) else { return }

        updateStreamState(.failed(message))
    }

    // 用户离开直播间：任意状态 -> ended
    // 由用户输入“结束”手动触发
    private func leaveRoom() {
        guard dispatchRoomEvent(.leaveRoom) else { return }
        appendLeaveRoomMessage(userName: "我")
        updateStreamState(.idle)

        chatService.stopReceivingMessages()
        liveStreamService.stopStream()

        onRoomEnded?()
    }

    // 追加系统消息
    // 用于把直播间状态变化、调试提示等事件转换成聊天列表中的消息
    private func appendSystemMessage(_ content: String) {
        let message = ChatMessage(
            id: UUID().uuidString,
            type: .system,
            userName: "系统",
            content: content,
            timestamp: Date()
        )

        messages.append(message)
        onMessagesChanged?()
    }

    // 追加进房消息
    // 真实项目中通常来自 IM 服务端推送的用户进房事件
    private func appendEnterRoomMessage(userName: String) {
        let message = ChatMessage(
            id: UUID().uuidString,
            type: .enterRoom,
            userName: userName,
            content: "",
            timestamp: Date()
        )

        messages.append(message)
        onMessagesChanged?()
    }

    // 追加离房消息
    // 真实项目中通常来自 IM 服务端推送的用户离房事件
    private func appendLeaveRoomMessage(userName: String) {
        let message = ChatMessage(
            id: UUID().uuidString,
            type: .leaveRoom,
            userName: userName,
            content: "",
            timestamp: Date()
        )

        messages.append(message)
        onMessagesChanged?()
    }

    // 开始接收模拟聊天消息
    // 当前由 MockChatService 定时推送，后续可直接替换为 WebSocket 或 IM SDK 回调
    private func startReceivingMessages() {
        chatService.startReceivingMessages { [weak self] event in
            guard let self else { return }

            self.handleChatEvent(event)
        }
    }

    // 处理聊天事件
    // ChatService 或房间状态机只负责告诉 ViewModel “发生了什么事件”，ViewModel 再转换成页面可展示的 ChatMessage
    private func handleChatEvent(_ event: ChatEvent) {
        switch event {
        case let .receiveUserMessage(userName, content):
            let message = ChatMessage(
                id: UUID().uuidString,
                type: .user,
                userName: userName,
                content: content,
                timestamp: Date()
            )

            messages.append(message)
            onMessagesChanged?()

        case let .receiveSystemMessage(content):
            appendSystemMessage(content)

        case let .userEnterRoom(userName):
            appendEnterRoomMessage(userName: userName)

        case let .userLeaveRoom(userName):
            appendLeaveRoomMessage(userName: userName)

        case let .roomStateChanged(oldState, newState):
            appendSystemMessage("状态变化：\(oldState.displayText) -> \(newState.displayText)")
        }
    }

    // 输入“断线 / 重试 / 成功 / 失败 / 结束”时，不发送聊天消息，而是模拟外部事件
    // 同样的提示文案已作为默认系统消息展示在聊天列表第一行
    // 注意：这里不是直接设置状态，最终能否切换由 LiveRoomStateMachine 决定
    private func handleDebugCommand(_ text: String) -> Bool {
        switch text {
        case "断线":
            simulateNetworkLost()
            return true

        case "重试":
            simulateRetryReconnect()
            return true

        case "成功":
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
    // 返回值表示状态是否真正发生变化
    @discardableResult
    func dispatchRoomEvent(_ event: LiveRoomEvent) -> Bool {
        let oldState = roomState
        let nextState = stateMachine.transition(by: event)

        guard oldState != nextState else {
            print("忽略事件：\(oldState.displayText) -- \(event)")
            appendSystemMessage("忽略事件：当前状态为\(oldState.displayText)，不能处理该事件")
            return false
        }

        roomState = nextState

        print("状态流转：\(oldState.displayText) -- \(event) --> \(nextState.displayText)")

        handleChatEvent(.roomStateChanged(oldState: oldState, newState: nextState))
        onRoomStateChanged?(nextState)

        return true
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
