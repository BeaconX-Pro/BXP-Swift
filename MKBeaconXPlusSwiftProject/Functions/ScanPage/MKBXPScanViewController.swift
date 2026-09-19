//
//  MKBXPScanViewController.swift
//  MKBeaconXPlusSwiftProject
//
//  Created by aa on 2026/9/18.
//

import UIKit
@preconcurrency import CoreBluetooth
import SnapKit
import MKBaseSwiftModule
import MKSwiftCustomUI
import MKSwiftBeaconXCustomUI

public final class MKBXPScanViewController: MKSwiftBaseViewController,
                                             MKBXPCentralManagerScanDelegate,
                                             MKSwiftBXScanSearchButtonDelegate,
                                             MKBXPScanInfoCellDelegate,
                                             MKBXPTabBarControllerDelegate {

    // MARK: - 常量

    private static let offset_X: CGFloat = 15
    private static let searchButtonHeight: CGFloat = 40
    private static let headerViewHeight: CGFloat = 90
    private static let kRefreshInterval: TimeInterval = 0.5

    // MARK: - Subviews

    private lazy var tableView: MKSwiftBaseTableView = {
        let tv = MKSwiftBaseTableView(frame: .zero, style: .plain)
        tv.backgroundColor = .white
        tv.delegate = self
        tv.dataSource = self
        tv.separatorStyle = .none
        return tv
    }()

    private lazy var searchButton: MKSwiftBXScanSearchButton = {
        let btn = MKSwiftBXScanSearchButton()
        btn.delegate = self
        return btn
    }()

    private lazy var refreshIcon: UIImageView = {
        let iv = UIImageView()
        iv.image = UIImage(named: "bxp_scan_refreshIcon.png")
        return iv
    }()

    private lazy var refreshButton: UIButton = {
        let btn = UIButton(type: .custom)
        btn.addTarget(self, action: #selector(refreshButtonPressed), for: .touchUpInside)
        return btn
    }()

    // MARK: - Data

    private lazy var dataList: [MKBXPScanInfoCellModel] = []

    private lazy var buttonModel: MKSwiftBXScanSearchButtonModel = {
        let model = MKSwiftBXScanSearchButtonModel()
        model.placeholder = "Edit Filter"
        model.minSearchRssi = -100
        model.searchRssi = -100
        return model
    }()

    private var observerRef: CFRunLoopObserver?
    private var isNeedRefresh: Bool = false
    private var asciiText: String = ""

    // MARK: - Life Cycle

    deinit {
        NSLog("MKBXPScanViewController销毁")
        NotificationCenter.default.removeObserver(self)
        if let observerRef = observerRef {
            CFRunLoopRemoveObserver(CFRunLoopGetCurrent(), observerRef, .commonModes)
        }
        MKBXPCentralManager.shared.stopScan()
        MKBXPCentralManager.removeFromCentralList()
    }

    public override func viewDidLoad() {
        super.viewDidLoad()
        loadSubViews()
        startRefresh()
        NotificationCenter.default.addObserver(self,
                                              selector: #selector(dfuUpdateComplete),
                                              name: Notification.Name("mk_bxp_centralDeallocNotification"),
                                              object: nil)
    }

    // MARK: - Super

    public override func rightButtonMethod() {
        let vc = MKBXPAboutController()
        navigationController?.pushViewController(vc, animated: true)
    }

    // MARK: - Notification

    @objc private func dfuUpdateComplete() {
        mk_bxp_needResetScanDelegate(true)
    }

    // MARK: - MKSwiftBXScanSearchButtonDelegate

    public func mk_bx_scanSearchButtonMethod() {
        MKSwiftBXScanFilterView.showSearch(name: buttonModel.searchName,
                                            macAddress: buttonModel.searchMac,
                                            rssi: buttonModel.searchRssi) { [weak self] name, mac, rssi in
            guard let self = self else { return }
            self.buttonModel.searchRssi = rssi
            self.buttonModel.searchName = name
            self.buttonModel.searchMac = mac
            self.searchButton.dataModel = self.buttonModel
            self.refreshButton.isSelected = false
            self.refreshButtonPressed()
        }
    }

    public func mk_bx_scanSearchButtonClearMethod() {
        buttonModel.searchRssi = -100
        buttonModel.searchMac = ""
        buttonModel.searchName = ""
        searchButton.dataModel = buttonModel
        refreshButton.isSelected = false
        refreshButtonPressed()
    }

    // MARK: - MKBXPCentralManagerScanDelegate

    public func mk_bxp_receiveBeacon(_ beaconList: [MKBXPBaseBeacon]) {
        for beacon in beaconList {
            updateDataWithBeacon(beacon)
        }
    }

    public func mk_bxp_stopScan() {
        if refreshButton.isSelected {
            refreshIcon.layer.removeAnimation(forKey: "mk_refreshAnimationKey")
            refreshButton.isSelected = false
        }
    }

    // MARK: - MKBXPScanInfoCellDelegate

    public func mk_bxp_connectPeripheral(_ deviceModel: MKBXPScanInfoCellModel) {
        connectPeripheral(deviceModel)
    }

    // MARK: - MKBXPTabBarControllerDelegate

    public func mk_bxp_needResetScanDelegate(_ need: Bool) {
        if need {
            MKBXPCentralManager.shared.delegate = self
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + (need ? 1.0 : 0.1)) { [weak self] in
            self?.startScanDevice()
        }
    }

    // MARK: - Event

    @objc private func refreshButtonPressed() {
        guard MKBXPCentralManager.shared.centralStatus == .enable else {
            view.showCentralToast("The current system of bluetooth is not available!")
            return
        }
        refreshButton.isSelected.toggle()
        refreshIcon.layer.removeAnimation(forKey: "mk_refreshAnimationKey")

        if !refreshButton.isSelected {
            MKBXPCentralManager.shared.stopScan()
            return
        }

        dataList.removeAll()
        tableView.reloadData()
        defaultTitle = "DEVICE(\(dataList.count))"

        let animation = MKBXPSwiftAdopter.refreshAnimation(2.0)
        refreshIcon.layer.add(animation, forKey: "mk_refreshAnimationKey")
        MKBXPCentralManager.shared.startScan()
    }

    // MARK: - 刷新

    @objc private func startScanDevice() {
        refreshButton.isSelected = false
        refreshButtonPressed()
    }

    private func needRefreshList() {
        isNeedRefresh = true
        CFRunLoopWakeUp(CFRunLoopGetMain())
    }

    private func runloopObserver() {
        // 先移除旧的 observer，避免重复
        if let oldObserver = observerRef {
            CFRunLoopRemoveObserver(CFRunLoopGetCurrent(), oldObserver, .commonModes)
            observerRef = nil
        }

        var timeInterval = Date().timeIntervalSince1970
        let observer = CFRunLoopObserverCreateWithHandler(
            CFAllocatorGetDefault()?.takeUnretainedValue(),
            CFRunLoopActivity.allActivities.rawValue,
            true,
            0
        ) { [weak self] _, activity in
            guard let self = self else { return }
            if activity == .beforeWaiting {
                let currentInterval = Date().timeIntervalSince1970
                if currentInterval - timeInterval < Self.kRefreshInterval {
                    return
                }
                timeInterval = currentInterval
                if self.isNeedRefresh {
                    self.tableView.reloadData()
                    self.defaultTitle = "DEVICE(\(self.dataList.count))"
                    self.isNeedRefresh = false
                }
            }
        }
        observerRef = observer
        if let observerRef = observerRef {
            CFRunLoopAddObserver(CFRunLoopGetCurrent(), observerRef, .commonModes)
        }
    }

    private func updateDataWithBeacon(_ beacon: MKBXPBaseBeacon) {
        guard beacon.frameType != .unknown else { return }

        if !(buttonModel.searchMac ?? "").isEmpty || !(buttonModel.searchName ?? "").isEmpty {
            if beacon.rssi.intValue >= buttonModel.searchRssi {
                filterBeaconWithSearchName(beacon)
            }
            return
        }
        if buttonModel.searchRssi > buttonModel.minSearchRssi {
            if beacon.rssi.intValue >= buttonModel.searchRssi {
                processBeacon(beacon)
            }
            return
        }
        processBeacon(beacon)
    }

    private func filterBeaconWithSearchName(_ beacon: MKBXPBaseBeacon) {
        var filter = false
        var macAddress = ""
        var deviceName = ""

        if beacon.frameType == .deviceInfo || beacon.frameType == .threeASensor || beacon.frameType == .thSensor {
            filter = true
            if let tempBeacon = beacon as? MKBXPDeviceInfoBeacon {
                macAddress = tempBeacon.macAddress
                deviceName = tempBeacon.deviceName
            } else if let tempBeacon = beacon as? MKBXPThreeASensorBeacon {
                macAddress = tempBeacon.macAddress
                deviceName = tempBeacon.deviceName
            } else if let tempBeacon = beacon as? MKBXPTHSensorBeacon {
                macAddress = tempBeacon.macAddress
                deviceName = tempBeacon.deviceName
            }
        }

        if filter {
            let searchName = buttonModel.searchName ?? ""
            let searchMac = buttonModel.searchMac ?? ""
            let nameMatch = deviceName.uppercased().contains(searchName.uppercased())
            let macMatch = macAddress.replacingOccurrences(of: ":", with: "")
                .uppercased()
                .contains(searchMac.uppercased())
            if nameMatch || macMatch {
                processBeacon(beacon)
            }
            return
        }

        guard let peripheral = beacon.peripheral else { return }
        let identy = peripheral.identifier.uuidString
        guard let existModel = dataList.first(where: { $0.identifier == identy }) else {
            return
        }
        MKBXPScanPageAdopter.updateInfoCellModel(existModel, beaconData: beacon)
        needRefreshList()
    }

    private func processBeacon(_ beacon: MKBXPBaseBeacon) {
        guard let peripheral = beacon.peripheral else { return }
        let identy = peripheral.identifier.uuidString

        if let existModel = dataList.first(where: { $0.identifier == identy }) {
            MKBXPScanPageAdopter.updateInfoCellModel(existModel, beaconData: beacon)
            needRefreshList()
            return
        }

        let deviceModel = MKBXPScanPageAdopter.parseBaseBeaconToInfoModel(beacon)
        dataList.append(deviceModel)
        needRefreshList()
    }

    // MARK: - 连接设备

    private func connectPeripheral(_ deviceModel: MKBXPScanInfoCellModel) {
        refreshIcon.layer.removeAnimation(forKey: "mk_refreshAnimationKey")
        MKBXPCentralManager.shared.stopScan()

        guard let peripheral = deviceModel.peripheral else { return }

        if deviceModel.otaMode {
            MKSwiftHudManager.shared.showHUD(with: "Connecting...", in: view, isPenetration: false)
            MKBXPCentralManager.shared.dfuconnectPeripheral(peripheral) { [weak self] _ in
                MKSwiftHudManager.shared.hide()
                let vc = MKBXPUpdateController()
                self?.navigationController?.pushViewController(vc, animated: true)
            } failedBlock: { [weak self] error in
                MKSwiftHudManager.shared.hide()
                let msg = (error as NSError).userInfo["errorInfo"] as? String ?? ""
                self?.view.showCentralToast(msg)
                self?.connectFailed()
            }
            return
        }

        MKSwiftHudManager.shared.showHUD(with: "Loading...", in: view, isPenetration: false)
        MKBXPCentralManager.shared.readLockState(with: peripheral) { [weak self] lockState in
            MKSwiftHudManager.shared.hide()
            if lockState == "00" {
                self?.showPasswordAlert(peripheral)
                return
            }
            if lockState == "02" {
                self?.connectDeviceWithoutPassword(peripheral)
                return
            }
        } failedBlock: { [weak self] error in
            MKSwiftHudManager.shared.hide()
            let msg = (error as NSError).userInfo["errorInfo"] as? String ?? ""
            self?.view.showCentralToast(msg)
            self?.connectFailed()
        }
    }

    private func connectDeviceWithoutPassword(_ peripheral: CBPeripheral) {
        MKSwiftHudManager.shared.showHUD(with: "Connecting...", in: view, isPenetration: false)
        MKBXPConnectManager.shared.connectPeripheral(peripheral,
                                                     password: "") { _ in
            // 进度忽略
        } sucBlock: { [weak self] in
            MKSwiftHudManager.shared.hide()
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { [weak self] in
                self?.pushTabBarPage()
            }
        } failedBlock: { [weak self] error in
            MKSwiftHudManager.shared.hide()
            let msg = (error as NSError).userInfo["errorInfo"] as? String ?? ""
            self?.view.showCentralToast(msg)
            self?.connectFailed()
        }
    }

    private func connectDeviceWithPassword(_ peripheral: CBPeripheral) {
        let password = asciiText
        guard !password.isEmpty, password.count <= 16 else {
            view.showCentralToast("Password incorrect!")
            return
        }
        MKSwiftHudManager.shared.showHUD(with: "Connecting...", in: view, isPenetration: false)
        MKBXPConnectManager.shared.connectPeripheral(peripheral,
                                                     password: password) { _ in
            // 进度忽略
        } sucBlock: { [weak self] in
            UserDefaults.standard.set(password, forKey: "mk_bxp_localPasswordKey")
            MKSwiftHudManager.shared.hide()
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { [weak self] in
                self?.pushTabBarPage()
            }
        } failedBlock: { [weak self] error in
            MKSwiftHudManager.shared.hide()
            let msg = (error as NSError).userInfo["errorInfo"] as? String ?? ""
            self?.view.showCentralToast(msg)
            self?.connectFailed()
        }
    }

    @objc private func pushTabBarPage() {
        let vc = MKBXPTabBarController()
        vc.modalPresentationStyle = .fullScreen
        present(vc, animated: true) { [weak self] in
            vc.bxpDelegate = self
        }
    }

    private func connectFailed() {
        refreshButton.isSelected = false
        refreshButtonPressed()
    }

    private func showPasswordAlert(_ peripheral: CBPeripheral) {
        let localPassword = UserDefaults.standard.string(forKey: "mk_bxp_localPasswordKey") ?? ""
        asciiText = localPassword

        let textField = MKSwiftAlertViewTextField(textValue: localPassword,
                                                  placeholder: "No more than 16 characters.",
                                                  textFieldType: .normal,
                                                  maxLength: 16) { [weak self] text in
            self?.asciiText = text
        }

        let alert = MKSwiftAlertView()
        alert.addAction(MKSwiftAlertViewAction(title: "Cancel", handler: { [weak self] in
            self?.connectFailed()
        }))
        alert.addAction(MKSwiftAlertViewAction(title: "OK", handler: { [weak self] in
            self?.connectDeviceWithPassword(peripheral)
        }))
        alert.addTextField(textField)
        alert.showAlert(title: "Please enter password.",
                        message: "Please enter connection password.",
                        notificationName: "mk_bxp_needDismissAlert")
    }

    // MARK: - 启动刷新

    private func startRefresh() {
        searchButton.dataModel = buttonModel
        runloopObserver()
        MKBXPCentralManager.shared.delegate = self
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
            self?.showCentralStatus()
        }
    }

    @objc private func showCentralStatus() {
        guard MKBXPCentralManager.shared.centralStatus == .enable else {
            let msg = "The current system of bluetooth is not available!"
            let alert = MKSwiftAlertView()
            alert.addAction(MKSwiftAlertViewAction(title: "OK", handler: {}))
            alert.showAlert(title: "Dismiss", message: msg, notificationName: "")
            return
        }
        refreshButtonPressed()
    }

    // MARK: - UI

    private func loadSubViews() {
        view.backgroundColor = UIColor(red: 237/255.0, green: 243/255.0, blue: 250/255.0, alpha: 1)
        rightButton.setImage(UIImage(named: "bxp_scanRightAboutIcon.png"), for: .normal)
        defaultTitle = "DEVICE(0)"

        let topView = UIView()
        topView.backgroundColor = UIColor(red: 237/255.0, green: 243/255.0, blue: 250/255.0, alpha: 1)
        view.addSubview(topView)
        topView.snp.makeConstraints { make in
            make.left.right.equalToSuperview()
            make.top.equalTo(view).offset(MKLayout.topBarHeight)
            make.height.equalTo(Self.searchButtonHeight + 2 * 15)
        }

        refreshButton.addSubview(refreshIcon)
        topView.addSubview(refreshButton)
        refreshIcon.snp.makeConstraints { make in
            make.centerX.equalTo(refreshButton)
            make.centerY.equalTo(refreshButton)
            make.width.height.equalTo(22)
        }
        refreshButton.snp.makeConstraints { make in
            make.right.equalTo(-15)
            make.width.height.equalTo(40)
            make.top.equalTo(15)
        }

        topView.addSubview(searchButton)
        searchButton.snp.makeConstraints { make in
            make.left.equalTo(15)
            make.right.equalTo(refreshButton.snp.left).offset(-10)
            make.top.equalTo(15)
            make.height.equalTo(Self.searchButtonHeight)
        }

        view.addSubview(tableView)
        tableView.snp.makeConstraints { make in
            make.left.equalTo(10)
            make.right.equalTo(-10)
            make.top.equalTo(topView.snp.bottom)
            make.bottom.equalTo(view).offset(-(MKLayout.safeAreaBottom + 5))
        }
    }
}

// MARK: - UITableViewDelegate / DataSource

extension MKBXPScanViewController: UITableViewDelegate, UITableViewDataSource {

    public func numberOfSections(in tableView: UITableView) -> Int {
        dataList.count
    }

    public func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        dataList[section].advertiseList.count + 1
    }

    public func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let model = dataList[indexPath.section]
        if indexPath.row == 0 {
            let cell = MKBXPScanInfoCell.initCellWithTableView(tableView)
            cell.dataModel = model
            cell.delegate = self
            return cell
        }
        return MKSwiftBXScanPageAdopter.loadCell(with: tableView,
                                                 dataModel: model.advertiseList[indexPath.row - 1])
    }

    public func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        if indexPath.row == 0 {
            return Self.headerViewHeight
        }
        let model = dataList[indexPath.section]
        return MKSwiftBXScanPageAdopter.loadCellHeight(with: model.advertiseList[indexPath.row - 1])
    }

    public func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        section == 0 ? 0 : 5
    }

    public func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let headerView = MKSwiftTableSectionLineHeader.dequeueHeader(with: tableView)
        let sectionData = MKSwiftTableSectionLineHeaderModel()
        sectionData.contentColor = UIColor(red: 237/255.0, green: 243/255.0, blue: 250/255.0, alpha: 1)
        headerView.headerModel = sectionData
        return headerView
    }
}
