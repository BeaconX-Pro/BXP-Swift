//
//  MKBXPRecodeHistoryHudView.swift
//  MKBeaconXPlusSwiftProject
//
//  Created by aa on 2026/9/18.
//

import UIKit
import SnapKit
import MKBaseSwiftModule

/// 历史记录 HUD 提示视图
public final class MKBXPRecodeHistoryHudView: UIView {

    private lazy var msgLabel: UILabel = {
        let label = UILabel()
        label.backgroundColor = .black
        label.textColor = .white
        label.font = MKFont.font(15)
        label.textAlignment = .center
        label.numberOfLines = 0
        label.layer.masksToBounds = true
        label.layer.cornerRadius = 6
        return label
    }()

    public override init(frame: CGRect) {
        super.init(frame: frame)
        self.frame = MKApp.window?.bounds ?? UIScreen.main.bounds
        backgroundColor = UIColor(red: 0, green: 0, blue: 0, alpha: 0.3)
        addSubview(msgLabel)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    public override func layoutSubviews() {
        super.layoutSubviews()
        msgLabel.snp.remakeConstraints { make in
            make.centerX.equalTo(self)
            make.centerY.equalTo(self)
            make.width.equalTo(frame.size.width - 2 * 90)
            make.height.equalTo(40)
        }
    }

    // MARK: - Public

    public func showMsg(_ msg: String) {
        msgLabel.text = msg
        setNeedsLayout()
    }
}
