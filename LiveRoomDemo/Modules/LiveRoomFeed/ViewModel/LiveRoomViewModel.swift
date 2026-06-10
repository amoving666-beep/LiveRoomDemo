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
    
    // 房间生命周期状态机
    let stateMachine = RoomLifecycleStateMachine()

    // 重连管理器
    let reconnectManager = ReconnectManager()
    
    // MARK: - 页面状态
    
    // 聊天消息
    var chatMessages: [ChatMessage] = [
        ChatMessage(
            id: UUID().uuidString,
            type: .system,
            userName: "系统",
            content: "输入“断线 / 断流”可自动重连；失败后输入“重试”可手动重连；输入“失败 / 超时 / 下播 / 关闭 / 踢出 / 结束”可模拟异常事件",
            timestamp: Date()
        )
    ]
    
    // 播放器状态
    var streamState: LiveStreamState = .idle
    
    // 房间状态
    var roomState: RoomLifecycleState = .idle
    
    // IM 连接状态
    var imConnectionState: IMConnectionState = .disconnected
    
    // 在线人数
    var onlineCount: Int = 0
    
    // MARK: - 页面回调
    
    // 房间结束
    var onLiveRoomEnded: (() -> Void)?
    // 聊天消息更新
    var onChatMessagesChanged: (() -> Void)?
    // 播放器状态更新
    var onLiveStreamStateChanged: ((LiveStreamState) -> Void)?
    // 房间状态更新
    var onLiveRoomStateChanged: ((RoomLifecycleState) -> Void)?
    // IM 状态更新
    var onIMConnectionStateChanged: ((IMConnectionState) -> Void)?
    // 在线人数更新
    var onAudienceCountChanged: ((Int) -> Void)?
    // 播放礼物动画
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
