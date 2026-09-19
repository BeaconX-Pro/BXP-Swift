//
//  MKBXPAccelerationHeaderView.swift
//  MKBeaconXPlusSwiftProject
//
//  Created by aa on 2026/9/18.
//

import UIKit
import SnapKit
import MKBaseSwiftModule
import MKSwiftCustomUI

public protocol MKBXPAccelerationHeaderViewDelegate: AnyObject {
    func bxp_updateThreeAxisNotifyStatus(_ notify: Bool)
}

public final class MKBXPAccelerationHeaderView: UIView {

    public weak var delegate: MKBXPAccelerationHeaderViewDelegate?

    // MARK: - Subviews

    private lazy var backView: UIView = {
        let view = UIView()
        view.backgroundColor = .white
        view.layer.masksToBounds = true
        view.layer.cornerRadius = 8
        return view
    }()

    private lazy var syncButton: UIButton = {
        let btn = UIButton(type: .custom)
        btn.addTarget(self, action: #selector(syncButtonPressed), for: .touchUpInside)
        return btn
    }()

    private lazy var synIcon: UIImageView = {
        let iv = UIImageView()
        iv.image = UIImage(named: "bxp_threeAxisAcceLoadingIcon.png")
        return iv
    }()

    private lazy var syncLabel: UILabel = {
        let label = UILabel()
        label.textColor = MKColor.defaultText
        label.textAlignment = .center
        label.font = MKFont.font(10)
        label.text = "Sync"
        return label
    }()

    private lazy var xDataLabel: UILabel = {
        let label = UILabel()
        label.textColor = MKColor.defaultText
        label.textAlignment = .center
        label.font = MKFont.font(12)
        label.text = "X-axis:N/A"
        return label
    }()

    private lazy var yDataLabel: UILabel = {
        let label = UILabel()
        label.textColor = MKColor.defaultText
        label.textAlignment = .center
        label.font = MKFont.font(12)
        label.text = "Y-axis:N/A"
        return label
    }()

    private lazy var zDataLabel: UILabel = {
        let label = UILabel()
        label.textColor = MKColor.defaultText
        label.textAlignment = .center
        label.font = MKFont.font(12)
        label.text = "Z-axis:N/A"
        return label
    }()

    // MARK: - Init

    public override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = UIColor(red: 242/255.0, green: 242/255.0, blue: 242/255.0, alpha: 1)

        addSubview(backView)
        backView.addSubview(syncButton)
        syncButton.addSubview(synIcon)
        backView.addSubview(syncLabel)
        backView.addSubview(xDataLabel)
        backView.addSubview(yDataLabel)
        backView.addSubview(zDataLabel)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Layout

    public override func layoutSubviews() {
        super.layoutSubviews()

        backView.snp.remakeConstraints { make in
            make.left.equalTo(5)
            make.right.equalTo(-5)
            make.top.equalTo(15)
            make.bottom.equalTo(-30)
        }
        syncButton.snp.makeConstraints { make in
            make.left.equalTo(15)
            make.width.equalTo(30)
            make.top.equalTo(5)
            make.height.equalTo(30)
        }
        synIcon.snp.makeConstraints { make in
            make.centerX.equalTo(syncButton)
            make.centerY.equalTo(syncButton)
            make.width.height.equalTo(25)
        }
        syncLabel.snp.makeConstraints { make in
            make.left.equalTo(15)
            make.width.equalTo(25)
            make.top.equalTo(syncButton.snp.bottom).offset(2)
            make.height.equalTo(MKFont.font(10).lineHeight)
        }
        let width = (MKScreen.width - 6 * 15) / 3
        xDataLabel.snp.makeConstraints { make in
            make.left.equalTo(syncButton.snp.right).offset(5)
            make.width.equalTo(width)
            make.centerY.equalTo(syncButton).offset(2)
            make.height.equalTo(MKFont.font(12).lineHeight)
        }
        yDataLabel.snp.makeConstraints { make in
            make.left.equalTo(xDataLabel.snp.right).offset(5)
            make.width.equalTo(width)
            make.centerY.equalTo(xDataLabel)
            make.height.equalTo(MKFont.font(12).lineHeight)
        }
        zDataLabel.snp.makeConstraints { make in
            make.left.equalTo(yDataLabel.snp.right).offset(5)
            make.width.equalTo(width)
            make.centerY.equalTo(xDataLabel)
            make.height.equalTo(MKFont.font(12).lineHeight)
        }
    }

    // MARK: - Event

    @objc private func syncButtonPressed() {
        syncButton.isSelected.toggle()
        synIcon.layer.removeAnimation(forKey: "bxp_synIconAnimationKey")
        delegate?.bxp_updateThreeAxisNotifyStatus(syncButton.isSelected)
        if syncButton.isSelected {
            let animation = MKBXPSwiftAdopter.refreshAnimation(2.0)
            synIcon.layer.add(animation, forKey: "bxp_synIconAnimationKey")
            syncLabel.text = "Stop"
            return
        }
        syncLabel.text = "Sync"
    }

    // MARK: - Public

    public func updateDataWithXData(_ xData: String, yData: String, zData: String) {
        xDataLabel.text = "X-axis:0x" + xData
        yDataLabel.text = "Y-axis:0x" + yData
        zDataLabel.text = "Z-axis:0x" + zData
    }
}
