//
//  MKBXPSensorConfigController.swift
//  MKBeaconXPlusSwiftProject
//
//  Created by aa on 2026/9/18.
//

import UIKit
import SnapKit
import MKBaseSwiftModule
import MKSwiftCustomUI

public final class MKBXPSensorConfigController: MKSwiftBaseViewController {

    // MARK: - Subviews

    private lazy var tableView: MKSwiftBaseTableView = {
        let tv = MKSwiftBaseTableView(frame: .zero, style: .plain)
        tv.delegate = self
        tv.dataSource = self
        tv.separatorStyle = .none
        return tv
    }()

    private lazy var dataList: [MKSwiftNormalTextCellModel] = []

    // MARK: - Life Cycle

    deinit {
        NSLog("MKBXPSensorConfigController销毁")
    }

    public override func viewDidLoad() {
        super.viewDidLoad()
        loadSubViews()
        loadSectionDatas()
    }

    // MARK: - Cell 点击事件

    @objc private func pushAccelerationPage() {
        let vc = MKBXPAccelerationController()
        navigationController?.pushViewController(vc, animated: true)
    }

    @objc private func pushHTConfigPage() {
        let vc = MKBXPHTConfigController()
        navigationController?.pushViewController(vc, animated: true)
    }

    @objc private func pushLightSensorPage() {
        let vc = MKBXPLightSensorController()
        navigationController?.pushViewController(vc, animated: true)
    }

    // MARK: - loadSectionDatas

    private func loadSectionDatas() {
        var list: [MKSwiftNormalTextCellModel] = []
        let deviceType = MKBXPConnectManager.shared.deviceType

        // 00: 无传感器, 01: 带 LIS3DH 三轴加速度计, 02: 带 SHT3X 温湿度传感器,
        // 03: 同时带有 LIS3DH 及 SHT3X 传感器, 04: 光感, 05: 三轴 + 光感
        switch deviceType {
        case .lis3dh:
            // 三轴传感器
            let cellModel = MKSwiftNormalTextCellModel()
            cellModel.showRightIcon = true
            cellModel.leftMsg = "3-axis accelerometer"
            cellModel.methodName = "pushAccelerationPage"
            list.append(cellModel)

        case .sht3x:
            // 温湿度
            let cellModel = MKSwiftNormalTextCellModel()
            cellModel.showRightIcon = true
            cellModel.leftMsg = "Temperature & Humidity"
            cellModel.methodName = "pushHTConfigPage"
            list.append(cellModel)

        case .lis3dhAndSht3x:
            // 三轴 + 温湿度
            let cellModel1 = MKSwiftNormalTextCellModel()
            cellModel1.showRightIcon = true
            cellModel1.leftMsg = "3-axis accelerometer"
            cellModel1.methodName = "pushAccelerationPage"
            list.append(cellModel1)

            let cellModel2 = MKSwiftNormalTextCellModel()
            cellModel2.showRightIcon = true
            cellModel2.leftMsg = "Temperature & Humidity"
            cellModel2.methodName = "pushHTConfigPage"
            list.append(cellModel2)

        case .light:
            // 光感
            let cellModel = MKSwiftNormalTextCellModel()
            cellModel.showRightIcon = true
            cellModel.leftMsg = "Light sensor"
            cellModel.methodName = "pushLightSensorPage"
            list.append(cellModel)

        case .threeAxisAndLight:
            // 三轴 + 光感
            let cellModel1 = MKSwiftNormalTextCellModel()
            cellModel1.showRightIcon = true
            cellModel1.leftMsg = "3-axis accelerometer"
            cellModel1.methodName = "pushAccelerationPage"
            list.append(cellModel1)

            let cellModel2 = MKSwiftNormalTextCellModel()
            cellModel2.showRightIcon = true
            cellModel2.leftMsg = "Light sensor"
            cellModel2.methodName = "pushLightSensorPage"
            list.append(cellModel2)

        default:
            break
        }

        dataList = list
        tableView.reloadData()
    }

    // MARK: - UI

    private func loadSubViews() {
        defaultTitle = "Sensor configurations"
        view.addSubview(tableView)
        tableView.snp.makeConstraints { make in
            make.left.right.equalToSuperview()
            make.top.equalTo(view).offset(MKLayout.topBarHeight)
            make.bottom.equalTo(view).offset(-MKLayout.safeAreaBottom)
        }
    }

    // MARK: - 方法分发

    /// 根据 methodName 动态调用对应方法
    private func performMethod(named methodName: String) {
        guard !methodName.isEmpty else { return }
        let selector = NSSelectorFromString(methodName)
        guard responds(to: selector) else { return }
        perform(selector, with: nil)
    }
}

// MARK: - UITableViewDelegate / DataSource

extension MKBXPSensorConfigController: UITableViewDelegate, UITableViewDataSource {

    public func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        dataList.count
    }

    public func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = MKSwiftNormalTextCell.initCellWithTableView(tableView)
        cell.dataModel = dataList[indexPath.row]
        return cell
    }

    public func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let cellModel = dataList[indexPath.row]
        performMethod(named: cellModel.methodName)
    }
}
