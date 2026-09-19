//
//  MKBXPLightSensorButtonView.swift
//  MKBeaconXPlusSwiftProject
//
//  Created by aa on 2026/9/18.
//

import UIKit
import SnapKit
import MKBaseSwiftModule

// MARK: - View Model

public final class MKBXPLightSensorButtonViewModel: NSObject {
    public var msg: String = ""
    public var icon: UIImage?
}

// MARK: - Button View

public final class MKBXPLightSensorButtonView: UIControl {

    public var dataModel: MKBXPLightSensorButtonViewModel? {
        didSet { updateUI() }
    }

    // MARK: - Subviews

    private lazy var icon: UIImageView = {
        let iv = UIImageView()
        return iv
    }()

    private lazy var msgLabel: UILabel = {
        let label = UILabel()
        label.textColor = MKColor.defaultText
        label.textAlignment = .center
        label.font = MKFont.font(11)
        return label
    }()

    // MARK: - Init

    public override init(frame: CGRect) {
        super.init(frame: frame)
        addSubview(icon)
        addSubview(msgLabel)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Layout

    public override func layoutSubviews() {
        super.layoutSubviews()

        let iconSize = icon.image?.size ?? .zero
        icon.snp.remakeConstraints { make in
            make.centerX.equalTo(self)
            make.width.equalTo(iconSize.width)
            make.top.equalTo(2)
            make.height.equalTo(iconSize.height)
        }
        msgLabel.snp.remakeConstraints { make in
            make.left.right.bottom.equalToSuperview()
            make.height.equalTo(MKFont.font(13).lineHeight)
        }
    }

    // MARK: - Private

    private func updateUI() {
        guard let dataModel = dataModel else { return }
        msgLabel.text = dataModel.msg
        icon.image = dataModel.icon
    }
}
