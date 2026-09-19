//
//  MKBXPAccelerationParamsCell.swift
//  MKBeaconXPlusSwiftProject
//
//  Created by aa on 2026/9/18.
//

import UIKit
import SnapKit
import MKBaseSwiftModule
import MKSwiftCustomUI

// MARK: - Cell Model

public final class MKBXPAccelerationParamsCellModel: NSObject {
    /// 0:1hz, 1:10hz, 2:25hz, 3:50hz, 4:100hz
    public var samplingRate: Int = 0
    /// 0:±2g, 1:±4g, 2:±8g, 3:±16g
    public var scale: Int = 0
    /// 灵敏度
    public var sensitivityValue: Int = 0
}

// MARK: - Cell Delegate

public protocol MKBXPAccelerationParamsCellDelegate: AnyObject {
    /// 用户改变了 scale
    /// - Parameter scale: 0:±2g, 1:±4g, 2:±8g, 3:±16g
    func bxp_accelerationParamsScaleChanged(_ scale: Int)

    /// 用户改变了 samplingRate
    /// - Parameter samplingRate: 0:1hz, 1:10hz, 2:25hz, 3:50hz, 4:100hz
    func bxp_accelerationParamsSamplingRateChanged(_ samplingRate: Int)

    /// 用户改变了 sensitivityValue
    func bxp_accelerationParamsSensitivityValueChanged(_ sensitivityValue: Int)
}

// MARK: - Cell

public final class MKBXPAccelerationParamsCell: MKSwiftBaseCell {

    public weak var delegate: MKBXPAccelerationParamsCellDelegate?

    public var dataModel: MKBXPAccelerationParamsCellModel? {
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
        label.text = "Sensor parameters"
        return label
    }()

    private lazy var scaleLabel: UILabel = {
        let label = UILabel()
        label.textColor = MKColor.defaultText
        label.textAlignment = .left
        label.font = MKFont.font(13)
        label.text = "Full-scale"
        return label
    }()

    private lazy var scaleButton: UIButton = {
        let btn = UIButton(type: .custom)
        btn.titleLabel?.font = MKFont.font(12)
        btn.setTitleColor(MKColor.defaultText, for: .normal)
        btn.addTarget(self, action: #selector(scaleButtonPressed), for: .touchUpInside)
        btn.layer.masksToBounds = true
        btn.layer.borderColor = MKColor.navBar.cgColor
        btn.layer.borderWidth = 0.5
        btn.layer.cornerRadius = 6
        return btn
    }()

    private lazy var scaleList: [String] = ["±2g", "±4g", "±8g", "±16g"]

    private lazy var sampleRateLabel: UILabel = {
        let label = UILabel()
        label.textColor = MKColor.defaultText
        label.textAlignment = .left
        label.font = MKFont.font(13)
        label.text = "Sampling rate"
        return label
    }()

    private lazy var sampleRateButton: UIButton = {
        let btn = UIButton(type: .custom)
        btn.titleLabel?.font = MKFont.font(12)
        btn.setTitleColor(MKColor.defaultText, for: .normal)
        btn.addTarget(self, action: #selector(sampleRateButtonPressed), for: .touchUpInside)
        btn.layer.masksToBounds = true
        btn.layer.borderColor = MKColor.navBar.cgColor
        btn.layer.borderWidth = 0.5
        btn.layer.cornerRadius = 6
        return btn
    }()

    private lazy var sampleRateList: [String] = ["1hz", "10hz", "25hz", "50hz", "100hz"]

    private lazy var sensitivityLabel: UILabel = {
        let label = UILabel()
        label.textColor = MKColor.defaultText
        label.textAlignment = .left
        label.font = MKFont.font(13)
        label.text = "Motion threshold"
        return label
    }()

    private lazy var sensitivitySlider: UISlider = {
        let slider = UISlider()
        slider.maximumValue = 255
        slider.minimumValue = 7
        slider.addTarget(self, action: #selector(sliderValueChanged), for: .valueChanged)
        return slider
    }()

    private lazy var sensitivityValueLabel: UILabel = {
        let label = UILabel()
        label.textColor = MKColor.defaultText
        label.font = MKFont.font(12)
        label.textAlignment = .left
        label.text = "0.1g"
        return label
    }()

    // MARK: - Init

    public override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        selectionStyle = .none
        contentView.addSubview(backView)
        backView.addSubview(msgLabel)
        backView.addSubview(scaleLabel)
        backView.addSubview(scaleButton)
        backView.addSubview(sampleRateLabel)
        backView.addSubview(sampleRateButton)
        backView.addSubview(sensitivityLabel)
        backView.addSubview(sensitivitySlider)
        backView.addSubview(sensitivityValueLabel)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    public static func initCellWithTableView(_ tableView: UITableView) -> MKBXPAccelerationParamsCell {
        let identifier = "MKBXPAccelerationParamsCellIdenty"
        if let cell = tableView.dequeueReusableCell(withIdentifier: identifier) as? MKBXPAccelerationParamsCell {
            return cell
        }
        return MKBXPAccelerationParamsCell(style: .default, reuseIdentifier: identifier)
    }

    // MARK: - Layout

    public override func layoutSubviews() {
        super.layoutSubviews()

        backView.snp.remakeConstraints { make in
            make.edges.equalTo(contentView)
        }
        msgLabel.snp.remakeConstraints { make in
            make.left.equalTo(15)
            make.right.equalTo(-15)
            make.top.equalTo(5)
            make.height.equalTo(MKFont.font(15).lineHeight)
        }
        scaleLabel.snp.remakeConstraints { make in
            make.left.equalTo(15)
            make.width.equalTo(110)
            make.centerY.equalTo(scaleButton)
            make.height.equalTo(MKFont.font(13).lineHeight)
        }
        scaleButton.snp.remakeConstraints { make in
            make.left.equalTo(scaleLabel.snp.right).offset(15)
            make.width.equalTo(50)
            make.top.equalTo(msgLabel.snp.bottom).offset(10)
            make.height.equalTo(30)
        }
        sampleRateLabel.snp.remakeConstraints { make in
            make.left.equalTo(15)
            make.width.equalTo(110)
            make.centerY.equalTo(sampleRateButton)
            make.height.equalTo(MKFont.font(13).lineHeight)
        }
        sampleRateButton.snp.remakeConstraints { make in
            make.left.equalTo(sampleRateLabel.snp.right).offset(15)
            make.width.equalTo(50)
            make.top.equalTo(scaleButton.snp.bottom).offset(10)
            make.height.equalTo(30)
        }
        sensitivityLabel.snp.remakeConstraints { make in
            make.left.equalTo(15)
            make.right.equalTo(-15)
            make.top.equalTo(sampleRateButton.snp.bottom).offset(10)
            make.height.equalTo(MKFont.font(13).lineHeight)
        }
        sensitivitySlider.snp.remakeConstraints { make in
            make.left.equalTo(15)
            make.right.equalTo(sensitivityValueLabel.snp.left).offset(-10)
            make.top.equalTo(sensitivityLabel.snp.bottom).offset(10)
            make.height.equalTo(10)
        }
        sensitivityValueLabel.snp.remakeConstraints { make in
            make.right.equalTo(-15)
            make.width.equalTo(45)
            make.centerY.equalTo(sensitivitySlider)
            make.height.equalTo(MKFont.font(12).lineHeight)
        }
    }

    // MARK: - Event

    @objc private func scaleButtonPressed() {
        guard let title = scaleButton.title(for: .normal),
              let index = scaleList.firstIndex(of: title) else { return }
        let pickerView = MKSwiftPickerView()
        pickerView.showPickView(with: scaleList, selectedRow: index) { [weak self] currentRow in
            self?.scaleChanged(currentRow)
        }
    }

    @objc private func sampleRateButtonPressed() {
        guard let title = sampleRateButton.title(for: .normal),
              let index = sampleRateList.firstIndex(of: title) else { return }
        let pickerView = MKSwiftPickerView()
        pickerView.showPickView(with: sampleRateList, selectedRow: index) { [weak self] currentRow in
            guard let self = self else { return }
            self.sampleRateButton.setTitle(self.sampleRateList[currentRow], for: .normal)
            self.delegate?.bxp_accelerationParamsSamplingRateChanged(currentRow)
        }
    }

    @objc private func sliderValueChanged() {
        let tempValue = Int(sensitivitySlider.value)
        delegate?.bxp_accelerationParamsSensitivityValueChanged(tempValue)
        if MKBXPConnectManager.shared.newVersion {
            // 新版本固件
            sensitivityValueLabel.text = String(format: "%.1f%@", Double(tempValue) * 0.1, "g")
            return
        }
        // 旧版本固件
        sensitivityValueLabel.text = "\(tempValue)"
    }

    // MARK: - Private

    private func scaleChanged(_ scale: Int) {
        scaleButton.setTitle(scaleList[scale], for: .normal)
        if MKBXPConnectManager.shared.newVersion {
            sensitivitySlider.minimumValue = 1
            switch scale {
            case 0: sensitivitySlider.maximumValue = 20   // ±2g
            case 1: sensitivitySlider.maximumValue = 40   // ±4g
            case 2: sensitivitySlider.maximumValue = 80   // ±8g
            case 3: sensitivitySlider.maximumValue = 160  // ±16g
            default: break
            }
            sensitivityValueLabel.text = "0.1g"
            sensitivitySlider.value = 1
        } else {
            sensitivitySlider.minimumValue = 7
            sensitivitySlider.maximumValue = 255
            sensitivityValueLabel.text = "7"
            sensitivitySlider.value = 7
        }
        delegate?.bxp_accelerationParamsScaleChanged(scale)
        let tempValue = Int(sensitivitySlider.value)
        delegate?.bxp_accelerationParamsSensitivityValueChanged(tempValue)
    }

    private func updateUI() {
        guard let dataModel = dataModel else { return }
        scaleButton.setTitle(scaleList[dataModel.scale], for: .normal)
        sampleRateButton.setTitle(sampleRateList[dataModel.samplingRate], for: .normal)
        if MKBXPConnectManager.shared.newVersion {
            sensitivitySlider.minimumValue = 1
            switch dataModel.scale {
            case 0: sensitivitySlider.maximumValue = 20
            case 1: sensitivitySlider.maximumValue = 40
            case 2: sensitivitySlider.maximumValue = 80
            case 3: sensitivitySlider.maximumValue = 160
            default: break
            }
            sensitivityValueLabel.text = String(format: "%.1f%@", Double(dataModel.sensitivityValue) * 0.1, "g")
        } else {
            sensitivitySlider.minimumValue = 7
            sensitivitySlider.maximumValue = 255
            sensitivityValueLabel.text = "\(dataModel.sensitivityValue)"
        }
        sensitivitySlider.value = Float(dataModel.sensitivityValue)
    }
}
