//
//  LiveRoomState.swift
//  LiveRoomDemo
//
//  Created by 天亮了 on 2026/6/2.
//

import Foundation

enum LiveRoomState {
    case idle
    case entering
    case connecting
    case playing
    case reconnecting
    case failed(String)
    case ended
    
    var displayText: String {
        switch self {
        case .idle:
            return "空闲"

        case .entering:
            return "进入中"

        case .connecting:
            return "连接中"

        case .playing:
            return "播放中"

        case .reconnecting:
            return "重连中"

        case .failed(let message):
            return "播放失败：\(message)"

        case .ended:
            return "直播结束"
        }
    }
    
}
