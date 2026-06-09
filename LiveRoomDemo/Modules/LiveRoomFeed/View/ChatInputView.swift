//
//  ChatInputView.swift
//  LiveRoomDemo
//
//  Created by 天亮了 on 2026/6/1.
//

import UIKit
import SnapKit

final class ChatInputView: UIView {
    var onSend: ((String) -> Void)?

    private let textField = UITextField()
    private let sendButton = UIButton(type: .system)

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupUI() {
        backgroundColor = .secondarySystemBackground

        textField.placeholder = "说点什么..."
        textField.borderStyle = .roundedRect

        sendButton.setTitle("发送", for: .normal)
        sendButton.addTarget(self, action: #selector(handleSendButtonTapped), for: .touchUpInside)

        addSubview(textField)
        addSubview(sendButton)

        textField.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(12)
            make.centerY.equalToSuperview()
            make.trailing.equalTo(sendButton.snp.leading).offset(-8)
            make.height.equalTo(36)
        }

        sendButton.snp.makeConstraints { make in
            make.trailing.equalToSuperview().offset(-12)
            make.centerY.equalToSuperview()
            make.width.equalTo(52)
        }
    }

    @objc private func handleSendButtonTapped() {
        let text = textField.text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        guard !text.isEmpty else { return }

        onSend?(text)
        textField.text = nil
    }
}
