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
    private let headerView = LiveRoomHeaderView()

    // MARK: - 模拟播放器区域
    private let playerView = LivePlayerPlaceholderView()

    // MARK: - 聊天消息列表区域
    private let chatTableView = UITableView(frame: .zero, style: .plain)

    // MARK: - 底部输入区域
    private let chatInputView = ChatInputView()
    private var chatInputBottomConstraint: Constraint?

    // MARK: - 房间状态展示
    private let roomStateLabel = UILabel()

    // MARK: - 键盘监听
    private var keyboardObserver: KeyboardObserver?

    init(room: LiveRoom) {
        self.room = room
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    deinit {
        keyboardObserver?.stop()
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        bindViewModel()
        bindKeyboardObserver()

        // 进入直播间，启动房间生命周期状态流转
        viewModel.enterRoom()
    }

    private func setupUI() {
        title = "直播间"
        view.backgroundColor = .systemBackground

        headerView.configure(with: room)
        view.addSubview(headerView)

        view.addSubview(playerView)
        setupRoomStateLabel()

        setupChatTableView()
        setupInputView()
        setupLayout()
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

    private func setupRoomStateLabel() {
        roomStateLabel.text = "房间状态：空闲"
        roomStateLabel.font = .systemFont(ofSize: 13, weight: .medium)
        roomStateLabel.textColor = .secondaryLabel
        roomStateLabel.textAlignment = .center
        roomStateLabel.backgroundColor = UIColor.systemBackground.withAlphaComponent(0.85)
        roomStateLabel.layer.cornerRadius = 12
        roomStateLabel.layer.masksToBounds = true
        view.addSubview(roomStateLabel)
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

        viewModel.onRoomStateChanged = { [weak self] state in
            DispatchQueue.main.async {
                self?.renderRoomState(state)
            }
        }
        viewModel.onRoomEnded = { [weak self] in
            DispatchQueue.main.async {
                self?.navigationController?.popViewController(animated: true)
            }
        }
    }

    // 根据播放器状态刷新模拟播放器区域
    private func renderStreamState(_ state: LiveStreamState) {
        playerView.render(state: state)
    }

    // 根据房间生命周期状态刷新页面 UI
    private func renderRoomState(_ state: LiveRoomState) {
//        title = "直播间 - \(state.displayText)"
        roomStateLabel.text = "房间状态：\(state.displayText)"
        print("房间状态变化：\(state)")
    }

    private func setupLayout() {
        headerView.snp.makeConstraints { make in
            make.top.equalTo(view.safeAreaLayoutGuide.snp.top)
            make.leading.trailing.equalToSuperview()
            make.height.equalTo(72)
        }

        playerView.snp.makeConstraints { make in
            make.top.equalTo(headerView.snp.bottom)
            make.leading.trailing.equalToSuperview()
            make.height.equalTo(220)
        }

        roomStateLabel.snp.makeConstraints { make in
            make.top.equalTo(playerView.snp.top).offset(12)
            make.trailing.equalTo(playerView.snp.trailing).offset(-12)
            make.height.equalTo(24)
            make.width.greaterThanOrEqualTo(120)
        }

        chatInputView.snp.makeConstraints { make in
            make.leading.trailing.equalToSuperview()
            chatInputBottomConstraint = make.bottom.equalTo(view.safeAreaLayoutGuide.snp.bottom).constraint
            make.height.equalTo(56)
        }

        chatTableView.snp.makeConstraints { make in
            make.top.equalTo(playerView.snp.bottom)
            make.leading.trailing.equalToSuperview()
            make.bottom.equalTo(chatInputView.snp.top)
        }
    }

    // 绑定键盘监听，键盘弹出时上移输入框
    private func bindKeyboardObserver() {
        let observer = KeyboardObserver(containerView: view)

        observer.onKeyboardOffsetChange = { [weak self] offset in
            self?.chatInputBottomConstraint?.update(offset: offset)
        }

        observer.start()
        keyboardObserver = observer
    }

    // 发送新消息后滚动到聊天列表底部
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
