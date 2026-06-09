//
//  LivePlayerPlaceholderView.swift
//  LiveRoomDemo
//
//  Created by 天亮了 on 2026/6/1.
//
import UIKit
import SnapKit

final class LivePlayerPlaceholderView: UIView {
    private let statusLabel = UILabel()

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func render(state: LiveStreamState) {
        switch state {
        case .idle:
            statusLabel.text = "模拟播放器区域"

        case .connecting:
            statusLabel.text = "连接中..."

        case .playing:
            statusLabel.text = "正在播放"

        case .reconnecting:
            statusLabel.text = "重连中..."

        case .failed(let message):
            statusLabel.text = "播放失败：\(message)"
        }
    }

    private func setupUI() {
        backgroundColor = .black

        statusLabel.text = "模拟播放器区域"
        statusLabel.textColor = .white
        statusLabel.font = .boldSystemFont(ofSize: 18)
        statusLabel.textAlignment = .center

        addSubview(statusLabel)

        statusLabel.snp.makeConstraints { make in
            make.center.equalToSuperview()
        }
    }
}
