//
//  MockGiftService.swift
//  LiveRoomDemo
//
//  Created by 天亮了 on 2026/6/9.
//

import Foundation

/// Mock 礼物服务。
///
/// 用 DispatchWorkItem 模拟服务端持续推送礼物事件。
/// Feed 场景下 Cell 会复用，所以必须支持停止和取消回调。
final class MockGiftService: GiftServiceProtocol {

    /// 礼物事件回调。
    var onGiftReceived: ((GiftEvent) -> Void)?

    /// 当前房间 ID。
    private var currentRoomID: String?

    /// 当前模拟到第几次礼物事件。
    private var currentGiftIndex: Int = 0

    /// 待执行的礼物任务。
    private var giftWorkItem: DispatchWorkItem?

    /// 模拟礼物数据。
    ///
    /// 当前阶段用于压测礼物队列，所以所有 Mock 礼物都触发动画，
    /// 方便观察 GiftQueueManager 是否能按 1-10 顺序串行播放礼物动画。
    private let mockGiftList: [(senderName: String, giftName: String, giftCount: Int, shouldPlayAnimation: Bool)] = [
        ("1张三", "小心心", 1, true),
        ("2李四", "火箭", 1, true),
        ("3王五", "棒棒糖", 3, true),
        ("4赵六", "嘉年华", 1, true),
        ("5小明", "玫瑰", 5, true),
        ("6小红", "跑车", 1, true),
        ("7阿强", "飞机", 1, true),
        ("8娜娜", "皇冠", 2, true),
        ("9老王", "钻石", 6, true),
        ("10琪琪", "城堡", 1, true)
    ]

    /// 开始监听指定房间礼物事件。
    func startGiftEvents(roomID: String) {
        cancelGiftWorkItem()

        currentRoomID = roomID
        currentGiftIndex = 0
        scheduleNextGiftEvent()
    }

    /// 停止监听礼物事件。
    func stopGiftEvents() {
        cancelGiftWorkItem()
        currentRoomID = nil
        currentGiftIndex = 0
        onGiftReceived = nil
    }

    /// 取消当前礼物任务。
    ///
    /// 注意：这里不能清空 onGiftReceived。
    /// startGiftEvents 会调用它来取消旧任务，如果清空回调，ViewModel 就收不到礼物事件了。
    private func cancelGiftWorkItem() {
        giftWorkItem?.cancel()
        giftWorkItem = nil
    }

    /// 安排下一次礼物事件。
    private func scheduleNextGiftEvent() {
        cancelGiftWorkItem()

        let workItem = DispatchWorkItem { [weak self] in
            self?.handleNextGiftEvent()
        }

        giftWorkItem = workItem
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.2, execute: workItem)
    }

    /// 处理下一次礼物事件。
    private func handleNextGiftEvent() {
        guard let currentRoomID else { return }

        let mockGift = mockGiftList[currentGiftIndex % mockGiftList.count]
        currentGiftIndex += 1

        let event = GiftEvent(
            roomID: currentRoomID,
            senderName: mockGift.senderName,
            giftName: mockGift.giftName,
            giftCount: mockGift.giftCount,
            shouldPlayAnimation: mockGift.shouldPlayAnimation
        )

        onGiftReceived?(event)
        scheduleNextGiftEvent()
    }
}
