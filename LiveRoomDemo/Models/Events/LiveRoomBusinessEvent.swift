//
//  RoomEvent.swift
//  LiveRoomDemo
//
//  Created by 天亮了 on 2026/6/10.
//

import Foundation

enum LiveRoomBusinessEvent {
    case chat(ChatMessage)
    case audience(AudienceEvent)
    case gift(GiftEvent)
}

// Realtime 事件外壳。
// 后面断线重连时，可以根据 seq 补拉漏掉的事件。
struct RoomEventEnvelope {
    let eventID: String
    let seq: Int
    let event: LiveRoomBusinessEvent
}
