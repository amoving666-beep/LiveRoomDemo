
//
//  LiveRoomViewModel+DebugCommand.swift
//  LiveRoomDemo
//
//  Created by 天亮了 on 2026/6/10.
//

import Foundation

// MARK: - 调试事件
///调试输入命令：断线、断流、重试、成功、失败、下播、关闭、踢出、结束。
extension LiveRoomViewModel {
    
    // 模拟网络断开事件，触发状态机进入重连中，并交给 ReconnectManager 自动安排重连尝试。
    private func simulateNetworkLostEvent() {
        guard dispatchLiveRoomEvent(.networkLost) else { return }
        updateLiveStreamState(.reconnecting)
        startAutomaticReconnect(reason: "网络断开")
    }
    
    // 模拟直播流中断事件，例如播放器 SDK 回调断流。
    private func simulateStreamInterruptedEvent() {
        guard dispatchLiveRoomEvent(.streamInterrupted) else { return }
        updateLiveStreamState(.reconnecting)
        startAutomaticReconnect(reason: "直播流中断")
    }
    
    // 开始自动重连流程。
    private func startAutomaticReconnect(reason: String) {
        reconnectManager.startReconnect { retryCount in
            print("\(reason)，自动发起第 \(retryCount) 次重连")
        } onReachLimit: { [weak self] in
            self?.simulatePlaybackFailureEvent(message: "重连次数已达上限")
        }
    }
    
    // 模拟失败后的手动重试连接事件。
    private func simulateRetryReconnectEvent() {
        guard dispatchLiveRoomEvent(.retryReconnect) else { return }
        updateLiveStreamState(.reconnecting)
        startAutomaticReconnect(reason: "用户手动重试")
    }
    
    // 模拟重连成功事件。
    private func simulateReconnectSuccessEvent() {
        guard dispatchLiveRoomEvent(.reconnectSuccess) else { return }
        reconnectManager.reset()
        updateLiveStreamState(.playing)
        print("重连成功，重连次数已重置")
    }
    
    // 模拟播放失败事件。
    private func simulatePlaybackFailureEvent(message: String = "模拟播放失败") {
        reconnectManager.cancelReconnect()
        guard dispatchLiveRoomEvent(.reconnectFailed(message)) else { return }
        updateLiveStreamState(.failed(message))
    }
    
    // 模拟首次拉流失败：connecting -> failed。
    private func simulateStreamFailedEvent() {
        simulatePlaybackFailureEvent(message: "模拟拉流失败")
    }

    // 模拟重连超时：reconnecting -> failed。
    private func simulateReconnectTimeoutEvent() {
        guard dispatchLiveRoomEvent(.reconnectTimeout) else { return }
        updateLiveStreamState(.failed("重连超时"))
    }

    // 模拟主播下播：playing / reconnecting -> ended。
    private func simulateAnchorEndedEvent() {
        guard dispatchLiveRoomEvent(.anchorEnded) else { return }
        finishLiveRoomAfterExternalEndEvent(message: "主播已下播")
    }

    // 模拟房间关闭：playing / reconnecting -> ended。
    private func simulateRoomClosedEvent() {
        guard dispatchLiveRoomEvent(.roomClosed) else { return }
        finishLiveRoomAfterExternalEndEvent(message: "房间已关闭")
    }

    // 模拟用户被踢出：playing / reconnecting -> ended。
    private func simulateKickedOutEvent() {
        guard dispatchLiveRoomEvent(.kickedOut) else { return }
        finishLiveRoomAfterExternalEndEvent(message: "你已被踢出直播间")
    }

    // 处理直播间调试命令。
    // 这里不是直接设置状态，而是把用户输入转换成直播间事件，再交给状态机判断是否允许流转。
    func handleLiveRoomDebugCommand(_ text: String) -> Bool {
        switch text {
        case "断线":
            simulateNetworkLostEvent()
            return true

        case "断流":
            simulateStreamInterruptedEvent()
            return true

        case "重试":
            simulateRetryReconnectEvent()
            return true

        case "成功":
            simulateReconnectSuccessEvent()
            return true

        case "失败":
            simulatePlaybackFailureEvent()
            return true

        case "拉流失败":
            simulateStreamFailedEvent()
            return true

        case "超时":
            simulateReconnectTimeoutEvent()
            return true

        case "下播":
            simulateAnchorEndedEvent()
            return true

        case "关闭":
            simulateRoomClosedEvent()
            return true

        case "踢出":
            simulateKickedOutEvent()
            return true

        case "结束":
            leaveLiveRoom()
            return true

        default:
            return false
        }
    }
}
