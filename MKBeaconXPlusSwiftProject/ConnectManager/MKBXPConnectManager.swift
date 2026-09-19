//
//  MKBXPConnectManager.swift
//  MKBeaconXPlusSwiftProject
//
//  Created by aa on 2026/9/18.
//

import Foundation

@preconcurrency import CoreBluetooth

import MKBaseSwiftModule
import MKSwiftBleModule

/// 设备类型
/// - none: 无传感器
/// - lis3dh: 带 LIS3DH 三轴加速度计
/// - sht3x: 带 SHT3X 温湿度传感器
/// - lis3dhAndSht3x: 同时带有 LIS3DH 及 SHT3X 传感器
/// - light: 光感
/// - threeAxisAndLight: 三轴 + 光感
public enum MKBXPDeviceType: String {
    case none = "00"
    case lis3dh = "01"
    case sht3x = "02"
    case lis3dhAndSht3x = "03"
    case light = "04"
    case threeAxisAndLight = "05"
}

/// BXP 连接管理器（负责连接、读取设备信息、同步时间等完整连接流程）
public final class MKBXPConnectManager: NSObject, @unchecked Sendable {

    // MARK: - 单例

    private static var _shared: MKBXPConnectManager?
    private static let sharedLock = NSLock()

    public static var shared: MKBXPConnectManager {
        sharedLock.lock()
        defer { sharedLock.unlock() }
        if let s = _shared { return s }
        let s = MKBXPConnectManager()
        _shared = s
        return s
    }

    // MARK: - 公开属性

    /// 连接密码
    public var password: String = ""

    /// 设备类型
    public var deviceType: MKBXPDeviceType = .none

    /// 生产日期在 2021/01/01（含）以后的都是新版本
    public var newVersion: Bool = false

    /// 固件版本
    public private(set) var firmware: String = ""

    /// 软件版本
    public private(set) var software: String = ""

    /// 是否打开了密码验证，当 lockState 为 .open 时表明设备打开了密码验证
    public var passwordVerification: Bool = false

    /// 软件版本是否包含 BXP-C 字符
    public var isBXPC: Bool = false

    /// 固件版本是否包含 BXP-DH01 或 BXP-DH_W7 或 BXP-D04
    public var tamperDetect: Bool = false

    /// 是否为 BXP-D04
    public var isBXPD04: Bool = false

    // MARK: - 私有属性

    private lazy var connectQueue: DispatchQueue = {
        DispatchQueue(label: "com.moko.connectQueue", qos: .default)
    }()

    private lazy var semaphore: DispatchSemaphore = {
        DispatchSemaphore(value: 0)
    }()

    // MARK: - Init

    private override init() {
        super.init()
    }

    // MARK: - 公开方法

    /// 清除当前所有参数
    public func clearParams() {
        password = ""
        deviceType = .none
        newVersion = false
        software = ""
        firmware = ""
    }

    /// 连接设备（完整流程：连接 → 读设备类型 → 读生产日期 → 读固件 → 读软件 → 同步时间）
    /// - Parameters:
    ///   - peripheral: 外设
    ///   - password: 密码（有效密码时走密码登录，否则走免密登录）
    ///   - progressBlock: 连接进度回调
    ///   - sucBlock: 成功回调
    ///   - failedBlock: 失败回调
    public func connectPeripheral(_ peripheral: CBPeripheral,
                                  password: String,
                                  progressBlock: @escaping (Float) -> Void,
                                  sucBlock: @escaping () -> Void,
                                  failedBlock: @escaping (Error) -> Void) {
        connectQueue.async { [weak self] in
            guard let self = self else { return }

            var connectResult: [String: Any] = [:]
            if !password.isEmpty && password.count < 16 {
                // 有密码登录
                connectResult = self.connectDevice(peripheral,
                                                   password: password,
                                                   progressBlock: progressBlock)
            } else {
                // 免密登录
                connectResult = self.connectDevice(peripheral,
                                                   progressBlock: progressBlock)
            }

            self.tamperDetect = false
            self.isBXPD04 = false

            guard (connectResult["success"] as? Bool) == true else {
                let msg = connectResult["msg"] as? String ?? ""
                self.operationFailedMsg(msg, completeBlock: failedBlock)
                return
            }

            guard self.readDeviceType() else {
                self.operationFailedMsg("Read Device Type Error", completeBlock: failedBlock)
                return
            }

            guard self.readManuDate() else {
                self.operationFailedMsg("Read Manu Date Error", completeBlock: failedBlock)
                return
            }

            guard self.readFirmware() else {
                self.operationFailedMsg("Read Firmware Error", completeBlock: failedBlock)
                return
            }

            guard self.readSoftware() else {
                self.operationFailedMsg("Read Software Error", completeBlock: failedBlock)
                return
            }

            // 温湿度和光感需要同步时间
            if self.deviceType == .sht3x
                || self.deviceType == .lis3dhAndSht3x
                || self.deviceType == .light
                || self.deviceType == .threeAxisAndLight {
                guard self.syncTimeToDevice() else {
                    self.operationFailedMsg("Config Date Error", completeBlock: failedBlock)
                    return
                }
            }

            self.password = password

            DispatchQueue.main.async {
                sucBlock()
            }
        }
    }

    // MARK: - Private：连接

    /// 有密码连接（同步等待）
    private func connectDevice(_ peripheral: CBPeripheral,
                               password: String,
                               progressBlock: @escaping (Float) -> Void) -> [String: Any] {
        var connectResult: [String: Any] = [:]

        MKBXPCentralManager.shared.connectPeripheral(
            peripheral,
            password: password,
            progressBlock: progressBlock,
            sucBlock: { _ in
                connectResult = ["success": true]
                self.semaphore.signal()
            },
            failedBlock: { error in
                let msg = (error as NSError).userInfo["errorInfo"] as? String ?? ""
                connectResult = [
                    "success": false,
                    "msg": msg
                ]
                self.semaphore.signal()
            }
        )

        semaphore.wait()
        return connectResult
    }

    /// 免密连接（同步等待）
    private func connectDevice(_ peripheral: CBPeripheral,
                               progressBlock: @escaping (Float) -> Void) -> [String: Any] {
        var connectResult: [String: Any] = [:]

        MKBXPCentralManager.shared.connectPeripheral(
            peripheral,
            progressBlock: progressBlock,
            sucBlock: { _ in
                connectResult = ["success": true]
                self.semaphore.signal()
            },
            failedBlock: { error in
                let msg = (error as NSError).userInfo["errorInfo"] as? String ?? ""
                connectResult = [
                    "success": false,
                    "msg": msg
                ]
                self.semaphore.signal()
            }
        )

        semaphore.wait()
        return connectResult
    }

    // MARK: - Private：读取设备信息

    /// 读取设备类型
    private func readDeviceType() -> Bool {
        var success = false

        MKBXPInterface.bxp_readDeviceType { returnData in
            success = true
            if let result = returnData as? [String: Any],
               let innerResult = result["result"] as? [String: Any],
               var deviceType = innerResult["deviceType"] as? String {
                if deviceType.count > 2 {
                    deviceType = String(deviceType.suffix(2))
                }
                self.deviceType = MKBXPDeviceType(rawValue: deviceType) ?? .none
                self.passwordVerification = (MKBXPCentralManager.shared.lockState == .open)
            }
            self.semaphore.signal()
        } failedBlock: { _ in
            self.semaphore.signal()
        }

        semaphore.wait()
        return success
    }

    /// 读取生产日期
    private func readManuDate() -> Bool {
        var success = false

        MKBXPInterface.bxp_readProductionDate { returnData in
            success = true
            if let result = returnData as? [String: Any],
               let innerResult = result["result"] as? [String: Any],
               let date = innerResult["productionDate"] as? String {
                let cleanDate = date.replacingOccurrences(of: "/", with: "")
                MKBXPConnectManager.shared.newVersion = (Int(cleanDate) ?? 0) >= 20210101
            }
            self.semaphore.signal()
        } failedBlock: { _ in
            self.semaphore.signal()
        }

        semaphore.wait()
        return success
    }

    /// 读取固件版本
    private func readFirmware() -> Bool {
        var success = false

        MKBXPInterface.bxp_readFirmware { returnData in
            success = true
            if let result = returnData as? [String: Any],
               let innerResult = result["result"] as? [String: Any],
               let tempFirmware = innerResult["firmware"] as? String {
                if tempFirmware.contains("BXP-DH01") || tempFirmware.contains("BXP-DH_W7") {
                    self.tamperDetect = true
                } else if tempFirmware.contains("BXP-D04") {
                    self.tamperDetect = true
                    self.isBXPD04 = true
                }
                self.isBXPC = tempFirmware.contains("BXP-C")
                if let range = tempFirmware.range(of: "_V") {
                    self.firmware = String(tempFirmware[range.upperBound...])
                }
            }
            self.semaphore.signal()
        } failedBlock: { _ in
            self.semaphore.signal()
        }

        semaphore.wait()
        return success
    }

    /// 读取软件版本
    private func readSoftware() -> Bool {
        var success = false

        MKBXPInterface.bxp_readSoftware { returnData in
            success = true
            if let result = returnData as? [String: Any],
               let innerResult = result["result"] as? [String: Any],
               let software = innerResult["software"] as? String {
                self.software = software
            }
            self.semaphore.signal()
        } failedBlock: { _ in
            self.semaphore.signal()
        }

        semaphore.wait()
        return success
    }

    // MARK: - Private：同步时间

    /// 同步设备时间
    private func syncTimeToDevice() -> Bool {
        var success = false

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

        MKBXPInterface.bxp_configDeviceTime(dateModel) { _ in
            success = true
            self.semaphore.signal()
        } failedBlock: { _ in
            self.semaphore.signal()
        }

        semaphore.wait()
        return success
    }

    // MARK: - Private：失败处理

    private func operationFailedMsg(_ msg: String, completeBlock: ((Error) -> Void)?) {
        DispatchQueue.main.async {
            MKBXPCentralManager.shared.disconnect()
            self.clearParams()
            if let completeBlock = completeBlock {
                let error = NSError(domain: "connectDevice",
                                    code: -999,
                                    userInfo: ["errorInfo": msg])
                completeBlock(error)
            }
        }
    }
}
