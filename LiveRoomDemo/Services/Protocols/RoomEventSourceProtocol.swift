//
//  RoomEventSourceProtocol.swift
//  LiveRoomDemo
//
//  Created by 天亮了 on 2026/6/12.
//

import Foundation


protocol RoomEventSourceProtocol: AnyObject {
    var onEvent: ((LiveRoomBusinessEvent) -> Void)? { get set }
    var onConnectionStateChanged: ((IMConnectionState) -> Void)? { get set }

    func start(roomID: String)
    func stop()

    // 发送聊天文本，写入实时事件源。
    func sendChatText(roomID: String, userName: String, content: String)
}
