//
//  GiftQueueManager.swift
//  LiveRoomDemo
//
//  Created by 天亮了 on 2026/6/9.
//

import Foundation

/// 礼物队列管理器。
///
/// 负责把连续到来的礼物事件排队，保证礼物动画按顺序播放，
/// 避免多个礼物同时触发时互相覆盖。
final class GiftQueueManager {

    /// 当前需要播放礼物动画时回调给展示层。
    var onGiftReadyToPlay: ((GiftEvent) -> Void)?

    /// 等待播放的礼物队列。
    private var pendingGiftEvents: [GiftEvent] = []

    /// 当前是否正在播放礼物动画。
    private var isPlayingGiftAnimation = false

    /// 入队一个礼物事件。
    func enqueue(_ event: GiftEvent) {
        pendingGiftEvents.append(event)
        playNextGiftIfNeeded()
    }

    /// 当前礼物动画播放完成。
    ///
    /// 展示层播放完动画后必须调用这个方法，
    /// 否则队列会一直认为当前礼物还在播放，下一个礼物不会继续展示。
    func finishCurrentGift() {
        isPlayingGiftAnimation = false
        playNextGiftIfNeeded()
    }

    /// 清空礼物队列。
    ///
    /// Cell 复用、房间离开、直播结束时都应该调用，
    /// 避免旧房间礼物动画串到新房间。
    func reset() {
        pendingGiftEvents.removeAll()
        isPlayingGiftAnimation = false
        onGiftReadyToPlay = nil
    }

    /// 如果当前没有播放动画，则取出下一个礼物开始播放。
    private func playNextGiftIfNeeded() {
        guard isPlayingGiftAnimation == false else { return }
        guard pendingGiftEvents.isEmpty == false else { return }

        let event = pendingGiftEvents.removeFirst()
        isPlayingGiftAnimation = true
        onGiftReadyToPlay?(event)
    }
}
