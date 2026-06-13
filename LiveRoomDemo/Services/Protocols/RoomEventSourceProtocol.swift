
//
//  RoomEventSourceProtocol.swift
//  LiveRoomDemo
//
//  Created by 天亮了 on 2026/6/12.
//

import Foundation

// 直播间实时事件源协议。
// 负责：监听实时事件、拉历史、补漏、发送聊天。
protocol RoomEventSourceProtocol: AnyObject {
    // 收到一条带 seq 的实时事件。
    // ViewModel 根据 seq 记录进度，根据 event 分发业务。
    var onRoomEventEnvelopeReceived: ((RoomEventEnvelope) -> Void)? { get set }

    // Realtime 连接状态变化。
    // 用来同步 IMConnectionState。
    var onConnectionStateChanged: ((IMConnectionState) -> Void)? { get set }

    // 开始监听当前房间的新事件。
    func start(roomID: String)

    // 停止监听并释放回调。
    func stop()

    // 进入房间时拉最近聊天记录。
    func fetchRecentChatMessages(roomID: String, limit: Int, completion: @escaping ([ChatMessage]) -> Void)

    // 重连后拉 seq 之后漏掉的事件。
    func fetchMissedRoomEventEnvelopes(roomID: String, afterSeq: Int, completion: @escaping ([RoomEventEnvelope]) -> Void)

    // 用户发送聊天文本，写入事件表。
    func sendChatText(roomID: String, userName: String, content: String)
}
