//
//  RealtimeNetworkMonitor.swift
//  LiveRoomDemo
//
//  Created by 天亮了 on 2026/6/14.
//

import Foundation

//
//  RealtimeNetworkMonitor.swift
//  LiveRoomDemo
//
//  Created by 天亮了 on 2026/6/14.
//

import Foundation
import Network

// 监听网络状态，用于网络恢复后触发 Realtime 补偿逻辑。
final class RealtimeNetworkMonitor {
    var onNetworkAvailableAgain: (() -> Void)?
    var onNetworkUnavailable: (() -> Void)?

    private let monitor = NWPathMonitor()
    private let monitorQueue = DispatchQueue(label: "com.liveroomdemo.realtime.network.monitor")
    private var hasStarted = false
    private var lastPathStatus: NWPath.Status?

    func start() {
        guard !hasStarted else { return }
        hasStarted = true

        monitor.pathUpdateHandler = { [weak self] path in
            guard let self else { return }

            let oldStatus = self.lastPathStatus
            self.lastPathStatus = path.status

            DispatchQueue.main.async {
                switch path.status {
                case .satisfied:
                    if oldStatus == .unsatisfied || oldStatus == .requiresConnection {
                        self.onNetworkAvailableAgain?()
                    }

                case .unsatisfied, .requiresConnection:
                    self.onNetworkUnavailable?()

                @unknown default:
                    break
                }
            }
        }

        monitor.start(queue: monitorQueue)
    }

    func stop() {
        guard hasStarted else { return }
        hasStarted = false
        monitor.cancel()
        onNetworkAvailableAgain = nil
        onNetworkUnavailable = nil
    }
}
