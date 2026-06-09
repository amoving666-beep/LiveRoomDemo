//
//  LiveRoomHeaderView.swift
//  LiveRoomDemo
//
//  Created by 天亮了 on 2026/6/1.
//

import UIKit
import SnapKit

final class LiveRoomHeaderView: UIView {
    private let anchorLabel = UILabel()
    private let viewerCountLabel = UILabel()

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func configure(with room: LiveRoom) {
        anchorLabel.text = "主播：\(room.anchorName)"
        viewerCountLabel.text = "在线：\(room.viewerCount)"
    }

    /// 更新在线人数。
    ///
    /// 在线人数属于直播间持续变化数据，
    /// 不需要重新 configure 整个 Header，只刷新人数标签。
    func updateOnlineCount(_ count: Int) {
        viewerCountLabel.text = "在线：\(count)"
    }

    private func setupUI() {
        backgroundColor = .secondarySystemBackground

        anchorLabel.font = .boldSystemFont(ofSize: 16)

        viewerCountLabel.font = .systemFont(ofSize: 14)
        viewerCountLabel.textColor = .secondaryLabel

        let stackView = UIStackView(arrangedSubviews: [anchorLabel, viewerCountLabel])
        stackView.axis = .vertical
        stackView.spacing = 6

        addSubview(stackView)

        stackView.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(16)
            make.trailing.equalToSuperview().offset(-16)
            make.centerY.equalToSuperview()
        }
    }
}
