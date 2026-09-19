//
//  MKBXPLightSensorHeaderView.swift
//  MKBeaconXPlusSwiftProject
//
//  Created by aa on 2026/9/18.
//

import UIKit
import SnapKit
import MKBaseSwiftModule
import MKSwiftCustomUI

// MARK: - Delegate

public protocol MKBXPLightSensorHeaderViewDelegate: AnyObject {
    func bxp_lightSensorSyncTime()
}

// MARK: - Header View

public final class MKBXPLightSensorHeaderView: UIView {

    public weak var delegate: MKBXPLightSensorHeaderViewDelegate?

    // MARK: - Subviews

    private lazy var topView: UIView = {
        let view = UIView()
        view.backgroundColor = .white
        view.layer.masksToBounds = true
        view.layer.cornerRadius = 6
        return view
    }()

    private lazy var icon: UIImageView = {
        let iv = UIImageView()
        iv.image = UIImage(named: "bxp_lightSensorIcon.png")
        return iv
    }()

    private lazy var sensorLabel: UILabel = {
        let label = UILabel()
        label.textColor = MKColor.defaultText
        label.font = MKFont.font(15)
        label.textAlignment = .left
        label.text = "Sensor status"
        return label
    }()

    private lazy var sensorStatusLabel: UILabel = {
        let label = UILabel()
        label.textColor = MKColor.defaultText
        label.textAlignment = .right
        label.font = MKFont.font(13)
        label.text = "Ambient light NOT detected"
        return label
    }()

    private lazy var bottomView: UIView = {
        let view = UIView()
        view.backgroundColor = .white
        view.layer.masksToBounds = true
        view.layer.cornerRadius = 6
        return view
    }()

    private lazy var syncLabel: UILabel = {
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
        label.font = MKFont.font(15)
        return label
    }()

    // MARK: - Init

    public override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = UIColor(red: 242/255.0, green: 242/255.0, blue: 242/255.0, alpha: 1)
        addSubview(topView)
        topView.addSubview(icon)
        topView.addSubview(sensorLabel)
        topView.addSubview(sensorStatusLabel)

        addSubview(bottomView)
        bottomView.addSubview(syncLabel)
        bottomView.addSubview(syncButton)
        bottomView.addSubview(dateLabel)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Layout

    public override func layoutSubviews() {
        super.layoutSubviews()

        topView.snp.makeConstraints { make in
            make.left.equalTo(10)
            make.right.equalTo(-10)
            make.top.equalTo(15)
            make.height.equalTo(44)
        }
        icon.snp.makeConstraints { make in
            make.left.equalTo(5)
            make.width.height.equalTo(33)
            make.centerY.equalTo(topView)
        }
        sensorLabel.snp.makeConstraints { make in
            make.left.equalTo(icon.snp.right).offset(5)
            make.width.equalTo(100)
            make.centerY.equalTo(topView)
            make.height.equalTo(MKFont.font(15).lineHeight)
        }
        sensorStatusLabel.snp.makeConstraints { make in
            make.left.equalTo(sensorLabel.snp.right).offset(5)
            make.right.equalTo(-5)
            make.centerY.equalTo(topView)
            make.height.equalTo(MKFont.font(13).lineHeight)
        }

        bottomView.snp.makeConstraints { make in
            make.left.equalTo(10)
            make.right.equalTo(-10)
            make.top.equalTo(topView.snp.bottom).offset(15)
            make.height.equalTo(90)
        }
        syncButton.snp.makeConstraints { make in
            make.right.equalTo(-5)
            make.width.equalTo(45)
            make.top.equalTo(10)
            make.height.equalTo(30)
        }
        syncLabel.snp.makeConstraints { make in
            make.left.equalTo(5)
            make.right.equalTo(syncButton.snp.left).offset(-10)
            make.centerY.equalTo(syncButton)
            make.height.equalTo(MKFont.font(15).lineHeight)
        }
        dateLabel.snp.makeConstraints { make in
            make.left.equalTo(15)
            make.right.equalTo(-15)
            make.top.equalTo(syncButton.snp.bottom).offset(10)
            make.height.equalTo(MKFont.font(15).lineHeight)
        }
    }

    // MARK: - Event

    @objc private func syncButtonPressed() {
        delegate?.bxp_lightSensorSyncTime()
    }

    // MARK: - Public

    public func updateSensorStatus(_ detected: Bool) {
        sensorStatusLabel.text = detected ? "Ambient light detected" : "Ambient light NOT detected"
    }

    public func updateCurrentTime(_ time: String) {
        dateLabel.text = time
    }
}
