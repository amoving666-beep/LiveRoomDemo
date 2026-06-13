//
//  LiveRoomViewModel+ChatInput.swift
//  LiveRoomDemo
//
//  Created by 天亮了 on 2026/6/10.
//

import Foundation

// MARK: - 用户聊天输入

extension LiveRoomViewModel {
    
    // 追加真正需要展示在聊天区的系统消息。
    // 注意：状态变化、忽略事件、重连日志不要走这里，否则 Feed 场景下每个房间都会刷大量系统消息。
    func appendSystemChatMessage(_ content: String) {
        let message = ChatMessage(
            id: UUID().uuidString,
            type: .system,
            userName: "系统",
            content: content,
            timestamp: Date()
        )
        
        chatMessages.append(message)
        onChatMessagesChanged?()
    }
    
    // 追加用户进入房间消息，模拟真实 IM 推送事件，保持聊天列表信息完整。
    func appendUserEnterRoomMessage(userName: String) {
        let message = ChatMessage(
            id: UUID().uuidString,
            type: .enterRoom,
            userName: userName,
            content: "",
            timestamp: Date()
        )
        
        chatMessages.append(message)
        onChatMessagesChanged?()
    }
    
    // 追加用户离开房间消息，模拟真实 IM 推送事件，方便聊天列表状态同步。
    func appendUserLeaveRoomMessage(userName: String) {
        let message = ChatMessage(
            id: UUID().uuidString,
            type: .leaveRoom,
            userName: userName,
            content: "",
            timestamp: Date()
        )
        
        chatMessages.append(message)
        onChatMessagesChanged?()
    }
    
    // 发送聊天文本。
    // 先处理调试命令，命中后不再当作普通聊天消息发送。
    func sendChatText(_ text: String) {
        let trimmedText = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedText.isEmpty else { return }

        if handleLiveRoomDebugCommand(trimmedText) {
            return
        }

        // 写入 Supabase；成功后会通过 Realtime 推回并刷新聊天区。
        roomEventSource.sendChatText(
            roomID: activeRoom.id,
            userName: "我",
            content: trimmedText
        )
    }
    
    // 根据下标安全获取聊天消息，避免数组越界。
    func chatMessage(at index: Int) -> ChatMessage? {
        guard chatMessages.indices.contains(index) else { return nil }
        return chatMessages[index]
    }
}
