//
//  MKBXPSlotController.swift
//  MKBeaconXPlusSwiftProject
//
//  Created by aa on 2026/9/18.
//

import UIKit
import SnapKit
import MKBaseSwiftModule
import MKSwiftCustomUI
import MKSwiftBeaconXCustomUI

public final class MKBXPSlotController: MKSwiftBaseViewController {

    // MARK: - Subviews

    private lazy var tableView: MKSwiftBaseTableView = {
        let tv = MKSwiftBaseTableView(frame: .zero, style: .plain)
        tv.delegate = self
        tv.dataSource = self
        tv.separatorStyle = .none
        return tv
    }()

    private lazy var dataList: [MKBXPSlotDataModel] = []

    // MARK: - Life Cycle

    deinit {
        NSLog("MKBXPSlotController销毁")
    }

    public override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        readSlotDataType()
    }

    public override func viewDidLoad() {
        super.viewDidLoad()
        loadSubViews()
    }

    // MARK: - Super

    public override func leftButtonMethod() {
        NotificationCenter.default.post(name: Notification.Name("mk_bxp_popToRootViewControllerNotification"),
                                        object: nil)
    }

    // MARK: - Interface

    private func readSlotDataType() {
        MKSwiftHudManager.shared.showHUD(with: "Reading...", in: view, isPenetration: false)
        MKBXPInterface.bxp_readSlotDataType { [weak self] returnData in
            guard let self = self else { return }
            MKSwiftHudManager.shared.hide()
            if let result = (returnData as? [String: Any])?["result"] as? [String: Any] {
                self.parseSlotDataType(result)
            }
        } failedBlock: { [weak self] error in
            MKSwiftHudManager.shared.hide()
            let msg = (error as NSError).userInfo["errorInfo"] as? String ?? ""
            self?.view.showCentralToast(msg)
        }
    }

    private func parseSlotDataType(_ returnData: [String: Any]) {
        guard let slotList = returnData["slotTypeList"] as? [String] else { return }
        dataList.removeAll()

        for (i, typeStr) in slotList.enumerated() {
            let slotModel = MKBXPSlotDataModel()
            slotModel.slotType = MKSwiftBXSlotDataAdopter.fetchSlotFrameType(typeStr)
            slotModel.slotIndex = i
            slotModel.leftMsg = "SLOT\(i + 1)"
            slotModel.rightMsg = fetchSlotCellRightMsg(slotModel.slotType)
            dataList.append(slotModel)
        }
        tableView.reloadData()
    }

    // MARK: - Private

    private func fetchSlotCellRightMsg(_ type: MKSwiftBXSlotFrameType) -> String {
        switch type {
        case .beacon: return "iBeacon"
        case .uid: return "UID"
        case .url: return "URL"
        case .tlm: return "TLM"
        case .null: return "No data"
        case .info: return "Device info"
        case .threeASensor: return "3-axis Acc"
        case .thSensor: return "T&H"
        }
    }

    // MARK: - UI

    private func loadSubViews() {
        defaultTitle = "SLOT"
        view.addSubview(tableView)
        tableView.snp.makeConstraints { make in
            make.left.right.equalToSuperview()
            make.top.equalTo(view).offset(MKLayout.topBarHeight)
            make.bottom.equalTo(view).offset(-(MKLayout.safeAreaBottom + 49))
        }
    }
}

// MARK: - UITableViewDelegate / DataSource

extension MKBXPSlotController: UITableViewDelegate, UITableViewDataSource {

    public func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        dataList.count
    }

    public func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        let slotModel = dataList[indexPath.row]
        let msgSize = slotModel.leftMsg.size(
            withFont: MKFont.font(15),
            maxSize: CGSize(width: MKScreen.width / 2 - 15 - 3,
                            height: .greatestFiniteMagnitude)
        )
        return max(msgSize.height + 2 * 15, 50)
    }

    public func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = MKBXPSlotCell.initCellWithTableView(tableView)
        cell.dataModel = dataList[indexPath.row]
        return cell
    }

    public func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let slotModel = dataList[indexPath.row]
        let vc = MKBXPSlotConfigController()
        vc.slotType = slotModel.slotType
        vc.slotIndex = slotModel.slotIndex
        navigationController?.pushViewController(vc, animated: true)
    }
}
