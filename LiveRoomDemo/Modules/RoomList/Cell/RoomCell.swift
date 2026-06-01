//
//  RoomCell.swift
//  LiveRoomDemo
//
//  Created by 天亮了 on 2026/6/1.
//

import UIKit

final class RoomCell: UITableViewCell {
    static let reuseIdentifier = "RoomCell"

    private let titleLabel = UILabel()
    private let anchorLabel = UILabel()
    private let viewerCountLabel = UILabel()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupUI()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func configure(with room: LiveRoom) {
        titleLabel.text = room.title
        anchorLabel.text = "主播：\(room.anchorName)"
        viewerCountLabel.text = "在线：\(room.viewerCount)"
    }

    private func setupUI() {
        selectionStyle = .none

        titleLabel.font = .boldSystemFont(ofSize: 16)
        anchorLabel.font = .systemFont(ofSize: 14)
        viewerCountLabel.font = .systemFont(ofSize: 13)
        viewerCountLabel.textColor = .secondaryLabel

        let stackView = UIStackView(arrangedSubviews: [titleLabel, anchorLabel, viewerCountLabel])
        stackView.axis = .vertical
        stackView.spacing = 6
        stackView.translatesAutoresizingMaskIntoConstraints = false

        contentView.addSubview(stackView)

        NSLayoutConstraint.activate([
            stackView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 12),
            stackView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            stackView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            stackView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -12)
        ])
    }
}
