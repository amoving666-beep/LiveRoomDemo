//
//  LiveRoomContentView.swift
//  LiveRoomDemo
//
//  Created by 天亮了 on 2026/6/7.
//

import UIKit
import SnapKit

final class LiveRoomContentView: UIView {
    // MARK: - 对外回调

    // 用户点击发送按钮后的聊天文本回调
    var onSendChatText: ((String) -> Void)?

    // MARK: - 子视图

    private let liveRoomHeaderView = LiveRoomHeaderView()
    private let livePlayerView = LivePlayerPlaceholderView()
    private let liveRoomStateLabel = UILabel()
    let chatMessageTableView = UITableView(frame: .zero, style: .plain)
    private let chatMessageInputView = ChatInputView()

    // MARK: - 键盘处理

    // 输入框底部约束，键盘弹出时通过 KeyboardObserver 更新 offset
    private var chatMessageInputBottomConstraint: Constraint?
    private var keyboardObserver: KeyboardObserver?

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    deinit {
        keyboardObserver?.stop()
    }

    // MARK: - 对外配置

    // 配置直播间基础信息，例如主播名、在线人数
    func configure(room: LiveRoom) {
        liveRoomHeaderView.configure(with: room)
    }

    // 根据播放器状态刷新播放器区域
    func renderStreamState(_ state: LiveStreamState) {
        livePlayerView.render(state: state)
    }

    // 根据房间生命周期状态刷新页面状态展示
    func renderRoomState(_ state: LiveRoomState) {
        liveRoomStateLabel.text = state.displayText
    }

    // 发送新消息后滚动到聊天列表底部
    func scrollToLatestMessage(messageCount: Int) {
        let actualRowCount = chatMessageTableView.numberOfRows(inSection: 0)
        let safeRowCount = min(messageCount, actualRowCount)

        guard safeRowCount > 0 else { return }

        let indexPath = IndexPath(row: safeRowCount - 1, section: 0)
        chatMessageTableView.scrollToRow(at: indexPath, at: .bottom, animated: true)
    }

    // MARK: - UI

    private func setupUI() {
        backgroundColor = .systemBackground

        setupLiveRoomStateLabel()
        setupChatMessageTableView()
        setupChatMessageInputView()
        setupLayout()
        bindKeyboardObserver()
    }

    private func setupLiveRoomStateLabel() {
        liveRoomStateLabel.text = "准备中"
        liveRoomStateLabel.font = .systemFont(ofSize: 13)
        liveRoomStateLabel.textColor = .secondaryLabel
        liveRoomStateLabel.textAlignment = .center
        liveRoomStateLabel.backgroundColor = UIColor.systemBackground.withAlphaComponent(0.85)
        liveRoomStateLabel.layer.cornerRadius = 12
        liveRoomStateLabel.layer.masksToBounds = true
    }

    private func setupChatMessageTableView() {
        chatMessageTableView.dataSource = nil
        chatMessageTableView.separatorStyle = .none
        chatMessageTableView.keyboardDismissMode = .interactive
        chatMessageTableView.register(ChatMessageCell.self, forCellReuseIdentifier: ChatMessageCell.reuseIdentifier)
    }

    private func setupChatMessageInputView() {
        chatMessageInputView.onSend = { [weak self] text in
            self?.onSendChatText?(text)
        }
    }

    private func setupLayout() {
        addSubview(liveRoomHeaderView)
        addSubview(livePlayerView)
        addSubview(liveRoomStateLabel)
        addSubview(chatMessageTableView)
        addSubview(chatMessageInputView)

        liveRoomHeaderView.snp.makeConstraints { make in
            make.top.equalToSuperview()
            make.leading.trailing.equalToSuperview()
            make.height.equalTo(72)
        }

        livePlayerView.snp.makeConstraints { make in
            make.top.equalTo(liveRoomHeaderView.snp.bottom)
            make.leading.trailing.equalToSuperview()
            make.height.equalTo(220)
        }

        liveRoomStateLabel.snp.makeConstraints { make in
            make.top.equalTo(livePlayerView.snp.top).offset(12)
            make.trailing.equalTo(livePlayerView.snp.trailing).offset(-12)
            make.height.equalTo(24)
            make.width.greaterThanOrEqualTo(80)
        }

        chatMessageInputView.snp.makeConstraints { make in
            make.leading.trailing.equalToSuperview()
            chatMessageInputBottomConstraint = make.bottom.equalToSuperview().constraint
            make.height.equalTo(56)
        }

        chatMessageTableView.snp.makeConstraints { make in
            make.top.equalTo(livePlayerView.snp.bottom)
            make.leading.trailing.equalToSuperview()
            make.bottom.equalTo(chatMessageInputView.snp.top)
        }
    }

    // 绑定键盘监听
    // KeyboardObserver 已经封装了系统键盘通知，这里只负责根据键盘高度更新输入框底部约束
    private func bindKeyboardObserver() {
        let observer = KeyboardObserver(containerView: self)

        observer.onKeyboardOffsetChange = { [weak self] offset in
            self?.chatMessageInputBottomConstraint?.update(offset: offset)
        }

        observer.start()
        keyboardObserver = observer
    }
}
