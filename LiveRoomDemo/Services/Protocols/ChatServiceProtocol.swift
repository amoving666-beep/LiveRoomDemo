//
//  ChatServiceProtocol.swift
//  LiveRoomDemo
//
//  Created by 天亮了 on 2026/6/1.
//

import Foundation

protocol ChatServiceProtocol {
    // 发送用户消息
    func sendMessage(_ text: String, completion: @escaping (Result<ChatMessage, Error>) -> Void)

    // 开始模拟接收服务端推送的聊天消息
    func startReceivingMessages(onReceive: @escaping (ChatEvent) -> Void)

    // 停止模拟接收消息
    func stopReceivingMessages()
}
