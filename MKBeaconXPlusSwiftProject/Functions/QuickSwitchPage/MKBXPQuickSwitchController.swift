//
//  MKBXPQuickSwitchController.swift
//  MKBeaconXPlusSwiftProject
//
//  Created by aa on 2026/9/18.
//

import UIKit
import SnapKit
import MKBaseSwiftModule
import MKSwiftCustomUI
import MKSwiftBeaconXCustomUI

public final class MKBXPQuickSwitchController: MKSwiftBaseViewController {

    // MARK: - Subviews

    private lazy var collectionView: UICollectionView = {
        let layout = MKBXQuickSwitchCellLayout()
        layout.sectionInset = UIEdgeInsets(top: 11, left: 11, bottom: 0, right: 11)
        layout.scrollDirection = .vertical

        let cv = UICollectionView(frame: .zero, collectionViewLayout: layout)
        cv.backgroundColor = UIColor(red: 246/255.0, green: 247/255.0, blue: 251/255.0, alpha: 1)
        cv.delegate = self
        cv.dataSource = self
        cv.alwaysBounceVertical = true
        cv.register(MKBXQuickSwitchCell.self, forCellWithReuseIdentifier: "MKBXQuickSwitchCellIdenty")
        return cv
    }()

    private lazy var dataList: [MKBXQuickSwitchCellModel] = []

    private let dataModel = MKBXPQuickSwitchModel()

    // MARK: - Life Cycle

    deinit {
        NSLog("MKBXPQuickSwitchController销毁")
    }

    public override func viewDidLoad() {
        super.viewDidLoad()
        loadSubViews()
        readDataFromDevice()
    }

    // MARK: - MKBXQuickSwitchCellDelegate

    private func quickSwitchStatusChanged(_ isOn: Bool, index: Int) {
        switch index {
        case 0:
            // 可连接性
            configConnectEnable(isOn)
        case 1:
            // 按键关机
            configButtonPowerOff(isOn)
        case 2:
            // 密码验证
            configPasswordVerification(isOn)
        case 3:
            // 按键恢复出厂设置
            configButtonReset(isOn)
        case 4:
            // 设置 LED 触发
            configTriggerLEDNotification(isOn)
        case 5:
            // 设置回应包触发
            configScanPacket(isOn)
        default:
            break
        }
    }

    // MARK: - 设置可连接状态

    private func configConnectEnable(_ connect: Bool) {
        if connect {
            setConnectStatusToDevice(connect)
            return
        }
        // 设置设备为不可连接状态
        let alert = MKSwiftAlertView()
        alert.addAction(MKSwiftAlertViewAction(title: "Cancel", handler: { [weak self] in
            self?.collectionView.reloadData()
        }))
        alert.addAction(MKSwiftAlertViewAction(title: "OK", handler: { [weak self] in
            self?.setConnectStatusToDevice(connect)
        }))
        alert.showAlert(title: "Warning!",
                        message: "Are you sure to set the Beacon non-connectable？",
                        notificationName: "mk_bxp_needDismissAlert")
    }

    private func setConnectStatusToDevice(_ connect: Bool) {
        MKSwiftHudManager.shared.showHUD(with: "Setting...", in: view, isPenetration: false)
        MKBXPInterface.bxp_configConnectStatus(connect) { [weak self] _ in
            guard let self = self else { return }
            MKSwiftHudManager.shared.hide()
            if !self.dataList.isEmpty {
                self.dataList[0].isOn = connect
            }
            self.view.showCentralToast("Success!")
        } failedBlock: { [weak self] error in
            guard let self = self else { return }
            MKSwiftHudManager.shared.hide()
            let msg = (error as NSError).userInfo["errorInfo"] as? String ?? ""
            self.view.showCentralToast(msg)
            self.collectionView.reloadData()
        }
    }

    // MARK: - 配置按键关机状态

    private func configButtonPowerOff(_ isOn: Bool) {
        if isOn {
            setButtonPowerOffToDevice(isOn)
            return
        }
        // 禁用按键关机
        let alert = MKSwiftAlertView()
        alert.addAction(MKSwiftAlertViewAction(title: "Cancel", handler: { [weak self] in
            self?.collectionView.reloadData()
        }))
        alert.addAction(MKSwiftAlertViewAction(title: "OK", handler: { [weak self] in
            self?.setButtonPowerOffToDevice(isOn)
        }))
        alert.showAlert(title: "Warning!",
                        message: "If this function is disabled, you cannot power off the Beacon by button.",
                        notificationName: "mk_bxp_needDismissAlert")
    }

    private func setButtonPowerOffToDevice(_ isOn: Bool) {
        MKSwiftHudManager.shared.showHUD(with: "Setting...", in: view, isPenetration: false)
        MKBXPInterface.bxp_configButtonPowerStatus(isOn) { [weak self] _ in
            guard let self = self else { return }
            MKSwiftHudManager.shared.hide()
            if self.dataList.count > 1 {
                self.dataList[1].isOn = isOn
            }
            self.view.showCentralToast("Success!")
        } failedBlock: { [weak self] error in
            guard let self = self else { return }
            MKSwiftHudManager.shared.hide()
            let msg = (error as NSError).userInfo["errorInfo"] as? String ?? ""
            self.view.showCentralToast(msg)
            self.collectionView.reloadData()
        }
    }

    // MARK: - 设置设备是否免密码登录

    private func configPasswordVerification(_ isOn: Bool) {
        if isOn {
            commandForLockState(isOn)
            return
        }
        let alert = MKSwiftAlertView()
        alert.addAction(MKSwiftAlertViewAction(title: "Cancel", handler: { [weak self] in
            self?.collectionView.reloadData()
        }))
        alert.addAction(MKSwiftAlertViewAction(title: "OK", handler: { [weak self] in
            self?.commandForLockState(isOn)
        }))
        alert.showAlert(title: "Warning!",
                        message: "If Password verification is disabled, it will not need password to connect the Beacon.",
                        notificationName: "mk_bxp_needDismissAlert")
    }

    private func commandForLockState(_ isOn: Bool) {
        MKSwiftHudManager.shared.showHUD(with: "Setting...", in: view, isPenetration: false)
        let lockState: MKBXPLockState = isOn ? .open : .unlockAutoMaticRelockDisabled
        MKBXPInterface.bxp_configLockState(lockState) { [weak self] _ in
            guard let self = self else { return }
            MKSwiftHudManager.shared.hide()
            if self.dataList.count > 2 {
                self.dataList[2].isOn = isOn
            }
            MKBXPConnectManager.shared.passwordVerification = isOn
            self.view.showCentralToast("Success!")
        } failedBlock: { [weak self] error in
            guard let self = self else { return }
            MKSwiftHudManager.shared.hide()
            let msg = (error as NSError).userInfo["errorInfo"] as? String ?? ""
            self.view.showCentralToast(msg)
            self.collectionView.reloadData()
        }
    }

    // MARK: - 配置按键恢复出厂开关

    private func configButtonReset(_ isOn: Bool) {
        if isOn {
            setButtonResetToDevice(isOn)
            return
        }
        // 禁用按键恢复出厂
        let alert = MKSwiftAlertView()
        alert.addAction(MKSwiftAlertViewAction(title: "Cancel", handler: { [weak self] in
            self?.collectionView.reloadData()
        }))
        alert.addAction(MKSwiftAlertViewAction(title: "OK", handler: { [weak self] in
            self?.setButtonResetToDevice(isOn)
        }))
        alert.showAlert(title: "Warning!",
                        message: "If Button reset is disabled, you cannot reset the Beacon by button operation.",
                        notificationName: "mk_bxp_needDismissAlert")
    }

    private func setButtonResetToDevice(_ isOn: Bool) {
        MKSwiftHudManager.shared.showHUD(with: "Setting...", in: view, isPenetration: false)
        MKBXPInterface.bxp_configResetBeaconByButtonStatus(isOn) { [weak self] _ in
            guard let self = self else { return }
            MKSwiftHudManager.shared.hide()
            self.dataModel.resetByButton = isOn
            for cellModel in self.dataList {
                if cellModel.index == 3 {
                    cellModel.isOn = isOn
                    break
                }
            }
            self.view.showCentralToast("Success!")
        } failedBlock: { [weak self] error in
            guard let self = self else { return }
            MKSwiftHudManager.shared.hide()
            let msg = (error as NSError).userInfo["errorInfo"] as? String ?? ""
            self.view.showCentralToast(msg)
            self.collectionView.reloadData()
        }
    }

    // MARK: - 设置 LED 触发功能

    private func configTriggerLEDNotification(_ isOn: Bool) {
        MKSwiftHudManager.shared.showHUD(with: "Setting...", in: view, isPenetration: false)
        MKBXPInterface.bxp_configLEDTriggerStatus(isOn) { [weak self] _ in
            guard let self = self else { return }
            MKSwiftHudManager.shared.hide()
            self.dataModel.triggerLED = isOn
            for cellModel in self.dataList {
                if cellModel.index == 4 {
                    cellModel.isOn = isOn
                    break
                }
            }
            self.view.showCentralToast("Success!")
        } failedBlock: { [weak self] error in
            guard let self = self else { return }
            MKSwiftHudManager.shared.hide()
            let msg = (error as NSError).userInfo["errorInfo"] as? String ?? ""
            self.view.showCentralToast(msg)
            self.collectionView.reloadData()
        }
    }

    // MARK: - 设置回应包

    private func configScanPacket(_ isOn: Bool) {
        MKSwiftHudManager.shared.showHUD(with: "Setting...", in: view, isPenetration: false)
        MKBXPInterface.bxp_configScanResponsePacket(isOn) { [weak self] _ in
            guard let self = self else { return }
            MKSwiftHudManager.shared.hide()
            self.dataModel.scanPacket = isOn
            for cellModel in self.dataList {
                if cellModel.index == 5 {
                    cellModel.isOn = isOn
                    break
                }
            }
            self.view.showCentralToast("Success!")
        } failedBlock: { [weak self] error in
            guard let self = self else { return }
            MKSwiftHudManager.shared.hide()
            let msg = (error as NSError).userInfo["errorInfo"] as? String ?? ""
            self.view.showCentralToast(msg)
            self.collectionView.reloadData()
        }
    }

    // MARK: - 读取数据

    private func readDataFromDevice() {
        MKSwiftHudManager.shared.showHUD(with: "Reading...", in: view, isPenetration: false)
        dataModel.read { [weak self] in
            MKSwiftHudManager.shared.hide()
            self?.loadSectionData()
        } failedBlock: { [weak self] error in
            MKSwiftHudManager.shared.hide()
            let msg = (error as NSError).userInfo["errorInfo"] as? String ?? ""
            self?.view.showCentralToast(msg)
        }
    }

    // MARK: - loadSectionData

    private func loadSectionData() {
        var list: [MKBXQuickSwitchCellModel] = []

        let cellModel1 = MKBXQuickSwitchCellModel()
        cellModel1.index = 0
        cellModel1.titleMsg = "Connectable status"
        cellModel1.isOn = dataModel.connectable
        list.append(cellModel1)

        let cellModel2 = MKBXQuickSwitchCellModel()
        cellModel2.index = 1
        cellModel2.titleMsg = "Turn off Beacon by button"
        cellModel2.isOn = dataModel.turnOffByButton
        list.append(cellModel2)

        let cellModel3 = MKBXQuickSwitchCellModel()
        cellModel3.index = 2
        cellModel3.titleMsg = "Password verification"
        cellModel3.isOn = dataModel.passwordVerification
        list.append(cellModel3)

        if dataModel.supportResetByButton {
            let cellModel4 = MKBXQuickSwitchCellModel()
            cellModel4.index = 3
            cellModel4.titleMsg = "Reset Beacon by button"
            cellModel4.isOn = dataModel.resetByButton
            list.append(cellModel4)
        }

        if dataModel.supportLED {
            let cellModel5 = MKBXQuickSwitchCellModel()
            cellModel5.index = 4
            cellModel5.titleMsg = "Trigger LED indicator"
            cellModel5.isOn = dataModel.triggerLED
            list.append(cellModel5)
        }

        if dataModel.supportScanPackage() {
            let cellModel6 = MKBXQuickSwitchCellModel()
            cellModel6.index = 5
            cellModel6.titleMsg = "Scan response packet"
            cellModel6.isOn = dataModel.scanPacket
            list.append(cellModel6)
        }

        dataList = list
        collectionView.reloadData()
    }

    // MARK: - UI

    private func loadSubViews() {
        defaultTitle = "Quick switch"
        view.backgroundColor = UIColor(red: 242/255.0, green: 242/255.0, blue: 242/255.0, alpha: 1)

        view.addSubview(collectionView)
        collectionView.snp.makeConstraints { make in
            make.left.right.equalToSuperview()
            make.top.equalTo(view).offset(MKLayout.topBarHeight)
            make.bottom.equalTo(view).offset(-MKLayout.safeAreaBottom)
        }
    }
}

// MARK: - UICollectionViewDataSource

extension MKBXPQuickSwitchController: UICollectionViewDataSource {

    public func numberOfSections(in collectionView: UICollectionView) -> Int { 1 }

    public func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        dataList.count
    }

    public func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "MKBXQuickSwitchCellIdenty", for: indexPath) as! MKBXQuickSwitchCell
        cell.dataModel = dataList[indexPath.row]
        cell.delegate = self
        return cell
    }
}

// MARK: - UICollectionViewDelegateFlowLayout

extension MKBXPQuickSwitchController: UICollectionViewDelegateFlowLayout {

    public func collectionView(_ collectionView: UICollectionView,
                               layout collectionViewLayout: UICollectionViewLayout,
                               sizeForItemAt indexPath: IndexPath) -> CGSize {
        return CGSize(width: (MKScreen.width - 3 * 11) / 2, height: 85)
    }
}

// MARK: - MKBXQuickSwitchCellDelegate

extension MKBXPQuickSwitchController: MKBXQuickSwitchCellDelegate {
    public func mk_swift_bx_quickSwitchStatusChanged(_ isOn: Bool, index: Int) {
        quickSwitchStatusChanged(isOn, index: index)
    }
}
