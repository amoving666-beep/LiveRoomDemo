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

    // 重连管理器负责控制重连次数和重连间隔，避免弱网场景下无限重试
    private let reconnectManager = ReconnectManager()
    
    // MARK: - 页面状态
    
    // 当前聊天消息列表，属于页面状态
    private(set) var chatMessages: [ChatMessage] = [
        ChatMessage(
            id: UUID().uuidString,
            type: .system,
            userName: "系统",
            content: "输入“断线 / 断流”可自动重连；失败后输入“重试”可手动重连；输入“失败 / 超时 / 下播 / 关闭 / 踢出 / 结束”可模拟异常事件",
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
    // 进房消息由 ChatService 模拟服务端推送，ViewModel 不再主动插入，避免和服务端事件重复
    func enterRoom() {
        dispatchLiveRoomEvent(.enterRoom)

        startReceivingChatEvents()
        
        dispatchLiveRoomEvent(.roomInfoLoaded)
        prepareLiveStream()
    }
    
    // 停止直播间生命周期
    // Feed cell 离开屏幕或复用时调用，避免消息 timer / 重连 timer 在不可见 cell 中继续回调
    func stopLiveRoomLifecycle() {
        chatService.stopReceivingMessages()
        liveStreamService.stopStream()
        reconnectManager.reset()

        onChatMessagesChanged = nil
        onLiveStreamStateChanged = nil
        onLiveRoomStateChanged = nil
        onLiveRoomEnded = nil
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
//                self.dispatchLiveRoomEvent(.streamConnecting)
                break
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
    
    // 模拟网络断开事件，触发状态机进入重连中，并交给 ReconnectManager 自动安排重连尝试
    private func simulateNetworkLostEvent() {
        guard dispatchLiveRoomEvent(.networkLost) else { return }
        updateLiveStreamState(.reconnecting)
        startAutomaticReconnect(reason: "网络断开")
    }
    
    // 模拟直播流中断事件，例如播放器 SDK 回调断流
    private func simulateStreamInterruptedEvent() {
        guard dispatchLiveRoomEvent(.streamInterrupted) else { return }
        updateLiveStreamState(.reconnecting)
        startAutomaticReconnect(reason: "直播流中断")
    }
    
    // 开始自动重连流程
    // 输入“断线 / 断流”后会进入 reconnecting，随后由 ReconnectManager 延迟触发自动重连成功
    private func startAutomaticReconnect(reason: String) {
        reconnectManager.startReconnect { [weak self] retryCount in
            guard let self else { return }
            // 自动重连属于状态日志，不进入聊天列表，避免消息区被系统提示刷屏
            print("\(reason)，自动发起第 \(retryCount) 次重连")
        } onReachLimit: { [weak self] in
            self?.simulatePlaybackFailureEvent(message: "重连次数已达上限")
        }
    }
    
    // 模拟失败后的手动重试连接事件
    // 用户输入“重试”后，从 failed 进入 reconnecting，再交给 ReconnectManager 自动完成一次重连尝试
    private func simulateRetryReconnectEvent() {
        guard dispatchLiveRoomEvent(.retryReconnect) else { return }
        updateLiveStreamState(.reconnecting)
        startAutomaticReconnect(reason: "用户手动重试")
    }
    
    // 模拟重连成功事件，触发状态机事件并更新播放器状态，测试重连成功后的状态切换
    private func simulateReconnectSuccessEvent() {
        guard dispatchLiveRoomEvent(.reconnectSuccess) else { return }
        reconnectManager.reset()
        updateLiveStreamState(.playing)
        // 重连结果交给播放器状态和房间状态展示，不塞进聊天列表
        print("重连成功，重连次数已重置")
    }
    
    // 模拟播放失败事件，触发状态机事件并更新播放器状态，调试播放失败处理逻辑
    private func simulatePlaybackFailureEvent(message: String = "模拟播放失败") {
        reconnectManager.cancelReconnect()
        guard dispatchLiveRoomEvent(.reconnectFailed(message)) else { return }
        updateLiveStreamState(.failed(message))
    }
    
    // 模拟首次拉流失败：connecting -> failed
    private func simulateStreamFailedEvent() {
        simulatePlaybackFailureEvent(message: "模拟拉流失败")
    }

    // 模拟重连超时：reconnecting -> failed
    private func simulateReconnectTimeoutEvent() {
        guard dispatchLiveRoomEvent(.reconnectTimeout) else { return }
        updateLiveStreamState(.failed("重连超时"))
    }

    // 模拟主播下播：playing / reconnecting -> ended
    private func simulateAnchorEndedEvent() {
        guard dispatchLiveRoomEvent(.anchorEnded) else { return }
        finishLiveRoomAfterExternalEndEvent(message: "主播已下播")
    }

    // 模拟房间关闭：playing / reconnecting -> ended
    private func simulateRoomClosedEvent() {
        guard dispatchLiveRoomEvent(.roomClosed) else { return }
        finishLiveRoomAfterExternalEndEvent(message: "房间已关闭")
    }

    // 模拟用户被踢出：playing / reconnecting -> ended
    private func simulateKickedOutEvent() {
        guard dispatchLiveRoomEvent(.kickedOut) else { return }
        finishLiveRoomAfterExternalEndEvent(message: "你已被踢出直播间")
    }

    // 外部事件导致直播间结束后的统一清理逻辑
    // 例如主播下播、房间关闭、用户被踢出，都需要停止聊天流和直播流
    private func finishLiveRoomAfterExternalEndEvent(message: String) {
        // 外部结束原因属于房间生命周期日志，当前先输出到控制台，不进入聊天列表
        print(message)
        updateLiveStreamState(.idle)
        reconnectManager.reset()

        chatService.stopReceivingMessages()
        liveStreamService.stopStream()

        onLiveRoomEnded?()
    }
    
    // 用户离开直播间，触发状态机事件并清理资源，确保页面退出和状态清理一致
    private func leaveLiveRoom() {
        guard dispatchLiveRoomEvent(.leaveRoom) else { return }
        appendUserLeaveRoomMessage(userName: "我")
        updateLiveStreamState(.idle)
        reconnectManager.reset()
        
        chatService.stopReceivingMessages()
        liveStreamService.stopStream()
        
        onLiveRoomEnded?()
    }

    // 处理直播间调试命令
    // 这里不是直接设置状态，而是把用户输入转换成直播间事件，再交给状态机判断是否允许流转
    // 这些命令只是当前 Demo 的测试入口，未来可以替换成真实 IM / 播放器 / 网络回调
    private func handleLiveRoomDebugCommand(_ text: String) -> Bool {
        switch text {
        case "断线":
            simulateNetworkLostEvent()
            return true

        case "断流":
            simulateStreamInterruptedEvent()
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

        case "拉流失败":
            simulateStreamFailedEvent()
            return true

        case "超时":
            simulateReconnectTimeoutEvent()
            return true

        case "下播":
            simulateAnchorEndedEvent()
            return true

        case "关闭":
            simulateRoomClosedEvent()
            return true

        case "踢出":
            simulateKickedOutEvent()
            return true

        case "结束":
            leaveLiveRoom()
            return true

        default:
            return false
        }
    }
    
    // MARK: - 聊天事件流
    
    // 追加真正需要展示在聊天区的系统消息
    // 注意：状态变化、忽略事件、重连日志不要走这里，否则 Feed 场景下每个房间都会刷大量系统消息
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
            // 服务端系统事件先只打日志，不进入聊天列表，避免系统消息影响真实聊天内容
            print("收到系统事件：\(content)")
            
        case let .userEnterRoom(userName):
            appendUserEnterRoomMessage(userName: userName)
            
        case let .userLeaveRoom(userName):
            appendUserLeaveRoomMessage(userName: userName)
            
        case let .roomStateChanged(oldState, newState):
            // 房间状态变化由 roomStateLabel 和控制台承接，不作为聊天消息展示
            print("房间状态变化：\(oldState.displayText) -> \(newState.displayText)")
        }
    }
    
    // MARK: - 直播间事件分发
    
    // 分发直播间事件，状态机决定是否状态切换，保证状态流转的正确性和可追踪性
    @discardableResult
    func dispatchLiveRoomEvent(_ event: LiveRoomEvent) -> Bool {
        let oldState = roomState
        let nextState = stateMachine.transition(by: event)
        
        guard oldState != nextState else {
            // 非法事件只作为调试日志输出，不进入聊天列表
            print("忽略事件：\(oldState.displayText) -- \(event)")
            return false
        }
        
        roomState = nextState
        
        print("状态流转：\(oldState.displayText) -- \(event) --> \(nextState.displayText)")
        
        // 状态变化只驱动状态 UI，不再写入聊天列表
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
