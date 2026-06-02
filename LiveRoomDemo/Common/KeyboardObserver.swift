//
//  KeyboardObserver.swift
//  LiveRoomDemo
//
//  Created by 天亮了 on 2026/6/2.
//

import UIKit

final class KeyboardObserver {
    var onKeyboardChange: ((CGFloat, Notification) -> Void)?
    var onKeyboardHide: ((Notification) -> Void)?

    private weak var view: UIView?

    init(view: UIView) {
        self.view = view
    }

    deinit {
        stop()
    }

    func start() {
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
        NotificationCenter.default.removeObserver(self)
    }

    @objc private func handleKeyboardWillChangeFrame(_ notification: Notification) {
        guard let view,
              let userInfo = notification.userInfo,
              let keyboardFrameValue = userInfo[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue else {
            return
        }

        let keyboardFrameInScreen = keyboardFrameValue.cgRectValue
        let keyboardFrameInView = view.convert(keyboardFrameInScreen, from: nil)
        let overlapHeight = max(0, view.bounds.maxY - keyboardFrameInView.minY - view.safeAreaInsets.bottom)

        onKeyboardChange?(-overlapHeight, notification)
    }

    @objc private func handleKeyboardWillHide(_ notification: Notification) {
        onKeyboardHide?(notification)
    }
}
