//
//  MKBXPDeviceInfoController.swift
//  MKBeaconXPlusSwiftProject
//
//  Created by aa on 2026/9/18.
//

import UIKit
import SnapKit
import MKBaseSwiftModule
import MKSwiftCustomUI

public final class MKBXPDeviceInfoController: MKSwiftBaseViewController {

    // MARK: - Subviews

    private lazy var tableView: MKSwiftBaseTableView = {
        let tv = MKSwiftBaseTableView(frame: .zero, style: .plain)
        tv.delegate = self
        tv.dataSource = self
        return tv
    }()

    // MARK: - Data

    private lazy var dataList: [MKSwiftNormalTextCellModel] = []

    /// 外部传入的设备信息 model
    public var dataModel: MKBXPDeviceInfoModel?

    /// 左侧按钮的点击事件
    public var leftButtonActionBlock: (() -> Void)?

    // MARK: - Lifecycle

    public override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        readDatasFromDevice()
    }

    public override func viewDidLoad() {
        super.viewDidLoad()
        loadSubViews()
    }

    // MARK: - Super

    public override func leftButtonMethod() {
        leftButtonActionBlock?()
    }

    // MARK: - Read

    private func readDatasFromDevice() {
        guard let dataModel = dataModel else { return }
        MKSwiftHudManager.shared.showHUD(with: "Reading...", in: view, isPenetration: false)
        dataModel.read { [weak self] in
            MKSwiftHudManager.shared.hide()
            self?.loadSectionDatas()
        } failedBlock: { [weak self] error in
            MKSwiftHudManager.shared.hide()
            let msg = (error as NSError).userInfo["errorInfo"] as? String ?? ""
            self?.view.showCentralToast(msg)
        }
    }

    // MARK: - Load Section Datas

    private func loadSectionDatas() {
        guard let dataModel = dataModel else { return }
        var list: [MKSwiftNormalTextCellModel] = []

        let m1 = MKSwiftNormalTextCellModel()
        m1.leftMsg = "Battery voltage"
        m1.rightMsg = dataModel.battery + "mV"
        list.append(m1)

        let m2 = MKSwiftNormalTextCellModel()
        m2.leftMsg = "MAC address"
        m2.rightMsg = dataModel.macAddress
        list.append(m2)

        let m3 = MKSwiftNormalTextCellModel()
        m3.leftMsg = "Product model"
        m3.rightMsg = dataModel.produce
        list.append(m3)

        let m4 = MKSwiftNormalTextCellModel()
        m4.leftMsg = "Software version"
        m4.rightMsg = dataModel.software
        list.append(m4)

        let m5 = MKSwiftNormalTextCellModel()
        m5.leftMsg = "Firmware version"
        m5.rightMsg = dataModel.firmware
        list.append(m5)

        let m6 = MKSwiftNormalTextCellModel()
        m6.leftMsg = "Hardware version"
        m6.rightMsg = dataModel.hardware
        list.append(m6)

        let m7 = MKSwiftNormalTextCellModel()
        m7.leftMsg = "Manufacture date"
        m7.rightMsg = dataModel.manuDate
        list.append(m7)

        let m8 = MKSwiftNormalTextCellModel()
        m8.leftMsg = "Manufacturer"
        m8.rightMsg = dataModel.manu
        list.append(m8)

        dataList = list
        tableView.reloadData()
    }

    // MARK: - UI

    private func loadSubViews() {
        defaultTitle = "DEVICE"
        view.addSubview(tableView)
        tableView.snp.makeConstraints { make in
            make.left.right.equalToSuperview()
            make.top.equalTo(view).offset(MKLayout.topBarHeight)
            make.bottom.equalTo(view).offset(-(MKLayout.safeAreaBottom + 49))
        }
    }
}

// MARK: - UITableViewDelegate / DataSource

extension MKBXPDeviceInfoController: UITableViewDelegate, UITableViewDataSource {

    public func numberOfSections(in tableView: UITableView) -> Int { 1 }

    public func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        dataList.count
    }

    public func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        44
    }

    public func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = MKSwiftNormalTextCell.initCellWithTableView(tableView)
        cell.dataModel = dataList[indexPath.row]
        return cell
    }
}
