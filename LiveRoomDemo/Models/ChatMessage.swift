//
//  ChatMessage.swift
//  LiveRoomDemo
//
//  Created by 天亮了 on 2026/6/1.
//


import Foundation

// 聊天消息类型
// 这里不是为了显示文字，而是为了区分不同消息的业务来源和后续 UI 展示方式。
// 例如：普通用户消息要显示用户名和内容，系统消息可以居中展示，进房/离房消息可以用弱提示样式。
enum ChatMessageType {
    // 普通用户聊天消息，例如“我：你好”
    case user

    // 系统提示消息，例如调试指令说明、直播间状态提示
    case system

    // 用户进入直播间消息，例如“张三进入了直播间”
    case enterRoom

    // 用户离开直播间消息，例如“张三离开了直播间”
    case leaveRoom
    
    case gift
}

// 聊天消息模型
// Phase3 开始，聊天列表不再只展示用户输入的文字，而是承载多种 IM 事件转成的消息。
struct ChatMessage {
    // 消息唯一标识，后续做插入、去重、局部刷新时会用到
    let id: String
    // 消息类型，决定这条消息来自用户、系统、进房事件还是离房事件
    let type: ChatMessageType
    // 消息发送者名称；系统消息可以固定为“系统”
    let userName: String
    // 消息正文内容，最终展示在聊天列表中
    let content: String
    // 消息产生时间，后续可用于排序或展示时间
    let timestamp: Date
}
