//
//  LiveRoomViewModel+Lifecycle.swift
//  LiveRoomDemo
//
//  Created by 天亮了 on 2026/6/10.
//

import Foundation

// MARK: - 房间生命周期

extension LiveRoomViewModel {
    
    // 用户进入直播间。
    func enterRoom() {
        dispatchLiveRoomEvent(.enterRoom)

        fetchRecentChatMessages()
        startReceivingRoomEvents()

        dispatchLiveRoomEvent(.roomInfoLoaded)
        prepareLiveStream()
    }

    // 拉取最近聊天历史，进入房间时先补一屏旧消息。
    func fetchRecentChatMessages() {
        roomEventSource.fetchRecentChatMessages(roomID: activeRoom.id, limit: 30) { [weak self] messages in
            guard let self else { return }

            for message in messages {
                if self.hasHandledMessageID(message.id) {
                    continue
                }

                self.markMessageIDHandled(message.id)
                self.chatMessages.append(message)
            }

            self.onChatMessagesChanged?()
        }
    }

    // 绑定网络监听，网络恢复后补拉断线期间漏掉的事件。
    func bindRealtimeNetworkMonitor() {
        realtimeNetworkMonitor.onNetworkUnavailable = { [weak self] in
            guard let self else { return }
            self.updateIMState(.disconnected)
        }

        realtimeNetworkMonitor.onNetworkAvailableAgain = { [weak self] in
            guard let self else { return }

            self.updateIMState(.connecting)
            self.markRealtimeRecoveryNeeded()

            // 网络恢复后不能只调用 roomEventSource.start。
            // startReceivingRoomEvents 会重新绑定回调，再重新订阅 Realtime。
            self.startReceivingRoomEvents()
        }
    }

    // Feed Cell 离开屏幕时停止整个房间生命周期。
    func stopLiveRoomLifecycle() {
        realtimeNetworkMonitor.stop()
        roomEventSource.stop()
        streamService.stopStream()

        reconnectManager.reset()

        onChatMessagesChanged = nil
        onStreamStateChanged = nil
        onRoomStateChanged = nil
        onAudienceChanged = nil
        onGiftAnimationRequested = nil
        onLiveRoomEnded = nil
    }

    // 准备直播流。
    func prepareLiveStream() {
        streamService.prepareStream { [weak self] state in
            guard let self else { return }

            self.updateLiveStreamState(state)

            switch state {
            case .idle:
                break

            case .connecting:
                break

            case .playing:
                // 播放器首帧成功后，房间才从进入流程切到直播中。
                self.dispatchLiveRoomEvent(.streamPlaying)

            case .reconnecting:
                // 播放器重连属于 LiveStreamState，不再改变房间生命周期。
                break

            case .failed(let message):
                // 播放器失败属于 LiveStreamState，不等于房间结束。
                print("播放器失败：\(message)")
            }
        }
    }

    // 更新播放器状态。
    func updateLiveStreamState(_ state: LiveStreamState) {
        streamState = state
        onStreamStateChanged?(state)
    }

    // 外部结束事件统一出口。
    func finishLiveRoomAfterExternalEndEvent(message: String) {
        print(message)

        updateLiveStreamState(.idle)
        reconnectManager.reset()

        realtimeNetworkMonitor.stop()
        roomEventSource.stop()
        streamService.stopStream()

        onLiveRoomEnded?()
    }

    // 用户主动离开房间。
    func leaveLiveRoom() {
        guard dispatchLiveRoomEvent(.leaveRoom) else { return }

        appendUserLeaveRoomMessage(userName: "我")

        updateLiveStreamState(.idle)
        reconnectManager.reset()

        realtimeNetworkMonitor.stop()
        roomEventSource.stop()
        streamService.stopStream()

        onLiveRoomEnded?()
    }

    // 分发直播间事件。
    @discardableResult
    func dispatchLiveRoomEvent(_ event: LiveRoomEvent) -> Bool {
        let oldState = roomState
        let nextState = stateMachine.transition(by: event)

        guard oldState != nextState else {
            print("忽略事件：\(oldState.displayText) -- \(event)")
            return false
        }

        roomState = nextState

        print("状态流转：\(oldState.displayText) -- \(event) --> \(nextState.displayText)")

        onRoomStateChanged?(nextState)

        return true
    }
}
