//
//  MKBXPSlotConfigController.swift
//  MKBeaconXPlusSwiftProject
//
//  Created by aa on 2026/9/18.
//

import UIKit
import SnapKit
import MKBaseSwiftModule
import MKSwiftCustomUI
import MKSwiftBeaconXCustomUI

public final class MKBXPSlotConfigController: MKSwiftBaseViewController {

    // MARK: - 常量

    private static let mk_advContentKey = "mk_advContentKey"
    private static let mk_advParamsKey = "mk_advParamsKey"
    private static let mk_advTriggerKey = "mk_advTriggerKey"

    private static let mk_beaconAdvContentHeight: CGFloat = 160
    private static let mk_advParamsContentHeight: CGFloat = 190
    private static let mk_triggerOpenHeight: CGFloat = 280
    private static let mk_triggerCloseHeight: CGFloat = 50
    private static let mk_uidAdvContentHeight: CGFloat = 120
    private static let mk_urlAdvContentHeight: CGFloat = 100
    private static let mk_deviceAdvContentHeight: CGFloat = 100

    // MARK: - 公开属性

    /// 数据通道类型
    public var slotType: MKSwiftBXSlotFrameType = .null

    /// 通道 index
    public var slotIndex: Int = 0

    // MARK: - Subviews

    private lazy var headerView: MKSwiftBXSlotFrameTypePickView = {
        let view = MKSwiftBXSlotFrameTypePickView(frame: CGRect(x: 0, y: 20,
                                                                 width: MKScreen.width,
                                                                 height: 130))
        view.delegate = self
        view.dataList = fetchFrameTypeList()
        return view
    }()

    private lazy var tableView: MKSwiftBaseTableView = {
        let tv = MKSwiftBaseTableView(frame: .zero, style: .plain)
        tv.delegate = self
        tv.dataSource = self
        tv.separatorStyle = .none
        tv.tableHeaderView = makeTableHeader()
        return tv
    }()

    // MARK: - Data

    private lazy var section0List: [Any] = []
    private lazy var section1List: [MKBXPSlotConfigAdvParamsCellModel] = []
    private lazy var section2List: [MKSwiftBXSlotConfigTriggerCellModel] = []

    private let dataModel = MKBXPSlotConfigModel()

    /// 保存各个 section 中配置好的 Cell，用于提交时提取参数
    private var cellDic: [String: UITableViewCell] = [:]

    /// 当前 slotType 是否有 Section 0（广播内容）
    /// - 只有 beacon / uid / url / info 才有广播内容
    /// - tlm / threeASensor / thSensor 没有广播内容，Section 0 不加载
    private var hasSection0: Bool {
        return slotType == .beacon || slotType == .uid || slotType == .url || slotType == .info
    }

    // MARK: - Life Cycle

    deinit {
        NSLog("MKBXPSlotConfigController销毁")
    }

    public override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        navigationController?.interactivePopGestureRecognizer?.isEnabled = true
    }

    public override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        navigationController?.interactivePopGestureRecognizer?.isEnabled = false
    }

    public override func viewDidLoad() {
        super.viewDidLoad()
        loadSubViews()
        readDataFromDevice()
    }

    // MARK: - Super

    public override func rightButtonMethod() {
        // 校验其他通道是否至少有一个不是 NO DATA
        var valid = false
        for (i, type) in dataModel.slotTypeList.enumerated() {
            if i != slotIndex {
                if type != "ff" {
                    valid = true
                    break
                }
            }
        }
        if !valid && slotType == .null {
            // 如果其他通道都是 ff，则当前通道不能设置为 ff
            let alert = MKSwiftAlertView()
            alert.addAction(MKSwiftAlertViewAction(title: "OK", handler: {}))
            alert.showAlert(title: "Warning!",
                            message: "*Please ensure that at lease 1 SLOT is enabled",
                            notificationName: "mk_bxp_needDismissAlert")
            return
        }

        var dataDic: [String: Any] = [:]
        if slotType != .null {
            // 当前要配置的通道信息不是 NO DATA
            for (_, value) in cellDic {
                guard let protocolCell = value as? MKSwiftBXSlotConfigCellProtocol else { continue }
                let paramDic = protocolCell.slotConfigCellParams()
                if let msg = paramDic["msg"] as? String, !msg.isEmpty {
                    // 存在参数错误
                    view.showCentralToast(msg)
                    return
                }
                if let result = paramDic["result"] as? [String: Any],
                   let dataType = result["dataType"] as? String,
                   let params = result["params"] as? [String: Any] {
                    dataDic[dataType] = params
                }
            }
        }

        dataModel.slotType = slotType
        MKSwiftHudManager.shared.showHUD(with: "Config...", in: view, isPenetration: false)
        dataModel.configSlotParams(dataDic) { [weak self] in
            guard let self = self else { return }
            MKSwiftHudManager.shared.hide()
            self.view.showCentralToast("Success")
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
                self?.leftButtonMethod()
            }
        } failedBlock: { [weak self] error in
            MKSwiftHudManager.shared.hide()
            let msg = (error as NSError).userInfo["errorInfo"] as? String ?? ""
            self?.view.showCentralToast(msg)
        }
    }

    // MARK: - 读取数据

    private func readDataFromDevice() {
        MKSwiftHudManager.shared.showHUD(with: "Reading...", in: view, isPenetration: false)
        dataModel.slotType = slotType
        dataModel.slotIndex = slotIndex

        dataModel.read { [weak self] in
            guard let self = self else { return }
            MKSwiftHudManager.shared.hide()
            self.slotType = self.dataModel.slotType
            self.headerView.updateFrameType(self.slotType)
            self.loadSectionDatas()
        } failedBlock: { [weak self] error in
            MKSwiftHudManager.shared.hide()
            let msg = (error as NSError).userInfo["errorInfo"] as? String ?? ""
            self?.view.showCentralToast(msg)
        }
    }

    // MARK: - 列表刷新

    private func loadSectionDatas() {
        section0List.removeAll()
        section1List.removeAll()
        section2List.removeAll()
        cellDic.removeAll()

        if slotType == .null {
            tableView.reloadData()
            return
        }
        loadSection0Datas()
        loadSection1Datas()
        loadSection2Datas()
        tableView.reloadData()
    }

    private func loadSection0Datas() {
        switch slotType {
        case .beacon:
            let cellModel = MKSwiftBXSlotConfigBeaconCellModel()
            if !dataModel.advSlotData.isEmpty,
               let frameType = dataModel.advSlotData["frameType"] as? String,
               frameType == "50" {
                // 当前设备广播通道是 beacon
                cellModel.uuid = (dataModel.advSlotData["uuid"] as? String ?? "")
                    .replacingOccurrences(of: "-", with: "")
                cellModel.major = dataModel.advSlotData["major"] as? String ?? ""
                cellModel.minor = dataModel.advSlotData["minor"] as? String ?? ""
            }
            section0List.append(cellModel)

        case .uid:
            let cellModel = MKSwiftBXSlotConfigUIDCell()
            if !dataModel.advSlotData.isEmpty,
               let frameType = dataModel.advSlotData["frameType"] as? String,
               frameType == "00" {
                // 当前设备广播通道是 UID
                cellModel.nameSpace = dataModel.advSlotData["namespaceId"] as? String ?? ""
                cellModel.instanceID = dataModel.advSlotData["instanceId"] as? String ?? ""
            }
            section0List.append(cellModel)

        case .url:
            let cellModel = MKSwiftBXSlotConfigURLCellModel()
            if !dataModel.advSlotData.isEmpty,
               let frameType = dataModel.advSlotData["frameType"] as? String,
               frameType == "10" {
                // 当前设备广播通道是 URL
                cellModel.advData = dataModel.advSlotData["advData"] as? Data
            }
            section0List.append(cellModel)

        case .info:
            let cellModel = MKSwiftBXSlotConfigInfoCellModel()
            if !dataModel.advSlotData.isEmpty,
               let frameType = dataModel.advSlotData["frameType"] as? String,
               frameType == "40" {
                // 当前设备广播通道是 Info
                cellModel.deviceName = dataModel.advSlotData["peripheralName"] as? String ?? ""
            }
            section0List.append(cellModel)

        default:
            // tlm / threeASensor / thSensor / null 没有广播内容，section0List 保持为空
            break
        }
    }

    private func loadSection1Datas() {
        let cellModel = MKBXPSlotConfigAdvParamsCellModel()
        cellModel.slotType = slotType
        if slotType == dataModel.slotType {
            cellModel.txPower = dataModel.txPower
            cellModel.rssiValue = dataModel.rssi0M
            cellModel.advInterval = dataModel.advInterval
        } else {
            cellModel.txPower = 5
            cellModel.rssiValue = (slotType == .beacon ? -59 : 0)
            cellModel.advInterval = "10"
        }
        section1List = [cellModel]
    }

    private func loadSection2Datas() {
        let cellModel = MKSwiftBXSlotConfigTriggerCellModel()
        cellModel.deviceType = MKBXPConnectManager.shared.deviceType.rawValue
        cellModel.isBXPC = MKBXPConnectManager.shared.isBXPC
        cellModel.tamperDetect = MKBXPConnectManager.shared.tamperDetect

        if slotType == dataModel.slotType {
            let type = dataModel.triggerConditions["type"] as? String ?? "00"
            cellModel.type = type
            cellModel.conditions = dataModel.triggerConditions["conditions"] as? [String: Any] ?? [:]
            cellModel.isOn = !dataModel.triggerConditions.isEmpty && !type.isEmpty && type != "00"
        } else {
            cellModel.type = "00"
            cellModel.isOn = false
        }
        section2List = [cellModel]
    }

    // MARK: - Cell 加载

    private func loadCellWithIndexPath(_ indexPath: IndexPath) -> UITableViewCell {
        if indexPath.section == 0 {
            switch slotType {
            case .beacon:
                let cell = MKSwiftBXSlotConfigBeaconCell.dequeueReusableCell(with: tableView)
                cell.dataModel = section0List[indexPath.row] as? MKSwiftBXSlotConfigBeaconCellModel
                cellDic[Self.mk_advContentKey] = cell
                return cell

            case .uid:
                let cell = MKBXSlotConfigUIDCell.dequeueReusableCell(with: tableView)
                cell.dataModel = section0List[indexPath.row] as? MKSwiftBXSlotConfigUIDCell
                cellDic[Self.mk_advContentKey] = cell
                return cell

            case .url:
                let cell = MKSwiftBXSlotConfigURLCell.dequeueReusableCell(with: tableView)
                cell.dataModel = section0List[indexPath.row] as? MKSwiftBXSlotConfigURLCellModel
                cellDic[Self.mk_advContentKey] = cell
                return cell

            case .info:
                let cell = MKSwiftBXSlotConfigInfoCell.dequeueReusableCell(with: tableView)
                cell.dataModel = section0List[indexPath.row] as? MKSwiftBXSlotConfigInfoCellModel
                cellDic[Self.mk_advContentKey] = cell
                return cell

            default:
                return UITableViewCell()
            }
        }

        if indexPath.section == 1 {
            // AdvParams
            let cell = MKBXPSlotConfigAdvParamsCell.initCellWithTableView(tableView)
            cell.dataModel = section1List[indexPath.row]
            cellDic[Self.mk_advParamsKey] = cell
            return cell
        }

        // 触发条件
        let cell = MKSwiftBXSlotConfigTriggerCell.initCell(with: tableView)
        cell.dataModel = section2List[indexPath.row]
        cell.delegate = self
        cellDic[Self.mk_advTriggerKey] = cell
        return cell
    }

    private func getCellHeightWithIndexPath(_ indexPath: IndexPath) -> CGFloat {
        if slotType == .null {
            return 0
        }
        if indexPath.section == 0 {
            switch slotType {
            case .beacon: return Self.mk_beaconAdvContentHeight
            case .uid:    return Self.mk_uidAdvContentHeight
            case .url:    return Self.mk_urlAdvContentHeight
            case .info:   return Self.mk_deviceAdvContentHeight
            default:      return 0
            }
        }
        if indexPath.section == 1 {
            return (slotType == .tlm ? 140 : Self.mk_advParamsContentHeight)
        }
        // Trigger
        guard !section2List.isEmpty else { return 0 }
        let cellModel = section2List[0]
        return cellModel.isOn ? Self.mk_triggerOpenHeight : Self.mk_triggerCloseHeight
    }

    // MARK: - UI

    private func loadSubViews() {
        defaultTitle = "SLOT\(slotIndex + 1)"
        rightButton.setImage(UIImage(named: "bxp_slotSaveIcon.png"), for: .normal)
        view.backgroundColor = UIColor(red: 242/255.0, green: 242/255.0, blue: 242/255.0, alpha: 1)

        view.addSubview(tableView)
        tableView.snp.makeConstraints { make in
            make.left.equalTo(5)
            make.right.equalTo(-5)
            make.top.equalTo(view).offset(MKLayout.topBarHeight)
            make.bottom.equalTo(view).offset(-MKLayout.safeAreaBottom)
        }
        headerView.updateFrameType(dataModel.slotType)
    }

    private func makeTableHeader() -> UIView {
        let tableHeader = UIView(frame: CGRect(x: 5, y: 0,
                                                width: MKScreen.width - 10,
                                                height: 150))
        tableHeader.backgroundColor = UIColor(red: 242/255.0, green: 242/255.0, blue: 242/255.0, alpha: 1)
        tableHeader.addSubview(headerView)
        return tableHeader
    }

    private func fetchFrameTypeList() -> [MKSwiftBXSlotFrameTypePickViewModel] {
        func makeModel(_ name: String, _ type: MKSwiftBXSlotFrameType) -> MKSwiftBXSlotFrameTypePickViewModel {
            let model = MKSwiftBXSlotFrameTypePickViewModel()
            model.frameName = name
            model.frameType = type
            return model
        }

        let tlmModel = makeModel("TLM", .tlm)
        let uidModel = makeModel("UID", .uid)
        let urlModel = makeModel("URL", .url)
        let iBeaconModel = makeModel("iBeacon", .beacon)
        let deviceInfoModel = makeModel("Device info", .info)
        let noDataModel = makeModel("No data", .null)
        let axisModel = makeModel("3-axis Acc", .threeASensor)
        let thModel = makeModel("T&H", .thSensor)

        let deviceType = MKBXPConnectManager.shared.deviceType
        switch deviceType {
        case .lis3dh:
            return [tlmModel, uidModel, urlModel, iBeaconModel, deviceInfoModel, axisModel, noDataModel]
        case .sht3x:
            return [tlmModel, uidModel, urlModel, iBeaconModel, deviceInfoModel, thModel, noDataModel]
        case .lis3dhAndSht3x:
            return [tlmModel, uidModel, urlModel, iBeaconModel, deviceInfoModel, thModel, axisModel, noDataModel]
        case .light:
            return [tlmModel, uidModel, urlModel, iBeaconModel, deviceInfoModel, noDataModel]
        case .threeAxisAndLight:
            return [tlmModel, uidModel, urlModel, iBeaconModel, deviceInfoModel, axisModel, noDataModel]
        default:
            return [tlmModel, uidModel, urlModel, iBeaconModel, deviceInfoModel, noDataModel]
        }
    }
}

// MARK: - UITableViewDelegate / DataSource

extension MKBXPSlotConfigController: UITableViewDelegate, UITableViewDataSource {

    public func numberOfSections(in tableView: UITableView) -> Int {
        slotType == .null ? 0 : 3
    }

    public func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if slotType == .null { return 0 }
        switch section {
        case 0:
            // ✅ 只有 beacon / uid / url / info 才有 Section 0 内容
            return hasSection0 ? section0List.count : 0
        case 1: return section1List.count
        case 2: return section2List.count
        default: return 0
        }
    }

    public func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        getCellHeightWithIndexPath(indexPath)
    }

    public func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        loadCellWithIndexPath(indexPath)
    }

    /// Header 高度：
    /// - `slotType == .null`：整个列表不显示（numberOfSections == 0）
    /// - Section 0：永远无 header（顶部不需要灰色间隔）
    /// - Section 1：如果无 Section 0 内容，说明它是第一个 section，也无 header
    /// - Section 1 / Section 2：默认 10
    public func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        if slotType == .null { return 0 }
//        if section == 0 { return 0 }
        if section == 1 && !hasSection0 { return 0 }
        return 10
    }

    public func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        if slotType == .null { return nil }
//        if section == 0 { return nil }
        if section == 1 && !hasSection0 { return nil }
        let header = MKSwiftTableSectionLineHeader.dequeueHeader(with: tableView)
        return header
    }
}

// MARK: - MKSwiftBXSlotFrameTypePickViewDelegate

extension MKBXPSlotConfigController: MKSwiftBXSlotFrameTypePickViewDelegate {
    public func slotFrameTypeChanged(_ frameType: MKSwiftBXSlotFrameType) {
        slotType = frameType
        loadSectionDatas()
    }
}

// MARK: - MKSwiftBXSlotConfigTriggerCellDelegate

extension MKBXPSlotConfigController: MKSwiftBXSlotConfigTriggerCellDelegate {
    public func triggerSwitchStatusChanged(_ isOn: Bool) {
        cellDic.removeValue(forKey: Self.mk_advTriggerKey)
        dataModel.triggerIsOn = isOn
        if !section2List.isEmpty {
            section2List[0].isOn = isOn
        }
        tableView.reloadSections(IndexSet(integer: 2), with: .none)
    }
}
