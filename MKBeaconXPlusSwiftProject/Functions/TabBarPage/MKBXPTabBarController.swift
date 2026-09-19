//
//  MKBXPTabBarController.swift
//  MKBeaconXPlusSwiftProject
//
//  Created by aa on 2026/9/18.
//

import UIKit
import MKBaseSwiftModule
import MKSwiftCustomUI
import MKSwiftBeaconXCustomUI
import MKSwiftBleModule

// MARK: - Delegate

public protocol MKBXPTabBarControllerDelegate: AnyObject {
    /// 返回到扫描页面，肯定需要开启扫描。当 DFU 升级之后返回扫描页面，则需要重新设置扫描代理
    /// - Parameter need: true: DFU 升级情况下返回，需要设置扫描代理；false: 不需要重设代理
    func mk_bxp_needResetScanDelegate(_ need: Bool)
}

// MARK: - TabBarController

public final class MKBXPTabBarController: UITabBarController {

    /// 自定义业务代理（避免与 UITabBarController.delegate 冲突）
    public weak var bxpDelegate: MKBXPTabBarControllerDelegate?

    // MARK: - 私有属性

    private var disconnectType: Bool = false
    private var startDfu: Bool = false

    // MARK: - Life Cycle

    deinit {
        NSLog("MKBXPTabBarController销毁")
        NotificationCenter.default.removeObserver(self)
        MKBXPConnectManager.shared.clearParams()
    }

    public override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        let containedInNav = navigationController?.viewControllers.contains(self) ?? false
        if !containedInNav {
            MKBXPCentralManager.shared.disconnect()
        }
    }

    public override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        navigationController?.interactivePopGestureRecognizer?.isEnabled = false
    }

    public override func viewDidLoad() {
        super.viewDidLoad()
        _ = MKSwiftBleLogManager.deleteLog(fileName: "T&HDatas")
        _ = MKSwiftBleLogManager.deleteLog(fileName: "LightSensorDatas")
        MKBXPDatabaseManager.deleteDatas(sucBlock: nil, failedBlock: nil)
        loadSubPages()
        addNotifications()
    }

    // MARK: - Notification

    private func addNotifications() {
        NotificationCenter.default.addObserver(self,
                                              selector: #selector(gotoScanPage),
                                              name: Notification.Name("mk_bxp_popToRootViewControllerNotification"),
                                              object: nil)
        NotificationCenter.default.addObserver(self,
                                              selector: #selector(dfuUpdateComplete),
                                              name: Notification.Name("mk_bxp_centralDeallocNotification"),
                                              object: nil)
        NotificationCenter.default.addObserver(self,
                                              selector: #selector(disconnectTypeNotification(_:)),
                                              name: Notification.Name("mk_bxp_deviceDisconnectTypeNotification"),
                                              object: nil)
        NotificationCenter.default.addObserver(self,
                                              selector: #selector(deviceConnectStateChanged),
                                              name: .mk_bxp_peripheralConnectStateChangedNotification,
                                              object: nil)
        NotificationCenter.default.addObserver(self,
                                              selector: #selector(centralManagerStateChanged),
                                              name: .mk_bxp_centralManagerStateChangedNotification,
                                              object: nil)
        NotificationCenter.default.addObserver(self,
                                              selector: #selector(deviceLockStateChanged),
                                              name: .mk_bxp_peripheralLockStateChangedNotification,
                                              object: nil)
        NotificationCenter.default.addObserver(self,
                                              selector: #selector(devicePowerOff),
                                              name: Notification.Name("mk_bxp_powerOffNotification"),
                                              object: nil)
        NotificationCenter.default.addObserver(self,
                                              selector: #selector(startDfuProcess),
                                              name: Notification.Name("mk_bxp_startDfuProcessNotification"),
                                              object: nil)
    }

    // MARK: - 通知回调

    @objc private func gotoScanPage() {
        dismiss(animated: true) { [weak self] in
            guard let self = self else { return }
            self.bxpDelegate?.mk_bxp_needResetScanDelegate(false)
        }
    }

    @objc private func dfuUpdateComplete() {
        dismiss(animated: true) { [weak self] in
            guard let self = self else { return }
            self.bxpDelegate?.mk_bxp_needResetScanDelegate(true)
        }
    }

    @objc private func centralManagerStateChanged() {
        if disconnectType || startDfu { return }
        if MKBXPCentralManager.shared.centralStatus != .enable {
            showAlertWithMsg("The current system of bluetooth is not available!", title: "Dismiss")
        }
    }

    @objc private func deviceConnectStateChanged() {
        if disconnectType || startDfu { return }
        showAlertWithMsg("The device is disconnected.", title: "Dismiss")
    }

    @objc private func deviceLockStateChanged() {
        if disconnectType || startDfu { return }
        let lockState = MKBXPCentralManager.shared.lockState
        if lockState != .open,
           lockState != .unlockAutoMaticRelockDisabled,
           MKBXPCentralManager.shared.connectState == .connected {
            showAlertWithMsg("The device is locked!", title: "Dismiss")
        }
    }

    @objc private func disconnectTypeNotification(_ note: Notification) {
        if startDfu { return }
        let type = note.userInfo?["type"] as? String ?? ""
        // 00 一分钟之内没有输入密码, 01 修改密码成功, 02 设备恢复出厂设置
        disconnectType = true
        if type == "01" {
            showAlertWithMsg("Modify password success! Please reconnect the Device.", title: "")
            return
        }
        if type == "02" {
            showAlertWithMsg("Reset success!Beacon is disconnected.", title: "")
            return
        }
    }

    @objc private func devicePowerOff() {
        if disconnectType { return }
        showAlertWithMsg("The device is turned off", title: "Dismiss")
    }

    @objc private func startDfuProcess() {
        startDfu = true
    }

    // MARK: - Private

    private func showAlertWithMsg(_ msg: String, title: String) {
        // 让 setting 页面推出的 alert 消失
        NotificationCenter.default.post(name: Notification.Name("mk_bxp_needDismissAlert"), object: nil)
        // 让所有 MKPickView 消失
        NotificationCenter.default.post(name: Notification.Name("mk_customUIModule_dismissPickView"), object: nil)

        let alert = MKSwiftAlertView()
        alert.addAction(MKSwiftAlertViewAction(title: "OK", handler: { [weak self] in
            self?.gotoScanPage()
        }))
        alert.showAlert(title: title,
                        message: msg,
                        notificationName: "mk_bxp_needDismissAlert")
    }

    private func loadSubPages() {
        // SLOT 页
        let slotPage = MKBXPSlotController()
        slotPage.tabBarItem.title = "SLOT"
        slotPage.tabBarItem.image = UIImage(named: "bxp_slotTabBarItemUnselected.png")
        slotPage.tabBarItem.selectedImage = UIImage(named: "bxp_slotTabBarItemSelected.png")
        let slotNav = MKSwiftBaseNavigationController(rootViewController: slotPage)

        // SETTING 页
        let settingPage = MKBXPSettingController()
        settingPage.tabBarItem.title = "SETTING"
        settingPage.tabBarItem.image = UIImage(named: "bxp_settingTabBarItemUnselected.png")
        settingPage.tabBarItem.selectedImage = UIImage(named: "bxp_settingTabBarItemSelected.png")
        let settingNav = MKSwiftBaseNavigationController(rootViewController: settingPage)

        // DEVICE 页
        let devicePage = MKBXPDeviceInfoController()
        devicePage.tabBarItem.title = "DEVICE"
        devicePage.tabBarItem.image = UIImage(named: "bxp_deviceTabBarItemUnselected.png")
        devicePage.tabBarItem.selectedImage = UIImage(named: "bxp_deviceTabBarItemSelected.png")
        devicePage.dataModel = MKBXPDeviceInfoModel()
        devicePage.leftButtonActionBlock = { [weak self] in
            self?.gotoScanPage()
        }
        let deviceNav = MKSwiftBaseNavigationController(rootViewController: devicePage)

        viewControllers = [slotNav, settingNav, deviceNav]
    }
}
