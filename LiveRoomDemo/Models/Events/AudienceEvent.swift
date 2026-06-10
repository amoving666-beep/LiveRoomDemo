//
//  AudienceEvent.swift
//  LiveRoomDemo
//
//  Created by 天亮了 on 2026/6/9.
//

import Foundation

/// 在线人数事件。
///
/// 真实直播间里，在线人数通常不是页面主动刷新，
/// 而是由长连接 / 轮询 / 服务端推送持续变化。
/// 当前 Demo 用它来模拟“人数变化流”。
struct AudienceEvent {
    /// 当前直播间 ID。
    let roomID: String

    /// 最新在线人数。
    let onlineCount: Int

    /// 本次人数变化值。
    /// 正数表示增加，负数表示减少。
    let changeCount: Int
}
