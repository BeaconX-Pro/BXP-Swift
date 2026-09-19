//
//  MKBXPSettingController.swift
//  MKBeaconXPlusSwiftProject
//
//  Created by aa on 2026/9/18.
//

import UIKit
import SnapKit
import MKBaseSwiftModule
import MKSwiftCustomUI

public final class MKBXPSettingController: MKSwiftBaseViewController {

    // MARK: - Subviews

    private lazy var tableView: MKSwiftBaseTableView = {
        let tv = MKSwiftBaseTableView(frame: .zero, style: .plain)
        tv.delegate = self
        tv.dataSource = self
        tv.separatorStyle = .none
        return tv
    }()

    // MARK: - Data

    private lazy var section0List: [MKSwiftNormalTextCellModel] = []
    private lazy var section1List: [MKSwiftNormalTextCellModel] = []
    private lazy var section2List: [MKSwiftNormalTextCellModel] = []
    private lazy var section3List: [MKSwiftTextFieldCellModel] = []
    private lazy var section4List: [MKSwiftNormalTextCellModel] = []

    private var passwordAsciiStr: String = ""
    private var confirmAsciiStr: String = ""
    private var dfuModule: Bool = false
    private var interval: String = ""

    // MARK: - Life Cycle

    deinit {
        NSLog("MKBXPSettingController销毁")
        NotificationCenter.default.removeObserver(self)
    }

    public override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        if dfuModule { return }
        readDataFromDevice()
    }

    public override func viewDidLoad() {
        super.viewDidLoad()
        loadSubViews()
        loadSectionDatas()
        NotificationCenter.default.addObserver(self,
                                              selector: #selector(deviceStartDFUProcess),
                                              name: Notification.Name("mk_bxp_startDfuProcessNotification"),
                                              object: nil)
    }

    // MARK: - Super

    public override func leftButtonMethod() {
        NotificationCenter.default.post(name: Notification.Name("mk_bxp_popToRootViewControllerNotification"),
                                        object: nil)
    }

    public override func rightButtonMethod() {
        saveDataToDevice()
    }

    // MARK: - Notification

    @objc private func deviceStartDFUProcess() {
        dfuModule = true
    }

    // MARK: - Interface

    private func readDataFromDevice() {
        MKSwiftHudManager.shared.showHUD(with: "Reading...", in: view, isPenetration: false)
        MKBXPInterface.bxp_readEffectiveClickInterval { [weak self] returnData in
            guard let self = self else { return }
            MKSwiftHudManager.shared.hide()
            if let result = (returnData as? [String: Any])?["result"] as? [String: Any],
               let intervalStr = result["interval"] as? String {
                let tempData = (Int(intervalStr) ?? 0) / 100
                self.interval = "\(tempData)"
                if !self.section3List.isEmpty {
                    self.section3List[0].textFieldValue = self.interval
                }
            }
            self.loadSection1Datas()
            self.tableView.reloadData()
        } failedBlock: { [weak self] _ in
            guard let self = self else { return }
            MKSwiftHudManager.shared.hide()
            self.loadSection1Datas()
            self.tableView.reloadData()
        }
    }

    private func saveDataToDevice() {
        guard !interval.isEmpty,
              let intervalValue = Int(interval),
              intervalValue >= 5, intervalValue <= 15 else {
            view.showCentralToast("Params Error")
            return
        }
        MKSwiftHudManager.shared.showHUD(with: "Config...", in: view, isPenetration: false)
        MKBXPInterface.bxp_configEffectiveClickInterval(intervalValue) { [weak self] _ in
            MKSwiftHudManager.shared.hide()
            self?.view.showCentralToast("Success")
        } failedBlock: { [weak self] error in
            MKSwiftHudManager.shared.hide()
            let msg = (error as NSError).userInfo["errorInfo"] as? String ?? ""
            self?.view.showCentralToast(msg)
        }
    }

    // MARK: - loadSectionDatas

    private func loadSectionDatas() {
        loadSection0Datas()
        loadSection2Datas()
        loadSection3Datas()
        loadSection4Datas()
    }

    // MARK: - section0

    private func loadSection0Datas() {
        var list: [MKSwiftNormalTextCellModel] = []

        if MKBXPConnectManager.shared.deviceType != .none {
            // 00 为不带传感器
            let cellModel1 = MKSwiftNormalTextCellModel()
            cellModel1.showRightIcon = true
            cellModel1.leftMsg = "Sensor configurations"
            cellModel1.methodName = "pushSensorConfigPage"
            list.append(cellModel1)
        }

        let cellModel2 = MKSwiftNormalTextCellModel()
        cellModel2.showRightIcon = true
        cellModel2.leftMsg = "Quick switch"
        cellModel2.methodName = "pushQuickSwitchPage"
        list.append(cellModel2)

        let cellModel3 = MKSwiftNormalTextCellModel()
        cellModel3.showRightIcon = true
        cellModel3.leftMsg = "Turn off Beacon"
        cellModel3.methodName = "powerOff"
        list.append(cellModel3)

        section0List = list
    }

    // MARK: - 传感器设置

    @objc private func pushSensorConfigPage() {
        let vc = MKBXPSensorConfigController()
        navigationController?.pushViewController(vc, animated: true)
    }

    // MARK: - 开关状态设置

    @objc private func pushQuickSwitchPage() {
        let vc = MKBXPQuickSwitchController()
        navigationController?.pushViewController(vc, animated: true)
    }

    // MARK: - App 命令关机设备

    @objc private func powerOff() {
        let alert = MKSwiftAlertView()
        alert.addAction(MKSwiftAlertViewAction(title: "Cancel", handler: {}))
        alert.addAction(MKSwiftAlertViewAction(title: "OK", handler: { [weak self] in
            self?.commandPowerOff()
        }))
        alert.showAlert(title: "Warning!",
                        message: "Are you sure to turn off the Beacon?Please make sure the Beacon has a button to turn on!",
                        notificationName: "mk_bxp_needDismissAlert")
    }

    private func commandPowerOff() {
        MKSwiftHudManager.shared.showHUD(with: "Setting...", in: view, isPenetration: false)
        MKBXPInterface.bxp_configPowerOff { _ in
            MKSwiftHudManager.shared.hide()
            NotificationCenter.default.post(name: Notification.Name("mk_bxp_powerOffNotification"), object: nil)
        } failedBlock: { [weak self] error in
            MKSwiftHudManager.shared.hide()
            let msg = (error as NSError).userInfo["errorInfo"] as? String ?? ""
            self?.view.showCentralToast(msg)
        }
    }

    // MARK: - section1

    private func loadSection1Datas() {
        var list: [MKSwiftNormalTextCellModel] = []

        if MKBXPConnectManager.shared.passwordVerification {
            let resetModel = MKSwiftNormalTextCellModel()
            resetModel.leftMsg = "Reset Beacon"
            resetModel.showRightIcon = true
            resetModel.methodName = "factoryReset"
            list.append(resetModel)
        }

        if !MKBXPConnectManager.shared.password.isEmpty,
           MKBXPConnectManager.shared.passwordVerification {
            // 是否能够修改密码取决于用户是否是输入密码这种情况进来的
            let passwordModel = MKSwiftNormalTextCellModel()
            passwordModel.leftMsg = "Modify password"
            passwordModel.showRightIcon = true
            passwordModel.methodName = "configPassword"
            list.append(passwordModel)
        }

        section1List = list
    }

    // MARK: - 设置密码

    @objc private func configPassword() {
        let passwordField = MKSwiftAlertViewTextField(textValue: "",
                                                       placeholder: "Enter new password",
                                                       textFieldType: .normal,
                                                       maxLength: 16) { [weak self] text in
            self?.passwordAsciiStr = text
        }

        let confirmField = MKSwiftAlertViewTextField(textValue: "",
                                                      placeholder: "Enter new password again",
                                                      textFieldType: .normal,
                                                      maxLength: 16) { [weak self] text in
            self?.confirmAsciiStr = text
        }

        let alert = MKSwiftAlertView()
        alert.addAction(MKSwiftAlertViewAction(title: "Cancel", handler: {}))
        alert.addAction(MKSwiftAlertViewAction(title: "OK", handler: { [weak self] in
            self?.setPasswordToDevice()
        }))
        alert.addTextField(passwordField)
        alert.addTextField(confirmField)
        alert.showAlert(title: "Modify password",
                        message: "Note:The password should not be exceed 16 characters in length.",
                        notificationName: "mk_bxp_needDismissAlert")
    }

    private func setPasswordToDevice() {
        let password = passwordAsciiStr
        let confirmpassword = confirmAsciiStr

        guard !password.isEmpty, !confirmpassword.isEmpty,
              password.count <= 16, confirmpassword.count <= 16 else {
            view.showCentralToast("Length error.")
            return
        }
        guard password == confirmpassword else {
            view.showCentralToast("Password not match! Please try again.")
            return
        }

        MKSwiftHudManager.shared.showHUD(with: "Setting...", in: view, isPenetration: false)
        MKBXPInterface.bxp_configNewPassword(newPassword: password,
                                              originalPassword: MKBXPConnectManager.shared.password) { _ in
            MKSwiftHudManager.shared.hide()
            NotificationCenter.default.post(name: Notification.Name("mk_bxp_modifyPasswordSuccessNotification"),
                                            object: nil)
        } failedBlock: { [weak self] error in
            MKSwiftHudManager.shared.hide()
            let msg = (error as NSError).userInfo["errorInfo"] as? String ?? ""
            self?.view.showCentralToast(msg)
        }
    }

    // MARK: - 恢复出厂设置

    @objc private func factoryReset() {
        let alert = MKSwiftAlertView()
        alert.addAction(MKSwiftAlertViewAction(title: "Cancel", handler: {}))
        alert.addAction(MKSwiftAlertViewAction(title: "OK", handler: { [weak self] in
            self?.sendResetCommandToDevice()
        }))
        alert.showAlert(title: "Warning!",
                        message: "Are you sure to reset the Beacon?",
                        notificationName: "mk_bxp_needDismissAlert")
    }

    private func sendResetCommandToDevice() {
        MKSwiftHudManager.shared.showHUD(with: "Setting...", in: view, isPenetration: false)
        MKBXPInterface.bxp_factoryDataReset { _ in
            MKSwiftHudManager.shared.hide()
        } failedBlock: { [weak self] error in
            MKSwiftHudManager.shared.hide()
            let msg = (error as NSError).userInfo["errorInfo"] as? String ?? ""
            self?.view.showCentralToast(msg)
        }
    }

    // MARK: - section2

    private func loadSection2Datas() {
        let dfuModel = MKSwiftNormalTextCellModel()
        dfuModel.leftMsg = "DFU"
        dfuModel.showRightIcon = true
        dfuModel.methodName = "pushDFUPage"
        section2List = [dfuModel]
    }

    @objc private func pushDFUPage() {
        let vc = MKBXPUpdateController()
        navigationController?.pushViewController(vc, animated: true)
    }

    // MARK: - section3

    private func loadSection3Datas() {
        let cellModel = MKSwiftTextFieldCellModel()
        cellModel.index = 0
        cellModel.msg = "Effective click interval"
        cellModel.textPlaceholder = "5 ~ 15"
        cellModel.maxLength = 2
        cellModel.textFieldType = .realNumberOnly
        cellModel.unit = "x 100ms"
        section3List = [cellModel]
    }

    // MARK: - section4

    private func loadSection4Datas() {
        let cellModel = MKSwiftNormalTextCellModel()
        cellModel.leftMsg = "Remote reminder"
        cellModel.showRightIcon = true
        cellModel.methodName = "pushRemoteReminderPage"
        section4List = [cellModel]
    }

    @objc private func pushRemoteReminderPage() {
        let vc = MKBXPRemoteReminderController()
        navigationController?.pushViewController(vc, animated: true)
    }

    // MARK: - UI

    private func loadSubViews() {
        defaultTitle = "SETTING"
        rightButton.setImage(UIImage(named: "bxp_slotSaveIcon.png"), for: .normal)
        view.addSubview(tableView)
        tableView.snp.makeConstraints { make in
            make.left.right.equalToSuperview()
            make.top.equalTo(view).offset(MKLayout.topBarHeight)
            make.bottom.equalTo(view).offset(-(MKLayout.safeAreaBottom + 49))
        }
    }

    // MARK: - 方法分发

    private func performMethod(named methodName: String) {
        guard !methodName.isEmpty else { return }
        let selector = NSSelectorFromString(methodName)
        guard responds(to: selector) else { return }
        perform(selector, with: nil)
    }
}

// MARK: - UITableViewDelegate / DataSource

extension MKBXPSettingController: UITableViewDelegate, UITableViewDataSource {

    public func numberOfSections(in tableView: UITableView) -> Int { 5 }

    public func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch section {
        case 0: return section0List.count
        case 1: return section1List.count
        case 2: return section2List.count
        case 3: return section3List.count
        case 4: return MKBXPConnectManager.shared.isBXPD04 ? section4List.count : 0
        default: return 0
        }
    }

    public func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        44
    }

    public func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        switch indexPath.section {
        case 0:
            let cell = MKSwiftNormalTextCell.initCellWithTableView(tableView)
            cell.dataModel = section0List[indexPath.row]
            return cell
        case 1:
            let cell = MKSwiftNormalTextCell.initCellWithTableView(tableView)
            cell.dataModel = section1List[indexPath.row]
            return cell
        case 2:
            let cell = MKSwiftNormalTextCell.initCellWithTableView(tableView)
            cell.dataModel = section2List[indexPath.row]
            return cell
        case 3:
            let cell = MKSwiftTextFieldCell.initCellWithTableView(tableView)
            cell.dataModel = section3List[indexPath.row]
            cell.delegate = self
            return cell
        default:
            let cell = MKSwiftNormalTextCell.initCellWithTableView(tableView)
            cell.dataModel = section4List[indexPath.row]
            return cell
        }
    }

    public func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let cellModel: MKSwiftNormalTextCellModel?
        switch indexPath.section {
        case 0: cellModel = section0List[indexPath.row]
        case 1: cellModel = section1List[indexPath.row]
        case 2: cellModel = section2List[indexPath.row]
        case 4: cellModel = section4List[indexPath.row]
        default: cellModel = nil
        }
        guard let model = cellModel else { return }
        performMethod(named: model.methodName)
    }
}

// MARK: - MKSwiftTextFieldCellDelegate

extension MKBXPSettingController: MKSwiftTextFieldCellDelegate {
    public func mkDeviceTextCellValueChanged(_ index: Int, textValue: String) {
        if index == 0 {
            // Effective click interval
            if !section3List.isEmpty {
                section3List[0].textFieldValue = textValue
            }
            interval = textValue
        }
    }
}
