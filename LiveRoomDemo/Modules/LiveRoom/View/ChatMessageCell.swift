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
        applyStyle(for: message.type)
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

    // 根据消息类型设置不同展示样式
    // 用户消息突出内容，系统/进房/离房消息作为弱提示展示
    private func applyStyle(for type: ChatMessageType) {
        switch type {
        case .user:
            messageLabel.textAlignment = .left
            messageLabel.textColor = .label
            messageLabel.font = .systemFont(ofSize: 14)

        case .system:
            messageLabel.textAlignment = .center
            messageLabel.textColor = .secondaryLabel
            messageLabel.font = .systemFont(ofSize: 13)

        case .enterRoom:
            messageLabel.textAlignment = .center
            messageLabel.textColor = .tertiaryLabel
            messageLabel.font = .systemFont(ofSize: 13)

        case .leaveRoom:
            messageLabel.textAlignment = .center
            messageLabel.textColor = .tertiaryLabel
            messageLabel.font = .systemFont(ofSize: 13)
        }
    }

    // 根据消息类型生成聊天列表展示文案
    // 文案和样式都由 Cell 内部处理，VC 不关心消息如何展示
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
