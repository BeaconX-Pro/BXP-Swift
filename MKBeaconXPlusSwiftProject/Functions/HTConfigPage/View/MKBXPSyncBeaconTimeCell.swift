//
//  MKBXPSyncBeaconTimeCell.swift
//  MKBeaconXPlusSwiftProject
//
//  Created by aa on 2026/9/18.
//

import UIKit
import SnapKit
import MKBaseSwiftModule
import MKSwiftCustomUI

// MARK: - Cell Model

public final class MKBXPSyncBeaconTimeCellModel: NSObject {
    public var date: String = ""
    public var time: String = ""
}

// MARK: - Cell Delegate

public protocol MKBXPSyncBeaconTimeCellDelegate: AnyObject {
    func bxp_needUpdateDate()
}

// MARK: - Cell

public final class MKBXPSyncBeaconTimeCell: MKSwiftBaseCell {

    public weak var delegate: MKBXPSyncBeaconTimeCellDelegate?

    public var dataModel: MKBXPSyncBeaconTimeCellModel? {
        didSet { updateUI() }
    }

    // MARK: - Subviews

    private lazy var backView: UIView = {
        let view = UIView()
        view.backgroundColor = .white
        view.layer.masksToBounds = true
        view.layer.cornerRadius = 8
        return view
    }()

    private lazy var msgLabel: UILabel = {
        let label = UILabel()
        label.textColor = MKColor.defaultText
        label.textAlignment = .left
        label.font = MKFont.font(15)
        label.text = "Sync Beacon time"
        return label
    }()

    private lazy var syncButton: UIButton = {
        let btn = MKSwiftUIAdaptor.createRoundedButton(title: "Sync",
                                                       target: self,
                                                       action:  #selector(syncButtonPressed))
        return btn
    }()

    private lazy var dateLabel: UILabel = {
        let label = UILabel()
        label.textColor = MKColor.defaultText
        label.textAlignment = .left
        label.font = MKFont.font(13)
        label.text = "N/A"
        return label
    }()

    private lazy var timeLabel: UILabel = {
        let label = UILabel()
        label.textColor = MKColor.defaultText
        label.textAlignment = .left
        label.font = MKFont.font(13)
        label.text = "N/A"
        return label
    }()

    // MARK: - Init

    public override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        selectionStyle = .none
        contentView.backgroundColor = UIColor(red: 242/255.0, green: 242/255.0, blue: 242/255.0, alpha: 1)
        contentView.addSubview(backView)
        backView.addSubview(msgLabel)
        backView.addSubview(syncButton)
        backView.addSubview(dateLabel)
        backView.addSubview(timeLabel)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    public static func initCellWithTableView(_ tableView: UITableView) -> MKBXPSyncBeaconTimeCell {
        let identifier = "MKBXPSyncBeaconTimeCellIdenty"
        if let cell = tableView.dequeueReusableCell(withIdentifier: identifier) as? MKBXPSyncBeaconTimeCell {
            return cell
        }
        return MKBXPSyncBeaconTimeCell(style: .default, reuseIdentifier: identifier)
    }

    // MARK: - Layout

    public override func layoutSubviews() {
        super.layoutSubviews()

        backView.snp.remakeConstraints { make in
            make.left.equalTo(5)
            make.right.equalTo(-5)
            make.top.equalTo(5)
            make.bottom.equalTo(-5)
        }
        syncButton.snp.remakeConstraints { make in
            make.right.equalTo(-10)
            make.width.equalTo(50)
            make.top.equalTo(5)
            make.height.equalTo(30)
        }
        msgLabel.snp.remakeConstraints { make in
            make.left.equalTo(10)
            make.right.equalTo(syncButton.snp.left).offset(-5)
            make.centerY.equalTo(syncButton)
            make.height.equalTo(MKFont.font(15).lineHeight)
        }
        dateLabel.snp.remakeConstraints { make in
            make.left.equalTo(15)
            make.right.equalTo(backView.snp.centerX).offset(-3)
            make.top.equalTo(syncButton.snp.bottom).offset(10)
            make.height.equalTo(MKFont.font(13).lineHeight)
        }
        timeLabel.snp.remakeConstraints { make in
            make.left.equalTo(backView.snp.centerX).offset(2)
            make.right.equalTo(-15)
            make.centerY.equalTo(dateLabel)
            make.height.equalTo(MKFont.font(13).lineHeight)
        }
    }

    // MARK: - Event

    @objc private func syncButtonPressed() {
        delegate?.bxp_needUpdateDate()
    }

    // MARK: - Private

    private func updateUI() {
        guard let dataModel = dataModel else { return }
        dateLabel.text = dataModel.date
        timeLabel.text = dataModel.time
    }
}
