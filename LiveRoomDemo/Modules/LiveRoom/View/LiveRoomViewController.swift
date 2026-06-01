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
    private let viewModel = LiveRoomViewModel()

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
    private let chatInputView = ChatInputView()


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
        bindViewModel()
        viewModel.prepareStream()
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
        chatTableView.dataSource = self
        chatTableView.register(UITableViewCell.self, forCellReuseIdentifier: "ChatCell")
        view.addSubview(chatTableView)
    }

    private func setupInputView() {
        chatInputView.onSend = { [weak self] text in
            self?.viewModel.sendMessage(text)
        }

        view.addSubview(chatInputView)
    }

    private func bindViewModel() {
        viewModel.onMessagesChanged = { [weak self] in
            DispatchQueue.main.async {
                self?.chatTableView.reloadData()
                self?.scrollToLatestMessage()
            }
        }

        viewModel.onStreamStateChanged = { [weak self] state in
            DispatchQueue.main.async {
                self?.renderStreamState(state)
            }
        }
    }

    private func renderStreamState(_ state: LiveStreamState) {
        switch state {
        case .idle:
            playerStatusLabel.text = "模拟播放器区域"

        case .connecting:
            playerStatusLabel.text = "连接中..."

        case .playing:
            playerStatusLabel.text = "正在播放"

        case .failed(let message):
            playerStatusLabel.text = "播放失败：\(message)"
        }
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

        chatInputView.snp.makeConstraints { make in
            make.leading.trailing.equalToSuperview()
            make.bottom.equalTo(view.safeAreaLayoutGuide.snp.bottom)
            make.height.equalTo(56)
        }

        chatTableView.snp.makeConstraints { make in
            make.top.equalTo(playerPlaceholderView.snp.bottom)
            make.leading.trailing.equalToSuperview()
            make.bottom.equalTo(chatInputView.snp.top)
        }
    }

    private func scrollToLatestMessage() {
        guard !viewModel.messages.isEmpty else { return }
        let indexPath = IndexPath(row: viewModel.messages.count - 1, section: 0)
        chatTableView.scrollToRow(at: indexPath, at: .bottom, animated: true)
    }
}

extension LiveRoomViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        viewModel.messages.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "ChatCell", for: indexPath)
        guard let message = viewModel.message(at: indexPath.row) else { return cell }
        cell.textLabel?.text = "\(message.userName)：\(message.content)"
        cell.selectionStyle = .none
        return cell
    }
}
   
