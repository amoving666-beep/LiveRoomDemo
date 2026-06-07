//
//  LiveRoomFeedViewController.swift
//  LiveRoomDemo
//
//  Created by 天亮了 on 2026/6/7.
//

import UIKit
import SnapKit

final class LiveRoomFeedViewController: UIViewController {
    // MARK: - 页面数据

    // Feed 页面中的房间列表，后续可由 RoomList 传入
    private let liveRooms: [LiveRoom]

    // 当前正在展示的房间下标，用于控制播放 / 停止 / 预加载
    private var currentRoomIndex = 0

    // MARK: - UI

    private let liveRoomCollectionView: UICollectionView

    init(liveRooms: [LiveRoom], initialIndex: Int = 0) {
        self.liveRooms = liveRooms
        self.currentRoomIndex = initialIndex

        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .vertical
        layout.minimumLineSpacing = 0
        layout.minimumInteritemSpacing = 0

        self.liveRoomCollectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)

        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        scrollToInitialRoomIfNeeded()
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        stopLiveRoomIfCellVisible(at: currentRoomIndex)
    }

    // MARK: - UI

    private func setupUI() {
        title = "直播 Feed"
        view.backgroundColor = .systemBackground

        liveRoomCollectionView.isPagingEnabled = true
        liveRoomCollectionView.showsVerticalScrollIndicator = false
        liveRoomCollectionView.backgroundColor = .systemBackground
        liveRoomCollectionView.dataSource = self
        liveRoomCollectionView.delegate = self
        liveRoomCollectionView.register(
            LiveRoomPageCell.self,
            forCellWithReuseIdentifier: LiveRoomPageCell.reuseIdentifier
        )

        view.addSubview(liveRoomCollectionView)

        liveRoomCollectionView.snp.makeConstraints { make in
            make.top.equalTo(view.safeAreaLayoutGuide.snp.top)
            make.leading.trailing.bottom.equalToSuperview()
        }
    }

    // MARK: - 初始定位

    private var hasScrolledToInitialRoom = false

    private func scrollToInitialRoomIfNeeded() {
        guard !hasScrolledToInitialRoom else { return }
        guard liveRooms.indices.contains(currentRoomIndex) else { return }

        hasScrolledToInitialRoom = true

        let indexPath = IndexPath(item: currentRoomIndex, section: 0)
        liveRoomCollectionView.scrollToItem(at: indexPath, at: .centeredVertically, animated: false)
        liveRoomCollectionView.layoutIfNeeded()
        startLiveRoomIfCellVisible(at: currentRoomIndex)
    }

    // MARK: - 房间切换

    private func updateCurrentRoomIfNeeded() {
        let pageHeight = liveRoomCollectionView.bounds.height
        guard pageHeight > 0 else { return }

        let newIndex = Int(round(liveRoomCollectionView.contentOffset.y / pageHeight))
        guard liveRooms.indices.contains(newIndex) else { return }
        guard newIndex != currentRoomIndex else { return }

        currentRoomIndex = newIndex
        startLiveRoomIfCellVisible(at: newIndex)
    }
    
    // 启动指定下标对应的直播间 cell
    // 只有 cell 当前可见时才会被 collectionView.cellForItem(at:) 取到
    private func startLiveRoomIfCellVisible(at index: Int) {
        guard liveRooms.indices.contains(index) else { return }
        let indexPath = IndexPath(item: index, section: 0)
        guard let cell = liveRoomCollectionView.cellForItem(at: indexPath) as? LiveRoomPageCell else {
            return
        }

        cell.startLiveRoom()
        print("开始房间：\(liveRooms[index].title)")
    }

    // 停止指定下标对应的直播间 cell
    // cell 不可见时取不到，说明已经被系统回收或离开屏幕
    private func stopLiveRoomIfCellVisible(at index: Int) {
        guard liveRooms.indices.contains(index) else { return }
        let indexPath = IndexPath(item: index, section: 0)
        guard let cell = liveRoomCollectionView.cellForItem(at: indexPath) as? LiveRoomPageCell else {
            return
        }

        cell.stopLiveRoom()
        print("停止房间：\(liveRooms[index].title)")
    }
}

extension LiveRoomFeedViewController: UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        liveRooms.count
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let cell = collectionView.dequeueReusableCell(
            withReuseIdentifier: LiveRoomPageCell.reuseIdentifier,
            for: indexPath
        ) as? LiveRoomPageCell else {
            return UICollectionViewCell()
        }

        let room = liveRooms[indexPath.item]
        cell.configure(room: room)
        return cell
    }
}

extension LiveRoomFeedViewController: UICollectionViewDelegateFlowLayout {
    func collectionView(
        _ collectionView: UICollectionView,
        layout collectionViewLayout: UICollectionViewLayout,
        sizeForItemAt indexPath: IndexPath
    ) -> CGSize {
        collectionView.bounds.size
    }

    func collectionView(_ collectionView: UICollectionView, willDisplay cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
        guard let liveRoomPageCell = cell as? LiveRoomPageCell else { return }
        guard indexPath.item == currentRoomIndex else { return }

        liveRoomPageCell.startLiveRoom()
        print("开始房间：\(liveRooms[indexPath.item].title)")
    }

    func collectionView(_ collectionView: UICollectionView, didEndDisplaying cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
        guard let liveRoomPageCell = cell as? LiveRoomPageCell else { return }

        liveRoomPageCell.stopLiveRoom()
        print("停止房间：\(liveRooms[indexPath.item].title)")
    }
}

extension LiveRoomFeedViewController: UIScrollViewDelegate {
    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        updateCurrentRoomIfNeeded()
    }

    func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
        if !decelerate {
            updateCurrentRoomIfNeeded()
        }
    }
}
