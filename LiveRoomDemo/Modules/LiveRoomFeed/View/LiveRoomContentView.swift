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
    private let imStateLabel = UILabel()
    private let giftAnimationView = GiftAnimationView()
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

    // 更新直播间在线人数。
    // 在线人数是持续变化数据，只刷新 Header 人数区域，不重刷整个直播间信息。
    func updateOnlineCount(_ count: Int) {
        liveRoomHeaderView.updateOnlineCount(count)
    }

    // 播放礼物动画。
    // ContentView 只负责把礼物动画请求转发给 GiftAnimationView，不再直接管理动画 Label。
    // completion 用于通知 GiftQueueManager 当前礼物已经播放完，可以继续播放下一个礼物。
    func playGiftAnimation(_ event: GiftEvent, completion: @escaping () -> Void) {
        giftAnimationView.playGiftAnimation(event, completion: completion)
    }
    

    // 根据播放器状态刷新播放器区域
    func renderStreamState(_ state: LiveStreamState) {
        livePlayerView.render(state: state)
    }

    // 根据房间生命周期状态刷新页面状态展示
    func renderRoomState(_ state: RoomLifecycleState) {
        liveRoomStateLabel.text = state.displayText
    }

    // 刷新 IM 连接状态。
    func renderIMConnectionState(_ state: IMConnectionState) {
        switch state {
        case .disconnected:
            imStateLabel.text = "IM未连接"
            imStateLabel.textColor = .secondaryLabel

        case .connecting:
            imStateLabel.text = "IM连接中"
            imStateLabel.textColor = .systemOrange

        case .connected:
            imStateLabel.text = "IM已连接"
            imStateLabel.textColor = .systemGreen

        case .reconnecting:
            imStateLabel.text = "IM重连中"
            imStateLabel.textColor = .systemOrange
        }
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
        setupIMStateLabel()
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

    private func setupIMStateLabel() {
        imStateLabel.text = "IM未连接"
        imStateLabel.font = .systemFont(ofSize: 12)
        imStateLabel.textColor = .secondaryLabel
        imStateLabel.textAlignment = .center
        imStateLabel.backgroundColor = UIColor.systemBackground.withAlphaComponent(0.85)
        imStateLabel.layer.cornerRadius = 11
        imStateLabel.layer.masksToBounds = true
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
        addSubview(imStateLabel)
        addSubview(giftAnimationView)
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

        imStateLabel.snp.makeConstraints { make in
            make.top.equalTo(livePlayerView.snp.top).offset(12)
            make.leading.equalTo(livePlayerView.snp.leading).offset(12)
            make.height.equalTo(22)
            make.width.greaterThanOrEqualTo(78)
        }

        giftAnimationView.snp.makeConstraints { make in
            make.centerX.equalTo(livePlayerView.snp.centerX)
            make.bottom.equalTo(livePlayerView.snp.bottom).offset(-20)
            make.height.equalTo(36)
            make.width.greaterThanOrEqualTo(220)
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
