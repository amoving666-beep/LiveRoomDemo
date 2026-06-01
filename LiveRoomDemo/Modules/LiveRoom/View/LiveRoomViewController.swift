//
//  LiveRoomViewController.swift
//  LiveRoomDemo
//
//  Created by 天亮了 on 2026/6/1.
//

import UIKit
import SnapKit

final class LiveRoomViewController: UIViewController {
    private let room: LiveRoom

    // MARK: - 顶部信息区域
    private let headerContainerView = UIView()
    private let anchorLabel = UILabel()
    private let viewerCountLabel = UILabel()

    // MARK: - 模拟播放器区域
    private let playerPlaceholderView = UIView()
    private let playerStatusLabel = UILabel()

    // MARK: - 聊天消息列表区域
    private let chatTableView = UITableView(frame: .zero, style: .plain)

    // MARK: - 底部输入区域
    private let inputContainerView = UIView()
    private let messageTextField = UITextField()
    private let sendButton = UIButton(type: .system)

    init(room: LiveRoom) {
        self.room = room
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
    }

    private func setupUI() {
        title = room.title
        view.backgroundColor = .systemBackground

        setupHeaderView()
        setupPlayerPlaceholderView()
        setupChatTableView()
        setupInputView()
        setupLayout()
    }

    private func setupHeaderView() {
        headerContainerView.backgroundColor = .secondarySystemBackground
        headerContainerView.translatesAutoresizingMaskIntoConstraints = false

        anchorLabel.text = "主播：\(room.anchorName)"
        anchorLabel.font = .boldSystemFont(ofSize: 16)

        viewerCountLabel.text = "在线：\(room.viewerCount)"
        viewerCountLabel.font = .systemFont(ofSize: 14)
        viewerCountLabel.textColor = .secondaryLabel

        let stackView = UIStackView(arrangedSubviews: [anchorLabel, viewerCountLabel])
        stackView.axis = .vertical
        stackView.spacing = 6

        headerContainerView.addSubview(stackView)
        view.addSubview(headerContainerView)

        stackView.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(16)
            make.trailing.equalToSuperview().offset(-16)
            make.centerY.equalToSuperview()
        }
    }

    private func setupPlayerPlaceholderView() {
        playerPlaceholderView.backgroundColor = .black
        playerPlaceholderView.translatesAutoresizingMaskIntoConstraints = false

        playerStatusLabel.text = "模拟播放器区域"
        playerStatusLabel.textColor = .white
        playerStatusLabel.font = .boldSystemFont(ofSize: 18)
        playerStatusLabel.textAlignment = .center

        playerPlaceholderView.addSubview(playerStatusLabel)
        view.addSubview(playerPlaceholderView)

        playerStatusLabel.snp.makeConstraints { make in
            make.center.equalToSuperview()
        }
    }

    private func setupChatTableView() {
        chatTableView.translatesAutoresizingMaskIntoConstraints = false
        chatTableView.dataSource = self
        chatTableView.register(UITableViewCell.self, forCellReuseIdentifier: "ChatCell")
        view.addSubview(chatTableView)
    }

    private func setupInputView() {
        inputContainerView.backgroundColor = .secondarySystemBackground
        inputContainerView.translatesAutoresizingMaskIntoConstraints = false

        messageTextField.placeholder = "说点什么..."
        messageTextField.borderStyle = .roundedRect

        sendButton.setTitle("发送", for: .normal)

        inputContainerView.addSubview(messageTextField)
        inputContainerView.addSubview(sendButton)
        view.addSubview(inputContainerView)
    }

    private func setupLayout() {
        headerContainerView.snp.makeConstraints { make in
            make.top.equalTo(view.safeAreaLayoutGuide.snp.top)
            make.leading.trailing.equalToSuperview()
            make.height.equalTo(72)
        }

        playerPlaceholderView.snp.makeConstraints { make in
            make.top.equalTo(headerContainerView.snp.bottom)
            make.leading.trailing.equalToSuperview()
            make.height.equalTo(220)
        }

        inputContainerView.snp.makeConstraints { make in
            make.leading.trailing.equalToSuperview()
            make.bottom.equalTo(view.safeAreaLayoutGuide.snp.bottom)
            make.height.equalTo(56)
        }

        chatTableView.snp.makeConstraints { make in
            make.top.equalTo(playerPlaceholderView.snp.bottom)
            make.leading.trailing.equalToSuperview()
            make.bottom.equalTo(inputContainerView.snp.top)
        }

        messageTextField.snp.makeConstraints { make in
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
}

extension LiveRoomViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        0
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        tableView.dequeueReusableCell(withIdentifier: "ChatCell", for: indexPath)
    }
}
