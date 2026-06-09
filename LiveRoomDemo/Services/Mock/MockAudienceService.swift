//
//  MockAudienceService.swift
//  LiveRoomDemo
//
//  Created by 天亮了 on 2026/6/9.
//

import Foundation

/// Mock 在线人数服务。
///
/// 用 DispatchWorkItem 模拟服务端持续推送在线人数变化。
/// Feed 场景下 Cell 会复用，所以必须支持停止和取消回调。
final class MockAudienceService: AudienceServiceProtocol {

    /// 在线人数变化回调。
    var onAudienceChanged: ((AudienceEvent) -> Void)?

    /// 当前房间 ID。
    private var currentRoomID: String?

    /// 当前在线人数。
    private var currentOnlineCount: Int = 0

    /// 当前模拟到第几次人数变化。
    private var currentEventIndex: Int = 0

    /// 待执行的人数变化任务。
    private var audienceWorkItem: DispatchWorkItem?

    /// 模拟人数变化序列。
    /// 正数表示进入直播间，负数表示离开直播间。
    private let mockChangeList: [Int] = [2, -4, 7, -2, 5, 3, -6, 4]

    /// 开始监听指定房间在线人数。
    func startAudience(roomID: String, initialCount: Int) {
        cancelAudienceWorkItem()

        currentRoomID = roomID
        currentOnlineCount = initialCount
        currentEventIndex = 0

        emitAudienceChange(changeCount: 0)
        scheduleNextAudienceChange()
    }

    /// 停止监听在线人数。
    func stopAudience() {
        cancelAudienceWorkItem()
        currentRoomID = nil
        currentEventIndex = 0
        onAudienceChanged = nil
    }

    /// 取消当前在线人数任务。
    ///
    /// 注意：这里不能清空 onAudienceChanged。
    /// startAudience 会调用它来取消旧任务，如果顺手清空回调，ViewModel 就收不到人数变化了。
    private func cancelAudienceWorkItem() {
        audienceWorkItem?.cancel()
        audienceWorkItem = nil
    }

    /// 安排下一次在线人数变化。
    private func scheduleNextAudienceChange() {
        cancelAudienceWorkItem()

        let workItem = DispatchWorkItem { [weak self] in
            self?.handleNextAudienceChange()
        }

        audienceWorkItem = workItem
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0, execute: workItem)
    }

    /// 处理下一次在线人数变化。
    private func handleNextAudienceChange() {
        guard currentRoomID != nil else { return }

        let changeCount = mockChangeList[currentEventIndex % mockChangeList.count]
        currentOnlineCount = max(0, currentOnlineCount + changeCount)
        currentEventIndex += 1

        emitAudienceChange(changeCount: changeCount)
        scheduleNextAudienceChange()
    }

    /// 对外抛出在线人数事件。
    private func emitAudienceChange(changeCount: Int) {
        guard let currentRoomID else { return }

        let event = AudienceEvent(
            roomID: currentRoomID,
            onlineCount: currentOnlineCount,
            changeCount: changeCount
        )

        onAudienceChanged?(event)
    }
}
