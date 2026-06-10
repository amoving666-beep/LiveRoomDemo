//
//  RoomLifecycleState.swift
//  LiveRoomDemo
//
//  Created by 天亮了 on 2026/6/2.
//

import Foundation

/// 房间生命周期状态。
///
/// 这里只描述“房间”走到哪一步，不描述播放器重连、IM 连接、礼物动画等子系统状态。
enum RoomLifecycleState: Equatable {
    case idle
    case entering
    case preparing
    case living
    case ended
    
    var displayText: String {
        switch self {
        case .idle:
            return "空闲"

        case .entering:
            return "进入中"

        case .preparing:
            return "准备中"

        case .living:
            return "直播中"

        case .ended:
            return "直播结束"
        }
    }
}
