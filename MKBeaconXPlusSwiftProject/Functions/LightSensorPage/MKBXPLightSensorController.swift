//
//  MKBXPLightSensorController.swift
//  MKBeaconXPlusSwiftProject
//
//  Created by aa on 2026/9/18.
//

import UIKit
import MessageUI
import SnapKit
import MKBaseSwiftModule
import MKSwiftCustomUI
import MKSwiftBleModule

public final class MKBXPLightSensorController: MKSwiftBaseViewController {

    // MARK: - Subviews

    private lazy var headerView: MKBXPLightSensorHeaderView = {
        let view = MKBXPLightSensorHeaderView()
        view.delegate = self
        return view
    }()

    private lazy var bottomView: UIView = {
        let view = UIView()
        view.backgroundColor = .white
        view.layer.masksToBounds = true
        view.layer.cornerRadius = 6
        return view
    }()

    private lazy var syncButton: UIButton = {
        let btn = UIButton(type: .custom)
        btn.addTarget(self, action: #selector(syncButtonPressed), for: .touchUpInside)
        return btn
    }()

    private lazy var syncIcon: UIImageView = {
        let iv = UIImageView()
        iv.image = UIImage(named: "bxp_threeAxisAcceLoadingIcon.png")
        return iv
    }()

    private lazy var syncLabel: UILabel = {
        let label = UILabel()
        label.textColor = MKColor.defaultText
        label.textAlignment = .center
        label.font = MKFont.font(10)
        label.text = "Sync"
        return label
    }()

    private lazy var deleteButton: MKBXPLightSensorButtonView = {
        let btn = MKBXPLightSensorButtonView()
        let model = MKBXPLightSensorButtonViewModel()
        model.msg = "Erase all"
        model.icon = UIImage(named: "bxp_slotExportDeleteIcon.png")
        btn.dataModel = model
        btn.addTarget(self, action: #selector(deleteButtonPressed), for: .touchUpInside)
        return btn
    }()

    private lazy var exportButton: MKBXPLightSensorButtonView = {
        let btn = MKBXPLightSensorButtonView()
        let model = MKBXPLightSensorButtonViewModel()
        model.msg = "Export"
        model.icon = UIImage(named: "bxp_slotExportEnableIcon.png")
        btn.dataModel = model
        btn.addTarget(self, action: #selector(exportButtonPressed), for: .touchUpInside)
        return btn
    }()

    private lazy var textView: UITextView = {
        let tv = UITextView()
        tv.backgroundColor = .white
        tv.font = MKFont.font(12)
        tv.layoutManager.allowsNonContiguousLayout = false
        tv.isEditable = false
        tv.textColor = MKColor.defaultText
        return tv
    }()

    private let dataModel = MKBXPLightSensorDataModel()

    // MARK: - Life Cycle

    deinit {
        NSLog("MKBXPLightSensorController销毁")
        _ = MKBXPCentralManager.shared.notifyLightSensorData(false)
        _ = MKBXPCentralManager.shared.notifyLightStatusData(false)
        NotificationCenter.default.removeObserver(self)
    }

    public override func viewDidLoad() {
        super.viewDidLoad()
        loadSubViews()
        addNotifications()
        readDatasFromDevice()
    }

    // MARK: - Notification

    private func addNotifications() {
        NotificationCenter.default.addObserver(self,
                                              selector: #selector(receiveLightSensorDatas(_:)),
                                              name: .mk_bxp_receiveLightSensorDataNotification,
                                              object: nil)
        NotificationCenter.default.addObserver(self,
                                              selector: #selector(receiveLightSensorStatus(_:)),
                                              name: .mk_bxp_receiveLightSensorStatusDataNotification,
                                              object: nil)
    }

    @objc private func receiveLightSensorDatas(_ note: Notification) {
        guard let dic = note.userInfo as? [String: Any] else { return }
        var state = "Ambient light NOT detected"
        if (dic["state"] as? String) == "01" {
            state = "Ambient light detected"
        }
        let date = dic["date"] as? String ?? ""
        let dateList = date.components(separatedBy: "-")
        let dateString: String
        if dateList.count >= 6 {
            dateString = "\(dateList[2])/\(dateList[1])/\(dateList[0]) \(dateList[3]):\(dateList[4]):\(dateList[5])"
        } else {
            dateString = date
        }
        let text = "\n\(dateString)\t\t\(state)"
        _ = saveDataToLocal(text)
        textView.text = (textView.text ?? "") + text
        textView.scrollRangeToVisible(NSRange(location: (textView.text as NSString).length, length: 1))
    }

    @objc private func receiveLightSensorStatus(_ note: Notification) {
        let status = note.userInfo?["status"] as? String ?? ""
        headerView.updateSensorStatus(status == "01")
    }

    // MARK: - Event

    @objc private func syncButtonPressed() {
        syncButton.isSelected.toggle()
        syncIcon.layer.removeAnimation(forKey: "synIconAnimationKey")

        if syncButton.isSelected {
            _ = MKBXPCentralManager.shared.notifyLightSensorData(true)
            let animation = MKBXPSwiftAdopter.refreshAnimation(2.0)
            syncIcon.layer.add(animation, forKey: "synIconAnimationKey")
            syncLabel.text = "Stop"
            return
        }
        _ = MKBXPCentralManager.shared.notifyLightSensorData(false)
        syncLabel.text = "Sync"
    }

    @objc private func deleteButtonPressed() {
        let alert = MKSwiftAlertView()
        alert.addAction(MKSwiftAlertViewAction(title: "Cancel", handler: {}))
        alert.addAction(MKSwiftAlertViewAction(title: "OK", handler: { [weak self] in
            self?.deleteRecordDatas()
        }))
        alert.showAlert(title: "Warning!",
                        message: "Are you sure to erase all the saved light sensor status data？",
                        notificationName: "mk_bxp_needDismissAlert")
    }

    @objc private func exportButtonPressed() {
        if !MFMailComposeViewController.canSendMail() {
            guard let url = URL(string: "MESSAGE://") else { return }
            UIApplication.shared.open(url, options: [:], completionHandler: nil)
            return
        }
        guard let emailData = MKSwiftBleLogManager.readData(fileName: "LightSensorDatas"),
              !emailData.isEmpty else {
            view.showCentralToast("Log file does not exist")
            return
        }
        let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? ""
        let bodyMsg = "APP Version: \(version) + + OS: \(UIDevice.current.systemVersion)"

        let mailComposer = MFMailComposeViewController()
        mailComposer.mailComposeDelegate = self
        mailComposer.setToRecipients(["Development@mokotechnology.com"])
        mailComposer.setSubject("Feedback of mail")
        mailComposer.addAttachmentData(emailData, mimeType: "application/txt", fileName: "LightSensorDatas.txt")
        mailComposer.setMessageBody(bodyMsg, isHTML: false)
        present(mailComposer, animated: true, completion: nil)
    }

    // MARK: - Interface

    private func readDatasFromDevice() {
        MKSwiftHudManager.shared.showHUD(with: "Reading...", in: view, isPenetration: false)
        dataModel.read { [weak self] in
            guard let self = self else { return }
            MKSwiftHudManager.shared.hide()
            _ = MKBXPCentralManager.shared.notifyLightStatusData(true)
            self.headerView.updateSensorStatus(self.dataModel.detected)
            self.headerView.updateCurrentTime(self.dataModel.date)
            if let localData = MKSwiftBleLogManager.readData(fileName: "LightSensorDatas") {
                self.textView.text = String(data: localData, encoding: .utf8)
            }
            self.textView.scrollRangeToVisible(NSRange(location: (self.textView.text as NSString).length, length: 1))
        } failedBlock: { [weak self] error in
            MKSwiftHudManager.shared.hide()
            let msg = (error as NSError).userInfo["errorInfo"] as? String ?? ""
            self?.view.showCentralToast(msg)
        }
    }

    private func deleteRecordDatas() {
        _ = MKSwiftBleLogManager.deleteLog(fileName: "LightSensorDatas")
        textView.text = ""
        syncButton.isSelected = false
        syncIcon.layer.removeAnimation(forKey: "synIconAnimationKey")
        _ = MKBXPCentralManager.shared.notifyLightSensorData(syncButton.isSelected)
        syncLabel.text = "Sync"

        MKSwiftHudManager.shared.showHUD(with: "Setting...", in: view, isPenetration: false)
        MKBXPInterface.bxp_clearLightSensorDatas { [weak self] _ in
            MKSwiftHudManager.shared.hide()
            self?.view.showCentralToast("Empty successfully!")
        } failedBlock: { [weak self] error in
            MKSwiftHudManager.shared.hide()
            let msg = (error as NSError).userInfo["errorInfo"] as? String ?? ""
            self?.view.showCentralToast(msg)
        }
    }

    // MARK: - Private

    private func saveDataToLocal(_ text: String) -> Bool {
        let path = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true).last ?? ""
        let localFileName = "/LightSensorDatas.txt"
        let filePath = path + localFileName

        let fileManager = FileManager.default
        var isDirectory: ObjCBool = false
        let existed = fileManager.fileExists(atPath: filePath, isDirectory: &isDirectory)

        if !existed {
            let newFilePath = (path as NSString).appendingPathComponent(localFileName)
            let createResult = fileManager.createFile(atPath: newFilePath, contents: nil, attributes: nil)
            if !createResult {
                return false
            }
        }

        guard let fileHandle = FileHandle(forUpdatingAtPath: filePath) else {
            return false
        }
        fileHandle.seekToEndOfFile()
        if let stringData = text.data(using: .utf8) {
            fileHandle.write(stringData)
        }
        fileHandle.closeFile()
        return true
    }

    // MARK: - UI

    private func loadSubViews() {
        defaultTitle = "Light sensor"
        view.backgroundColor = UIColor(red: 242/255.0, green: 242/255.0, blue: 242/255.0, alpha: 1)

        view.addSubview(headerView)
        headerView.snp.makeConstraints { make in
            make.left.right.equalToSuperview()
            make.top.equalTo(view).offset(MKLayout.topBarHeight)
            make.height.equalTo(200)
        }

        view.addSubview(bottomView)
        bottomView.snp.makeConstraints { make in
            make.left.equalTo(10)
            make.right.equalTo(-10)
            make.top.equalTo(headerView.snp.bottom).offset(5)
            make.bottom.equalTo(view).offset(-(MKLayout.safeAreaBottom + 10))
        }

        bottomView.addSubview(syncButton)
        bottomView.addSubview(syncLabel)
        syncButton.addSubview(syncIcon)

        syncButton.snp.makeConstraints { make in
            make.left.equalTo(5)
            make.width.equalTo(30)
            make.top.equalTo(15)
            make.height.equalTo(30)
        }
        syncIcon.snp.makeConstraints { make in
            make.centerX.equalTo(syncButton)
            make.centerY.equalTo(syncButton)
            make.width.height.equalTo(25)
        }
        syncLabel.snp.makeConstraints { make in
            make.left.equalTo(5)
            make.width.equalTo(30)
            make.top.equalTo(syncButton.snp.bottom).offset(2)
            make.height.equalTo(MKFont.font(10).lineHeight)
        }

        bottomView.addSubview(exportButton)
        exportButton.snp.makeConstraints { make in
            make.right.equalTo(-5)
            make.width.equalTo(50)
            make.top.equalTo(10)
            make.height.equalTo(50)
        }
        bottomView.addSubview(deleteButton)
        deleteButton.snp.makeConstraints { make in
            make.right.equalTo(exportButton.snp.left).offset(-10)
            make.width.equalTo(50)
            make.centerY.equalTo(exportButton)
            make.height.equalTo(50)
        }

        let timeLabel = makeTextLabel("Time")
        let statusLabel = makeTextLabel("Sensor status")
        bottomView.addSubview(timeLabel)
        bottomView.addSubview(statusLabel)

        timeLabel.snp.makeConstraints { make in
            make.left.equalTo(5)
            make.right.equalTo(bottomView.snp.centerX).offset(-15)
            make.top.equalTo(syncLabel.snp.bottom).offset(20)
            make.height.equalTo(MKFont.font(13).lineHeight)
        }
        statusLabel.snp.makeConstraints { make in
            make.left.equalTo(bottomView.snp.centerX).offset(-5)
            make.right.equalTo(-5)
            make.top.equalTo(syncLabel.snp.bottom).offset(20)
            make.height.equalTo(MKFont.font(13).lineHeight)
        }

        bottomView.addSubview(textView)
        textView.snp.makeConstraints { make in
            make.left.equalTo(5)
            make.right.equalTo(-5)
            make.top.equalTo(timeLabel.snp.bottom).offset(10)
            make.bottom.equalTo(view).offset(-(MKLayout.safeAreaBottom + 10))
        }
    }

    private func makeTextLabel(_ text: String) -> UILabel {
        let label = UILabel()
        label.textColor = MKColor.defaultText
        label.font = MKFont.font(13)
        label.textAlignment = .center
        label.text = text
        return label
    }
}

// MARK: - MFMailComposeViewControllerDelegate

extension MKBXPLightSensorController: MFMailComposeViewControllerDelegate {
    public func mailComposeController(_ controller: MFMailComposeViewController,
                                      didFinishWith result: MFMailComposeResult,
                                      error: Error?) {
        switch result {
        case .cancelled: break
        case .saved: break
        case .sent:
            view.showCentralToast("send success")
        case .failed: break
        @unknown default: break
        }
        dismiss(animated: true, completion: nil)
    }
}

// MARK: - MKBXPLightSensorHeaderViewDelegate

extension MKBXPLightSensorController: MKBXPLightSensorHeaderViewDelegate {
    public func bxp_lightSensorSyncTime() {
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
            let display = "\(dateList[2])/\(dateList[1])/\(dateList[0]) \(dateList[3]):\(dateList[4]):\(dateList[5])"
            self.headerView.updateCurrentTime(display)
        } failedBlock: { [weak self] error in
            MKSwiftHudManager.shared.hide()
            let msg = (error as NSError).userInfo["errorInfo"] as? String ?? ""
            self?.view.showCentralToast(msg)
        }
    }
}
