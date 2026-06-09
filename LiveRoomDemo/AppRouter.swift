//
//  AppRouter.swift
//  LiveRoomDemo
//
//  Created by 天亮了 on 2026/6/1.
//

import UIKit

final class AppRouter {
    static let shared = AppRouter()

    private init() {}

    func makeRootViewController() -> UIViewController {
        let roomListViewController = RoomListViewController()
        return UINavigationController(rootViewController: roomListViewController)
    }

    // 进入直播 Feed 页面
    // 传入完整房间列表和当前点击下标，用于支持上下滑动切换直播间
    func pushLiveRoomFeed(
        from viewController: UIViewController,
        rooms: [LiveRoom],
        initialIndex: Int
    ) {
        let feedViewController = LiveRoomFeedViewController(
            liveRooms: rooms,
            initialIndex: initialIndex
        )
        viewController.navigationController?.pushViewController(feedViewController, animated: true)
    }
}
