//
//  MKBXPHTConfigController.swift
//  MKBeaconXPlusSwiftProject
//
//  Created by aa on 2026/9/18.
//

import UIKit
import SnapKit
import MKBaseSwiftModule
import MKSwiftCustomUI

public final class MKBXPHTConfigController: MKSwiftBaseViewController {

    // MARK: - Subviews

    private lazy var tableView: MKSwiftBaseTableView = {
        let tv = MKSwiftBaseTableView(frame: .zero, style: .plain)
        tv.delegate = self
        tv.dataSource = self
        tv.separatorStyle = .none
        tv.tableHeaderView = headerView
        return tv
    }()

    private lazy var headerView: MKBXPHTConfigHeaderView = {
        let view = MKBXPHTConfigHeaderView(frame: CGRect(x: 0, y: 0, width: MKScreen.width, height: 150))
        return view
    }()

    private lazy var section0List: [MKBXPStorageTriggerCellModel] = []
    private lazy var section1List: [MKBXPSyncBeaconTimeCellModel] = []
    private lazy var section2List: [MKBXPHTConfigNormalCellModel] = []

    private let dataModel = MKBXPHTConfigModel()

    private lazy var triggerCell: MKBXPStorageTriggerCell = {
        let cell = MKBXPStorageTriggerCell.initCellWithTableView(tableView)
        if let first = section0List.first {
            cell.dataModel = first
        }
        return cell
    }()

    // MARK: - Life Cycle

    deinit {
        NSLog("MKBXPHTConfigController销毁")
        NotificationCenter.default.removeObserver(self)
    }

    public override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        _ = MKBXPCentralManager.shared.notifyTHData(true)
    }

    public override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        _ = MKBXPCentralManager.shared.notifyTHData(false)
    }

    public override func viewDidLoad() {
        super.viewDidLoad()
        loadSubViews()
        startReadDatas()
        NotificationCenter.default.addObserver(self,
                                              selector: #selector(receiveHTDatas(_:)),
                                              name: .mk_bxp_receiveHTDataNotification,
                                              object: nil)
    }

    // MARK: - Super

    public override func rightButtonMethod() {
        let samplingInterval = headerView.getSamplingInterval()
        guard !samplingInterval.isEmpty,
              let intervalValue = Int(samplingInterval),
              intervalValue >= 1, intervalValue <= 65535 else {
            view.showCentralToast("Sampling interval error")
            return
        }

        let dic = triggerCell.getStorageTriggerConditions()
        let model = MKBXPHTStorageConditionsModel()
        model.condition = MKBXPHTStorageConditions(rawValue: dic["triggerType"] as? Int ?? 0) ?? .temperature

        if let tempStr = dic["temperature"] as? String, !tempStr.isEmpty,
           let tempValue = Float(tempStr) {
            model.temperature = Int(tempValue * 10)
        }
        if let humiStr = dic["humidity"] as? String, !humiStr.isEmpty,
           let humiValue = Float(humiStr) {
            model.humidity = Int(humiValue * 10)
        }
        if let timeStr = dic["time"] as? String, !timeStr.isEmpty,
           let timeValue = Int(timeStr) {
            model.time = timeValue
        }

        MKSwiftHudManager.shared.showHUD(with: "Config...", in: view, isPenetration: false)
        dataModel.configData(samplingInterval: intervalValue,
                             triggerConditions: model) { [weak self] in
            MKSwiftHudManager.shared.hide()
            self?.view.showCentralToast("Success")
        } failedBlock: { [weak self] error in
            MKSwiftHudManager.shared.hide()
            let msg = (error as NSError).userInfo["errorInfo"] as? String ?? ""
            self?.view.showCentralToast(msg)
        }
    }

    // MARK: - Notification

    @objc private func receiveHTDatas(_ note: Notification) {
        guard let dataDic = note.userInfo as? [String: Any] else { return }
        let temperature = dataDic["temperature"] as? String ?? ""
        let humidity = dataDic["humidity"] as? String ?? ""
        headerView.updateTemperature(temperature, humidity: humidity)
    }

    // MARK: - Interface

    private func syncDate() {
        MKSwiftHudManager.shared.showHUD(with: "Config...", in: view, isPenetration: false)

        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd-HH-mm-ss"
        let dateString = formatter.string(from: Date())
        let dateList = dateString.components(separatedBy: "-")

        let dateModel = MKBXPDeviceTimeDataModel()
        dateModel.year = Int(dateList[0]) ?? 0
        dateModel.month = Int(dateList[1]) ?? 0
        dateModel.day = Int(dateList[2]) ?? 0
        dateModel.hour = Int(dateList[3]) ?? 0
        dateModel.minutes = Int(dateList[4]) ?? 0
        dateModel.seconds = Int(dateList[5]) ?? 0

        MKBXPInterface.bxp_configDeviceTime(dateModel) { [weak self] _ in
            guard let self = self else { return }
            MKSwiftHudManager.shared.hide()
            if !self.section1List.isEmpty {
                let cellModel = self.section1List[0]
                cellModel.date = "\(dateList[2])/\(dateList[1])/\(dateList[0])"
                cellModel.time = "\(dateList[3]):\(dateList[4]):\(dateList[5])"
            }
            self.tableView.reloadSections(IndexSet(integer: 1), with: .none)
        } failedBlock: { [weak self] error in
            MKSwiftHudManager.shared.hide()
            let msg = (error as NSError).userInfo["errorInfo"] as? String ?? ""
            self?.view.showCentralToast(msg)
        }
    }

    // MARK: - 读取数据

    private func startReadDatas() {
        MKSwiftHudManager.shared.showHUD(with: "Reading...", in: view, isPenetration: false)
        dataModel.readData { [weak self] in
            MKSwiftHudManager.shared.hide()
            self?.loadSectionDatas()
        } failedBlock: { [weak self] error in
            MKSwiftHudManager.shared.hide()
            let msg = (error as NSError).userInfo["errorInfo"] as? String ?? ""
            self?.view.showCentralToast(msg)
        }
    }

    // MARK: - 列表加载数据

    private func loadSectionDatas() {
        headerView.updateSamplingInterval(dataModel.samplingInterval)

        let triggerModel = MKBXPStorageTriggerCellModel()
        triggerModel.triggerType = dataModel.triggerType
        triggerModel.temperature = dataModel.temperature
        triggerModel.humidity = dataModel.humidity
        triggerModel.storageTime = dataModel.storageTime
        section0List = [triggerModel]

        let timeModel = MKBXPSyncBeaconTimeCellModel()
        timeModel.date = dataModel.date
        timeModel.time = dataModel.time
        section1List = [timeModel]

        let textModel = MKBXPHTConfigNormalCellModel()
        textModel.msg = "Export T&H data"
        section2List = [textModel]

        tableView.reloadData()
    }

    // MARK: - UI

    private func loadSubViews() {
        defaultTitle = "Temperature & Humidity"
        setNavTitleFont(MKFont.font(15))
        rightButton.setImage(UIImage(named: "bxp_slotSaveIcon.png"), for: .normal)
        view.backgroundColor = UIColor(red: 242/255.0, green: 242/255.0, blue: 242/255.0, alpha: 1)

        view.addSubview(tableView)
        tableView.snp.makeConstraints { make in
            make.left.equalTo(5)
            make.right.equalTo(-5)
            make.top.equalTo(view).offset(MKLayout.topBarHeight)
            make.bottom.equalTo(view).offset(-MKLayout.safeAreaBottom)
        }
    }
}

// MARK: - UITableViewDelegate / DataSource

extension MKBXPHTConfigController: UITableViewDelegate, UITableViewDataSource {

    public func numberOfSections(in tableView: UITableView) -> Int { 3 }

    public func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch section {
        case 0: return section0List.count
        case 1: return section1List.count
        case 2: return section2List.count
        default: return 0
        }
    }

    public func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        switch indexPath.section {
        case 0: return 190
        case 1: return 100
        default: return 55
        }
    }

    public func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        switch indexPath.section {
        case 0:
            return triggerCell
        case 1:
            let cell = MKBXPSyncBeaconTimeCell.initCellWithTableView(tableView)
            cell.dataModel = section1List[indexPath.row]
            cell.delegate = self
            return cell
        default:
            let cell = MKBXPHTConfigNormalCell.initCellWithTableView(tableView)
            cell.dataModel = section2List[indexPath.row]
            return cell
        }
    }

    public func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if indexPath.section == 2 && indexPath.row == 0 {
            let vc = MKBXPExportDataController()
            navigationController?.pushViewController(vc, animated: true)
        }
    }
}

// MARK: - MKBXPSyncBeaconTimeCellDelegate

extension MKBXPHTConfigController: MKBXPSyncBeaconTimeCellDelegate {
    public func bxp_needUpdateDate() {
        syncDate()
    }
}
