//
//  ChatEvent.swift
//  LiveRoomDemo
//
//  Created by 天亮了 on 2026/6/5.
//

import Foundation

// 聊天事件
// 它表示“发生了什么 IM / 直播间事件”，不是最终 UI 要展示的消息
enum ChatEvent {
    // 收到普通用户消息
    case receiveUserMessage(userName: String, content: String)

    // 收到系统消息
    case receiveSystemMessage(content: String)

    // 用户进入直播间
    case userEnterRoom(userName: String)

    // 用户离开直播间
    case userLeaveRoom(userName: String)

    // 房间生命周期状态发生变化
    // 用于把状态机流转也转换成聊天消息流中的系统事件
    case roomStateChanged(oldState: LiveRoomState, newState: LiveRoomState)
}
