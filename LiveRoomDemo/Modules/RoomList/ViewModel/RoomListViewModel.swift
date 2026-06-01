//
//  RoomListViewModel.swift
//  LiveRoomDemo
//
//  Created by 天亮了 on 2026/6/1.
//

import Foundation

final class RoomListViewModel {
    private let roomService: RoomServiceProtocol

    private(set) var rooms: [LiveRoom] = []

    var onRoomsChanged: (() -> Void)?
    var onError: ((String) -> Void)?

    init(roomService: RoomServiceProtocol = MockRoomService()) {
        self.roomService = roomService
    }

    func loadRooms() {
        roomService.fetchRooms { [weak self] result in
            guard let self else { return }

            switch result {
            case .success(let rooms):
                self.rooms = rooms
                self.onRoomsChanged?()

            case .failure(let error):
                self.onError?(error.localizedDescription)
            }
        }
    }

    func room(at index: Int) -> LiveRoom? {
        guard rooms.indices.contains(index) else { return nil }
        return rooms[index]
    }
}
