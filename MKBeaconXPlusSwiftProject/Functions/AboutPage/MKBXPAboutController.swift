//
//  MKBXPAboutController.swift
//  MKBeaconXPlusSwiftProject
//
//  Created by aa on 2026/9/18.
//

import UIKit
import SnapKit
import MKBaseSwiftModule
import MKSwiftCustomUI

public final class MKBXPAboutController: MKSwiftBaseViewController {

    // MARK: - Subviews

    private lazy var aboutIcon: UIImageView = {
        let iv = UIImageView()
        iv.image = UIImage(named: "bxp_aboutIcon.png")
        return iv
    }()

    private lazy var appNameLabel: UILabel = {
        let label = UILabel()
        label.textColor = MKColor.defaultText
        label.textAlignment = .center
        label.font = MKFont.font(20)
        label.text = "BXP-Nordic"
        return label
    }()

    private lazy var versionLabel: UILabel = {
        let label = UILabel()
        label.textColor = UIColor(red: 189/255.0, green: 189/255.0, blue: 189/255.0, alpha: 1)
        label.textAlignment = .center
        label.font = MKFont.font(16)
        label.text = "Version: V1.2.0"
        return label
    }()

    private lazy var companyNameLabel: UILabel = {
        let label = UILabel()
        label.textColor = MKColor.defaultText
        label.textAlignment = .center
        label.font = MKFont.font(16)
        label.text = "MOKO TECHNOLOGY LTD."
        return label
    }()

    private lazy var companyNetLabel: UILabel = {
        let label = UILabel()
        label.textAlignment = .center
        label.textColor = MKColor.navBar
        label.font = MKFont.font(16)
        label.text = "www.mokoblue.com"
        label.isUserInteractionEnabled = true
        label.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(openWebBrowser)))

        let lineView = UIView()
        lineView.backgroundColor = UIColor(red: 3/255.0, green: 191/255.0, blue: 234/255.0, alpha: 1)
        label.addSubview(lineView)
        lineView.snp.makeConstraints { make in
            make.centerX.equalTo(label)
            make.width.equalTo(155)
            make.bottom.equalTo(label)
            make.height.equalTo(0.5)
        }
        return label
    }()

    private lazy var bottomIcon: UIImageView = {
        let iv = UIImageView()
        iv.isUserInteractionEnabled = true
        iv.image = UIImage(named: "bxp_aboutBottomIcon.png")
        return iv
    }()

    // MARK: - Life Cycle

    deinit {
        NSLog("MKBXPAboutController销毁")
    }

    public override func viewDidLoad() {
        super.viewDidLoad()
        loadSubViews()
    }

    // MARK: - Event

    @objc private func openWebBrowser() {
        guard let url = URL(string: "https://www.mokoblue.com") else { return }
        UIApplication.shared.open(url, options: [:], completionHandler: nil)
    }

    // MARK: - UI

    private func loadSubViews() {
        defaultTitle = "ABOUT"
        rightButton.isHidden = true

        view.addSubview(aboutIcon)
        view.addSubview(appNameLabel)
        view.addSubview(versionLabel)
        view.addSubview(bottomIcon)
        view.addSubview(companyNameLabel)
        view.addSubview(companyNetLabel)

        aboutIcon.snp.makeConstraints { make in
            make.centerX.equalTo(view)
            make.width.equalTo(110)
            make.top.equalTo(view).offset(MKLayout.topBarHeight + 40)
            make.height.equalTo(110)
        }
        appNameLabel.snp.makeConstraints { make in
            make.left.right.equalToSuperview()
            make.top.equalTo(aboutIcon.snp.bottom).offset(17)
            make.height.equalTo(MKFont.font(20).lineHeight)
        }
        versionLabel.snp.makeConstraints { make in
            make.left.right.equalToSuperview()
            make.top.equalTo(appNameLabel.snp.bottom).offset(17)
            make.height.equalTo(MKFont.font(16).lineHeight)
        }
        companyNetLabel.snp.makeConstraints { make in
            make.left.right.equalToSuperview()
            make.bottom.equalTo(-60)
            make.height.equalTo(MKFont.font(16).lineHeight)
        }
        companyNameLabel.snp.makeConstraints { make in
            make.left.right.equalToSuperview()
            make.bottom.equalTo(companyNetLabel.snp.top).offset(-17)
            make.height.equalTo(MKFont.font(17).lineHeight)
        }
    }
}
