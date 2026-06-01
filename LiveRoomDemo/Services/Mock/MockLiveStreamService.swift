//
//  MockLiveStreamService.swift
//  LiveRoomDemo
//
//  Created by 天亮了 on 2026/6/1.
//

import Foundation

final class MockLiveStreamService: LiveStreamServiceProtocol {
    func prepareStream(completion: @escaping (LiveStreamState) -> Void) {
        completion(.connecting)

        DispatchQueue.main.asyncAfter(deadline: .now() + 1.8) {
            completion(.playing)
        }
    }

    func stopStream() {
        print("停止模拟直播流")
    }
}
