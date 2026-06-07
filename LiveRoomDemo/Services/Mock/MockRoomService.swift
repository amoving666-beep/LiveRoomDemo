//
//  MockRoomService.swift
//  LiveRoomDemo
//
//  Created by 天亮了 on 2026/6/1.
//

import Foundation

final class MockRoomService: RoomServiceProtocol {
    func fetchRooms(completion: @escaping (Result<[LiveRoom], Error>) -> Void) {
        let rooms = [
            LiveRoom(id: "room_001", title: "Swift UIKit 直播间", anchorName: "小明", viewerCount: 1280),
            LiveRoom(id: "room_002", title: "iOS 架构分享", anchorName: "Alice", viewerCount: 856),
            LiveRoom(id: "room_003", title: "弱网重连实战", anchorName: "Bob", viewerCount: 432),
            LiveRoom(id: "room_004", title: "测试 4", anchorName: "Alice", viewerCount: 8156),
            LiveRoom(id: "room_005", title: "测试 5", anchorName: "Alice", viewerCount: 8526),
            LiveRoom(id: "room_006", title: "测试 6", anchorName: "Alice", viewerCount: 8565),
        ]

        completion(.success(rooms))
    }
}
