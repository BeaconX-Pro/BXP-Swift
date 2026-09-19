//
//  MKBXPScanInfoCell.swift
//  MKBeaconXPlusSwiftProject
//
//  Created by aa on 2026/9/18.
//

import UIKit
@preconcurrency import CoreBluetooth
import SnapKit
import MKBaseSwiftModule
import MKSwiftCustomUI

// MARK: - Cell Delegate

public protocol MKBXPScanInfoCellDelegate: AnyObject {
    func mk_bxp_connectPeripheral(_ deviceModel: MKBXPScanInfoCellModel)
}

// MARK: - Cell

public final class MKBXPScanInfoCell: MKSwiftBaseCell {

    public weak var delegate: MKBXPScanInfoCellDelegate?

    public var dataModel: MKBXPScanInfoCellModel? {
        didSet { updateUI() }
    }

    // MARK: - 常量

    private static let offset_X: CGFloat = 15
    private static let rssiIconWidth: CGFloat = 22
    private static let rssiIconHeight: CGFloat = 11
    private static let connectButtonWidth: CGFloat = 80
    private static let connectButtonHeight: CGFloat = 30
    private static let batteryIconWidth: CGFloat = 25
    private static let batteryIconHeight: CGFloat = 25

    // MARK: - Subviews

    private lazy var topBackView: UIView = { UIView() }()
    private lazy var centerBackView: UIView = { UIView() }()
    private lazy var bottomBackView: UIView = { UIView() }()

    private lazy var rssiIcon: UIImageView = {
        let iv = UIImageView()
        iv.image = UIImage(named: "bxp_signalIcon.png")
        return iv
    }()

    private lazy var rssiLabel: UILabel = {
        let label = createLabel(MKFont.font(10))
        label.textAlignment = .center
        return label
    }()

    private lazy var nameLabel: UILabel = {
        let label = createLabel(MKFont.font(15))
        label.textColor = MKColor.defaultText
        label.numberOfLines = 0
        return label
    }()

    private lazy var connectButton: UIButton = {
        let btn = UIButton(type: .custom)
        btn.backgroundColor = MKColor.navBar
        btn.setTitle("CONNECT", for: .normal)
        btn.setTitleColor(.white, for: .normal)
        btn.titleLabel?.font = MKFont.font(15)
        btn.layer.masksToBounds = true
        btn.layer.cornerRadius = 10
        btn.addTarget(self, action: #selector(connectButtonPressed), for: .touchUpInside)
        return btn
    }()

    private lazy var batteryIcon: UIImageView = {
        let iv = UIImageView()
        iv.image = UIImage(named: "bxp_batteryHighest.png")
        return iv
    }()

    private lazy var batteryLabel: UILabel = {
        let label = createLabel(MKFont.font(10))
        label.textAlignment = .center
        return label
    }()

    private lazy var macLabel: UILabel = createLabel(MKFont.font(13))

    private lazy var tamperLabel: UILabel = createLabel(MKFont.font(10))

    private lazy var txPowerLabel: UILabel = {
        let label = createLabel(MKFont.font(10))
        label.text = "Tx Power:"
        return label
    }()

    private lazy var txPowerValueLabel: UILabel = createLabel(MKFont.font(10))

    private lazy var rangingDataLabel: UILabel = createLabel(MKFont.font(10))

    private lazy var timeLabel: UILabel = {
        let label = createLabel(MKFont.font(10))
        label.textAlignment = .center
        return label
    }()

    // MARK: - Init

    public override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        selectionStyle = .none
        contentView.addSubview(topBackView)
        contentView.addSubview(centerBackView)
        contentView.addSubview(bottomBackView)

        topBackView.addSubview(rssiIcon)
        topBackView.addSubview(rssiLabel)
        topBackView.addSubview(nameLabel)
        topBackView.addSubview(connectButton)

        centerBackView.addSubview(batteryIcon)
        centerBackView.addSubview(macLabel)
        centerBackView.addSubview(tamperLabel)

        bottomBackView.addSubview(batteryLabel)
        bottomBackView.addSubview(txPowerLabel)
        bottomBackView.addSubview(txPowerValueLabel)
        bottomBackView.addSubview(rangingDataLabel)
        bottomBackView.addSubview(timeLabel)

        layer.masksToBounds = true
        layer.cornerRadius = 4
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    public static func initCellWithTableView(_ tableView: UITableView) -> MKBXPScanInfoCell {
        let identifier = "MKBXPScanInfoCellIdenty"
        if let cell = tableView.dequeueReusableCell(withIdentifier: identifier) as? MKBXPScanInfoCell {
            return cell
        }
        return MKBXPScanInfoCell(style: .default, reuseIdentifier: identifier)
    }

    // MARK: - Layout

    public override func layoutSubviews() {
        super.layoutSubviews()

        topBackView.snp.remakeConstraints { make in
            make.left.right.top.equalToSuperview()
            make.height.equalTo(40)
        }
        rssiIcon.snp.remakeConstraints { make in
            make.left.equalTo(20)
            make.top.equalTo(10)
            make.width.equalTo(Self.rssiIconWidth)
            make.height.equalTo(Self.rssiIconHeight)
        }
        rssiLabel.snp.remakeConstraints { make in
            make.centerX.equalTo(rssiIcon)
            make.width.equalTo(40)
            make.top.equalTo(rssiIcon.snp.bottom).offset(5)
            make.height.equalTo(MKFont.font(10).lineHeight)
        }

        connectButton.snp.remakeConstraints { make in
            make.right.equalTo(-Self.offset_X)
            make.width.equalTo(Self.connectButtonWidth)
            make.centerY.equalTo(topBackView)
            make.height.equalTo(Self.connectButtonHeight)
        }

        nameLabel.snp.remakeConstraints { make in
            make.left.equalTo(rssiIcon.snp.right).offset(20)
            make.centerY.equalTo(rssiIcon)
            make.right.equalTo(connectButton.snp.left).offset(-8)
        }

        centerBackView.snp.remakeConstraints { make in
            make.left.right.equalToSuperview()
            make.top.equalTo(topBackView.snp.bottom)
            make.height.equalTo(Self.batteryIconHeight)
        }
        batteryIcon.snp.remakeConstraints { make in
            make.left.equalTo(Self.offset_X)
            make.width.equalTo(Self.batteryIconWidth)
            make.centerY.equalTo(centerBackView)
            make.height.equalTo(Self.batteryIconHeight)
        }
        macLabel.snp.remakeConstraints { make in
            make.left.equalTo(nameLabel)
            make.right.equalTo(tamperLabel.snp.left).offset(-5)
            make.centerY.equalTo(centerBackView)
            make.height.equalTo(MKFont.font(13).lineHeight)
        }
        tamperLabel.snp.remakeConstraints { make in
            make.right.equalTo(-15)
            make.width.equalTo(85)
            make.centerY.equalTo(centerBackView)
            make.height.equalTo(MKFont.font(10).lineHeight)
        }

        bottomBackView.snp.remakeConstraints { make in
            make.left.right.bottom.equalToSuperview()
            make.top.equalTo(centerBackView.snp.bottom)
        }
        batteryLabel.snp.remakeConstraints { make in
            make.centerX.equalTo(batteryIcon)
            make.width.equalTo(45)
            make.top.equalTo(3)
            make.height.equalTo(MKFont.font(15).lineHeight)
        }
        txPowerLabel.snp.remakeConstraints { make in
            make.left.equalTo(nameLabel)
            make.width.equalTo(55)
            make.centerY.equalTo(batteryLabel)
            make.height.equalTo(MKFont.font(10).lineHeight)
        }
        txPowerValueLabel.snp.remakeConstraints { make in
            make.left.equalTo(txPowerLabel.snp.right)
            make.width.equalTo(45)
            make.centerY.equalTo(txPowerLabel)
            make.height.equalTo(MKFont.font(10).lineHeight)
        }
        rangingDataLabel.snp.remakeConstraints { make in
            make.left.equalTo(txPowerValueLabel.snp.right).offset(5)
            make.right.equalTo(timeLabel.snp.left).offset(-5)
            make.centerY.equalTo(txPowerLabel)
            make.height.equalTo(MKFont.font(10).lineHeight)
        }
        timeLabel.snp.remakeConstraints { make in
            make.right.equalTo(-15)
            make.width.equalTo(70)
            make.centerY.equalTo(txPowerLabel)
            make.height.equalTo(MKFont.font(10).lineHeight)
        }
    }

    // MARK: - Event

    @objc private func connectButtonPressed() {
        guard let dataModel = dataModel, dataModel.peripheral != nil else { return }
        delegate?.mk_bxp_connectPeripheral(dataModel)
    }

    // MARK: - Private

    private func updateUI() {
        guard let dataModel = dataModel else { return }

        connectButton.isHidden = !dataModel.connectable

        txPowerLabel.text = dataModel.txPower.isEmpty ? "" : "Tx Power:"
        txPowerValueLabel.text = dataModel.txPower.isEmpty ? "" : (dataModel.txPower + "dBm")

        if dataModel.lightSensor {
            rangingDataLabel.text = dataModel.lightSensorStatus
                ? "Ambient light detected"
                : "Ambient light NOT detected"
        } else {
            rangingDataLabel.text = dataModel.rangingData.isEmpty
                ? ""
                : "Ranging data:\(dataModel.rangingData)dBm"
        }

        timeLabel.text = dataModel.displayTime
        rssiLabel.text = dataModel.rssi + "dBm"
        nameLabel.text = dataModel.deviceName.isEmpty ? "N/A" : dataModel.deviceName

        let macAddress = dataModel.macAddress.isEmpty ? "N/A" : dataModel.macAddress
        macLabel.text = "MAC:\(macAddress)"
        batteryLabel.text = dataModel.battery.isEmpty ? "N/A" : (dataModel.battery + "mV")

        if dataModel.tamperSensor {
            tamperLabel.text = dataModel.tamperAlert ? "Tamper alert" : "Tamper normal"
        } else {
            tamperLabel.text = ""
        }

        setNeedsLayout()
    }

    private func createLabel(_ font: UIFont) -> UILabel {
        let label = UILabel()
        label.textColor = UIColor(red: 184/255.0, green: 184/255.0, blue: 184/255.0, alpha: 1)
        label.textAlignment = .left
        label.font = font
        return label
    }
}
