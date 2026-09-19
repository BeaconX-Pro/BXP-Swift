//
//  MKBXPExportDataController.swift
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

public final class MKBXPExportDataController: MKSwiftBaseViewController {

    // MARK: - Subviews

    private lazy var backView: UIView = {
        let view = UIView()
        view.backgroundColor = .white
        view.layer.masksToBounds = true
        view.layer.cornerRadius = 8
        return view
    }()

    private lazy var topView: UIView = {
        let view = UIView()
        view.backgroundColor = .white
        return view
    }()

    private lazy var syncButton: UIButton = {
        let btn = UIButton(type: .custom)
        btn.addTarget(self, action: #selector(syncButtonPressed), for: .touchUpInside)
        return btn
    }()

    private lazy var synIcon: UIImageView = {
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

    private lazy var switchButton: UIButton = {
        let btn = UIButton(type: .custom)
        btn.setImage(UIImage(named: "bxp_exportHT_tableSelected.png"), for: .normal)
        btn.addTarget(self, action: #selector(switchButtonPressed), for: .touchUpInside)
        return btn
    }()

    private lazy var switchLabel: UILabel = {
        let label = UILabel()
        label.textColor = MKColor.defaultText
        label.textAlignment = .center
        label.font = MKFont.font(10)
        label.text = "Display"
        return label
    }()

    private lazy var deleteButton: UIButton = {
        let btn = UIButton(type: .custom)
        btn.setImage(UIImage(named: "bxp_slotExportDeleteIcon.png"), for: .normal)
        btn.addTarget(self, action: #selector(deleteButtonPressed), for: .touchUpInside)
        return btn
    }()

    private lazy var deleteLabel: UILabel = {
        let label = UILabel()
        label.textColor = MKColor.defaultText
        label.textAlignment = .center
        label.font = MKFont.font(10)
        label.text = "Erase all"
        return label
    }()

    private lazy var exportButton: UIButton = {
        let btn = UIButton(type: .custom)
        btn.setImage(UIImage(named: "bxp_slotExportEnableIcon.png"), for: .normal)
        btn.addTarget(self, action: #selector(exportButtonPressed), for: .touchUpInside)
        return btn
    }()

    private lazy var exportLabel: UILabel = {
        let label = UILabel()
        label.textColor = MKColor.defaultText
        label.textAlignment = .center
        label.font = MKFont.font(10)
        label.text = "Export"
        return label
    }()

    private lazy var textView: UITextView = {
        let tv = UITextView()
        tv.backgroundColor = .white
        tv.font = MKFont.font(13)
        tv.layoutManager.allowsNonContiguousLayout = false
        tv.isEditable = false
        tv.textColor = MKColor.defaultText
        return tv
    }()

    private lazy var textBackView: UIView = {
        let view = UIView()
        view.layer.masksToBounds = true
        view.layer.borderWidth = 0.5
        view.layer.cornerRadius = 2
        view.layer.borderColor = UIColor(red: 227/255.0, green: 227/255.0, blue: 227/255.0, alpha: 1).cgColor
        return view
    }()

    private lazy var curveView: MKBXPExportDataCurveView = {
        let view = MKBXPExportDataCurveView()
        return view
    }()

    // MARK: - Private

    private static let timeTextViewWidth: CGFloat = 130
    private static let htTextViewWidth: CGFloat = 80

    private var receiveTimer: DispatchSourceTimer?
    private var receiveCount: Int = 0

    private lazy var temperatureList: [String] = []
    private lazy var humidityList: [String] = []

    private var textBackViewHeight: CGFloat {
        MKScreen.height - MKLayout.topBarHeight - 70
    }

    private var textViewSpace: CGFloat {
        (MKScreen.width - 30 - Self.timeTextViewWidth - 2 * Self.htTextViewWidth) / 4
    }

    // MARK: - Life Cycle

    deinit {
        NSLog("MKBXPExportDataController销毁")
        NotificationCenter.default.removeObserver(self, name: .mk_bxp_receiveRecordHTDataNotification, object: nil)
        _ = MKBXPCentralManager.shared.notifyRecordTHData(false)
        receiveTimer?.cancel()
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
        readDatasFromLocal()
    }

    // MARK: - Super

    public override func leftButtonMethod() {
        let totalNum = min(temperatureList.count, humidityList.count)
        var list: [[String: Any]] = []
        for i in 0..<totalNum {
            list.append([
                "temperature": temperatureList[i],
                "humidity": humidityList[i]
            ])
        }

        // 先清除本地数据再保存
        MKBXPDatabaseManager.deleteDatas(sucBlock: nil, failedBlock: nil)
        MKSwiftHudManager.shared.showHUD(with: "Waiting...", in: view, isPenetration: false)

        MKBXPDatabaseManager.insertDeviceList(list, sucBlock: { [weak self] in
            guard let self = self else { return }
            MKSwiftHudManager.shared.hide()
            self.bxp_callSuperLeftButtonMethod()
        }, failedBlock: { [weak self] error in
            guard let self = self else { return }
            MKSwiftHudManager.shared.hide()
            let msg = (error as NSError).userInfo["errorInfo"] as? String ?? ""
            self.view.showCentralToast(msg)
            self.perform(#selector(self.backAction), with: nil, afterDelay: 0.5)
        })
    }

    /// 包装方法：在实例方法内调用 super，避免闭包中直接使用 super
    private func bxp_callSuperLeftButtonMethod() {
        super.leftButtonMethod()
    }

    // MARK: - Event

    @objc private func syncButtonPressed() {
        syncButton.isSelected.toggle()
        synIcon.layer.removeAnimation(forKey: "synIconAnimationKey")
        receiveCount = 0
        // 如果是开启监听，则不可切换列表和曲线
        switchButton.isEnabled = !syncButton.isSelected

        if syncButton.isSelected {
            _ = MKBXPCentralManager.shared.notifyRecordTHData(true)
            let animation = MKBXPSwiftAdopter.refreshAnimation(2.0)
            synIcon.layer.add(animation, forKey: "synIconAnimationKey")
            syncLabel.text = "Stop"
            startReceiveTimer()
            if switchButton.isSelected {
                switchButtonPressed()
            }
            return
        }
        _ = MKBXPCentralManager.shared.notifyRecordTHData(false)
        syncLabel.text = "Sync"
        receiveTimer?.cancel()
        receiveTimer = nil
    }

    @objc private func deleteButtonPressed() {
        let alert = MKSwiftAlertView()
        alert.addAction(MKSwiftAlertViewAction(title: "Cancel", handler: {}))
        alert.addAction(MKSwiftAlertViewAction(title: "OK", handler: { [weak self] in
            self?.deleteRecordDatas()
        }))
        alert.showAlert(title: "Warning!",
                        message: "Are you sure to erase all the saved T&H datas？",
                        notificationName: "mk_bxp_needDismissAlert")
    }

    @objc private func exportButtonPressed() {
        if !MFMailComposeViewController.canSendMail() {
            guard let url = URL(string: "MESSAGE://") else { return }
            UIApplication.shared.open(url, options: [:], completionHandler: nil)
            return
        }
        guard let emailData = MKSwiftBleLogManager.readData(fileName: "T&HDatas"),
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
        mailComposer.addAttachmentData(emailData, mimeType: "application/txt", fileName: "T&HDatas.txt")
        mailComposer.setMessageBody(bodyMsg, isHTML: false)
        present(mailComposer, animated: true, completion: nil)
    }

    @objc private func switchButtonPressed() {
        switchButton.isSelected.toggle()
        let iconName = switchButton.isSelected
            ? "bxp_exportHT_curveSelected.png"
            : "bxp_exportHT_tableSelected.png"
        switchButton.setImage(UIImage(named: iconName), for: .normal)

        if switchButton.isSelected {
            // 显示曲线图
            UIView.animate(withDuration: 0.3) {
                self.textBackView.frame = CGRect(x: -(MKScreen.width - 10),
                                                 y: 60,
                                                 width: MKScreen.width - 30,
                                                 height: self.textBackViewHeight)
                self.curveView.frame = CGRect(x: 10,
                                              y: 60,
                                              width: MKScreen.width - 30,
                                              height: self.textBackViewHeight)
            } completion: { _ in
                self.drawHTCurveView()
            }
            return
        }
        // 显示 textView
        UIView.animate(withDuration: 0.3) {
            self.textBackView.frame = CGRect(x: 10,
                                             y: 60,
                                             width: MKScreen.width - 30,
                                             height: self.textBackViewHeight)
            self.curveView.frame = CGRect(x: MKScreen.width - 10,
                                          y: 60,
                                          width: MKScreen.width - 30,
                                          height: self.textBackViewHeight)
        }
    }

    @objc private func backAction() {
        navigationController?.popViewController(animated: true)
    }

    // MARK: - Notification

    @objc private func receiveRecordHTData(_ note: Notification) {
        guard let userInfo = note.userInfo,
              let dataList = userInfo["dataList"] as? [[String: Any]],
              let dic = dataList.last else { return }

        if let temperature = dic["temperature"] as? String, !temperature.isEmpty {
            temperatureList.append(temperature)
        }
        if let humidity = dic["humidity"] as? String, !humidity.isEmpty {
            humidityList.append(humidity)
        }

        let temperature = "\(dic["temperature"] ?? "")℃"
        let humidity = "\(dic["humidity"] ?? "")%RH"

        let date = dic["date"] as? String ?? ""
        let dateList = date.components(separatedBy: "-")
        let dateString: String
        if dateList.count >= 6 {
            dateString = "\(dateList[2])/\(dateList[1])/\(dateList[0]) \(dateList[3]):\(dateList[4]):\(dateList[5])"
        } else {
            dateString = date
        }

        let text = "\n\(dateString)\t\t\(temperature)\t\t\(humidity)"
        _ = saveDataToLocal(text)
        textView.text = (textView.text ?? "") + text
        textView.scrollRangeToVisible(NSRange(location: (textView.text as NSString).length, length: 1))
        receiveCount = 0
    }

    // MARK: - Interface

    private func deleteRecordDatas() {
        _ = MKSwiftBleLogManager.deleteLog(fileName: "T&HDatas")
        textView.text = ""
        syncButton.isSelected = false
        synIcon.layer.removeAnimation(forKey: "synIconAnimationKey")
        _ = MKBXPCentralManager.shared.notifyRecordTHData(syncButton.isSelected)
        syncLabel.text = "Sync"

        MKSwiftHudManager.shared.showHUD(with: "Setting...", in: view, isPenetration: false)
        MKBXPInterface.bxp_deleteBXPRecordHTDatas { [weak self] _ in
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
        let localFileName = "/T&HDatas.txt"
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

    private func startReceiveTimer() {
        let timer = DispatchSource.makeTimerSource(queue: DispatchQueue.global())
        timer.schedule(deadline: .now() + 1.0, repeating: 1.0)
        timer.setEventHandler { [weak self] in
            guard let self = self else { return }
            self.receiveCount += 1
            if self.receiveCount == 10 {
                // 超时没有接收到数据，认为数据接收完毕
                DispatchQueue.main.async {
                    self.receiveTimer?.cancel()
                    self.receiveTimer = nil
                    self.syncButton.isSelected.toggle()
                    self.synIcon.layer.removeAnimation(forKey: "synIconAnimationKey")
                    _ = MKBXPCentralManager.shared.notifyRecordTHData(self.syncButton.isSelected)
                    self.syncLabel.text = "Sync"
                    self.switchButton.isEnabled = true
                }
            }
        }
        timer.resume()
        receiveTimer = timer
    }

    private func drawHTCurveView() {
        MKSwiftHudManager.shared.showHUD(with: "Loading...", in: view, isPenetration: false)
        let tempMax = temperatureList.compactMap { Float($0) }.max() ?? 0
        let tempMin = temperatureList.compactMap { Float($0) }.min() ?? 0
        let humiMax = humidityList.compactMap { Float($0) }.max() ?? 0
        let humiMin = humidityList.compactMap { Float($0) }.min() ?? 0

        curveView.updateTemperatureDatas(temperatureList,
                                         temperatureMax: CGFloat(tempMax),
                                         temperatureMin: CGFloat(tempMin),
                                         humidityList: humidityList,
                                         humidityMax: CGFloat(humiMax),
                                         humidityMin: CGFloat(humiMin),
                                         completeBlock: {
            MKSwiftHudManager.shared.hide()
        })
    }

    private func readDatasFromLocal() {
        MKSwiftHudManager.shared.showHUD(with: "Reading...", in: view, isPenetration: false)
        MKBXPDatabaseManager.readLocalDevice { [weak self] htList in
            guard let self = self else { return }
            MKSwiftHudManager.shared.hide()
            if let localData = MKSwiftBleLogManager.readData(fileName: "T&HDatas") {
                self.textView.text = String(data: localData, encoding: .utf8)
            }
            self.textView.scrollRangeToVisible(NSRange(location: (self.textView.text as NSString).length, length: 1))
            NotificationCenter.default.addObserver(self,
                                                  selector: #selector(self.receiveRecordHTData(_:)),
                                                  name: .mk_bxp_receiveRecordHTDataNotification,
                                                  object: nil)
            for dic in htList {
                if let temperature = dic["temperature"] as? String {
                    self.temperatureList.append(temperature)
                }
                if let humidity = dic["humidity"] as? String {
                    self.humidityList.append(humidity)
                }
            }
        } failedBlock: { [weak self] error in
            MKSwiftHudManager.shared.hide()
            let msg = (error as NSError).userInfo["errorInfo"] as? String ?? ""
            self?.view.showCentralToast(msg)
        }
    }

    // MARK: - UI

    private func loadSubViews() {
        defaultTitle = "Export T&H Data"
        view.backgroundColor = UIColor(red: 242/255.0, green: 242/255.0, blue: 242/255.0, alpha: 1)

        view.addSubview(backView)
        backView.snp.makeConstraints { make in
            make.left.equalTo(5)
            make.right.equalTo(-5)
            make.top.equalTo(view).offset(MKLayout.topBarHeight + 10)
            make.bottom.equalTo(view).offset(-(MKLayout.safeAreaBottom + 10))
        }

        backView.addSubview(topView)
        topView.snp.makeConstraints { make in
            make.left.equalTo(10)
            make.right.equalTo(-10)
            make.top.equalTo(5)
            make.height.equalTo(50)
        }

        topView.addSubview(syncButton)
        syncButton.addSubview(synIcon)
        topView.addSubview(syncLabel)
        topView.addSubview(switchButton)
        topView.addSubview(switchLabel)
        topView.addSubview(deleteButton)
        topView.addSubview(deleteLabel)
        topView.addSubview(exportButton)
        topView.addSubview(exportLabel)

        syncButton.snp.makeConstraints { make in
            make.left.equalTo(15)
            make.width.equalTo(30)
            make.top.equalTo(5)
            make.height.equalTo(30)
        }
        synIcon.snp.makeConstraints { make in
            make.centerX.equalTo(syncButton)
            make.centerY.equalTo(syncButton)
            make.width.height.equalTo(25)
        }
        syncLabel.snp.makeConstraints { make in
            make.left.equalTo(15)
            make.width.equalTo(25)
            make.top.equalTo(syncButton.snp.bottom).offset(2)
            make.height.equalTo(MKFont.font(10).lineHeight)
        }
        switchButton.snp.makeConstraints { make in
            make.left.equalTo(syncButton.snp.right).offset(20)
            make.width.equalTo(40)
            make.centerY.equalTo(syncButton)
            make.height.equalTo(30)
        }
        switchLabel.snp.makeConstraints { make in
            make.left.equalTo(switchButton)
            make.right.equalTo(switchButton)
            make.top.equalTo(switchButton.snp.bottom).offset(2)
            make.height.equalTo(MKFont.font(10).lineHeight)
        }
        deleteButton.snp.makeConstraints { make in
            make.right.equalTo(exportButton.snp.left).offset(-35)
            make.width.equalTo(40)
            make.centerY.equalTo(syncButton)
            make.height.equalTo(30)
        }
        deleteLabel.snp.makeConstraints { make in
            make.centerX.equalTo(deleteButton)
            make.width.equalTo(60)
            make.top.equalTo(deleteButton.snp.bottom).offset(2)
            make.height.equalTo(MKFont.font(10).lineHeight)
        }
        exportButton.snp.makeConstraints { make in
            make.right.equalTo(-15)
            make.width.equalTo(40)
            make.centerY.equalTo(syncButton)
            make.height.equalTo(30)
        }
        exportLabel.snp.makeConstraints { make in
            make.left.equalTo(exportButton)
            make.right.equalTo(exportButton)
            make.top.equalTo(exportButton.snp.bottom).offset(2)
            make.height.equalTo(MKFont.font(10).lineHeight)
        }

        backView.addSubview(textBackView)
        textBackView.addSubview(textView)
        backView.addSubview(curveView)

        // 设置初始 frame（与 OC 一致）
        textBackView.frame = CGRect(x: 10, y: 60,
                                     width: MKScreen.width - 30,
                                     height: textBackViewHeight)
        curveView.frame = CGRect(x: MKScreen.width - 10, y: 60,
                                 width: MKScreen.width - 30,
                                 height: textBackViewHeight)

        // textView 在 textBackView 内的位置
        textView.frame = CGRect(x: 10,
                                y: 3 * 5 + MKFont.font(13).lineHeight,
                                width: MKScreen.width - 30,
                                height: textBackViewHeight - 15 - MKFont.font(13).lineHeight - 45)

        // 表头
        let timeLabel = makeTextLabel("Time")
        let tempLabel = makeTextLabel("Temperature")
        let humidityLabel = makeTextLabel("Humidity")
        textBackView.addSubview(timeLabel)
        textBackView.addSubview(tempLabel)
        textBackView.addSubview(humidityLabel)

        timeLabel.frame = CGRect(x: textViewSpace, y: 5,
                                 width: Self.timeTextViewWidth,
                                 height: MKFont.font(13).lineHeight)
        tempLabel.frame = CGRect(x: 2 * textViewSpace + Self.timeTextViewWidth, y: 5,
                                 width: Self.htTextViewWidth,
                                 height: MKFont.font(13).lineHeight)
        humidityLabel.frame = CGRect(x: 3 * textViewSpace + Self.timeTextViewWidth + Self.htTextViewWidth, y: 5,
                                     width: Self.htTextViewWidth,
                                     height: MKFont.font(13).lineHeight)
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

extension MKBXPExportDataController: MFMailComposeViewControllerDelegate {
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
