//
//  AudienceServiceProtocol.swift
//  LiveRoomDemo
//
//  Created by 天亮了 on 2026/6/9.
//

import Foundation

/// 在线人数服务协议。
///
/// 用于模拟直播间在线人数持续变化。
protocol AudienceServiceProtocol: AnyObject {

    /// 在线人数变化回调。
    var onAudienceChanged: ((AudienceEvent) -> Void)? { get set }

    /// 开始监听指定房间在线人数。
    func startAudience(roomID: String, initialCount: Int)

    /// 停止监听在线人数。
    func stopAudience()
}
