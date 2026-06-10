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
