//
//  MKBXPCentralManager.swift
//  MKBeaconXPlusSwiftProject
//
//  Created by aa on 2026/9/18.
//

import Foundation
@preconcurrency import CoreBluetooth
import MKSwiftBleModule

// MARK: - 通知名常量

public extension Notification.Name {
    /// 三轴加速度传感器数据
    static let mk_bxp_receiveThreeAxisAccelerometerDataNotification = Notification.Name("mk_bxp_receiveThreeAxisAccelerometerDataNotification")
    /// 温湿度数据
    static let mk_bxp_receiveHTDataNotification = Notification.Name("mk_bxp_receiveHTDataNotification")
    /// 已存储的温湿度数据
    static let mk_bxp_receiveRecordHTDataNotification = Notification.Name("mk_bxp_receiveRecordHTDataNotification")
    /// 光感数据
    static let mk_bxp_receiveLightSensorDataNotification = Notification.Name("mk_bxp_receiveLightSensorDataNotification")
    /// 光感状态数据
    static let mk_bxp_receiveLightSensorStatusDataNotification = Notification.Name("mk_bxp_receiveLightSensorStatusDataNotification")
    /// BXP-CL-a 历史温湿度数据
    static let mk_bxp_cl_receiveHTDataNotification = Notification.Name("mk_bxp_cl_receiveHTDataNotification")

    /// 设备断开类型（0x00/0x01/0x02）
    static let mk_bxp_deviceDisconnectTypeNotification = Notification.Name("mk_bxp_deviceDisconnectTypeNotification")

    /// 设备连接状态变化
    static let mk_bxp_peripheralConnectStateChangedNotification = Notification.Name("mk_bxp_peripheralConnectStateChangedNotification")

    /// 蓝牙中心状态变化
    static let mk_bxp_centralManagerStateChangedNotification = Notification.Name("mk_bxp_centralManagerStateChangedNotification")

    /// Eddystone Lock 状态变化
    static let mk_bxp_peripheralLockStateChangedNotification = Notification.Name("mk_bxp_peripheralLockStateChangedNotification")
}

// MARK: - 状态枚举

/// 蓝牙中心可用状态
public enum MKBXPCentralManagerStatus: Int {
    /// 不可用
    case unable = 0
    /// 可用
    case enable
}

/// 设备连接状态
public enum MKBXPCentralConnectStatus: Int {
    /// 未知
    case unknow = 0
    /// 正在连接
    case connecting
    /// 连接成功
    case connected
    /// 连接失败
    case connectedFailed
    /// 断开
    case disconnect
}

/// Eddystone Lock 状态
public enum MKBXPLockState: Int {
    case unknow
    case lock
    case open
    case unlockAutoMaticRelockDisabled
}

// MARK: - 扫描代理

public protocol MKBXPCentralManagerScanDelegate: AnyObject {
    /// 收到扫描设备列表
    func mk_bxp_receiveBeacon(_ beaconList: [MKBXPBaseBeacon])

    /// 开始扫描（可选）
    func mk_bxp_startScan()
    /// 停止扫描（可选）
    func mk_bxp_stopScan()
}

public extension MKBXPCentralManagerScanDelegate {
    func mk_bxp_startScan() {}
    func mk_bxp_stopScan() {}
}

// MARK: - MKBXPCentralManager

/// BXP 中心管理器（业务层）
public final class MKBXPCentralManager: NSObject, MKSwiftBleCentralManagerProtocol, @unchecked Sendable {

    // MARK: - 单例

    private static var _shared: MKBXPCentralManager?
    private static let sharedLock = NSLock()

    public static var shared: MKBXPCentralManager {
        sharedLock.lock()
        defer { sharedLock.unlock() }
        if let s = _shared { return s }
        let s = MKBXPCentralManager()
        _shared = s
        return s
    }

    /// 销毁 MKBXPCentralManager 单例和底层 MKSwiftBleBaseCentralManager 单例（DFU 升级后调用）
    public static func sharedDealloc() {
        sharedLock.lock()
        defer { sharedLock.unlock() }
        MKSwiftBleBaseCentralManager.singleDealloc()
        _shared = nil
    }

    /// 从中心列表移除（保留 SPM 中心实例）
    public static func removeFromCentralList() {
        sharedLock.lock()
        defer { sharedLock.unlock() }
        MKSwiftBleBaseCentralManager.shared.removeCentralManager()
        _shared = nil
    }

    // MARK: - 公开属性

    public weak var delegate: MKBXPCentralManagerScanDelegate?

    /// 当前连接状态
    public private(set) var connectState: MKBXPCentralConnectStatus = .unknow

    /// 当前 Eddystone Lock 状态
    public private(set) var lockState: MKBXPLockState = .unknow

    // MARK: - 私有属性

    /// 正在读取 LockState（用于区分读 LockState 流程与正常连接流程）
    private var readingLockState: Bool = false

    private var sucBlock: ((CBPeripheral) -> Void)?
    private var failedBlock: ((Error) -> Void)?
    private var progressBlock: ((Float) -> Void)?
    private var readLockStateBlock: ((String) -> Void)?
    private var password: String = ""

    private let operationListLock = NSLock()
    private var _operationList: [MKBXPOperation] = []
    private var operationList: [MKBXPOperation] {
        get { operationListLock.lock(); defer { operationListLock.unlock() }; return _operationList }
        set { operationListLock.lock(); defer { operationListLock.unlock() }; _operationList = newValue }
    }
    private var _isAction: Bool = false
    private var isAction: Bool {
        get { operationListLock.lock(); defer { operationListLock.unlock() }; return _isAction }
        set { operationListLock.lock(); defer { operationListLock.unlock() }; _isAction = newValue }
    }

    private lazy var unlockQueue: DispatchQueue = {
        DispatchQueue(label: "com.moko.bxp.unlockEddystoneQueue", qos: .default)
    }()

    // MARK: - Init

    private override init() {
        super.init()
        MKSwiftBleBaseCentralManager.shared.configCentralManager(self)
    }

    deinit {
        NSLog("MKBXPCentralManager销毁")
    }

    // MARK: - MKSwiftBleScanProtocol

    public func centralManagerDiscoverPeripheral(_ peripheral: CBPeripheral,
                                                  advertisementData: MKBleAdvInfo) {
        let rssi = advertisementData.rssi
        if rssi.intValue >= -45 {
            NSLog("advertisementData")
        }

        DispatchQueue.global(qos: .default).async { [weak self] in
            guard let self = self else { return }

            // 还原 advertisementData 为字典，便于 MKBXPBaseBeacon.parseAdvData 使用
            var advDic: [String: Any] = [:]
            if let localName = advertisementData.localName {
                advDic[CBAdvertisementDataLocalNameKey] = localName
            }
            if let serviceData = advertisementData.serviceData {
                advDic[CBAdvertisementDataServiceDataKey] = serviceData
            }
            if let manufacturerData = advertisementData.manufacturerData {
                advDic[CBAdvertisementDataManufacturerDataKey] = manufacturerData
            }
            if let txPower = advertisementData.txPowerLevel {
                advDic[CBAdvertisementDataTxPowerLevelKey] = NSNumber(value: txPower)
            }
            if let isConnectable = advertisementData.isConnectable {
                advDic[CBAdvertisementDataIsConnectable] = isConnectable
            }
            if let serviceUUIDs = advertisementData.serviceUUIDs {
                advDic[CBAdvertisementDataServiceUUIDsKey] = serviceUUIDs
            }

            // OTA 广播帧
            if advertisementData.localName == "MK_OTA" {
                let beaconModel = MKBXPOTABeacon()
                beaconModel.frameType = .ota
                beaconModel.identifier = peripheral.identifier.uuidString
                beaconModel.rssi = rssi
                beaconModel.peripheral = peripheral
                beaconModel.deviceName = advertisementData.localName ?? ""
                beaconModel.connectEnable = advertisementData.isConnectable ?? false
                DispatchQueue.main.async { [weak self] in
                    self?.delegate?.mk_bxp_receiveBeacon([beaconModel])
                }
                return
            }

            let beaconList = MKBXPBaseBeacon.parseAdvData(advDic)
            for beaconModel in beaconList {
                beaconModel.identifier = peripheral.identifier.uuidString
                beaconModel.rssi = rssi
                beaconModel.peripheral = peripheral
                beaconModel.deviceName = advertisementData.localName ?? ""
                beaconModel.connectEnable = advertisementData.isConnectable ?? false
            }

            DispatchQueue.main.async { [weak self] in
                self?.delegate?.mk_bxp_receiveBeacon(beaconList)
            }
        }
    }

    public func centralManagerStartScan() {
        DispatchQueue.main.async { [weak self] in
            self?.delegate?.mk_bxp_startScan()
        }
    }

    public func centralManagerStopScan() {
        DispatchQueue.main.async { [weak self] in
            self?.delegate?.mk_bxp_stopScan()
        }
    }

    // MARK: - MKSwiftBleCentralManagerStateProtocol

    public func centralManagerStateChanged(_ centralManagerState: MKSwiftCentralManagerState) {
        DispatchQueue.main.async {
            NotificationCenter.default.post(name: .mk_bxp_centralManagerStateChangedNotification, object: nil)
        }
    }

    public func peripheralConnectStateChanged(_ connectState: MKSwiftPeripheralConnectState) {
        if readingLockState {
            return
        }
        switch connectState {
        case .unknown:
            self.connectState = .unknow
        case .connecting:
            self.connectState = .connecting
        case .disconnect:
            self.connectState = .disconnect
        case .connectedFailed:
            self.connectState = .connectedFailed
        case .connected:
            break
        }
        DispatchQueue.main.async {
            NotificationCenter.default.post(name: .mk_bxp_peripheralConnectStateChangedNotification, object: nil)
        }
    }

    // MARK: - MKSwiftBleCentralManagerProtocol

    public func peripheral(_ peripheral: CBPeripheral,
                           didUpdateValueFor characteristic: CBCharacteristic,
                           error: Error?) {
        if error != nil {
            NSLog("+++++++++++++++++接收数据出错")
            return
        }

        // 先派发给当前操作（匹配 OC 的 MKBLEBaseCentralManager 先 dispatch 再调 delegate）
        if !operationList.isEmpty && isAction {
            let currentOperation = operationList[0]
            currentOperation.didUpdateValueForCharacteristic(characteristic)
        }

        let uuidString = characteristic.uuid.uuidString

        // 设备断开原因
        if uuidString == "E62A0007-1362-4F28-9327-F5B74E970801" {
            let content = MKSwiftBleSDKAdopter.hexStringFromData(characteristic.value ?? Data())
            DispatchQueue.main.async {
                NotificationCenter.default.post(name: .mk_bxp_deviceDisconnectTypeNotification,
                                              object: nil,
                                              userInfo: ["type": content])
            }
            return
        }

        // notify 特征值：判断是否是 lockState 改变通知
        if uuidString == "E62A0003-1362-4F28-9327-F5B74E970801" {
            let content = MKSwiftBleSDKAdopter.hexStringFromData(characteristic.value ?? Data())
            if content.count > 6, content.bleSubstring(from: 0, length: 4) == "eb63" {
                let state = content.bleSubstring(from: content.count - 2, length: 2)
                var lockState: MKBXPLockState = .unknow
                switch state {
                case "00":
                    lockState = .lock
                case "01":
                    lockState = .open
                case "02":
                    lockState = .unlockAutoMaticRelockDisabled
                default:
                    break
                }
                updateLockState(lockState)
                return
            }
        }

        // 三轴加速度数据
        if uuidString == "E62A0008-1362-4F28-9327-F5B74E970801" {
            let content = MKSwiftBleSDKAdopter.hexStringFromData(characteristic.value ?? Data())
            if content.count >= 12 {
                var dataList: [[String: Any]] = []
                let count = content.count / 12
                for i in 0..<count {
                    let subContent = content.bleSubstring(from: i * 12, length: 12).uppercased()
                    let dic: [String: Any] = [
                        "x-Data": subContent.bleSubstring(from: 0, length: 4),
                        "y-Data": subContent.bleSubstring(from: 4, length: 4),
                        "z-Data": subContent.bleSubstring(from: 8, length: 4)
                    ]
                    dataList.append(dic)
                }
                DispatchQueue.main.async {
                    NotificationCenter.default.post(name: .mk_bxp_receiveThreeAxisAccelerometerDataNotification,
                                                  object: nil,
                                                  userInfo: ["axisData": dataList])
                }
            }
            return
        }

        // 温湿度数据
        if uuidString == "E62A0009-1362-4F28-9327-F5B74E970801" {
            let content = MKSwiftBleSDKAdopter.hexStringFromData(characteristic.value ?? Data())
            if content.count == 8 {
                let tempTemp = MKSwiftBleSDKAdopter.signedHexTurnToInt(content.bleSubstring(from: 0, length: 4))
                let tempHui = MKSwiftBleSDKAdopter.getDecimalWithHex(content, range: NSRange(location: 4, length: 4))
                let temperature = String(format: "%.1f", Double(tempTemp) * 0.1)
                let humidity = String(format: "%.1f", Double(tempHui) * 0.1)
                let htData: [String: Any] = [
                    "temperature": temperature,
                    "humidity": humidity
                ]
                DispatchQueue.main.async {
                    NotificationCenter.default.post(name: .mk_bxp_receiveHTDataNotification,
                                                  object: nil,
                                                  userInfo: htData)
                }
            }
            return
        }

        // 已存储的温湿度数据
        if uuidString == "E62A000A-1362-4F28-9327-F5B74E970801" {
            let content = MKSwiftBleSDKAdopter.hexStringFromData(characteristic.value ?? Data())
            if content.count == 20 || content.count == 40 {
                var dataList: [[String: Any]] = []
                let count = content.count / 20
                for i in 0..<count {
                    let subContent = content.bleSubstring(from: i * 20, length: 20)
                    let date = MKBXPAdopter.deviceTime(subContent.bleSubstring(from: 0, length: 12))
                    let tempTemp = MKSwiftBleSDKAdopter.signedHexTurnToInt(content.bleSubstring(from: 12, length: 4))
                    let tempHui = MKSwiftBleSDKAdopter.getDecimalWithHex(content, range: NSRange(location: 16, length: 4))
                    let temperature = String(format: "%.1f", Double(tempTemp) * 0.1)
                    let humidity = String(format: "%.1f", Double(tempHui) * 0.1)
                    let htData: [String: Any] = [
                        "temperature": temperature,
                        "humidity": humidity,
                        "date": date
                    ]
                    dataList.append(htData)
                }
                DispatchQueue.main.async {
                    NotificationCenter.default.post(name: .mk_bxp_receiveRecordHTDataNotification,
                                                  object: nil,
                                                  userInfo: ["dataList": dataList])
                }
            }
            return
        }

        // 光感数据
        if uuidString == "E62A000B-1362-4F28-9327-F5B74E970801" {
            let content = MKSwiftBleSDKAdopter.hexStringFromData(characteristic.value ?? Data())
            if content.count == 14 {
                let date = MKBXPAdopter.deviceTime(content.bleSubstring(from: 0, length: 12))
                let state = content.bleSubstring(from: 12, length: 2)
                let lightData: [String: Any] = [
                    "date": date,
                    "state": state
                ]
                DispatchQueue.main.async {
                    NotificationCenter.default.post(name: .mk_bxp_receiveLightSensorDataNotification,
                                                  object: nil,
                                                  userInfo: lightData)
                }
                return
            }
            return
        }

        // 光感状态数据
        if uuidString == "E62A000C-1362-4F28-9327-F5B74E970801" {
            let content = MKSwiftBleSDKAdopter.hexStringFromData(characteristic.value ?? Data())
            DispatchQueue.main.async {
                NotificationCenter.default.post(name: .mk_bxp_receiveLightSensorStatusDataNotification,
                                              object: nil,
                                              userInfo: ["status": content])
            }
            return
        }

        // BXP-CL-a 历史温湿度数据
        if uuidString == "E62A000E-1362-4F28-9327-F5B74E970801" {
            let content = MKSwiftBleSDKAdopter.hexStringFromData(characteristic.value ?? Data())
            let result = MKBXPAdopter.parseHistoryHTData(content.bleSubstring(from: 6, length: content.count - 6))
            DispatchQueue.main.async {
                NotificationCenter.default.post(name: .mk_bxp_cl_receiveHTDataNotification,
                                              object: nil,
                                              userInfo: result)
            }
            return
        }
    }

    public func peripheral(_ peripheral: CBPeripheral,
                           didWriteValueFor characteristic: CBCharacteristic,
                           error: Error?) {
        if error != nil {
            NSLog("+++++++++++++++++发送数据出错")
            return
        }

        if !operationList.isEmpty && isAction {
            let currentOperation = operationList[0]
            currentOperation.didWriteValueForCharacteristic(characteristic)
        }
    }

    // MARK: - 公开方法

    public var centralManager: CBCentralManager {
        MKSwiftBleBaseCentralManager.shared.centralManager
    }

    public func peripheral() -> CBPeripheral? {
        MKSwiftBleBaseCentralManager.shared.peripheral()
    }

    public var centralStatus: MKBXPCentralManagerStatus {
        MKSwiftBleBaseCentralManager.shared.centralStatus == .enable ? .enable : .unable
    }

    public func startScan() {
        _ = MKSwiftBleBaseCentralManager.shared.scanForPeripherals(
            withServices: [
                CBUUID(string: "EAFF"),
                CBUUID(string: "FEAA"),
                CBUUID(string: "FEAB")
            ],
            options: [CBCentralManagerScanOptionAllowDuplicatesKey: true]
        )
    }

    public func stopScan() {
        _ = MKSwiftBleBaseCentralManager.shared.stopScan()
    }

    /// 连接设备（带密码）
    /// - Parameters:
    ///   - peripheral: 外设
    ///   - password: 密码（不超过 16 个 ASCII 字符）
    ///   - progressBlock: 连接进度回调
    ///   - sucBlock: 成功回调
    ///   - failedBlock: 失败回调
    public func connectPeripheral(_ peripheral: CBPeripheral,
                                  password: String,
                                  progressBlock: @escaping (Float) -> Void,
                                  sucBlock: @escaping (CBPeripheral) -> Void,
                                  failedBlock: @escaping (Error) -> Void) {
        if !MKSwiftBleSDKAdopter.asciiString(password) || password.count > 16 {
            operationFailedBlock(withMsg: "Password incorrect!", failedBlock: failedBlock)
            return
        }
        self.password = ""
        self.password = password
        connectPeripheral(peripheral,
                          progressBlock: progressBlock,
                          sucBlock: sucBlock,
                          failedBlock: failedBlock)
    }

    /// 读取设备 LockState（连接后断开，不进入解锁流程）
    /// - Parameters:
    ///   - peripheral: 外设
    ///   - sucBlock: 成功回调，返回 "00" 或 "02"
    ///   - failedBlock: 失败回调
    public func readLockState(with peripheral: CBPeripheral,
                              sucBlock: @escaping (String) -> Void,
                              failedBlock: @escaping (Error) -> Void) {
        if readingLockState {
            operationFailedBlock(withMsg: "Device is busy now", failedBlock: failedBlock)
            return
        }
        readingLockState = true
        self.sucBlock = nil
        self.failedBlock = nil
        self.progressBlock = nil
        self.readLockStateBlock = { [weak self] lockState in
            guard let self = self else { return }
            self.clearAllParams()
            DispatchQueue.main.async {
                sucBlock(lockState)
            }
        }
        let bxpPeripheral = MKBXPPeripheral(peripheral: peripheral, dfuMode: false)
        Task { [weak self] in
            guard let self = self else { return }
            do {
                _ = try await MKSwiftBleBaseCentralManager.shared.connectDevice(bxpPeripheral)
                self.sendPasswordToDevice()
            } catch {
                self.clearAllParams()
                failedBlock(error)
            }
        }
    }

    /// 连接设备（无需密码，lockState 为 02 时使用）
    /// - Parameters:
    ///   - peripheral: 外设
    ///   - progressBlock: 进度回调
    ///   - sucBlock: 成功回调
    ///   - failedBlock: 失败回调
    public func connectPeripheral(_ peripheral: CBPeripheral,
                                  progressBlock: @escaping (Float) -> Void,
                                  sucBlock: @escaping (CBPeripheral) -> Void,
                                  failedBlock: @escaping (Error) -> Void) {
        if readingLockState {
            operationFailedBlock(withMsg: "Device is busy now", failedBlock: failedBlock)
            return
        }
        if peripheral.identifier.uuidString.isEmpty {
            operationConnectFailedBlock(failedBlock)
            return
        }
        connect(peripheral: peripheral,
                progressBlock: { progress in
                    progressBlock(progress)
                },
                dfu: false,
                sucBlock: { [weak self] peripheral in
                    guard let self = self else { return }
                    self.clearAllParams()
                    sucBlock(peripheral)
                },
                failedBlock: { [weak self] error in
                    guard let self = self else { return }
                    self.clearAllParams()
                    failedBlock(error)
                })
    }

    /// DFU 连接设备
    /// - Parameters:
    ///   - peripheral: 外设
    ///   - sucBlock: 成功回调
    ///   - failedBlock: 失败回调
    public func dfuconnectPeripheral(_ peripheral: CBPeripheral,
                                     sucBlock: @escaping (CBPeripheral) -> Void,
                                     failedBlock: @escaping (Error) -> Void) {
        if peripheral.identifier.uuidString.isEmpty {
            operationConnectFailedBlock(failedBlock)
            return
        }
        self.password = ""
        connect(peripheral: peripheral,
                progressBlock: { _ in },
                dfu: true,
                sucBlock: { [weak self] peripheral in
                    guard let self = self else { return }
                    self.clearAllParams()
                    sucBlock(peripheral)
                },
                failedBlock: { [weak self] error in
                    guard let self = self else { return }
                    self.clearAllParams()
                    failedBlock(error)
                })
    }

    public func disconnect() {
        MKSwiftBleBaseCentralManager.shared.disconnect()
    }

    // MARK: - 任务通信

    /// 添加写任务到队列
    /// - Parameters:
    ///   - operationID: 任务 ID
    ///   - commandData: 命令数据（hex 字符串）
    ///   - characteristic: 目标特征
    ///   - sucBlock: 成功回调
    ///   - failedBlock: 失败回调
    public func addTaskWithTaskID(_ operationID: MKBXPTaskOperationID,
                                  commandData: String,
                                  characteristic: CBCharacteristic,
                                  sucBlock: @escaping (Any) -> Void,
                                  failedBlock: @escaping (Error) -> Void) {
        guard let operation = generateOperationWithOperationID(operationID,
                                                                commandData: commandData,
                                                                characteristic: characteristic,
                                                                sucBlock: sucBlock,
                                                                failedBlock: failedBlock) else {
            return
        }
        operationList.append(operation)
        operationAction()
    }

    /// 添加读任务到队列
    /// - Parameters:
    ///   - operationID: 任务 ID
    ///   - characteristic: 目标特征
    ///   - sucBlock: 成功回调
    ///   - failedBlock: 失败回调
    public func addReadTaskWithTaskID(_ operationID: MKBXPTaskOperationID,
                                      characteristic: CBCharacteristic,
                                      sucBlock: @escaping (Any) -> Void,
                                      failedBlock: @escaping (Error) -> Void) {
        guard let operation = generateReadOperationWithID(operationID,
                                                          characteristic: characteristic,
                                                          sucBlock: sucBlock,
                                                          failedBlock: failedBlock) else {
            return
        }
        operationList.append(operation)
        operationAction()
    }

    // MARK: - Notify 开关

    /// 监听三轴加速度传感器数据
    public func notifyThreeAxisAcceleration(_ notify: Bool) -> Bool {
        guard connectState == .connected,
              let peripheral = MKSwiftBleBaseCentralManager.shared.peripheral(),
              let characteristic = peripheral.bxp_threeSensor else {
            return false
        }
        peripheral.setNotifyValue(notify, for: characteristic)
        return true
    }

    /// 监听温湿度传感器数据
    public func notifyTHData(_ notify: Bool) -> Bool {
        guard connectState == .connected,
              let peripheral = MKSwiftBleBaseCentralManager.shared.peripheral(),
              let characteristic = peripheral.bxp_temperatureHumidity else {
            return false
        }
        peripheral.setNotifyValue(notify, for: characteristic)
        return true
    }

    /// 监听已存储的温湿度数据
    public func notifyRecordTHData(_ notify: Bool) -> Bool {
        guard connectState == .connected,
              let peripheral = MKSwiftBleBaseCentralManager.shared.peripheral(),
              let characteristic = peripheral.bxp_recordTH else {
            return false
        }
        peripheral.setNotifyValue(notify, for: characteristic)
        return true
    }

    /// 监听光感数据
    public func notifyLightSensorData(_ notify: Bool) -> Bool {
        guard connectState == .connected,
              let peripheral = MKSwiftBleBaseCentralManager.shared.peripheral(),
              let characteristic = peripheral.bxp_lightSensor else {
            return false
        }
        peripheral.setNotifyValue(notify, for: characteristic)
        return true
    }

    /// 监听光感状态数据
    public func notifyLightStatusData(_ notify: Bool) -> Bool {
        guard connectState == .connected,
              let peripheral = MKSwiftBleBaseCentralManager.shared.peripheral(),
              let characteristic = peripheral.bxp_lightStatus else {
            return false
        }
        peripheral.setNotifyValue(notify, for: characteristic)
        return true
    }

    /// 监听 BXP-CL-a 历史温湿度数据
    public func notifyBXPCLHTData(_ notify: Bool) -> Bool {
        guard connectState == .connected,
              let peripheral = MKSwiftBleBaseCentralManager.shared.peripheral(),
              let characteristic = peripheral.bxp_clTHData else {
            return false
        }
        peripheral.setNotifyValue(notify, for: characteristic)
        return true
    }

    // MARK: - 私有：连接与解锁流程

    /// 连接设备私有入口
    private func connect(peripheral: CBPeripheral,
                         progressBlock: @escaping (Float) -> Void,
                         dfu: Bool,
                         sucBlock: @escaping (CBPeripheral) -> Void,
                         failedBlock: @escaping (Error) -> Void) {
        self.sucBlock = sucBlock
        self.failedBlock = failedBlock
        self.progressBlock = progressBlock
        updateConnectProgress(5.0)
        let bxpPeripheral = MKBXPPeripheral(peripheral: peripheral, dfuMode: dfu)
        Task { [weak self] in
            guard let self = self else { return }
            do {
                _ = try await MKSwiftBleBaseCentralManager.shared.connectDevice(bxpPeripheral)
                if dfu {
                    self.connectDeviecSuccess()
                    return
                }
                self.updateConnectProgress(30.0)
                self.sendPasswordToDevice()
            } catch {
                if let failedBlock = self.failedBlock {
                    failedBlock(error)
                }
            }
        }
    }

    /// 发送密码/读取 lockState 后的解锁流程
    /// 在串行队列中执行，内部使用信号量同步等待设备返回
    private func sendPasswordToDevice() {
        unlockQueue.async { [weak self] in
            guard let self = self else { return }
            let lockState = self.fetchLockState()
            if self.readingLockState {
                // 读取 lockState 操作，不需要进行后续步骤，读取完数据之后断开连接
                MKSwiftBleBaseCentralManager.shared.disconnect()
                self.readingLockState = false
                if let readLockStateBlock = self.readLockStateBlock {
                    let lockInfo = (lockState == .unlockAutoMaticRelockDisabled) ? "02" : "00"
                    DispatchQueue.main.async {
                        readLockStateBlock(lockInfo)
                    }
                }
                return
            }
            self.updateLockState(lockState)
            self.updateConnectProgress(50.0)
            if lockState == .unknow {
                self.operationConnectFailedBlock(self.failedBlock)
                self.readingLockState = false
                MKSwiftBleBaseCentralManager.shared.disconnect()
                return
            }
            if lockState == .lock {
                // 锁定状态：先读取设备的 unlock 数据，返回 16 位的随机 key
                let randKey = self.fetchRandDataArray()
                self.updateConnectProgress(65.0)
                guard let randKey = randKey, !randKey.isEmpty, randKey.count == 16 else {
                    self.operationConnectFailedBlock(self.failedBlock)
                    self.readingLockState = false
                    MKSwiftBleBaseCentralManager.shared.disconnect()
                    return
                }
                guard let keyToUnlock = MKBXPAdopter.fetchKeyToUnlock(password: self.password, randKey: randKey),
                      !keyToUnlock.isEmpty else {
                    self.operationConnectFailedBlock(self.failedBlock)
                    self.readingLockState = false
                    MKSwiftBleBaseCentralManager.shared.disconnect()
                    return
                }
                // 当前密码与 unlock 返回的 16 位 key 进行 aes128 加密之后生成对应的解锁码，发送给设备的 unlock 特征进行解锁
                let sendToUnlockSuccess = self.sendKeyToUnlock(keyToUnlock)
                self.updateConnectProgress(80.0)
                if !sendToUnlockSuccess {
                    self.operationConnectFailedBlock(self.failedBlock)
                    self.readingLockState = false
                    MKSwiftBleBaseCentralManager.shared.disconnect()
                    return
                }
                // 解锁码发送给设备之后，再次获取设备的锁定状态，看看是否解锁成功
                let newLockState = self.fetchLockState()
                self.updateLockState(newLockState)
                self.updateConnectProgress(100.0)
                if newLockState == .unknow || newLockState == .lock {
                    self.operationFailedBlock(withMsg: "Password incorrect!", failedBlock: self.failedBlock)
                    self.readingLockState = false
                    MKSwiftBleBaseCentralManager.shared.disconnect()
                    return
                }
                self.readingLockState = false
                self.connectDeviecSuccess()
                return
            }
            // lockState 为 open 或 unlockAutoMaticRelockDisabled，直接连接成功
            self.readingLockState = false
            self.connectDeviecSuccess()
        }
    }

    /// 连接成功回调
    private func connectDeviecSuccess() {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            self.connectState = .connected
            NotificationCenter.default.post(name: .mk_bxp_peripheralConnectStateChangedNotification, object: nil)
            if let sucBlock = self.sucBlock,
               let peripheral = MKSwiftBleBaseCentralManager.shared.peripheral() {
                sucBlock(peripheral)
            }
        }
    }

    // MARK: - 私有：信号量同步读取/写入

    /// 读取设备 LockState（同步阻塞）
    private func fetchLockState() -> MKBXPLockState {
        var lockState: MKBXPLockState = .unknow
        let semaphore = DispatchSemaphore(value: 0)
        let operation = MKBXPOperation(operationID: .readLockState,
                                       commandBlock: {
                                        guard let peripheral = MKSwiftBleBaseCentralManager.shared.peripheral(),
                                              let characteristic = peripheral.bxp_lockState else { return }
                                        peripheral.readValue(for: characteristic)
                                       },
                                       completeBlock: { [weak self] error, returnData in
                                        guard let self = self else {
                                            semaphore.signal()
                                            return
                                        }
                                        self.isAction = false
                                        if !self.operationList.isEmpty {
                                            self.operationList.removeFirst()
                                            self.operationAction()
                                        }
                                        if error == nil,
                                           let returnData = returnData as? [String: Any],
                                           let state = returnData["lockState"] as? String {
                                            switch state {
                                            case "00":
                                                lockState = .lock
                                            case "01":
                                                lockState = .open
                                            case "02":
                                                lockState = .unlockAutoMaticRelockDisabled
                                            default:
                                                lockState = .unknow
                                            }
                                        }
                                        semaphore.signal()
                                       })
        operationList.append(operation)
        operationAction()
        semaphore.wait()
        return lockState
    }

    /// 读取 unlock 特征返回的 16 字节随机 key（同步阻塞）
    private func fetchRandDataArray() -> Data? {
        var randDataArray: Data? = nil
        let semaphore = DispatchSemaphore(value: 0)
        let operation = MKBXPOperation(operationID: .readUnlock,
                                       commandBlock: {
                                        guard let peripheral = MKSwiftBleBaseCentralManager.shared.peripheral(),
                                              let characteristic = peripheral.bxp_unlock else { return }
                                        peripheral.readValue(for: characteristic)
                                       },
                                       completeBlock: { [weak self] error, returnData in
                                        guard let self = self else {
                                            semaphore.signal()
                                            return
                                        }
                                        self.isAction = false
                                        if !self.operationList.isEmpty {
                                            self.operationList.removeFirst()
                                            self.operationAction()
                                        }
                                        if error == nil, let returnData = returnData as? [String: Any] {
                                            randDataArray = returnData["RAND_DATA_ARRAY"] as? Data
                                        }
                                        semaphore.signal()
                                       })
        operationList.append(operation)
        operationAction()
        semaphore.wait()
        return randDataArray
    }

    /// 发送解锁码到 unlock 特征（同步阻塞）
    private func sendKeyToUnlock(_ keyData: Data) -> Bool {
        guard let peripheral = MKSwiftBleBaseCentralManager.shared.peripheral(),
              let characteristic = peripheral.bxp_unlock else {
            return false
        }
        var success = false
        let semaphore = DispatchSemaphore(value: 0)
        let operation = MKBXPOperation(operationID: .configUnlock,
                                       commandBlock: {
                                        peripheral.writeValue(keyData, for: characteristic, type: .withResponse)
                                       },
                                       completeBlock: { [weak self] error, _ in
                                        guard let self = self else {
                                            semaphore.signal()
                                            return
                                        }
                                        self.isAction = false
                                        if !self.operationList.isEmpty {
                                            self.operationList.removeFirst()
                                            self.operationAction()
                                        }
                                        if error == nil {
                                            success = true
                                        }
                                        semaphore.signal()
                                       })
        operationList.append(operation)
        operationAction()
        semaphore.wait()
        return success
    }

    // MARK: - 私有：任务生成

    private func generateOperationWithOperationID(_ operationID: MKBXPTaskOperationID,
                                                  commandData: String,
                                                  characteristic: CBCharacteristic,
                                                  sucBlock: @escaping (Any) -> Void,
                                                  failedBlock: @escaping (Error) -> Void) -> MKBXPOperation? {
        if !MKSwiftBleBaseCentralManager.shared.readyToCommunication {
            operationFailedBlock(withMsg: "The current connection device is in disconnect", failedBlock: failedBlock)
            return nil
        }
        if commandData.isEmpty {
            operationFailedBlock(withMsg: "Input parameter error", failedBlock: failedBlock)
            return nil
        }
        let operation = MKBXPOperation(operationID: operationID,
                                       commandBlock: {
                                        _ = MKSwiftBleBaseCentralManager.shared.sendDataToPeripheral(
                                            commandData,
                                            characteristic: characteristic,
                                            type: .withResponse
                                        )
                                       },
                                       completeBlock: { [weak self] error, returnData in
                                        guard let self = self else { return }
                                        self.parseTaskResult(error,
                                                             returnData: returnData as? [String : Any],
                                                             sucBlock: sucBlock,
                                                             failedBlock: failedBlock)
                                       })
        return operation
    }

    private func generateReadOperationWithID(_ operationID: MKBXPTaskOperationID,
                                             characteristic: CBCharacteristic,
                                             sucBlock: @escaping (Any) -> Void,
                                             failedBlock: @escaping (Error) -> Void) -> MKBXPOperation? {
        if !MKSwiftBleBaseCentralManager.shared.readyToCommunication {
            operationFailedBlock(withMsg: "The current connection device is in disconnect", failedBlock: failedBlock)
            return nil
        }
        let operation = MKBXPOperation(operationID: operationID,
                                       commandBlock: {
                                        if let peripheral = MKSwiftBleBaseCentralManager.shared.peripheral() {
                                            peripheral.readValue(for: characteristic)
                                        }
                                       },
                                       completeBlock: { [weak self] error, returnData in
                                        guard let self = self else { return }
                                        self.parseTaskResult(error,
                                                             returnData: returnData as? [String : Any],
                                                             sucBlock: sucBlock,
                                                             failedBlock: failedBlock)
                                       })
        return operation
    }

    private func parseTaskResult(_ error: Error?,
                                 returnData: [String: Any]?,
                                 sucBlock: @escaping (Any) -> Void,
                                 failedBlock: @escaping (Error) -> Void) {
        // 队列管理：完成当前任务，启动下一个
        isAction = false
        if !operationList.isEmpty {
            operationList.removeFirst()
            operationAction()
        }
        if let error = error {
            DispatchQueue.main.async {
                failedBlock(error)
            }
            return
        }
        guard let returnData = returnData else {
            operationFailedBlock(withMsg: "Request data error", failedBlock: failedBlock)
            return
        }
        let resultDic: [String: Any] = [
            "msg": "success",
            "code": "1",
            "result": returnData
        ]
        DispatchQueue.main.async {
            sucBlock(resultDic)
        }
    }

    // MARK: - 私有：状态与清理

    private func updateLockState(_ lockState: MKBXPLockState) {
        self.lockState = lockState
        DispatchQueue.main.async {
            NotificationCenter.default.post(name: .mk_bxp_peripheralLockStateChangedNotification,
                                          object: nil,
                                          userInfo: [:])
        }
    }

    private func updateConnectProgress(_ progress: Float) {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            self.progressBlock?(progress)
        }
    }

    private func clearAllParams() {
        sucBlock = nil
        failedBlock = nil
        progressBlock = nil
        readLockStateBlock = nil
        readingLockState = false
    }

    private func operationAction() {
        if operationList.isEmpty || isAction {
            return
        }
        isAction = true
        let currentOperation = operationList[0]
        currentOperation.startCommunication()
    }

    private func operationFailedBlock(withMsg message: String,
                                      failedBlock: ((Error) -> Void)?) {
        let error = NSError(domain: "com.moko.BXPCentralManager",
                            code: -999,
                            userInfo: ["errorInfo": message])
        DispatchQueue.main.async {
            failedBlock?(error)
        }
    }

    private func operationConnectFailedBlock(_ failedBlock: ((Error) -> Void)?) {
        let error = NSError(domain: "com.moko.BXPCentralManager",
                            code: -999,
                            userInfo: ["errorInfo": "Device is not exist"])
        DispatchQueue.main.async {
            failedBlock?(error)
        }
    }
}
