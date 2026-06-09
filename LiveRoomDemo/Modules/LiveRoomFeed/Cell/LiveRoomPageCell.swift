//
//  LiveRoomPageCell.swift
//  LiveRoomDemo
//
//  Created by 天亮了 on 2026/6/7.
//
import UIKit
import SnapKit

final class LiveRoomPageCell: UICollectionViewCell {
    static let reuseIdentifier = "LiveRoomPageCell"

    private let liveRoomContentView = LiveRoomContentView()
    private let giftQueueManager = GiftQueueManager()
    private var liveRoom: LiveRoom?
    private var liveRoomViewModel: LiveRoomViewModel?

    // 当前 Cell 绑定的房间 ViewModel
    // 目前仍由 Cell 创建，后续会改为 Feed 统一管理并注入

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        stopLiveRoom()
    }

    func configure(room: LiveRoom) {
        self.liveRoom = room
        liveRoomContentView.configure(room: room)
    }

    // 绑定外部传入的 ViewModel
    // Phase6 预加载完成后，Feed 会提前创建 ViewModel 并通过这里注入
    func bindLiveRoomViewModel(_ liveRoomViewModel: LiveRoomViewModel) {
        self.liveRoomViewModel = liveRoomViewModel

        liveRoomContentView.chatMessageTableView.dataSource = self

        liveRoomContentView.onSendChatText = { [weak self] text in
            self?.liveRoomViewModel?.sendChatText(text)
        }

        bind(liveRoomViewModel)
    }

    // 当前 cell 进入可见区域时启动直播间
    // 每个 LiveRoomPageCell 都有自己的 ViewModel，避免多个房间共用状态
    @discardableResult
    func startLiveRoom() -> Bool {
        guard liveRoomViewModel == nil else { return false }
        guard let liveRoom else { return false }

        // 当前阶段仍由 Cell 创建 ViewModel。
        // 后续会改成 Feed 预创建后通过 bindLiveRoomViewModel 注入。
        let liveRoomViewModel = LiveRoomViewModel(liveRoom: liveRoom)
        bindLiveRoomViewModel(liveRoomViewModel)

        liveRoomContentView.configure(room: liveRoom)

        liveRoomViewModel.enterRoom()

        return true
    }

    // 当前 cell 离开可见区域时停止直播间
    // 真实项目中这里会释放播放器、停止 IM 消息、取消重连任务
    @discardableResult
    func stopLiveRoom() -> Bool {
        guard liveRoomViewModel != nil else { return false }

        liveRoomViewModel?.stopLiveRoomLifecycle()
        liveRoomViewModel = nil

        liveRoomContentView.onSendChatText = nil
        liveRoomContentView.chatMessageTableView.dataSource = nil
        liveRoomContentView.chatMessageTableView.reloadData()

        giftQueueManager.reset()
        liveRoomContentView.renderStreamState(.idle)
        liveRoomContentView.renderRoomState(.idle)

        return true
    }

    private func bind(_ liveRoomViewModel: LiveRoomViewModel) {
        liveRoomViewModel.onChatMessagesChanged = { [weak self] in
            DispatchQueue.main.async {
                guard let self else { return }
                self.liveRoomContentView.chatMessageTableView.reloadData()
                self.liveRoomContentView.scrollToLatestMessage(
                    messageCount: liveRoomViewModel.chatMessages.count
                )
            }
        }

        liveRoomViewModel.onLiveStreamStateChanged = { [weak self] state in
            DispatchQueue.main.async {
                self?.liveRoomContentView.renderStreamState(state)
            }
        }

        liveRoomViewModel.onLiveRoomStateChanged = { [weak self] state in
            DispatchQueue.main.async {
                self?.liveRoomContentView.renderRoomState(state)
            }
        }

        liveRoomViewModel.onLiveRoomEnded = { [weak self] in
            DispatchQueue.main.async {
                self?.stopLiveRoom()
            }
        }

        liveRoomViewModel.onAudienceCountChanged = { [weak self] count in
            DispatchQueue.main.async {
                self?.liveRoomContentView.updateOnlineCount(count)
            }
        }

        giftQueueManager.onGiftReadyToPlay = { [weak self] event in
            DispatchQueue.main.async {
                self?.liveRoomContentView.playGiftAnimation(event) { [weak self] in
                    self?.giftQueueManager.finishCurrentGift()
                }
            }
        }

        liveRoomViewModel.onGiftAnimationRequested = { [weak self] event in
            self?.giftQueueManager.enqueue(event)
        }
    }

    private func setupUI() {
        contentView.addSubview(liveRoomContentView)

        liveRoomContentView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
    }
}

extension LiveRoomPageCell: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        liveRoomViewModel?.chatMessages.count ?? 0
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(
            withIdentifier: ChatMessageCell.reuseIdentifier,
            for: indexPath
        ) as? ChatMessageCell,
              let message = liveRoomViewModel?.chatMessage(at: indexPath.row) else {
            return UITableViewCell()
        }

        cell.configure(with: message)
        return cell
    }
}
