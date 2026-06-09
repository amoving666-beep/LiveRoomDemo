//
//  GiftAnimationView.swift
//  LiveRoomDemo
//
//  Created by 天亮了 on 2026/6/9.
//

import UIKit
import SnapKit

/// 礼物动画视图。
///
/// 只负责展示单个礼物动画，不负责礼物排队。
/// 礼物排队由 GiftQueueManager 管理。
final class GiftAnimationView: UIView {

    private let giftMessageLabel = UILabel()

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    /// 播放单个礼物动画。
    ///
    /// completion 用于通知 GiftQueueManager 当前礼物动画已结束。
    func playGiftAnimation(_ event: GiftEvent, completion: @escaping () -> Void) {
        giftMessageLabel.layer.removeAllAnimations()
        giftMessageLabel.alpha = 0
        giftMessageLabel.transform = CGAffineTransform(translationX: 0, y: 20).scaledBy(x: 0.9, y: 0.9)
        giftMessageLabel.text = "🎁 \(event.senderName) 送出 \(event.giftName) x\(event.giftCount)"
        giftMessageLabel.isHidden = false

        UIView.animate(withDuration: 0.25, animations: {
            self.giftMessageLabel.alpha = 1
            self.giftMessageLabel.transform = .identity
        }, completion: { _ in
            UIView.animate(withDuration: 0.35, delay: 1.0, options: [], animations: {
                self.giftMessageLabel.alpha = 0
                self.giftMessageLabel.transform = CGAffineTransform(translationX: 0, y: -20).scaledBy(x: 0.95, y: 0.95)
            }, completion: { _ in
                self.giftMessageLabel.isHidden = true
                self.giftMessageLabel.transform = .identity
                completion()
            })
        })
    }

    /// 停止当前礼物动画并恢复初始状态。
    func reset() {
        giftMessageLabel.layer.removeAllAnimations()
        giftMessageLabel.isHidden = true
        giftMessageLabel.alpha = 0
        giftMessageLabel.transform = .identity
    }

    private func setupUI() {
        isUserInteractionEnabled = false
        backgroundColor = .clear

        setupGiftMessageLabel()
        setupLayout()
    }

    private func setupGiftMessageLabel() {
        giftMessageLabel.isHidden = true
        giftMessageLabel.alpha = 0
        giftMessageLabel.font = .boldSystemFont(ofSize: 16)
        giftMessageLabel.textColor = .white
        giftMessageLabel.textAlignment = .center
        giftMessageLabel.backgroundColor = UIColor.black.withAlphaComponent(0.65)
        giftMessageLabel.layer.cornerRadius = 18
        giftMessageLabel.layer.masksToBounds = true
    }

    private func setupLayout() {
        addSubview(giftMessageLabel)

        giftMessageLabel.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
    }
}
