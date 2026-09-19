//
//  MKBXPAccelerationController.swift
//  MKBeaconXPlusSwiftProject
//
//  Created by aa on 2026/9/18.
//

import UIKit
import SnapKit
import MKBaseSwiftModule
import MKSwiftCustomUI

public final class MKBXPAccelerationController: MKSwiftBaseViewController {

    // MARK: - Subviews

    private lazy var headerView: MKBXPAccelerationHeaderView = {
        let header = MKBXPAccelerationHeaderView(frame: CGRect(x: 0, y: 0,
                                                                width: MKScreen.width,
                                                                height: 120))
        header.delegate = self
        return header
    }()

    private lazy var tableView: MKSwiftBaseTableView = {
        let tv = MKSwiftBaseTableView(frame: .zero, style: .plain)
        tv.delegate = self
        tv.dataSource = self
        tv.tableHeaderView = headerView
        tv.separatorStyle = .none
        return tv
    }()

    private lazy var dataList: [MKBXPAccelerationParamsCellModel] = []

    private let dataModel = MKBXPAccelerationModel()

    // MARK: - Life Cycle

    deinit {
        NSLog("MKBXPAccelerationController销毁")
        _ = MKBXPCentralManager.shared.notifyThreeAxisAcceleration(false)
        NotificationCenter.default.removeObserver(self)
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
        NotificationCenter.default.addObserver(self,
                                              selector: #selector(receiveAxisDatas(_:)),
                                              name: .mk_bxp_receiveThreeAxisAccelerometerDataNotification,
                                              object: nil)
    }

    // MARK: - Super

    public override func rightButtonMethod() {
        MKSwiftHudManager.shared.showHUD(with: "Config...", in: view, isPenetration: false)
        dataModel.config { [weak self] in
            MKSwiftHudManager.shared.hide()
            self?.view.showCentralToast("Success")
        } failedBlock: { [weak self] error in
            MKSwiftHudManager.shared.hide()
            self?.view.showCentralToast((error as NSError).userInfo["errorInfo"] as? String ?? "")
        }
    }

    // MARK: - Notification

    @objc private func receiveAxisDatas(_ note: Notification) {
        guard let dic = note.userInfo,
              let tempList = dic["axisData"] as? [[String: Any]],
              let axisData = tempList.last else {
            return
        }
        headerView.updateDataWithXData(axisData["x-Data"] as? String ?? "N/A",
                                        yData: axisData["y-Data"] as? String ?? "N/A",
                                        zData: axisData["z-Data"] as? String ?? "N/A")
    }

    // MARK: - Read

    private func readDataFromDevice() {
        MKSwiftHudManager.shared.showHUD(with: "Reading...", in: view, isPenetration: false)
        dataModel.read { [weak self] in
            MKSwiftHudManager.shared.hide()
            self?.loadSectionDatas()
        } failedBlock: { [weak self] error in
            MKSwiftHudManager.shared.hide()
            self?.view.showCentralToast((error as NSError).userInfo["errorInfo"] as? String ?? "")
        }
    }

    // MARK: - Load Data

    private func loadSectionDatas() {
        let cellModel = MKBXPAccelerationParamsCellModel()
        cellModel.scale = dataModel.scale
        cellModel.samplingRate = dataModel.samplingRate
        cellModel.sensitivityValue = dataModel.sensitivityValue
        dataList = [cellModel]
        tableView.reloadData()
    }

    // MARK: - UI

    private func loadSubViews() {
        defaultTitle = "3-axis accelerometer"
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

extension MKBXPAccelerationController: UITableViewDelegate, UITableViewDataSource {

    public func numberOfSections(in tableView: UITableView) -> Int { 1 }

    public func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        dataList.count
    }

    public func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        200
    }

    public func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = MKBXPAccelerationParamsCell.initCellWithTableView(tableView)
        cell.dataModel = dataList[indexPath.row]
        cell.delegate = self
        return cell
    }
}

// MARK: - MKBXPAccelerationHeaderViewDelegate

extension MKBXPAccelerationController: MKBXPAccelerationHeaderViewDelegate {
    public func bxp_updateThreeAxisNotifyStatus(_ notify: Bool) {
        _ = MKBXPCentralManager.shared.notifyThreeAxisAcceleration(notify)
    }
}

// MARK: - MKBXPAccelerationParamsCellDelegate

extension MKBXPAccelerationController: MKBXPAccelerationParamsCellDelegate {

    /// 用户改变了 scale
    public func bxp_accelerationParamsScaleChanged(_ scale: Int) {
        dataModel.scale = scale
        guard !dataList.isEmpty else { return }
        dataList[0].scale = scale
    }

    /// 用户改变了 samplingRate
    public func bxp_accelerationParamsSamplingRateChanged(_ samplingRate: Int) {
        dataModel.samplingRate = samplingRate
        guard !dataList.isEmpty else { return }
        dataList[0].samplingRate = samplingRate
    }

    /// 用户改变了 sensitivityValue
    public func bxp_accelerationParamsSensitivityValueChanged(_ sensitivityValue: Int) {
        dataModel.sensitivityValue = sensitivityValue
        guard !dataList.isEmpty else { return }
        dataList[0].sensitivityValue = sensitivityValue
    }
}
