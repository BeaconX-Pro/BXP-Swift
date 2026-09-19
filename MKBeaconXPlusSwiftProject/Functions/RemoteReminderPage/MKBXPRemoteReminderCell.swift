//
//  MKBXPRemoteReminderCell.swift
//  MKBeaconXPlusSwiftProject
//
//  Created by aa on 2026/9/18.
//

import UIKit
import SnapKit
import MKBaseSwiftModule
import MKSwiftCustomUI

// MARK: - Cell Model

public final class MKBXPRemoteReminderCellModel: NSObject {
    public var msg: String = ""
    public var index: Int = 0
}

// MARK: - Cell Delegate

public protocol MKBXPRemoteReminderCellDelegate: AnyObject {
    func bxd_remindButtonPressed(_ index: Int)
}

// MARK: - Cell

public final class MKBXPRemoteReminderCell: MKSwiftBaseCell {

    public weak var delegate: MKBXPRemoteReminderCellDelegate?

    public var dataModel: MKBXPRemoteReminderCellModel? {
        didSet { updateUI() }
    }

    // MARK: - Subviews

    private lazy var msgLabel: UILabel = {
        let label = UILabel()
        label.textAlignment = .left
        label.textColor = MKColor.defaultText
        label.font = MKFont.font(15)
        return label
    }()

    private lazy var remindButton: UIButton = {
        let btn = MKSwiftUIAdaptor.createRoundedButton(title: "Remind",
                                                  target: self,
                                                  action: #selector(remindButtonPressed))
        return btn
    }()

    // MARK: - Init

    public override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        selectionStyle = .none
        contentView.addSubview(msgLabel)
        contentView.addSubview(remindButton)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    public static func initCellWithTableView(_ tableView: UITableView) -> MKBXPRemoteReminderCell {
        let identifier = "MKBXPRemoteReminderCellIdenty"
        if let cell = tableView.dequeueReusableCell(withIdentifier: identifier) as? MKBXPRemoteReminderCell {
            return cell
        }
        return MKBXPRemoteReminderCell(style: .default, reuseIdentifier: identifier)
    }

    // MARK: - Layout

    public override func layoutSubviews() {
        super.layoutSubviews()

        remindButton.snp.makeConstraints { make in
            make.right.equalTo(-15)
            make.width.equalTo(60)
            make.centerY.equalTo(contentView)
            make.height.equalTo(35)
        }
        msgLabel.snp.makeConstraints { make in
            make.left.equalTo(15)
            make.right.equalTo(remindButton.snp.left).offset(-15)
            make.centerY.equalTo(contentView)
            make.height.equalTo(MKFont.font(15).lineHeight)
        }
    }

    // MARK: - Event

    @objc private func remindButtonPressed() {
        delegate?.bxd_remindButtonPressed(dataModel?.index ?? 0)
    }

    // MARK: - Private

    private func updateUI() {
        guard let dataModel = dataModel else { return }
        msgLabel.text = dataModel.msg
    }
}
