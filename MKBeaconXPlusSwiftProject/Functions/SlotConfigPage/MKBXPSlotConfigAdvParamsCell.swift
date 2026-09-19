//
//  MKBXPSlotConfigAdvParamsCell.swift
//  MKBeaconXPlusSwiftProject
//
//  Created by aa on 2026/9/18.
//

import UIKit
import SnapKit
import MKBaseSwiftModule
import MKSwiftCustomUI
import MKSwiftBeaconXCustomUI

// MARK: - Cell Model

public final class MKBXPSlotConfigAdvParamsCellModel: NSObject {
    public var advInterval: String = ""
    public var rssiValue: Int = 0
    public var txPower: Int = 0
    public var slotType: MKSwiftBXSlotFrameType = .null

    public override init() {
        super.init()
    }
}

// MARK: - Cell

public final class MKBXPSlotConfigAdvParamsCell: MKSwiftBaseCell, MKSwiftBXSlotConfigCellProtocol {

    public var dataModel: MKBXPSlotConfigAdvParamsCellModel? {
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

    private lazy var leftIcon: UIImageView = {
        let iv = UIImageView()
        iv.image = UIImage(named: "bxp_slot_baseParams.png")
        return iv
    }()

    private lazy var typeLabel: UILabel = {
        let label = UILabel()
        label.textColor = MKColor.defaultText
        label.textAlignment = .left
        label.font = MKFont.font(15)
        label.text = "Parameters"
        return label
    }()

    private lazy var advIntervalLabel: UILabel = {
        let label = UILabel()
        label.textAlignment = .left
        label.attributedText = MKSwiftUIAdaptor.createAttributedString(
            strings: ["Adv interval", " (1 ~ 100)"],
            fonts: [MKFont.font(13), MKFont.font(12)],
            colors: [MKColor.defaultText, MKColor.fromHex(0xDFDFDF)]
        )
        return label
    }()

    private lazy var intervalTextField: MKSwiftTextField = {
        let tf = MKSwiftTextField(textFieldType: .realNumberOnly)
        tf.textColor = MKColor.defaultText
        tf.textAlignment = .center
        tf.font = MKFont.font(12)
        tf.borderStyle = .none
        tf.text = "10"
        tf.maxLength = 3
        tf.placeholder = "1~100"

        let lineView = UIView()
        lineView.backgroundColor = MKColor.defaultText
        tf.addSubview(lineView)
        lineView.snp.makeConstraints { make in
            make.left.right.bottom.equalToSuperview()
            make.height.equalTo(1)
        }
        return tf
    }()

    private lazy var intervalUnitLabel: UILabel = {
        let label = UILabel()
        label.textColor = MKColor.defaultText
        label.font = MKFont.font(12)
        label.textAlignment = .left
        label.text = "x 100ms"
        return label
    }()

    private lazy var rssiMsgLabel: UILabel = {
        let label = UILabel()
        label.textAlignment = .left
        label.attributedText = MKSwiftUIAdaptor.createAttributedString(
            strings: ["RSSI@1m", "   (-100dBm ~ 0dBm)"],
            fonts: [MKFont.font(13), MKFont.font(12)],
            colors: [MKColor.defaultText, MKColor.fromHex(0xDFDFDF)]
        )
        return label
    }()

    private lazy var rssiSlider: UISlider = {
        let slider = UISlider()
        slider.maximumValue = 0
        slider.minimumValue = -100
        slider.value = -40
        slider.addTarget(self, action: #selector(rssiSliderValueChanged), for: .valueChanged)
        return slider
    }()

    private lazy var rssiValueLabel: UILabel = {
        let label = UILabel()
        label.textColor = MKColor.defaultText
        label.textAlignment = .left
        label.font = MKFont.font(11)
        label.text = "-40dBm"
        return label
    }()

    private lazy var txPowerMsgLabel: UILabel = {
        let label = UILabel()
        label.textAlignment = .left
        label.attributedText = MKSwiftUIAdaptor.createAttributedString(
            strings: ["Tx power", "   (-40,-20,-16,-12,-8,-4,0,+3,+4)"],
            fonts: [MKFont.font(13), MKFont.font(12)],
            colors: [MKColor.defaultText, MKColor.fromHex(0xDFDFDF)]
        )
        return label
    }()

    private lazy var txPowerSlider: UISlider = {
        let slider = UISlider()
        slider.maximumValue = 9
        slider.minimumValue = 0
        slider.value = 0
        slider.addTarget(self, action: #selector(txPowerSliderValueChanged), for: .valueChanged)
        return slider
    }()

    private lazy var txPowerValueLabel: UILabel = {
        let label = UILabel()
        label.textColor = MKColor.defaultText
        label.textAlignment = .left
        label.font = MKFont.font(11)
        label.text = "-12dBm"
        return label
    }()

    // MARK: - Init

    public override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        selectionStyle = .none
        contentView.addSubview(backView)
        backView.addSubview(leftIcon)
        backView.addSubview(typeLabel)
        backView.addSubview(advIntervalLabel)
        backView.addSubview(intervalTextField)
        backView.addSubview(intervalUnitLabel)
        backView.addSubview(rssiMsgLabel)
        backView.addSubview(rssiSlider)
        backView.addSubview(rssiValueLabel)
        backView.addSubview(txPowerMsgLabel)
        backView.addSubview(txPowerSlider)
        backView.addSubview(txPowerValueLabel)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    public class func initCellWithTableView(_ tableView: UITableView) -> MKBXPSlotConfigAdvParamsCell {
        let identifier = "MKBXPSlotConfigAdvParamsCellIdenty"
        if let cell = tableView.dequeueReusableCell(withIdentifier: identifier) as? MKBXPSlotConfigAdvParamsCell {
            return cell
        }
        return MKBXPSlotConfigAdvParamsCell(style: .default, reuseIdentifier: identifier)
    }

    // MARK: - Layout

    public override func layoutSubviews() {
        super.layoutSubviews()

        backView.snp.remakeConstraints { make in
            make.edges.equalToSuperview()
        }
        leftIcon.snp.remakeConstraints { make in
            make.left.equalTo(15)
            make.width.height.equalTo(22)
            make.top.equalTo(10)
        }
        typeLabel.snp.remakeConstraints { make in
            make.left.equalTo(leftIcon.snp.right).offset(15)
            make.right.equalTo(-15)
            make.centerY.equalTo(leftIcon)
            make.height.equalTo(MKFont.font(15).lineHeight)
        }
    }

    // MARK: - MKSwiftBXSlotConfigCellProtocol

    public func slotConfigCellParams() -> [String: Any] {
        let intervalText = intervalTextField.text ?? ""
        guard !intervalText.isEmpty,
              let intervalValue = Int(intervalText),
              intervalValue >= 1, intervalValue <= 100 else {
            return [
                "msg": "Adv interval Error",
                "result": [String: Any]()
            ]
        }

        let txPowerValue = String(format: "%.f", txPowerSlider.value)
        var rssiValue = String(format: "%.f", rssiSlider.value)
        if rssiValue == "-0" {
            rssiValue = "0"
        }

        return [
            "msg": "",
            "result": [
                "dataType": MKSwiftBXSlotConfigKey.advParamType,
                "params": [
                    "txPower": txPowerValue,
                    "rssi": rssiValue,
                    "interval": intervalText
                ]
            ]
        ]
    }

    // MARK: - Event

    @objc private func rssiSliderValueChanged() {
        var value = String(format: "%.f", rssiSlider.value)
        if value == "-0" {
            value = "0"
        }
        rssiValueLabel.text = value + "dBm"
    }

    @objc private func txPowerSliderValueChanged() {
        let value = Int(txPowerSlider.value)
        txPowerValueLabel.text = txPowerValueText(value)
    }

    // MARK: - Private

    private func updateUI() {
        guard let dataModel = dataModel else { return }

        txPowerSlider.value = Float(dataModel.txPower)
        txPowerValueLabel.text = txPowerValueText(dataModel.txPower)
        intervalTextField.text = dataModel.advInterval

        // 移除 RSSI 相关视图（避免 TLM 模式下残留）
        rssiMsgLabel.removeFromSuperview()
        rssiSlider.removeFromSuperview()
        rssiValueLabel.removeFromSuperview()

        if dataModel.slotType == .tlm {
            setupTLMUI()
            return
        }
        setupNormalUI()
    }

    private func txPowerValueText(_ value: Int) -> String {
        switch value {
        case 0: return "-40dBm"
        case 1: return "-20dBm"
        case 2: return "-16dBm"
        case 3: return "-12dBm"
        case 4: return "-8dBm"
        case 5: return "-4dBm"
        case 6: return "0dBm"
        case 7: return "3dBm"
        default: return "4dBm"
        }
    }

    private func setupNormalUI() {
        backView.addSubview(rssiMsgLabel)
        backView.addSubview(rssiSlider)
        backView.addSubview(rssiValueLabel)

        guard let dataModel = dataModel else { return }
        rssiSlider.value = Float(dataModel.rssiValue)
        rssiValueLabel.text = "\(dataModel.rssiValue)dBm"

        var tempMsg = "RSSI@0m"
        if dataModel.slotType == .beacon {
            tempMsg = "RSSI@1m"
        } else if dataModel.slotType == .info
                    || dataModel.slotType == .threeASensor
                    || dataModel.slotType == .thSensor {
            tempMsg = "Ranging data"
        }
        rssiMsgLabel.attributedText = MKSwiftUIAdaptor.createAttributedString(
            strings: [tempMsg, "   (-100dBm ~ 0dBm)"],
            fonts: [MKFont.font(13), MKFont.font(12)],
            colors: [MKColor.defaultText, MKColor.fromHex(0xDFDFDF)]
        )

        advIntervalLabel.snp.remakeConstraints { make in
            make.left.equalTo(15)
            make.right.equalTo(intervalTextField.snp.left).offset(-15)
            make.centerY.equalTo(intervalTextField)
            make.height.equalTo(MKFont.font(13).lineHeight)
        }
        intervalTextField.snp.remakeConstraints { make in
            make.right.equalTo(intervalUnitLabel.snp.left).offset(-5)
            make.width.equalTo(60)
            make.top.equalTo(leftIcon.snp.bottom).offset(15)
            make.height.equalTo(20)
        }
        intervalUnitLabel.snp.remakeConstraints { make in
            make.right.equalTo(-15)
            make.width.equalTo(60)
            make.centerY.equalTo(intervalTextField)
            make.height.equalTo(MKFont.font(12).lineHeight)
        }
        rssiMsgLabel.snp.remakeConstraints { make in
            make.left.equalTo(15)
            make.top.equalTo(intervalTextField.snp.bottom).offset(15)
            make.right.equalTo(-15)
            make.height.equalTo(MKFont.font(15).lineHeight)
        }
        rssiSlider.snp.remakeConstraints { make in
            make.left.equalTo(15)
            make.right.equalTo(rssiValueLabel.snp.left).offset(-5)
            make.top.equalTo(rssiMsgLabel.snp.bottom).offset(5)
            make.height.equalTo(10)
        }
        rssiValueLabel.snp.remakeConstraints { make in
            make.right.equalTo(-15)
            make.width.equalTo(60)
            make.centerY.equalTo(rssiSlider)
            make.height.equalTo(MKFont.font(12).lineHeight)
        }
        txPowerMsgLabel.snp.remakeConstraints { make in
            make.left.equalTo(15)
            make.top.equalTo(rssiSlider.snp.bottom).offset(15)
            make.right.equalTo(-15)
            make.height.equalTo(MKFont.font(15).lineHeight)
        }
        txPowerSlider.snp.remakeConstraints { make in
            make.left.equalTo(15)
            make.right.equalTo(txPowerValueLabel.snp.left).offset(-5)
            make.top.equalTo(txPowerMsgLabel.snp.bottom).offset(5)
            make.height.equalTo(10)
        }
        txPowerValueLabel.snp.remakeConstraints { make in
            make.right.equalTo(-15)
            make.width.equalTo(60)
            make.centerY.equalTo(txPowerSlider)
            make.height.equalTo(MKFont.font(12).lineHeight)
        }
    }

    private func setupTLMUI() {
        advIntervalLabel.snp.remakeConstraints { make in
            make.left.equalTo(15)
            make.right.equalTo(intervalTextField.snp.left).offset(-15)
            make.centerY.equalTo(intervalTextField)
            make.height.equalTo(MKFont.font(13).lineHeight)
        }
        intervalTextField.snp.remakeConstraints { make in
            make.right.equalTo(intervalUnitLabel.snp.left).offset(-5)
            make.width.equalTo(60)
            make.top.equalTo(leftIcon.snp.bottom).offset(15)
            make.height.equalTo(20)
        }
        intervalUnitLabel.snp.remakeConstraints { make in
            make.right.equalTo(-15)
            make.width.equalTo(60)
            make.centerY.equalTo(intervalTextField)
            make.height.equalTo(MKFont.font(12).lineHeight)
        }
        txPowerMsgLabel.snp.remakeConstraints { make in
            make.left.equalTo(15)
            make.top.equalTo(intervalTextField.snp.bottom).offset(15)
            make.right.equalTo(-15)
            make.height.equalTo(MKFont.font(15).lineHeight)
        }
        txPowerSlider.snp.remakeConstraints { make in
            make.left.equalTo(15)
            make.right.equalTo(txPowerValueLabel.snp.left).offset(-5)
            make.top.equalTo(txPowerMsgLabel.snp.bottom).offset(5)
            make.height.equalTo(10)
        }
        txPowerValueLabel.snp.remakeConstraints { make in
            make.right.equalTo(-15)
            make.width.equalTo(60)
            make.centerY.equalTo(txPowerSlider)
            make.height.equalTo(MKFont.font(12).lineHeight)
        }
    }
}
