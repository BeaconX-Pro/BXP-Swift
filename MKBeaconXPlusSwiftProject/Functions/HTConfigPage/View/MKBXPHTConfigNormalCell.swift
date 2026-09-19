//
//  MKBXPHTConfigNormalCell.swift
//  MKBeaconXPlusSwiftProject
//
//  Created by aa on 2026/9/18.
//

import UIKit
import SnapKit
import MKBaseSwiftModule
import MKSwiftCustomUI

// MARK: - Cell Model

public final class MKBXPHTConfigNormalCellModel: NSObject {
    public var msg: String = ""
}

// MARK: - Cell

public final class MKBXPHTConfigNormalCell: MKSwiftBaseCell {

    public var dataModel: MKBXPHTConfigNormalCellModel? {
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
        return label
    }()

    private lazy var rightIcon: UIImageView = {
        let iv = UIImageView()
        iv.image = UIImage(named: "bxp_goNextButton.png")
        return iv
    }()

    // MARK: - Init

    public override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        selectionStyle = .none
        contentView.backgroundColor = UIColor(red: 242/255.0, green: 242/255.0, blue: 242/255.0, alpha: 1)
        contentView.addSubview(backView)
        backView.addSubview(msgLabel)
        backView.addSubview(rightIcon)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    public static func initCellWithTableView(_ tableView: UITableView) -> MKBXPHTConfigNormalCell {
        let identifier = "MKBXPHTConfigNormalCellIdenty"
        if let cell = tableView.dequeueReusableCell(withIdentifier: identifier) as? MKBXPHTConfigNormalCell {
            return cell
        }
        return MKBXPHTConfigNormalCell(style: .default, reuseIdentifier: identifier)
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
        msgLabel.snp.remakeConstraints { make in
            make.left.equalTo(10)
            make.right.equalTo(-10)
            make.centerY.equalTo(backView)
            make.height.equalTo(MKFont.font(15).lineHeight)
        }
        rightIcon.snp.remakeConstraints { make in
            make.right.equalTo(-10)
            make.width.equalTo(8)
            make.centerY.equalTo(backView)
            make.height.equalTo(14)
        }
    }

    // MARK: - Private

    private func updateUI() {
        guard let dataModel = dataModel else { return }
        msgLabel.text = dataModel.msg
    }
}
