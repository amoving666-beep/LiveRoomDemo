//
//  GiftServiceProtocol.swift
//  LiveRoomDemo
//
//  Created by 天亮了 on 2026/6/9.
//

import Foundation

/// 礼物服务协议。
///
/// 用于模拟直播间礼物事件持续推送。
protocol GiftServiceProtocol: AnyObject {

    /// 礼物事件回调。
    var onGiftReceived: ((GiftEvent) -> Void)? { get set }

    /// 开始监听指定房间礼物事件。
    func startGiftEvents(roomID: String)

    /// 停止监听礼物事件。
    func stopGiftEvents()
}
