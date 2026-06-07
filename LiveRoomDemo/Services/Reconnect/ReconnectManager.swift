//
//  ReconnectManager.swift
//  LiveRoomDemo
//
//  Created by 天亮了 on 2026/6/7.
//

import Foundation

final class ReconnectManager {
    private let maxRetryCount: Int
    private let retryInterval: TimeInterval

    private var reconnectTimer: Timer?

    private(set) var currentRetryCount = 0

    init(maxRetryCount: Int = 3, retryInterval: TimeInterval = 2.0) {
        self.maxRetryCount = maxRetryCount
        self.retryInterval = retryInterval
    }

    // 是否还允许继续重连
    // 用于避免无限重连，真实项目中可以防止弱网场景下持续消耗资源
    func canRetry() -> Bool {
        currentRetryCount < maxRetryCount
    }

    // 记录一次重连尝试
    // 只有真正发起重连时才调用，避免状态展示和实际重试次数不一致
    func recordRetry() {
        currentRetryCount += 1
    }

    // 当前重连间隔
    // Phase4 先使用固定间隔，后续可以升级为指数退避策略
    func currentRetryInterval() -> TimeInterval {
        retryInterval
    }

    // 开始一次自动重连
    // 如果已经超过最大重试次数，直接回调失败；否则等待固定间隔后触发重连动作
    func startReconnect(onRetry: @escaping (Int) -> Void, onReachLimit: @escaping () -> Void) {
        cancelReconnect()

        guard canRetry() else {
            onReachLimit()
            return
        }

        recordRetry()
        let retryCount = currentRetryCount

        reconnectTimer = Timer.scheduledTimer(withTimeInterval: retryInterval, repeats: false) { [weak self] _ in
            self?.reconnectTimer = nil
            onRetry(retryCount)
        }
    }

    // 取消当前等待中的自动重连
    // 用户离开房间、重连成功或进入终态时都应该取消，避免离开页面后继续回调
    func cancelReconnect() {
        reconnectTimer?.invalidate()
        reconnectTimer = nil
    }

    // 重连成功或离开房间后重置
    // 避免下一次进入直播间时沿用上一次的失败次数
    func reset() {
        cancelReconnect()
        currentRetryCount = 0
    }
}
