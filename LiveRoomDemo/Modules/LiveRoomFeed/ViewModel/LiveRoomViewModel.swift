//
//  LiveRoomViewModel.swift
//  LiveRoomDemo
//
//  Created by 天亮了 on 2026/6/1.
//

import Foundation

final class LiveRoomViewModel {
    
    // MARK: - 房间数据
    
    let liveRoom: LiveRoom
    
    // MARK: - 服务层依赖
    
    let chatService: ChatServiceProtocol
    let liveStreamService: LiveStreamServiceProtocol
    let audienceService: AudienceServiceProtocol
    let giftService: GiftServiceProtocol
    
    // MARK: - 状态机
    
    // 状态机负责根据事件计算直播间的下一个生命周期状态
    let stateMachine = LiveRoomStateMachine()

    // 重连管理器负责控制重连次数和重连间隔，避免弱网场景下无限重试
    let reconnectManager = ReconnectManager()
    
    // MARK: - 页面状态
    
    // 当前聊天消息列表，属于页面状态
    var chatMessages: [ChatMessage] = [
        ChatMessage(
            id: UUID().uuidString,
            type: .system,
            userName: "系统",
            content: "输入“断线 / 断流”可自动重连；失败后输入“重试”可手动重连；输入“失败 / 超时 / 下播 / 关闭 / 踢出 / 结束”可模拟异常事件",
            timestamp: Date()
        )
    ]
    
    // 当前模拟播放器状态，例如连接中、播放中、失败
    var streamState: LiveStreamState = .idle
    
    // 当前直播间生命周期状态，例如进入中、连接中、播放中、重连中
    var roomState: LiveRoomState = .idle
    
    // 当前直播间在线人数，属于持续变化的房间数据
    var onlineCount: Int = 0
    
    // MARK: - 页面回调
    
    // 房间结束后通知 VC 退出直播间页面，命名更具业务语义，方便理解回调用途
    var onLiveRoomEnded: (() -> Void)?
    // 聊天消息变化后通知 VC 刷新聊天列表，明确是聊天消息相关的更新
    var onChatMessagesChanged: (() -> Void)?
    // 播放器状态变化后通知 VC 刷新播放器区域，区分直播流状态变化回调
    var onLiveStreamStateChanged: ((LiveStreamState) -> Void)?
    // 房间生命周期状态变化后通知 VC 做整体状态渲染，强调直播间状态变化
    var onLiveRoomStateChanged: ((LiveRoomState) -> Void)?
    // 在线人数变化后通知页面刷新顶部人数区域
    var onAudienceCountChanged: ((Int) -> Void)?
    // 需要播放礼物动画时通知页面展示动画层
    var onGiftAnimationRequested: ((GiftEvent) -> Void)?
    
    // MARK: - 初始化
    
    init(
        liveRoom: LiveRoom,
        chatService: ChatServiceProtocol = MockChatService(),
        liveStreamService: LiveStreamServiceProtocol = MockLiveStreamService(),
        audienceService: AudienceServiceProtocol = MockAudienceService(),
        giftService: GiftServiceProtocol = MockGiftService()
    ) {
        self.liveRoom = liveRoom
        self.chatService = chatService
        self.liveStreamService = liveStreamService
        self.audienceService = audienceService
        self.giftService = giftService
        self.onlineCount = liveRoom.viewerCount
    }
}
