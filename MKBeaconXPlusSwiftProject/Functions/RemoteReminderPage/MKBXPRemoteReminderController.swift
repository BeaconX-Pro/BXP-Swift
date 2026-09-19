//
//  MKBXPRemoteReminderController.swift
//  MKBeaconXPlusSwiftProject
//
//  Created by aa on 2026/9/18.
//

import UIKit
import SnapKit
import MKBaseSwiftModule
import MKSwiftCustomUI

public final class MKBXPRemoteReminderController: MKSwiftBaseViewController {

    // MARK: - Subviews

    private lazy var tableView: MKSwiftBaseTableView = {
        let tv = MKSwiftBaseTableView(frame: .zero, style: .plain)
        tv.delegate = self
        tv.dataSource = self
        tv.separatorStyle = .none
        return tv
    }()

    // MARK: - Data

    private lazy var section0List: [MKBXPRemoteReminderCellModel] = []
    private lazy var section1List: [MKSwiftTextButtonCellModel] = []
    private lazy var section2List: [MKSwiftTextFieldCellModel] = []
    private lazy var section3List: [MKBXPRemoteReminderCellModel] = []
    private lazy var section4List: [MKSwiftTextFieldCellModel] = []
    private lazy var headerList: [MKSwiftTableSectionLineHeaderModel] = []

    private let dataModel = MKBXPRemoteReminderModel()

    // MARK: - Life Cycle

    deinit {
        NSLog("MKBXPRemoteReminderController销毁")
    }

    public override func viewDidLoad() {
        super.viewDidLoad()
        loadSubViews()
        readDataFromDevice()
    }

    // MARK: - Interface

    private func readDataFromDevice() {
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

    private func reminderLED() {
        guard !dataModel.blinkingTime.isEmpty,
              let blinkTime = Int(dataModel.blinkingTime),
              blinkTime >= 1, blinkTime <= 600 else {
            view.showCentralToast("Blink Time Error")
            return
        }
        guard !dataModel.blinkingInterval.isEmpty,
              let blinkInterval = Int(dataModel.blinkingInterval),
              blinkInterval >= 1, blinkInterval <= 100 else {
            view.showCentralToast("Blink Interval Error")
            return
        }

        MKSwiftHudManager.shared.showHUD(with: "Config...", in: view, isPenetration: false)
        let color = MKBXPRemoteReminderLEDColor(rawValue: dataModel.color) ?? .red
        MKBXPInterface.bxp_configRemoteReminderLEDNotiParams(blinkingTime: blinkTime * 10,
                                                              blinkingInterval: blinkInterval,
                                                              color: color) { [weak self] _ in
            MKSwiftHudManager.shared.hide()
            self?.view.showCentralToast("Success")
        } failedBlock: { [weak self] error in
            MKSwiftHudManager.shared.hide()
            let msg = (error as NSError).userInfo["errorInfo"] as? String ?? ""
            self?.view.showCentralToast(msg)
        }
    }

    private func reminderBuzzer() {
        guard !dataModel.ringingTime.isEmpty,
              let ringingTime = Int(dataModel.ringingTime),
              ringingTime >= 1, ringingTime <= 600 else {
            view.showCentralToast("Ringing Time Error")
            return
        }
        guard !dataModel.ringingInterval.isEmpty,
              let ringingInterval = Int(dataModel.ringingInterval),
              ringingInterval >= 1, ringingInterval <= 100 else {
            view.showCentralToast("Ringing Interval Error")
            return
        }

        MKSwiftHudManager.shared.showHUD(with: "Config...", in: view, isPenetration: false)
        MKBXPInterface.bxp_configRemoteReminderBuzzerNotiParams(ringingTime: ringingTime * 10,
                                                                 ringingInterval: ringingInterval,
                                                                 frequent: Int(dataModel.frequent) ?? 0) { [weak self] _ in
            MKSwiftHudManager.shared.hide()
            self?.view.showCentralToast("Success")
        } failedBlock: { [weak self] error in
            MKSwiftHudManager.shared.hide()
            let msg = (error as NSError).userInfo["errorInfo"] as? String ?? ""
            self?.view.showCentralToast(msg)
        }
    }

    // MARK: - Load Section Datas

    private func loadSectionDatas() {
        loadSection0Datas()
        loadSection1Datas()
        loadSection2Datas()
        loadSection3Datas()
        loadSection4Datas()

        headerList = (0..<5).map { _ in MKSwiftTableSectionLineHeaderModel() }

        tableView.reloadData()
    }

    private func loadSection0Datas() {
        let cellModel = MKBXPRemoteReminderCellModel()
        cellModel.msg = "LED notification"
        cellModel.index = 0
        section0List = [cellModel]
    }

    private func loadSection1Datas() {
        let cellModel = MKSwiftTextButtonCellModel()
        cellModel.index = 0
        cellModel.msg = "LED color"
        cellModel.dataList = ["Red", "Green", "Blue"]
        cellModel.dataListIndex = dataModel.color
        section1List = [cellModel]
    }

    private func loadSection2Datas() {
        let cellModel1 = MKSwiftTextFieldCellModel()
        cellModel1.index = 0
        cellModel1.msg = "Blinking time"
        cellModel1.textPlaceholder = "1~600"
        cellModel1.textFieldValue = dataModel.blinkingTime
        cellModel1.textFieldType = .realNumberOnly
        cellModel1.unit = "s"
        cellModel1.maxLength = 3

        let cellModel2 = MKSwiftTextFieldCellModel()
        cellModel2.index = 1
        cellModel2.msg = "Blinking interval"
        cellModel2.textPlaceholder = "1~100"
        cellModel2.textFieldValue = dataModel.blinkingInterval
        cellModel2.textFieldType = .realNumberOnly
        cellModel2.unit = "x100ms"
        cellModel2.maxLength = 3

        section2List = [cellModel1, cellModel2]
    }

    private func loadSection3Datas() {
        let cellModel = MKBXPRemoteReminderCellModel()
        cellModel.msg = "Buzzer notification"
        cellModel.index = 1
        section3List = [cellModel]
    }

    private func loadSection4Datas() {
        let cellModel1 = MKSwiftTextFieldCellModel()
        cellModel1.index = 2
        cellModel1.msg = "Ringing time"
        cellModel1.textPlaceholder = "1~600"
        cellModel1.textFieldValue = dataModel.ringingTime
        cellModel1.textFieldType = .realNumberOnly
        cellModel1.unit = "x100ms"
        cellModel1.maxLength = 4

        let cellModel2 = MKSwiftTextFieldCellModel()
        cellModel2.index = 3
        cellModel2.msg = "Ringing interval"
        cellModel2.textPlaceholder = "1~100"
        cellModel2.textFieldValue = dataModel.ringingInterval
        cellModel2.textFieldType = .realNumberOnly
        cellModel2.unit = "x100ms"
        cellModel2.maxLength = 3

        section4List = [cellModel1, cellModel2]
    }

    // MARK: - UI

    private func loadSubViews() {
        defaultTitle = "Remote reminder"
        view.backgroundColor = UIColor(red: 242/255.0, green: 242/255.0, blue: 242/255.0, alpha: 1)

        view.addSubview(tableView)
        tableView.snp.makeConstraints { make in
            make.left.right.equalToSuperview()
            make.top.equalTo(view).offset(MKLayout.topBarHeight)
            make.bottom.equalTo(view).offset(-MKLayout.safeAreaBottom)
        }
    }
}

// MARK: - UITableViewDelegate / DataSource

extension MKBXPRemoteReminderController: UITableViewDelegate, UITableViewDataSource {

    public func numberOfSections(in tableView: UITableView) -> Int {
        headerList.count
    }

    public func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch section {
        case 0: return section0List.count
        case 1: return section1List.count
        case 2: return section2List.count
        case 3: return section3List.count
        case 4: return section4List.count
        default: return 0
        }
    }

    public func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        44
    }

    public func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        (section == 0 || section == 3) ? 10 : 0
    }

    public func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        guard section < headerList.count else { return nil }
        let headerView = MKSwiftTableSectionLineHeader.dequeueHeader(with: tableView)
        headerView.headerModel = headerList[section]
        return headerView
    }

    public func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        switch indexPath.section {
        case 0:
            let cell = MKBXPRemoteReminderCell.initCellWithTableView(tableView)
            cell.dataModel = section0List[indexPath.row]
            cell.delegate = self
            return cell
        case 1:
            let cell = MKSwiftTextButtonCell.initCellWithTableView(tableView)
            cell.dataModel = section1List[indexPath.row]
            cell.delegate = self
            return cell
        case 2:
            let cell = MKSwiftTextFieldCell.initCellWithTableView(tableView)
            cell.dataModel = section2List[indexPath.row]
            cell.delegate = self
            return cell
        case 3:
            let cell = MKBXPRemoteReminderCell.initCellWithTableView(tableView)
            cell.dataModel = section3List[indexPath.row]
            cell.delegate = self
            return cell
        default:
            let cell = MKSwiftTextFieldCell.initCellWithTableView(tableView)
            cell.dataModel = section4List[indexPath.row]
            cell.delegate = self
            return cell
        }
    }
}

// MARK: - MKSwiftTextButtonCellDelegate

extension MKBXPRemoteReminderController: MKSwiftTextButtonCellDelegate {
    public func MKSwiftTextButtonCellSelected(index: Int, dataListIndex: Int, value: String) {
        if index == 0 {
            // LED Color
            dataModel.color = dataListIndex
            if !section1List.isEmpty {
                section1List[0].dataListIndex = dataListIndex
            }
        }
    }
}

// MARK: - MKSwiftTextFieldCellDelegate

extension MKBXPRemoteReminderController: MKSwiftTextFieldCellDelegate {
    public func mkDeviceTextCellValueChanged(_ index: Int, textValue: String) {
        switch index {
        case 0:
            // Blinking time
            dataModel.blinkingTime = textValue
            if !section2List.isEmpty {
                section2List[0].textFieldValue = textValue
            }
        case 1:
            // Blinking interval
            dataModel.blinkingInterval = textValue
            if section2List.count > 1 {
                section2List[1].textFieldValue = textValue
            }
        case 2:
            // Ringing time
            dataModel.ringingTime = textValue
            if !section4List.isEmpty {
                section4List[0].textFieldValue = textValue
            }
        case 3:
            // Ringing interval
            dataModel.ringingInterval = textValue
            if section4List.count > 1 {
                section4List[1].textFieldValue = textValue
            }
        default:
            break
        }
    }
}

// MARK: - MKBXPRemoteReminderCellDelegate

extension MKBXPRemoteReminderController: MKBXPRemoteReminderCellDelegate {
    public func bxd_remindButtonPressed(_ index: Int) {
        if index == 0 {
            reminderLED()
            return
        }
        if index == 1 {
            reminderBuzzer()
            return
        }
    }
}
