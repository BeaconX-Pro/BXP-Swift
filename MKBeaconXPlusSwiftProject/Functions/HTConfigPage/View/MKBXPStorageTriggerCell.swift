//
//  MKBXPStorageTriggerCell.swift
//  MKBeaconXPlusSwiftProject
//
//  Created by aa on 2026/9/18.
//

import UIKit
import SnapKit
import MKBaseSwiftModule
import MKSwiftCustomUI

// MARK: - Cell Model

public final class MKBXPStorageTriggerCellModel: NSObject {
    /// 当前存储的触发条件
    /// 0: 温度, 1: 湿度, 2: 温湿度, 3: 时间
    public var triggerType: Int = 0
    /// triggerType = 0 或 2 才有值
    public var temperature: String = ""
    /// triggerType = 1 或 2 才有值
    public var humidity: String = ""
    /// triggerType = 3 才有值
    public var storageTime: String = ""
}

// MARK: - Cell

public final class MKBXPStorageTriggerCell: MKSwiftBaseCell {

    public var dataModel: MKBXPStorageTriggerCellModel? {
        didSet {
            guard let dataModel = dataModel else { return }
            index = dataModel.triggerType
            pickerView.selectRow(index, inComponent: 0, animated: true)
            setupUI()
        }
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
        label.font = MKFont.font(15)
        label.textAlignment = .left
        label.text = "Storage trigger"
        return label
    }()

    private lazy var pickerView: UIPickerView = {
        let picker = UIPickerView()
        picker.dataSource = self
        picker.delegate = self
        picker.layer.masksToBounds = true
        picker.layer.borderColor = MKColor.navBar.cgColor
        picker.layer.borderWidth = 0.5
        picker.layer.cornerRadius = 4
        return picker
    }()

    private lazy var dataList: [String] = ["Temperature", "Humidity", "T&H", "Time"]

    private lazy var thView: MKBXPStorageTriggerHTView = {
        let view = MKBXPStorageTriggerHTView()
        return view
    }()

    private lazy var humidityView: MKBXPStorageTriggerHumidityView = {
        let view = MKBXPStorageTriggerHumidityView()
        return view
    }()

    private lazy var tempView: MKBXPStorageTriggerTempView = {
        let view = MKBXPStorageTriggerTempView()
        return view
    }()

    private lazy var timeView: MKBXPStorageTriggerTimeView = {
        let view = MKBXPStorageTriggerTimeView()
        return view
    }()

    private var index: Int = 0

    // MARK: - Init

    public override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        selectionStyle = .none
        contentView.backgroundColor = UIColor(red: 242/255.0, green: 242/255.0, blue: 242/255.0, alpha: 1)
        contentView.addSubview(backView)

        backView.addSubview(msgLabel)
        backView.addSubview(pickerView)
        backView.addSubview(thView)
        backView.addSubview(humidityView)
        backView.addSubview(tempView)
        backView.addSubview(timeView)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    public static func initCellWithTableView(_ tableView: UITableView) -> MKBXPStorageTriggerCell {
        let identifier = "MKBXPStorageTriggerCellIdenty"
        if let cell = tableView.dequeueReusableCell(withIdentifier: identifier) as? MKBXPStorageTriggerCell {
            return cell
        }
        return MKBXPStorageTriggerCell(style: .default, reuseIdentifier: identifier)
    }

    // MARK: - Layout

    public override func layoutSubviews() {
        super.layoutSubviews()

        backView.snp.remakeConstraints { make in
            make.left.equalTo(5)
            make.right.equalTo(-5)
            make.top.equalTo(10)
            make.bottom.equalTo(-5)
        }
        msgLabel.snp.remakeConstraints { make in
            make.left.equalTo(10)
            make.right.equalTo(-10)
            make.top.equalTo(5)
            make.height.equalTo(MKFont.font(15).lineHeight)
        }
        pickerView.snp.remakeConstraints { make in
            make.left.equalTo(10)
            make.width.equalTo(100)
            make.top.equalTo(msgLabel.snp.bottom).offset(10)
            make.bottom.equalTo(-10)
        }
        tempView.snp.remakeConstraints { make in
            make.left.equalTo(pickerView.snp.right).offset(10)
            make.right.equalTo(-10)
            make.top.equalTo(msgLabel.snp.bottom).offset(10)
            make.bottom.equalTo(-10)
        }
        thView.snp.remakeConstraints { make in
            make.edges.equalTo(tempView)
        }
        humidityView.snp.remakeConstraints { make in
            make.edges.equalTo(tempView)
        }
        timeView.snp.remakeConstraints { make in
            make.edges.equalTo(tempView)
        }
    }

    // MARK: - Public

    public func getStorageTriggerConditions() -> [String: Any] {
        switch index {
        case 0:
            return [
                "triggerType": index,
                "temperature": tempView.getCurrentTemperateure()
            ]
        case 1:
            return [
                "triggerType": index,
                "humidity": humidityView.getCurrentHumidity()
            ]
        case 2:
            return [
                "triggerType": index,
                "temperature": thView.getCurrentTemperature(),
                "humidity": thView.getCurrentHumidity()
            ]
        case 3:
            return [
                "triggerType": index,
                "time": timeView.getCurrentTime()
            ]
        default:
            return ["triggerType": index]
        }
    }

    // MARK: - Private

    private func setupUI() {
        tempView.isHidden = (index != 0)
        humidityView.isHidden = (index != 1)
        thView.isHidden = (index != 2)
        timeView.isHidden = (index != 3)

        switch index {
        case 0:
            tempView.updateTemperateure(dataModel?.temperature ?? "")
        case 1:
            humidityView.updateHumidityValue(dataModel?.humidity ?? "")
        case 2:
            thView.updateTemperature(dataModel?.temperature ?? "",
                                     humidity: dataModel?.humidity ?? "")
        case 3:
            timeView.updateTime(dataModel?.storageTime ?? "")
        default:
            break
        }
    }
}

// MARK: - UIPickerViewDelegate / DataSource

extension MKBXPStorageTriggerCell: UIPickerViewDelegate, UIPickerViewDataSource {

    public func numberOfComponents(in pickerView: UIPickerView) -> Int { 1 }

    public func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        dataList.count
    }

    public func pickerView(_ pickerView: UIPickerView, rowHeightForComponent component: Int) -> CGFloat {
        30
    }

    /// 用于显示 title 的富文本（选中时高亮）
    public func pickerView(_ pickerView: UIPickerView,
                           attributedTitleForRow row: Int,
                           forComponent component: Int) -> NSAttributedString? {
        let typeName = dataList[row]
        return MKSwiftUIAdaptor.createAttributedString(
            strings: [typeName],
            fonts: [MKFont.font(13)],
            colors: [MKColor.navBar]
        )
    }

    /// 用于显示 title 的普通字符串（未选中）
    public func pickerView(_ pickerView: UIPickerView,
                           titleForRow row: Int,
                           forComponent component: Int) -> String? {
        dataList[row]
    }

    /// 自定义每个 row 的视图
    public func pickerView(_ pickerView: UIPickerView,
                           viewForRow row: Int,
                           forComponent component: Int,
                           reusing view: UIView?) -> UIView {
        let titleLabel: UILabel
        if let reused = view as? UILabel {
            titleLabel = reused
        } else {
            titleLabel = UILabel()
            titleLabel.textColor = MKColor.defaultText
            titleLabel.adjustsFontSizeToFitWidth = true
            titleLabel.textAlignment = .center
            titleLabel.font = MKFont.font(12)
        }
        if index == row {
            // 选中行：用富文本（蓝色）
            titleLabel.attributedText = attributedTitleForRow(row)
        } else {
            // 未选中行：用普通文本
            titleLabel.attributedText = nil
            titleLabel.text = dataList[row]
        }
        return titleLabel
    }

    public func pickerView(_ pickerView: UIPickerView,
                           didSelectRow row: Int,
                           inComponent component: Int) {
        index = row
        pickerView.reloadAllComponents()
        setupUI()
    }

    // MARK: - Private

    /// 生成选中行的富文本（对应 OC 的 `pickerView:attributedTitleForRow:forComponent:`）
    private func attributedTitleForRow(_ row: Int) -> NSAttributedString {
        let typeName = dataList[row]
        return MKSwiftUIAdaptor.createAttributedString(
            strings: [typeName],
            fonts: [MKFont.font(13)],
            colors: [MKColor.navBar]
        )
    }
}
