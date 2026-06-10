
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

        startReceivingChatEvents()
        startReceivingAudienceEvents()
        startReceivingGiftEvents()

        dispatchLiveRoomEvent(.roomInfoLoaded)
        prepareLiveStream()
    }

    // Feed Cell 离开屏幕时停止整个房间生命周期。
    func stopLiveRoomLifecycle() {
        chatService.stopReceivingMessages()
        liveStreamService.stopStream()
        audienceService.stopAudience()
        giftService.stopGiftEvents()

        reconnectManager.reset()

        onChatMessagesChanged = nil
        onLiveStreamStateChanged = nil
        onLiveRoomStateChanged = nil
        onAudienceCountChanged = nil
        onGiftAnimationRequested = nil
        onLiveRoomEnded = nil
    }

    // 准备直播流。
    func prepareLiveStream() {
        liveStreamService.prepareStream { [weak self] state in
            guard let self else { return }

            self.updateLiveStreamState(state)

            switch state {
            case .idle:
                break

            case .connecting:
                break

            case .playing:
                self.dispatchLiveRoomEvent(.streamPlaying)

            case .reconnecting:
                self.dispatchLiveRoomEvent(.networkLost)

            case .failed(let message):
                self.dispatchLiveRoomEvent(.reconnectFailed(message))
            }
        }
    }

    // 更新播放器状态。
    func updateLiveStreamState(_ state: LiveStreamState) {
        streamState = state
        onLiveStreamStateChanged?(state)
    }

    // 外部结束事件统一出口。
    func finishLiveRoomAfterExternalEndEvent(message: String) {
        print(message)

        updateLiveStreamState(.idle)
        reconnectManager.reset()

        chatService.stopReceivingMessages()
        liveStreamService.stopStream()
        audienceService.stopAudience()
        giftService.stopGiftEvents()

        onLiveRoomEnded?()
    }

    // 用户主动离开房间。
    func leaveLiveRoom() {
        guard dispatchLiveRoomEvent(.leaveRoom) else { return }

        appendUserLeaveRoomMessage(userName: "我")

        updateLiveStreamState(.idle)
        reconnectManager.reset()

        chatService.stopReceivingMessages()
        liveStreamService.stopStream()
        audienceService.stopAudience()
        giftService.stopGiftEvents()

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

        onLiveRoomStateChanged?(nextState)

        return true
    }
}
