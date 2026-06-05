//
//  ChatMessageCell.swift
//  LiveRoomDemo
//
//  Created by 天亮了 on 2026/6/1.
//

import UIKit
import SnapKit

final class ChatMessageCell: UITableViewCell {
    static let reuseIdentifier = "ChatMessageCell"

    private let messageLabel = UILabel()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupUI()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func configure(with message: ChatMessage) {
        messageLabel.text = displayText(for: message)
    }

    private func setupUI() {
        selectionStyle = .none

        messageLabel.font = .systemFont(ofSize: 14)
        messageLabel.numberOfLines = 0

        contentView.addSubview(messageLabel)

        messageLabel.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(8)
            make.leading.equalToSuperview().offset(16)
            make.trailing.equalToSuperview().offset(-16)
            make.bottom.equalToSuperview().offset(-8)
        }
    }

    // 根据消息类型生成聊天列表展示文案
    // Phase3 先只区分文案，后续可以继续扩展不同颜色、对齐方式和气泡样式
    private func displayText(for message: ChatMessage) -> String {
        switch message.type {
        case .user:
            return "\(message.userName)：\(message.content)"

        case .system:
            return "【系统】\(message.content)"

        case .enterRoom:
            return "\(message.userName) 进入了直播间"

        case .leaveRoom:
            return "\(message.userName) 离开了直播间"
        }
    }
}
