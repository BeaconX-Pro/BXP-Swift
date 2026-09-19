//
//  MKBXPStorageTriggerHTView.swift
//  MKBeaconXPlusSwiftProject
//
//  Created by aa on 2026/9/18.
//

import UIKit
import SnapKit
import MKBaseSwiftModule
import MKSwiftCustomUI

/// 温湿度触发条件配置视图
public final class MKBXPStorageTriggerHTView: UIView {

    // MARK: - Subviews

    private lazy var tempLabel: UILabel = makeMsgLabel("Temperature")

    private lazy var tempButton: UIButton = {
        let btn = UIButton(type: .custom)
        btn.setTitle("0.5", for: .normal)
        btn.titleLabel?.font = MKFont.font(12)
        btn.setTitleColor(MKColor.defaultText, for: .normal)
        btn.addTarget(self, action: #selector(tempButtonPressed), for: .touchUpInside)
        btn.layer.masksToBounds = true
        btn.layer.borderColor = MKColor.navBar.cgColor
        btn.layer.borderWidth = 0.5
        btn.layer.cornerRadius = 6
        return btn
    }()

    private lazy var tempUnitLabel: UILabel = makeMsgLabel("℃")

    private lazy var tempList: [String] = []

    private lazy var humidityLabel: UILabel = makeMsgLabel("Humidity")

    private lazy var humidityButton: UIButton = {
        let btn = UIButton(type: .custom)
        btn.setTitle("0.5", for: .normal)
        btn.titleLabel?.font = MKFont.font(12)
        btn.setTitleColor(MKColor.defaultText, for: .normal)
        btn.addTarget(self, action: #selector(humidityButtonPressed), for: .touchUpInside)
        btn.layer.masksToBounds = true
        btn.layer.borderColor = MKColor.navBar.cgColor
        btn.layer.borderWidth = 0.5
        btn.layer.cornerRadius = 6
        return btn
    }()

    private lazy var humidityUnitLabel: UILabel = makeMsgLabel("%RH")

    private lazy var humidityList: [String] = []

    private lazy var noteLabel: UILabel = {
        let label = UILabel()
        label.textAlignment = .left
        label.font = MKFont.font(12)
        label.textColor = UIColor(red: 229/255.0, green: 173/255.0, blue: 140/255.0, alpha: 1)
        label.numberOfLines = 0
        label.text = "*The device stores T&H data when the temperature changed ≥ 0 ℃ or humidity changed ≥ 0%RH."
        return label
    }()

    // MARK: - Init

    public override init(frame: CGRect) {
        super.init(frame: frame)
        addSubview(tempLabel)
        addSubview(tempButton)
        addSubview(tempUnitLabel)
        addSubview(humidityLabel)
        addSubview(humidityButton)
        addSubview(humidityUnitLabel)
        addSubview(noteLabel)
        loadListDatas()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Layout

    public override func layoutSubviews() {
        super.layoutSubviews()

        tempLabel.snp.remakeConstraints { make in
            make.left.equalTo(5)
            make.width.equalTo(85)
            make.centerY.equalTo(tempButton)
            make.height.equalTo(MKFont.font(13).lineHeight)
        }
        tempButton.snp.remakeConstraints { make in
            make.left.equalTo(tempLabel.snp.right).offset(10)
            make.width.equalTo(50)
            make.top.equalTo(10)
            make.height.equalTo(30)
        }
        tempUnitLabel.snp.remakeConstraints { make in
            make.left.equalTo(tempButton.snp.right).offset(5)
            make.right.equalTo(-5)
            make.centerY.equalTo(tempButton)
            make.height.equalTo(MKFont.font(13).lineHeight)
        }

        humidityLabel.snp.remakeConstraints { make in
            make.left.equalTo(5)
            make.width.equalTo(85)
            make.centerY.equalTo(humidityButton)
            make.height.equalTo(MKFont.font(13).lineHeight)
        }
        humidityButton.snp.remakeConstraints { make in
            make.left.equalTo(humidityLabel.snp.right).offset(10)
            make.width.equalTo(50)
            make.top.equalTo(tempButton.snp.bottom).offset(10)
            make.height.equalTo(30)
        }
        humidityUnitLabel.snp.remakeConstraints { make in
            make.left.equalTo(humidityButton.snp.right).offset(5)
            make.right.equalTo(-5)
            make.centerY.equalTo(humidityButton)
            make.height.equalTo(MKFont.font(13).lineHeight)
        }

        // ⚠️ 用 boundingRect 做多行尺寸计算，不能用 size(withAttributes:)
        let maxWidth = max(bounds.width - 10, 0)
        let size = noteLabel.text!.boundingRect(
            with: CGSize(width: maxWidth, height: .greatestFiniteMagnitude),
            options: [.usesLineFragmentOrigin, .usesFontLeading],
            attributes: [.font: noteLabel.font!],
            context: nil
        ).size
        noteLabel.snp.remakeConstraints { make in
            make.left.equalTo(5)
            make.right.equalTo(-5)
            make.bottom.equalTo(-5)
            make.height.equalTo(ceil(size.height))
        }
    }

    // MARK: - Event

    @objc private func tempButtonPressed() {
        let pickerView = MKSwiftPickerView()
        pickerView.showPickView(with: tempList, selectedRow: getCurrentTempIndex()) { [weak self] currentRow in
            guard let self = self else { return }
            self.tempButton.setTitle(self.tempList[currentRow], for: .normal)
            self.updateNoteMsg()
        }
    }

    @objc private func humidityButtonPressed() {
        let pickerView = MKSwiftPickerView()
        pickerView.showPickView(with: humidityList, selectedRow: getCurrentHumidityIndex()) { [weak self] currentRow in
            guard let self = self else { return }
            self.humidityButton.setTitle(self.humidityList[currentRow], for: .normal)
            self.updateNoteMsg()
        }
    }

    // MARK: - Public

    public func updateTemperature(_ temperature: String, humidity: String) {
        guard !temperature.isEmpty, !humidity.isEmpty else { return }
        tempButton.setTitle(temperature, for: .normal)
        humidityButton.setTitle(humidity, for: .normal)
        updateNoteMsg()
    }

    public func getCurrentTemperature() -> String {
        tempButton.title(for: .normal) ?? ""
    }

    public func getCurrentHumidity() -> String {
        humidityButton.title(for: .normal) ?? ""
    }

    // MARK: - Private

    private func updateNoteMsg() {
        noteLabel.text = "*The device stores T&H data when the temperature changed ≥ \(tempButton.title(for: .normal) ?? "") ℃ or humidity changed ≥ \(humidityButton.title(for: .normal) ?? "")%RH."
        setNeedsLayout()
    }

    private func getCurrentTempIndex() -> Int {
        guard let title = tempButton.title(for: .normal) else { return 0 }
        return tempList.firstIndex(of: title) ?? 0
    }

    private func getCurrentHumidityIndex() -> Int {
        guard let title = humidityButton.title(for: .normal) else { return 0 }
        return humidityList.firstIndex(of: title) ?? 0
    }

    private func loadListDatas() {
        for i in 1...120 {
            let value = String(format: "%.1f", Double(i) * 0.5)
            tempList.append(value)
        }
        for i in 1...190 {
            let value = String(format: "%.1f", Double(i) * 0.5)
            humidityList.append(value)
        }
    }

    private func makeMsgLabel(_ msg: String) -> UILabel {
        let label = UILabel()
        label.textAlignment = .left
        label.textColor = MKColor.defaultText
        label.font = MKFont.font(13)
        label.text = msg
        return label
    }
}
