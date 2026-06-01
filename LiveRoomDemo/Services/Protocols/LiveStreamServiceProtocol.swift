//
//  LiveStreamServiceProtocol.swift
//  LiveRoomDemo
//
//  Created by 天亮了 on 2026/6/1.
//

import Foundation

protocol LiveStreamServiceProtocol {
    func prepareStream(completion: @escaping (LiveStreamState) -> Void)
    func stopStream()
}
