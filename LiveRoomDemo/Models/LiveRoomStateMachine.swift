//
//  LiveRoomStateMachine.swift
//  LiveRoomDemo
//
//  Created by 天亮了 on 2026/6/2.
//

import Foundation

final class LiveRoomStateMachine {
    private(set) var currentState: LiveRoomState = .idle

    func transition(by event: LiveRoomEvent) -> LiveRoomState {
        let nextState = resolveNextState(from: currentState, event: event)
        currentState = nextState
        return nextState
    }

    /*
     直播间状态机流转表

     当前状态        事件                    下一个状态        说明
     idle           enterRoom               entering        用户进入
     entering       roomInfoLoaded          connecting      房间信息成功
     entering       roomInfoLoadFailed      failed          房间信息失败

     connecting     streamConnecting        connecting      开始拉流
     connecting     streamPlaying           playing         拉流成功
     connecting     streamFailed            failed          首次拉流失败

     playing        networkLost             reconnecting    播放中断网
     playing        streamInterrupted       reconnecting    播放流中断
     playing        anchorEnded             ended           主播下播
     playing        roomClosed              ended           房间关闭
     playing        kickedOut               ended           被踢出房间

     reconnecting   reconnectSuccess        playing         重连成功
     reconnecting   reconnectFailed         failed          重连失败
     reconnecting   reconnectTimeout        failed          重连超时
     reconnecting   anchorEnded             ended           重连期间主播下播
     reconnecting   roomClosed              ended           重连期间房间关闭
     reconnecting   kickedOut               ended           重连期间被踢出房间

     failed         retryReconnect          reconnecting    失败后用户手动重试重连
     failed         reconnectFailed         failed          失败状态下更新失败原因
     failed         leaveRoom               ended           离开房间

     ended          任意事件                 ended           终态，不再恢复
     任意状态        leaveRoom               ended           用户主动离开
     
     
     设计原则：
     1. ViewModel 只负责把外部行为转换成 LiveRoomEvent。
     2. 能不能切状态，只由 LiveRoomStateMachine 决定。
     3. 非法事件不报错，保持当前状态。
     */
    
    private func resolveNextState(from state: LiveRoomState, event: LiveRoomEvent) -> LiveRoomState {
        switch (state, event) {
        // 空闲状态下，用户进入直播间：idle -> entering
        case (.idle, .enterRoom):
            return .entering

        // 房间信息加载完成：entering -> connecting
        case (.entering, .roomInfoLoaded):
            return .connecting

        // 房间信息加载失败：entering -> failed
        case (.entering, .roomInfoLoadFailed(let message)):
            return .failed(message)

        // 直播流开始连接：connecting -> connecting
        // 当前状态不变，但保留事件语义，方便后续扩展加载 UI
        case (.connecting, .streamConnecting):
            return .connecting

        // 拉流成功：connecting -> playing
        case (.connecting, .streamPlaying):
            return .playing

        // 首次拉流失败：connecting -> failed
        case (.connecting, .streamFailed(let message)):
            return .failed(message)

        // 播放过程中网络中断：playing -> reconnecting
        case (.playing, .networkLost):
            return .reconnecting

        // 播放流中断：playing -> reconnecting
        case (.playing, .streamInterrupted):
            return .reconnecting

        // 主播下播：playing -> ended
        case (.playing, .anchorEnded):
            return .ended

        // 房间被关闭：playing -> ended
        case (.playing, .roomClosed):
            return .ended

        // 当前用户被踢出房间：playing -> ended
        case (.playing, .kickedOut):
            return .ended

        // 播放中直接失败：playing -> failed
        case (.playing, .reconnectFailed(let message)):
            return .failed(message)

        // 重连成功：reconnecting -> playing
        case (.reconnecting, .reconnectSuccess):
            return .playing

        // 重连失败：reconnecting -> failed
        case (.reconnecting, .reconnectFailed(let message)):
            return .failed(message)

        // 重连超时：reconnecting -> failed
        case (.reconnecting, .reconnectTimeout):
            return .failed("重连超时")

        // 重连期间主播下播：reconnecting -> ended
        case (.reconnecting, .anchorEnded):
            return .ended

        // 重连期间房间被关闭：reconnecting -> ended
        case (.reconnecting, .roomClosed):
            return .ended

        // 重连期间当前用户被踢出房间：reconnecting -> ended
        case (.reconnecting, .kickedOut):
            return .ended

        // 失败后用户手动重试重连：failed -> reconnecting
        case (.failed, .retryReconnect):
            return .reconnecting

        // 失败状态下再次收到失败事件：failed -> failed
        // 这里允许更新失败原因，例如“重连次数已达上限”
        case (.failed, .reconnectFailed(let message)):
            return .failed(message)

        // 直播间已结束后，任何事件都不能恢复状态
        case (.ended, _):
            return .ended

        // 用户离开直播间：任意状态 -> ended
        case (_, .leaveRoom):
            return .ended

        // 非法状态流转，保持当前状态
        default:
            return state
        }
    }
}
