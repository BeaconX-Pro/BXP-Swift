//
//  MKBXPSlotCell.swift
//  MKBeaconXPlusSwiftProject
//
//  Created by aa on 2026/9/18.
//

import UIKit
import SnapKit
import MKBaseSwiftModule
import MKSwiftCustomUI

/// Slot 列表 Cell
public final class MKBXPSlotCell: MKSwiftBaseCell {

    // MARK: - 公开属性

    public var dataModel: MKBXPSlotDataModel? {
        didSet {
            updateUI()
        }
    }

    // MARK: - 常量

    private let offsetX: CGFloat = 15

    // MARK: - Subviews

    private lazy var leftMsgLabel: UILabel = {
        let label = UILabel()
        label.textColor = MKColor.defaultText
        label.font = MKFont.font(15)
        label.numberOfLines = 0
        label.textAlignment = .left
        return label
    }()

    private lazy var rightMsgLabel: UILabel = {
        let label = UILabel()
        label.textColor = MKColor.fromHex(0x808080)
        label.font = MKFont.font(13)
        label.textAlignment = .right
        return label
    }()

    private lazy var rightIcon: UIImageView = {
        let iv = UIImageView()
        iv.image = UIImage(named: "bxp_goNextButton.png")
        return iv
    }()

    // MARK: - 类方法

    public class func initCellWithTableView(_ tableView: UITableView) -> MKBXPSlotCell {
        let identifier = "MKBXPSlotCellIdenty"
        var cell = tableView.dequeueReusableCell(withIdentifier: identifier) as? MKBXPSlotCell
        if cell == nil {
            cell = MKBXPSlotCell(style: .default, reuseIdentifier: identifier)
        }
        return cell!
    }

    // MARK: - Init

    public override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        selectionStyle = .none
        contentView.backgroundColor = .white
        contentView.addSubview(leftMsgLabel)
        contentView.addSubview(rightMsgLabel)
        contentView.addSubview(rightIcon)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Layout

    public override func layoutSubviews() {
        super.layoutSubviews()

        let msgSize = leftMsgLabel.text?.size(withFont: leftMsgLabel.font,
                                              maxSize: CGSize(width: contentView.frame.width / 2 - offsetX - 3,
                                                              height: .greatestFiniteMagnitude)) ?? .zero

        leftMsgLabel.snp.remakeConstraints { make in
            make.left.equalToSuperview().offset(offsetX)
            make.right.equalTo(contentView.snp.centerX).offset(-3)
            make.centerY.equalToSuperview()
            make.height.equalTo(max(msgSize.height, 20))
        }

        rightIcon.snp.remakeConstraints { make in
            make.right.equalToSuperview().offset(-offsetX)
            make.width.equalTo(8)
            make.height.equalTo(14)
            make.centerY.equalToSuperview()
        }

        rightMsgLabel.snp.remakeConstraints { make in
            make.right.equalTo(rightIcon.snp.left).offset(-2)
            make.left.equalTo(contentView.snp.centerX).offset(-2)
            make.centerY.equalToSuperview()
            make.height.equalTo(rightMsgLabel.font.lineHeight)
        }
    }

    // MARK: - Private

    private func updateUI() {
        guard let dataModel = dataModel else { return }
        leftMsgLabel.text = dataModel.leftMsg
        rightMsgLabel.text = dataModel.rightMsg
        setNeedsLayout()
    }
}
