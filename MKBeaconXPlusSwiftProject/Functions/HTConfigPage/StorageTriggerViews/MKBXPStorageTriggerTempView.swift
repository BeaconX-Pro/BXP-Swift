//
//  MKBXPStorageTriggerTempView.swift
//  MKBeaconXPlusSwiftProject
//
//  Created by aa on 2026/9/18.
//

import UIKit
import SnapKit
import MKBaseSwiftModule
import MKSwiftCustomUI

/// 温度触发条件配置视图
public final class MKBXPStorageTriggerTempView: UIView {

    // MARK: - Subviews

    private lazy var valueButton: UIButton = {
        let btn = UIButton(type: .custom)
        btn.setTitle("0.0", for: .normal)
        btn.titleLabel?.font = MKFont.font(12)
        btn.setTitleColor(MKColor.defaultText, for: .normal)
        btn.addTarget(self, action: #selector(valueButtonPressed), for: .touchUpInside)
        btn.layer.masksToBounds = true
        btn.layer.borderColor = MKColor.navBar.cgColor
        btn.layer.borderWidth = 0.5
        btn.layer.cornerRadius = 6
        return btn
    }()

    private lazy var unitLabel: UILabel = {
        let label = UILabel()
        label.textAlignment = .left
        label.textColor = MKColor.defaultText
        label.font = MKFont.font(13)
        label.text = "℃"
        return label
    }()

    private lazy var noteLabel: UILabel = {
        let label = UILabel()
        label.textAlignment = .left
        label.font = MKFont.font(12)
        label.textColor = UIColor(red: 229/255.0, green: 173/255.0, blue: 140/255.0, alpha: 1)
        label.numberOfLines = 0
        label.text = "*The device stores all sampled T&H data."
        return label
    }()

    private lazy var dataList: [String] = []

    // MARK: - Init

    public override init(frame: CGRect) {
        super.init(frame: frame)
        addSubview(valueButton)
        addSubview(unitLabel)
        addSubview(noteLabel)
        loadDataList()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Layout

    public override func layoutSubviews() {
        super.layoutSubviews()

        valueButton.snp.remakeConstraints { make in
            make.right.equalTo(self.snp.centerX).offset(-3)
            make.width.equalTo(50)
            make.top.equalTo(15)
            make.height.equalTo(30)
        }
        unitLabel.snp.remakeConstraints { make in
            make.left.equalTo(self.snp.centerX).offset(2)
            make.width.equalTo(40)
            make.centerY.equalTo(valueButton)
            make.height.equalTo(MKFont.font(13).lineHeight)
        }

        // ⚠️ 用 boundingRect 做多行尺寸计算
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

    @objc private func valueButtonPressed() {
        let pickerView = MKSwiftPickerView()
        pickerView.showPickView(with: dataList, selectedRow: getCurrentIndex()) { [weak self] currentRow in
            guard let self = self else { return }
            self.valueButton.setTitle(self.dataList[currentRow], for: .normal)
            self.processSelectMethod(currentRow)
        }
    }

    // MARK: - Public

    public func updateTemperateure(_ temperateure: String) {
        guard !temperateure.isEmpty else { return }
        valueButton.setTitle(temperateure, for: .normal)
        processSelectMethod(getCurrentIndex())
    }

    public func getCurrentTemperateure() -> String {
        valueButton.title(for: .normal) ?? ""
    }

    // MARK: - Private

    private func processSelectMethod(_ index: Int) {
        if index == 0 {
            noteLabel.text = "*The device stores all sampled T&H data."
        } else {
            noteLabel.text = "*The device stores T&H data when the temperateure changed ≥ \(dataList[index])℃."
        }
        setNeedsLayout()
    }

    private func getCurrentIndex() -> Int {
        guard let title = valueButton.title(for: .normal) else { return 0 }
        return dataList.firstIndex(of: title) ?? 0
    }

    private func loadDataList() {
        for i in 0...120 {
            let value = String(format: "%.1f", Double(i) * 0.5)
            dataList.append(value)
        }
    }
}
