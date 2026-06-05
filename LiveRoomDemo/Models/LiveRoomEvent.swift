//
//  LiveRoomEvent.swift
//  LiveRoomDemo
//
//  Created by 天亮了 on 2026/6/2.
//

import Foundation

enum LiveRoomEvent {
    // 用户进入直播间
    case enterRoom

    // 房间信息加载完成
    case roomInfoLoaded

    // 直播流开始连接
    case streamConnecting

    // 直播流连接成功，进入播放中
    case streamPlaying

    // 播放过程中网络断开
    case networkLost

    // 失败后，用户手动重试重连
    case retryReconnect

    // 重连成功，恢复播放
    case reconnectSuccess

    // 重连失败，进入失败状态
    case reconnectFailed(String)

    // 用户离开直播间
    case leaveRoom
}
