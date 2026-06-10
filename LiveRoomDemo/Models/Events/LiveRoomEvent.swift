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

    // 直播首帧成功，房间进入直播中
    case streamPlaying

    // 主播主动下播
    case anchorEnded

    // 房间被后台关闭
    case roomClosed

    // 当前用户被踢出直播间
    case kickedOut

    // 用户离开直播间
    case leaveRoom
}
