//
//  ChatServiceProtocol.swift
//  LiveRoomDemo
//
//  Created by 天亮了 on 2026/6/1.
//

import Foundation

protocol ChatServiceProtocol {
    func sendMessage(_ text: String, completion: @escaping (Result<ChatMessage, Error>) -> Void)
}
