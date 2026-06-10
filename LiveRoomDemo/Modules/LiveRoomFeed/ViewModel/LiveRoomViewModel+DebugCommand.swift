
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
    
    // 开始自动重连流程。
    private func startAutomaticReconnect(reason: String) {
        reconnectManager.startReconnect { retryCount in
            print("\(reason)，自动发起第 \(retryCount) 次重连")
        } onReachLimit: { [weak self] in
            self?.reconnectManager.cancelReconnect()
            self?.updateLiveStreamState(.failed("重连次数已达上限"))
        }
    }

    // 处理直播间调试命令。
    // 播放器类命令只改 LiveStreamState；房间结束类命令才走 RoomLifecycleStateMachine。
    func handleLiveRoomDebugCommand(_ text: String) -> Bool {
        switch text {
        case "断线":
            updateLiveStreamState(.reconnecting)
            startAutomaticReconnect(reason: "网络断开")
            return true

        case "断流":
            updateLiveStreamState(.reconnecting)
            startAutomaticReconnect(reason: "直播流中断")
            return true

        case "重试":
            updateLiveStreamState(.reconnecting)
            startAutomaticReconnect(reason: "用户手动重试")
            return true

        case "成功":
            reconnectManager.reset()
            updateLiveStreamState(.playing)
            print("播放器重连成功，重连次数已重置")
            return true

        case "失败":
            reconnectManager.cancelReconnect()
            updateLiveStreamState(.failed("模拟播放失败"))
            return true

        case "拉流失败":
            reconnectManager.cancelReconnect()
            updateLiveStreamState(.failed("模拟拉流失败"))
            return true

        case "超时":
            reconnectManager.cancelReconnect()
            updateLiveStreamState(.failed("重连超时"))
            return true

        case "下播":
            guard dispatchLiveRoomEvent(.anchorEnded) else { return true }
            finishLiveRoomAfterExternalEndEvent(message: "主播已下播")
            return true

        case "关闭":
            guard dispatchLiveRoomEvent(.roomClosed) else { return true }
            finishLiveRoomAfterExternalEndEvent(message: "房间已关闭")
            return true

        case "踢出":
            guard dispatchLiveRoomEvent(.kickedOut) else { return true }
            finishLiveRoomAfterExternalEndEvent(message: "你已被踢出直播间")
            return true

        case "结束":
            leaveLiveRoom()
            return true

        default:
            return false
        }
    }
}
