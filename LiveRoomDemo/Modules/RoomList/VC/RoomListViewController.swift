//
//  RoomListViewController.swift
//  LiveRoomDemo
//
//  Created by 天亮了 on 2026/6/1.
//

import UIKit
import SnapKit

final class RoomListViewController: UIViewController {
    private let viewModel = RoomListViewModel()
    private let tableView = UITableView(frame: .zero, style: .plain)

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        bindViewModel()
        viewModel.loadRooms()
    }

    private func setupUI() {
        title = "直播房间"
        view.backgroundColor = .systemBackground

        tableView.dataSource = self
        tableView.delegate = self
        tableView.register(RoomCell.self, forCellReuseIdentifier: RoomCell.reuseIdentifier)

        view.addSubview(tableView)

        tableView.snp.makeConstraints { make in
            make.top.equalTo(view.safeAreaLayoutGuide.snp.top)
            make.leading.trailing.bottom.equalToSuperview()
        }
    }

    // 绑定 ViewModel 回调，房间数据变化后刷新列表
    private func bindViewModel() {
        viewModel.onRoomsChanged = { [weak self] in
            DispatchQueue.main.async {
                self?.tableView.reloadData()
            }
        }

        viewModel.onError = { errorMessage in
            print("加载房间失败：\(errorMessage)")
        }
    }
}

extension RoomListViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        viewModel.rooms.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: RoomCell.reuseIdentifier, for: indexPath) as? RoomCell,
              let room = viewModel.room(at: indexPath.row) else {
            return UITableViewCell()
        }

        cell.configure(with: room)
        return cell
    }
}

extension RoomListViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard viewModel.room(at: indexPath.row) != nil else { return }
        // 页面跳转统一交给 AppRouter 处理
        AppRouter.shared.pushLiveRoomFeed(from: self, rooms: viewModel.rooms, initialIndex: indexPath.row)
    }
}
