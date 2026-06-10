//
//  LiveStreamState.swift
//  LiveRoomDemo
//
//  Created by 天亮了 on 2026/6/1.
//

import Foundation

enum LiveStreamState {
    case idle
    case connecting
    case playing
    case failed(String)
    case reconnecting
}
