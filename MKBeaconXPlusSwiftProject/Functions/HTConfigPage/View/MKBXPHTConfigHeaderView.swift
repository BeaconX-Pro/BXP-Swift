//
//  MKBXPHTConfigHeaderView.swift
//  MKBeaconXPlusSwiftProject
//
//  Created by aa on 2026/9/18.
//

import UIKit
import SnapKit
import MKBaseSwiftModule
import MKSwiftCustomUI

// MARK: - 内部值视图

private final class MKBXPHTConfigValueView: UIView {

    lazy var leftIcon: UIImageView = {
        let iv = UIImageView()
        return iv
    }()

    lazy var msgLabel: UILabel = {
        let label = UILabel()
        label.textAlignment = .left
        label.textColor = MKColor.defaultText
        label.font = MKFont.font(15)
        return label
    }()

    lazy var valueLabel: UILabel = {
        let label = UILabel()
        label.textAlignment = .left
        label.textColor = MKColor.defaultText
        label.font = MKFont.font(28)
        return label
    }()

    lazy var unitLabel: UILabel = {
        let label = UILabel()
        label.textAlignment = .left
        label.textColor = MKColor.defaultText
        label.font = MKFont.font(12)
        return label
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)
        addSubview(leftIcon)
        addSubview(msgLabel)
        addSubview(valueLabel)
        addSubview(unitLabel)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func layoutSubviews() {
        super.layoutSubviews()

        leftIcon.snp.remakeConstraints { make in
            make.left.equalTo(5)
            make.width.height.equalTo(25)
            make.centerY.equalTo(self)
        }
        msgLabel.snp.remakeConstraints { make in
            make.left.equalTo(leftIcon.snp.right).offset(5)
            make.right.equalTo(valueLabel.snp.left).offset(-5)
            make.centerY.equalTo(self)
            make.height.equalTo(MKFont.font(15).lineHeight)
        }
        valueLabel.snp.remakeConstraints { make in
            make.right.equalTo(unitLabel.snp.left).offset(-10)
            make.width.equalTo(85)
            make.centerY.equalTo(self)
            make.height.equalTo(MKFont.font(28).lineHeight)
        }
        unitLabel.snp.remakeConstraints { make in
            make.right.equalTo(-5)
            make.width.equalTo(30)
            make.bottom.equalTo(valueLabel)
            make.height.equalTo(MKFont.font(12).lineHeight)
        }
    }
}

// MARK: - MKBXPHTConfigHeaderView

public final class MKBXPHTConfigHeaderView: UIView {

    // MARK: - Subviews

    private lazy var backView: UIView = {
        let view = UIView()
        view.backgroundColor = .white
        view.layer.masksToBounds = true
        view.layer.cornerRadius = 8
        return view
    }()

    private lazy var tempView: MKBXPHTConfigValueView = {
        let view = MKBXPHTConfigValueView()
        view.leftIcon.image = UIImage(named: "bxp_slotConfig_temperatureIcon.png")
        view.msgLabel.text = "Temperature"
        view.valueLabel.text = "0.0"
        view.unitLabel.text = "℃"
        return view
    }()

    private lazy var humidityView: MKBXPHTConfigValueView = {
        let view = MKBXPHTConfigValueView()
        view.leftIcon.image = UIImage(named: "bxp_slotConfig_humidityIcon.png")
        view.msgLabel.text = "Humidity"
        view.valueLabel.text = "0.0"
        view.unitLabel.text = "%RH"
        return view
    }()

    private lazy var samplingLabel: UILabel = {
        let label = UILabel()
        label.textColor = MKColor.defaultText
        label.textAlignment = .left
        label.font = MKFont.font(13)
        label.text = "Sampling interval"
        return label
    }()

    private lazy var textField: MKSwiftTextField = {
        let tf = MKSwiftTextField(textFieldType: .realNumberOnly)
        tf.textColor = MKColor.defaultText
        tf.textAlignment = .center
        tf.font = MKFont.font(12)
        tf.borderStyle = .none
        tf.text = "1"
        tf.maxLength = 5
        tf.placeholder = "1~65535"

        let lineView = UIView()
        lineView.backgroundColor = MKColor.defaultText
        tf.addSubview(lineView)
        lineView.snp.remakeConstraints { make in
            make.left.right.bottom.equalToSuperview()
            make.height.equalTo(1)
        }
        return tf
    }()

    private lazy var unitLabel: UILabel = {
        let label = UILabel()
        label.textAlignment = .left
        label.attributedText = MKBXPSwiftAdopter.createAttributedString(
            strings: ["sec", "   (1 ~ 65535)"],
            fonts: [MKFont.font(13), MKFont.font(12)],
            colors: [MKColor.defaultText, UIColor(red: 223/255.0, green: 223/255.0, blue: 223/255.0, alpha: 1)]
        )
        return label
    }()

    // MARK: - Init

    public override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = UIColor(red: 242/255.0, green: 242/255.0, blue: 242/255.0, alpha: 1)
        addSubview(backView)
        backView.addSubview(tempView)
        backView.addSubview(humidityView)
        backView.addSubview(samplingLabel)
        backView.addSubview(textField)
        backView.addSubview(unitLabel)
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
            make.top.equalTo(20)
            make.bottom.equalTo(-10)
        }
        tempView.snp.remakeConstraints { make in
            make.left.equalTo(10)
            make.right.equalTo(-10)
            make.top.equalTo(10)
            make.height.equalTo(30)
        }
        humidityView.snp.remakeConstraints { make in
            make.left.equalTo(10)
            make.right.equalTo(-10)
            make.top.equalTo(tempView.snp.bottom).offset(10)
            make.height.equalTo(30)
        }
        samplingLabel.snp.remakeConstraints { make in
            make.left.equalTo(45)
            make.width.equalTo(110)
            make.centerY.equalTo(textField)
            make.height.equalTo(MKFont.font(13).lineHeight)
        }
        textField.snp.remakeConstraints { make in
            make.left.equalTo(samplingLabel.snp.right).offset(5)
            make.width.equalTo(65)
            make.top.equalTo(humidityView.snp.bottom).offset(10)
            make.height.equalTo(20)
        }
        unitLabel.snp.remakeConstraints { make in
            make.right.equalTo(-10)
            make.left.equalTo(textField.snp.right).offset(3)
            make.centerY.equalTo(textField)
            make.height.equalTo(MKFont.font(13).lineHeight)
        }
    }

    // MARK: - Public

    public func updateTemperature(_ temperature: String, humidity: String) {
        tempView.valueLabel.text = temperature
        humidityView.valueLabel.text = humidity
    }

    public func updateSamplingInterval(_ interval: String) {
        textField.text = interval
    }

    public func getSamplingInterval() -> String {
        return textField.text ?? ""
    }
}
