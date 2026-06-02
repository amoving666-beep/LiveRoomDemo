//
//  LiveRoomEvent.swift
//  LiveRoomDemo
//
//  Created by 天亮了 on 2026/6/2.
//

import Foundation

enum LiveRoomEvent {
    case enterRoom
    case roomInfoLoaded
    case streamConnecting
    case streamPlaying
    case networkLost
    case reconnectSuccess
    case reconnectFailed(String)
    case leaveRoom
}
