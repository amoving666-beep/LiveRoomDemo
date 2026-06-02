//
//  LiveRoomStateMachine.swift
//  LiveRoomDemo
//
//  Created by 天亮了 on 2026/6/2.
//

import Foundation

final class LiveRoomStateMachine {
    private(set) var currentState: LiveRoomState = .idle

    func handle(event: LiveRoomEvent) -> LiveRoomState {
        let nextState = transition(from: currentState, event: event)
        currentState = nextState
        return nextState
    }

    /*
     状态流转图

     idle
       ↓ enterRoom
     entering
       ↓ roomInfoLoaded
     connecting
       ↓ streamPlaying
     playing
       ↓ networkLost
     reconnecting

     reconnecting
       ↓ reconnectSuccess
     playing

     reconnecting
       ↓ reconnectFailed
     failed

     任意状态
       ↓ leaveRoom
     ended
     */
    
    private func transition(from state: LiveRoomState, event: LiveRoomEvent) -> LiveRoomState {
        switch (state, event) {
        // 用户进入直播间
        case (.idle, .enterRoom):
            return .entering

        // 房间信息加载完成，开始连接直播流
        case (.entering, .roomInfoLoaded):
            return .connecting

        // 拉流成功，进入播放状态
        case (.connecting, .streamPlaying):
            return .playing

        // 播放过程中网络中断
        case (.playing, .networkLost):
            return .reconnecting

        // 重连成功，恢复播放
        case (.reconnecting, .reconnectSuccess):
            return .playing

        // 重连失败，进入失败状态
        case (.reconnecting, .reconnectFailed(let message)):
            return .failed(message)

        // 用户离开直播间
        case (_, .leaveRoom):
            return .ended

        // 非法状态流转，保持当前状态
        default:
            return state
        }
    }
}
