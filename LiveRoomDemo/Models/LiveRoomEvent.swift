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

    // 房间信息加载失败，例如接口失败或房间不存在
    case roomInfoLoadFailed(String)

    // 直播流开始连接
    case streamConnecting

    // 直播流连接失败，例如播放地址失效或拉流失败
    case streamFailed(String)

    // 直播流连接成功，进入播放中
    case streamPlaying

    // 播放过程中直播流中断，例如播放器回调断流
    case streamInterrupted

    // 播放过程中网络断开
    case networkLost

    // 失败后，用户手动重试重连
    case retryReconnect

    // 重连成功，恢复播放
    case reconnectSuccess

    // 重连超时，超过最大等待时间仍未恢复
    case reconnectTimeout

    // 重连失败，进入失败状态
    case reconnectFailed(String)

    // 主播主动下播
    case anchorEnded

    // 房间被后台关闭
    case roomClosed

    // 当前用户被踢出直播间
    case kickedOut

    // 用户离开直播间
    case leaveRoom
}
