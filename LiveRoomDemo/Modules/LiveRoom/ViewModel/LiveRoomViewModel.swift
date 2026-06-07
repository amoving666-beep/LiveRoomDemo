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
    
    // MARK: - 状态机
    
    // 状态机负责根据事件计算直播间的下一个生命周期状态
    private let stateMachine = LiveRoomStateMachine()
    
    // MARK: - 页面状态
    
    // 当前聊天消息列表，属于页面状态
    private(set) var chatMessages: [ChatMessage] = [
        ChatMessage(
            id: UUID().uuidString,
            type: .system,
            userName: "系统",
            content: "输入“断线 / 重试 / 成功 / 失败 / 结束”时，可以模拟直播间事件",
            timestamp: Date()
        )
    ]
    
    // 当前模拟播放器状态，例如连接中、播放中、失败
    private(set) var streamState: LiveStreamState = .idle
    
    // 当前直播间生命周期状态，例如进入中、连接中、播放中、重连中
    private(set) var roomState: LiveRoomState = .idle
    
    // MARK: - 页面回调
    
    // 房间结束后通知 VC 退出直播间页面，命名更具业务语义，方便理解回调用途
    var onLiveRoomEnded: (() -> Void)?
    // 聊天消息变化后通知 VC 刷新聊天列表，明确是聊天消息相关的更新
    var onChatMessagesChanged: (() -> Void)?
    // 播放器状态变化后通知 VC 刷新播放器区域，区分直播流状态变化回调
    var onLiveStreamStateChanged: ((LiveStreamState) -> Void)?
    // 房间生命周期状态变化后通知 VC 做整体状态渲染，强调直播间状态变化
    var onLiveRoomStateChanged: ((LiveRoomState) -> Void)?
    
    // MARK: - 初始化
    
    init(
        chatService: ChatServiceProtocol = MockChatService(),
        liveStreamService: LiveStreamServiceProtocol = MockLiveStreamService()
    ) {
        self.chatService = chatService
        self.liveStreamService = liveStreamService
    }
    
    // MARK: - 房间生命周期
    
    // 用户进入直播间，流程模拟进入房间、加载房间信息、准备直播流，保证状态流转顺序合理
    func enterRoom() {
        dispatchLiveRoomEvent(.enterRoom)
        appendSystemChatMessage("欢迎进入直播间，Phase3 开始模拟聊天消息流")
        appendUserEnterRoomMessage(userName: "游客001")
        
        startReceivingChatEvents()
        
        dispatchLiveRoomEvent(.roomInfoLoaded)
        prepareLiveStream()
    }
    
    // 准备模拟直播流，异步回调直播流状态，确保播放器状态和房间状态同步更新
    func prepareLiveStream() {
        liveStreamService.prepareStream { [weak self] state in
            guard let self else { return }
            
            self.updateLiveStreamState(state)
            
            switch state {
            case .idle:
                break
                
            case .connecting:
                self.dispatchLiveRoomEvent(.streamConnecting)
                
            case .playing:
                self.dispatchLiveRoomEvent(.streamPlaying)
                
            case .reconnecting:
                self.dispatchLiveRoomEvent(.networkLost)
                
            case .failed(let message):
                self.dispatchLiveRoomEvent(.reconnectFailed(message))
            }
        }
    }
    
    // MARK: - 播放器状态
    
    // 更新播放器状态，并通知 VC 刷新播放器区域，保持状态和界面同步
    private func updateLiveStreamState(_ state: LiveStreamState) {
        streamState = state
        onLiveStreamStateChanged?(state)
    }
    
    // MARK: - 调试事件
    
    // 模拟网络断开事件，触发状态机事件并更新播放器状态，方便调试网络异常场景
    private func simulateNetworkLostEvent() {
        guard dispatchLiveRoomEvent(.networkLost) else { return }
        updateLiveStreamState(.reconnecting)
    }
    
    // 模拟重试连接事件，触发状态机事件并更新播放器状态，便于调试重连流程
    private func simulateRetryReconnectEvent() {
        guard dispatchLiveRoomEvent(.retryReconnect) else { return }
        updateLiveStreamState(.reconnecting)
    }
    
    // 模拟重连成功事件，触发状态机事件并更新播放器状态，测试重连成功后的状态切换
    private func simulateReconnectSuccessEvent() {
        guard dispatchLiveRoomEvent(.reconnectSuccess) else { return }
        updateLiveStreamState(.playing)
    }
    
    // 模拟播放失败事件，触发状态机事件并更新播放器状态，调试播放失败处理逻辑
    private func simulatePlaybackFailureEvent() {
        let message = "模拟播放失败"
        
        guard dispatchLiveRoomEvent(.reconnectFailed(message)) else { return }
        
        updateLiveStreamState(.failed(message))
    }
    
    // 用户离开直播间，触发状态机事件并清理资源，确保页面退出和状态清理一致
    private func leaveLiveRoom() {
        guard dispatchLiveRoomEvent(.leaveRoom) else { return }
        appendUserLeaveRoomMessage(userName: "我")
        updateLiveStreamState(.idle)
        
        chatService.stopReceivingMessages()
        liveStreamService.stopStream()
        
        onLiveRoomEnded?()
    }

    // 处理直播间调试命令
    // 这里不是直接设置状态，而是把用户输入转换成直播间事件，再交给状态机判断是否允许流转
    private func handleLiveRoomDebugCommand(_ text: String) -> Bool {
        switch text {
        case "断线":
            simulateNetworkLostEvent()
            return true

        case "重试":
            simulateRetryReconnectEvent()
            return true

        case "成功":
            simulateReconnectSuccessEvent()
            return true

        case "失败":
            simulatePlaybackFailureEvent()
            return true

        case "结束":
            leaveLiveRoom()
            return true

        default:
            return false
        }
    }
    
    // MARK: - 聊天事件流
    
    // 追加系统聊天消息，统一系统消息格式，方便后续维护和样式统一
    private func appendSystemChatMessage(_ content: String) {
        let message = ChatMessage(
            id: UUID().uuidString,
            type: .system,
            userName: "系统",
            content: content,
            timestamp: Date()
        )
        
        chatMessages.append(message)
        onChatMessagesChanged?()
    }
    
    // 追加用户进入房间消息，模拟真实 IM 推送事件，保持聊天列表信息完整
    private func appendUserEnterRoomMessage(userName: String) {
        let message = ChatMessage(
            id: UUID().uuidString,
            type: .enterRoom,
            userName: userName,
            content: "",
            timestamp: Date()
        )
        
        chatMessages.append(message)
        onChatMessagesChanged?()
    }
    
    // 追加用户离开房间消息，模拟真实 IM 推送事件，方便聊天列表状态同步
    private func appendUserLeaveRoomMessage(userName: String) {
        let message = ChatMessage(
            id: UUID().uuidString,
            type: .leaveRoom,
            userName: userName,
            content: "",
            timestamp: Date()
        )
        
        chatMessages.append(message)
        onChatMessagesChanged?()
    }
    
    // 开始接收聊天事件，使用服务层回调，方便后续替换为真实 IM 或 WebSocket 实现
    private func startReceivingChatEvents() {
        chatService.startReceivingMessages { [weak self] event in
            guard let self else { return }
            
            self.convertChatEventToMessage(event)
        }
    }
    
    // 将聊天事件转换为页面可展示的消息，解耦事件和 UI 表现，方便扩展和维护
    private func convertChatEventToMessage(_ event: ChatEvent) {
        switch event {
        case let .receiveUserMessage(userName, content):
            let message = ChatMessage(
                id: UUID().uuidString,
                type: .user,
                userName: userName,
                content: content,
                timestamp: Date()
            )
            
            chatMessages.append(message)
            onChatMessagesChanged?()
            
        case let .receiveSystemMessage(content):
            appendSystemChatMessage(content)
            
        case let .userEnterRoom(userName):
            appendUserEnterRoomMessage(userName: userName)
            
        case let .userLeaveRoom(userName):
            appendUserLeaveRoomMessage(userName: userName)
            
        case let .roomStateChanged(oldState, newState):
            appendSystemChatMessage("状态变化：\(oldState.displayText) -> \(newState.displayText)")
        }
    }
    
    // MARK: - 直播间事件分发
    
    // 分发直播间事件，状态机决定是否状态切换，保证状态流转的正确性和可追踪性
    @discardableResult
    func dispatchLiveRoomEvent(_ event: LiveRoomEvent) -> Bool {
        let oldState = roomState
        let nextState = stateMachine.transition(by: event)
        
        guard oldState != nextState else {
            print("忽略事件：\(oldState.displayText) -- \(event)")
            appendSystemChatMessage("忽略事件：当前状态为\(oldState.displayText)，不能处理该事件")
            return false
        }
        
        roomState = nextState
        
        print("状态流转：\(oldState.displayText) -- \(event) --> \(nextState.displayText)")
        
        convertChatEventToMessage(.roomStateChanged(oldState: oldState, newState: nextState))
        onLiveRoomStateChanged?(nextState)
        
        return true
    }
    
    // MARK: - 用户发送消息
    
    // 发送聊天文本，处理调试命令优先，确保调试命令不会被当作普通消息发送
    func sendChatText(_ text: String) {
        let trimmedText = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedText.isEmpty else { return }
        
        if handleLiveRoomDebugCommand(trimmedText) {
            return
        }
        
        chatService.sendMessage(trimmedText) { [weak self] result in
            guard let self else { return }
            
            switch result {
            case .success(let message):
                self.chatMessages.append(message)
                self.onChatMessagesChanged?()
                
            case .failure(let error):
                print("发送消息失败：\(error.localizedDescription)")
            }
        }
    }
    
    // MARK: - 对外读取
    
    // 根据下标安全获取聊天消息，避免数组越界，保证调用安全
    func chatMessage(at index: Int) -> ChatMessage? {
        guard chatMessages.indices.contains(index) else { return nil }
        return chatMessages[index]
    }
}
