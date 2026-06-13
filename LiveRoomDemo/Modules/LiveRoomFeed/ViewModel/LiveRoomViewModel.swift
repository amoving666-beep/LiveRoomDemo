//
//  LiveRoomViewModel.swift
//  LiveRoomDemo
//
//  Created by 天亮了 on 2026/6/1.
//

import Foundation

final class LiveRoomViewModel {
    
    // MARK: - 房间数据
    
    let activeRoom: LiveRoom
    
    // MARK: - 服务层依赖
    
    // 直播间实时事件源：统一承接聊天、礼物、在线人数等实时事件
    let roomEventSource: RoomEventSourceProtocol

    // 播放器服务：暂时仍使用 MockLiveStreamService，后续替换为 AVPlayerLiveStreamService
    let streamService: LiveStreamServiceProtocol
    
    // MARK: - 状态机
    
    // 房间生命周期状态机
    let stateMachine = RoomLifecycleStateMachine()

    // 重连管理器
    let reconnectManager = ReconnectManager()
    
    // MARK: - 页面状态
    
    // 已处理消息 ID，防止 Realtime 重复推送导致聊天重复显示
    private var handledMessageIDs = Set<String>()

    // 最近处理到的事件 seq，用于重连后补拉漏掉的事件
    private var lastReceivedRoomEventSeq: Int = 0

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
    var imState: IMConnectionState = .disconnected
    
    // 在线人数
    var onlineCount: Int = 0
    
    // MARK: - 页面回调
    
    // 房间结束
    var onLiveRoomEnded: (() -> Void)?
    // 聊天消息更新
    var onChatMessagesChanged: (() -> Void)?
    // 播放器状态更新
    var onStreamStateChanged: ((LiveStreamState) -> Void)?
    // 房间状态更新
    var onRoomStateChanged: ((RoomLifecycleState) -> Void)?
    // IM 状态更新
    var onIMStateChanged: ((IMConnectionState) -> Void)?
    // 在线人数更新
    var onAudienceChanged: ((Int) -> Void)?
    // 播放礼物动画
    var onGiftAnimationRequested: ((GiftEvent) -> Void)?
    
    // MARK: - 初始化
    
    init(
        liveRoom: LiveRoom,
        roomEventSource: RoomEventSourceProtocol = SupabaseRealtimeService(),
        liveStreamService: LiveStreamServiceProtocol = MockLiveStreamService()
    ) {
        self.activeRoom = liveRoom
        self.roomEventSource = roomEventSource
        self.streamService = liveStreamService
        self.onlineCount = liveRoom.viewerCount
    }
    // 根据 messageID 判断是否已经处理过。
    func hasHandledMessageID(_ messageID: String) -> Bool {
        handledMessageIDs.contains(messageID)
    }

    // 标记 messageID 已处理。
    func markMessageIDHandled(_ messageID: String) {
        handledMessageIDs.insert(messageID)
    }

    // 更新最近处理到的事件 seq。
    func updateLastReceivedRoomEventSeq(_ seq: Int) {
        lastReceivedRoomEventSeq = max(lastReceivedRoomEventSeq, seq)
    }

    // 当前最近处理到的事件 seq。
    func currentLastReceivedRoomEventSeq() -> Int {
        lastReceivedRoomEventSeq
    }
}
