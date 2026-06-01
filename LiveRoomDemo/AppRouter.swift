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

    func pushLiveRoom(from viewController: UIViewController, room: LiveRoom) {
        let liveRoomViewController = LiveRoomViewController(room: room)
        viewController.navigationController?.pushViewController(liveRoomViewController, animated: true)
    }
}
