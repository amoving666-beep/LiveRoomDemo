//
//  GiftEvent.swift
//  LiveRoomDemo
//
//  Created by 天亮了 on 2026/6/9.
//

import Foundation

/// 礼物事件。
///
/// 真实直播间里，礼物通常来自 IM / 长连接推送，
/// 当前 Demo 用它来模拟“用户送礼物”的业务事件。
struct GiftEvent {
    /// 当前直播间 ID。
    let roomID: String

    /// 送礼物的用户昵称。
    let senderName: String

    /// 礼物名称，例如小心心、火箭。
    let giftName: String

    /// 礼物数量。
    let giftCount: Int

    /// 是否需要触发动画。
    let shouldPlayAnimation: Bool
}
