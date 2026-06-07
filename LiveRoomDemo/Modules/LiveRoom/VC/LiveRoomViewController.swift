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
    private let liveRoomViewModel = LiveRoomViewModel()
    private let liveRoomContentView = LiveRoomContentView()

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

        // 进入直播间，启动房间生命周期状态流转
        liveRoomViewModel.enterRoom()
    }

    private func setupUI() {
        title = "直播间"
        view.backgroundColor = .systemBackground

        liveRoomContentView.configure(room: room)
        view.addSubview(liveRoomContentView)

        liveRoomContentView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }

        liveRoomContentView.chatMessageTableView.dataSource = self

        liveRoomContentView.onSendChatText = { [weak self] text in
            self?.liveRoomViewModel.sendChatText(text)
        }
    }

    private func bindViewModel() {
        liveRoomViewModel.onChatMessagesChanged = { [weak self] in
            DispatchQueue.main.async {
                self?.liveRoomContentView.chatMessageTableView.reloadData()
                self?.scrollToLatestMessage()
            }
        }

        liveRoomViewModel.onLiveStreamStateChanged = { [weak self] state in
            DispatchQueue.main.async {
                self?.renderStreamState(state)
            }
        }

        liveRoomViewModel.onLiveRoomStateChanged = { [weak self] state in
            DispatchQueue.main.async {
                self?.renderRoomState(state)
            }
        }
        liveRoomViewModel.onLiveRoomEnded = { [weak self] in
            DispatchQueue.main.async {
                self?.navigationController?.popViewController(animated: true)
            }
        }
    }

    // 根据播放器状态刷新模拟播放器区域
    private func renderStreamState(_ state: LiveStreamState) {
        liveRoomContentView.renderStreamState(state)
    }

    // 根据房间生命周期状态刷新页面 UI
    private func renderRoomState(_ state: LiveRoomState) {
        liveRoomContentView.renderRoomState(state)
        print("房间状态变化：\(state)")
    }

    // 发送新消息后滚动到聊天列表底部
    private func scrollToLatestMessage() {
        liveRoomContentView.scrollToLatestMessage(
            messageCount: liveRoomViewModel.chatMessages.count
        )
    }
}

extension LiveRoomViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        liveRoomViewModel.chatMessages.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(
            withIdentifier: ChatMessageCell.reuseIdentifier,
            for: indexPath
        ) as? ChatMessageCell,
              let message = liveRoomViewModel.chatMessage(at: indexPath.row) else {
            return UITableViewCell()
        }

        cell.configure(with: message)
        return cell
    }

}
