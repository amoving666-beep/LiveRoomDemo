//
//  RoomLifecycleStateMachine.swift
//  LiveRoomDemo
//
//  Created by 天亮了 on 2026/6/2.
//

import Foundation

final class RoomLifecycleStateMachine {
    private(set) var currentState: RoomLifecycleState = .idle

    func transition(by event: LiveRoomEvent) -> RoomLifecycleState {
        let nextState = resolveNextState(from: currentState, event: event)
        currentState = nextState
        return nextState
    }

    /*
     房间生命周期状态机流转表

     当前状态        事件                    下一个状态        说明
     idle           enterRoom               entering        用户进入
     entering       roomInfoLoaded          preparing       房间信息成功，准备进入直播
     entering       roomInfoLoadFailed      ended           房间信息失败，结束流程

     preparing      streamPlaying           living          首帧成功，房间进入直播中

     living         anchorEnded             ended           主播下播
     living         roomClosed              ended           房间关闭
     living         kickedOut               ended           被踢出房间

     ended          任意事件                 ended           终态，不再恢复
     任意状态        leaveRoom               ended           用户主动离开

     设计原则：
     1. 这里只处理房间生命周期。
     2. 播放器重连、失败、超时属于 LiveStreamState。
     3. IM 连接、重连、断开属于 IMConnectionState。
     */
    
    private func resolveNextState(from state: RoomLifecycleState, event: LiveRoomEvent) -> RoomLifecycleState {
        switch (state, event) {
        // 空闲状态下，用户进入直播间：idle -> entering
        case (.idle, .enterRoom):
            return .entering

        // 房间信息加载完成：entering -> preparing
        case (.entering, .roomInfoLoaded):
            return .preparing

        // 房间信息加载失败：entering -> ended
        case (.entering, .roomInfoLoadFailed):
            return .ended

        // 首帧成功：preparing -> living
        case (.preparing, .streamPlaying):
            return .living

        // 主播下播：living -> ended
        case (.living, .anchorEnded):
            return .ended

        // 房间被关闭：living -> ended
        case (.living, .roomClosed):
            return .ended

        // 当前用户被踢出房间：living -> ended
        case (.living, .kickedOut):
            return .ended

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
