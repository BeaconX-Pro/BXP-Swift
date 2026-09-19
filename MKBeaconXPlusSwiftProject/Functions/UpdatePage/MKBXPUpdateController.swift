//
//  MKBXPUpdateController.swift
//  MKBeaconXPlusSwiftProject
//
//  Created by aa on 2026/9/18.
//

import UIKit
import UniformTypeIdentifiers
import SnapKit
import MKBaseSwiftModule
import MKSwiftCustomUI

public final class MKBXPUpdateController: MKSwiftBaseViewController {

    // MARK: - Subviews

    private lazy var tableView: MKSwiftBaseTableView = {
        let tv = MKSwiftBaseTableView(frame: .zero, style: .plain)
        tv.backgroundColor = .white
        tv.delegate = self
        tv.dataSource = self
        tv.separatorStyle = .none
        tv.tableHeaderView = makeTableHeader()
        return tv
    }()

    // MARK: - Data

    private lazy var dataList: [MKSwiftNormalTextCellModel] = []

    private lazy var dfuModule: MKBXPDFUModule = MKBXPDFUModule()
    private lazy var dfu04DModule: MKBXPD04DFUModule = MKBXPD04DFUModule()

    private var monitorQueue: DispatchQueue?
    private var monitorSource: DispatchSourceFileSystemObject?

    // MARK: - Life Cycle

    deinit {
        NSLog("MKBXPUpdateController销毁")
        monitorSource?.cancel()
        monitorSource = nil
    }

    public override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        navigationController?.interactivePopGestureRecognizer?.isEnabled = true
    }

    public override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        // 本页面禁止右划退出手势
        navigationController?.interactivePopGestureRecognizer?.isEnabled = false
    }

    public override func viewDidLoad() {
        super.viewDidLoad()
        loadSubViews()
        loadFileList()
        startMonitoringDFUFiles()
    }

    // MARK: - Event

    @objc private func selectBtnPressed() {
        let dataType = UTType.data
        let documentPicker = UIDocumentPickerViewController(forOpeningContentTypes: [dataType])
        documentPicker.delegate = self
        documentPicker.allowsMultipleSelection = false
        present(documentPicker, animated: true, completion: nil)
    }

    // MARK: - DFU

    private func startDFUWithFilePath(_ filePath: String) {
        guard !filePath.isEmpty else {
            view.showCentralToast("Firmware cannot be empty!")
            return
        }
        // 抛出该通知，设备信息页面再次返回不需要读取任何数据了，防止出现读取错误
        NotificationCenter.default.post(name: Notification.Name("mk_bxp_startDfuProcessNotification"),
                                        object: nil)
        startDFU(filePath)
    }

    private func startDFU(_ filePath: String) {
        leftButton.isEnabled = false
        // BLE 升级
        MKSwiftHudManager.shared.showHUD(with: "Waiting...", in: view, isPenetration: false)
        dfuModule.updateWithFileUrl(filePath) { _ in

        } sucBlock: { [weak self] in
            guard let self = self else { return }
            MKSwiftHudManager.shared.showHUD(with: "Update firmware successfully!",
                                              in: self.view,
                                              isPenetration: false)
            self.perform(#selector(self.updateComplete), with: nil, afterDelay: 1.0)
        } failedBlock: { [weak self] _ in
            guard let self = self else { return }
            MKSwiftHudManager.shared.showHUD(with: "Opps!DFU Failed. Please try again!",
                                              in: self.view,
                                              isPenetration: false)
            self.perform(#selector(self.updateComplete), with: nil, afterDelay: 1.0)
        }
    }

    private func startBXPD04DFU(_ filePath: String) {
        leftButton.isEnabled = false
        // BLE 升级
        MKSwiftHudManager.shared.showHUD(with: "Waiting...", in: view, isPenetration: false)
        dfu04DModule.updateWithFileUrl(filePath) { _ in

        } sucBlock: { [weak self] in
            guard let self = self else { return }
            MKSwiftHudManager.shared.showHUD(with: "Update firmware successfully!",
                                              in: self.view,
                                              isPenetration: false)
            self.perform(#selector(self.updateComplete), with: nil, afterDelay: 1.0)
        } failedBlock: { [weak self] _ in
            guard let self = self else { return }
            MKSwiftHudManager.shared.showHUD(with: "Opps!DFU Failed. Please try again!",
                                              in: self.view,
                                              isPenetration: false)
            self.perform(#selector(self.updateComplete), with: nil, afterDelay: 1.0)
        }
    }

    @objc private func updateComplete() {
        leftButton.isEnabled = true
        MKSwiftHudManager.shared.hide()
        MKBXPCentralManager.sharedDealloc()
        NotificationCenter.default.post(name: Notification.Name("mk_bxp_centralDeallocNotification"),
                                        object: nil)
        navigationController?.popToRootViewController(animated: true)
    }

    // MARK: - 监听文件

    private func startMonitoringDFUFiles() {
        let directoryPath = NSSearchPathForDirectoriesInDomains(.documentDirectory,
                                                                 .userDomainMask,
                                                                 true).last ?? ""
        let filedes = open((directoryPath as NSString).fileSystemRepresentation, O_EVTONLY)
        guard filedes >= 0 else { return }

        // 创建 dispatch queue，当文件改变事件发生时会发送到该 queue
        let queue = DispatchQueue(label: "ZFileMonitorQueue")
        self.monitorQueue = queue

        // 创建 GCD source，用于监听 file descriptor 来判断是否有文件写入操作
        let source = DispatchSource.makeFileSystemObjectSource(fileDescriptor: filedes,
                                                                eventMask: .write,
                                                                queue: queue)
        // 当文件发生改变时会调用该 block
        source.setEventHandler { [weak self] in
            DispatchQueue.main.async {
                // 监听到有文件了
                self?.loadFileList()
            }
        }
        // 当文件监听停止时会调用该 block
        source.setCancelHandler {
            // 关闭文件监听时，关闭该 file descriptor
            close(filedes)
        }
        source.resume()
        self.monitorSource = source
    }

    private func currentFileList() -> [String] {
        let document = NSSearchPathForDirectoriesInDomains(.documentDirectory,
                                                            .userDomainMask,
                                                            true).last ?? ""
        let fileManager = FileManager.default
        return (try? fileManager.contentsOfDirectory(atPath: document)) ?? []
    }

    private func loadFileList() {
        let list = currentFileList()
        guard !list.isEmpty else { return }
        dataList.removeAll()
        for fileName in list {
            let model = MKSwiftNormalTextCellModel()
            model.leftMsg = fileName
            dataList.append(model)
        }
        tableView.reloadData()
    }

    // MARK: - UI

    private func loadSubViews() {
        defaultTitle = "OTA"
        rightButton.isHidden = true
        view.addSubview(tableView)
        tableView.snp.makeConstraints { make in
            make.left.right.equalToSuperview()
            make.top.equalTo(view).offset(MKLayout.topBarHeight)
            make.bottom.equalTo(view).offset(-MKLayout.safeAreaBottom)
        }
    }

    private func makeTableHeader() -> UIView {
        let headerView = UIView(frame: CGRect(x: 0, y: 0,
                                               width: MKScreen.width,
                                               height: 60))
        headerView.backgroundColor = .white

        let selectBtn = MKSwiftUIAdaptor.createRoundedButton(title: "Select Firmware",
                                                        target: self,
                                                        action: #selector(selectBtnPressed))
        selectBtn.frame = CGRect(x: (MKScreen.width - 200) / 2, y: 10,
                                 width: 200, height: 40)
        headerView.addSubview(selectBtn)
        return headerView
    }
}

// MARK: - UITableViewDelegate / DataSource

extension MKBXPUpdateController: UITableViewDelegate, UITableViewDataSource {

    public func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        dataList.count
    }

    public func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        44
    }

    public func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = MKSwiftNormalTextCell.initCellWithTableView(tableView)
        cell.dataModel = dataList[indexPath.row]
        return cell
    }

    public func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let firmwareModel = dataList[indexPath.row]
        let fileName = firmwareModel.leftMsg
        guard !fileName.isEmpty else {
            view.showCentralToast("Firmware cannot be empty!")
            return
        }
        let document = NSSearchPathForDirectoriesInDomains(.documentDirectory,
                                                            .userDomainMask,
                                                            true).last ?? ""
        let filePath = (document as NSString).appendingPathComponent(fileName)
        startDFUWithFilePath(filePath)
    }
}

// MARK: - UIDocumentPickerDelegate

extension MKBXPUpdateController: UIDocumentPickerDelegate {

    public func documentPicker(_ controller: UIDocumentPickerViewController,
                               didPickDocumentsAt urls: [URL]) {
        guard let sourceURL = urls.first else { return }

        let documentDir = NSSearchPathForDirectoriesInDomains(.documentDirectory,
                                                               .userDomainMask,
                                                               true).last ?? ""
        let fileName = sourceURL.lastPathComponent
        let destPath = (documentDir as NSString).appendingPathComponent(fileName)

        let fileManager = FileManager.default
        if fileManager.fileExists(atPath: destPath) {
            try? fileManager.removeItem(atPath: destPath)
        }

        var success = false
        if sourceURL.startAccessingSecurityScopedResource() {
            do {
                try fileManager.copyItem(at: sourceURL, to: URL(fileURLWithPath: destPath))
                success = true
            } catch {
                success = false
            }
            sourceURL.stopAccessingSecurityScopedResource()
        }

        if success {
            startDFUWithFilePath(destPath)
        } else {
            view.showCentralToast("Failed to import firmware file!")
        }
    }

    public func documentPickerWasCancelled(_ controller: UIDocumentPickerViewController) {
        // 用户取消选择，无需处理
    }
}
