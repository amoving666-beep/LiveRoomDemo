//
//  KeyboardObserver.swift
//  LiveRoomDemo
//
//  Created by 天亮了 on 2026/6/2.
//

import UIKit

final class KeyboardObserver {
    // 键盘高度变化回调：返回输入区域底部需要更新的 offset
    var onKeyboardOffsetChange: ((CGFloat) -> Void)?

    private weak var containerView: UIView?
    private var isObserving = false

    init(containerView: UIView) {
        self.containerView = containerView
    }

    deinit {
        stop()
    }

    func start() {
        guard !isObserving else { return }
        isObserving = true

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleKeyboardWillChangeFrame(_:)),
            name: UIResponder.keyboardWillChangeFrameNotification,
            object: nil
        )

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleKeyboardWillHide(_:)),
            name: UIResponder.keyboardWillHideNotification,
            object: nil
        )
    }

    func stop() {
        guard isObserving else { return }
        isObserving = false
        NotificationCenter.default.removeObserver(self)
    }

    private func handleKeyboard(notification: Notification, offset: CGFloat) {
        let duration = notification.userInfo?[UIResponder.keyboardAnimationDurationUserInfoKey] as? TimeInterval ?? 0.25
        let curveRawValue = notification.userInfo?[UIResponder.keyboardAnimationCurveUserInfoKey] as? UInt ?? UInt(UIView.AnimationCurve.easeInOut.rawValue)
        let options = UIView.AnimationOptions(rawValue: curveRawValue << 16)

        UIView.animate(
            withDuration: duration,
            delay: 0,
            options: options,
            animations: { [weak self] in
                self?.onKeyboardOffsetChange?(offset)
                self?.containerView?.layoutIfNeeded()
            },
            completion: nil
        )
    }

    @objc private func handleKeyboardWillChangeFrame(_ notification: Notification) {
        guard let containerView,
              let userInfo = notification.userInfo,
              let keyboardFrameValue = userInfo[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue else {
            return
        }

        let keyboardFrameInScreen = keyboardFrameValue.cgRectValue
        let keyboardFrameInView = containerView.convert(keyboardFrameInScreen, from: nil)
        let overlapHeight = max(0, containerView.bounds.maxY - keyboardFrameInView.minY - containerView.safeAreaInsets.bottom)

        handleKeyboard(notification: notification, offset: -overlapHeight)
    }

    @objc private func handleKeyboardWillHide(_ notification: Notification) {
        handleKeyboard(notification: notification, offset: 0)
    }
}
