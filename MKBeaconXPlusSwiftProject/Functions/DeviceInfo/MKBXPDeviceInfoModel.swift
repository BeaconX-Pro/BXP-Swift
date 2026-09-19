//
//  MKBXPDeviceInfoModel.swift
//  MKBeaconXPlusSwiftProject
//
//  Created by aa on 2026/9/18.
//

import Foundation

import MKBaseSwiftModule

/// 设备信息模型
public final class MKBXPDeviceInfoModel: NSObject {

    /// 电池电量
    public var battery: String = ""

    /// mac 地址
    public var macAddress: String = ""

    /// 产品型号
    public var produce: String = ""

    /// 软件版本
    public var software: String = ""

    /// 固件版本
    public var firmware: String = ""

    /// 硬件版本
    public var hardware: String = ""

    /// 生产日期
    public var manuDate: String = ""

    /// 厂商信息
    public var manu: String = ""

    // MARK: - 私有

    private lazy var readQueue: DispatchQueue = {
        DispatchQueue(label: "deviceInfoParamsQueue")
    }()

    private lazy var semaphore: DispatchSemaphore = {
        DispatchSemaphore(value: 0)
    }()

    // MARK: - 公开方法

    /// 读取所有设备信息
    public func read(sucBlock: @escaping () -> Void,
                     failedBlock: @escaping (Error) -> Void) {
        readQueue.async { [weak self] in
            guard let self = self else { return }
            guard self.readBatteryPower() else {
                self.operationFailedBlockWithMsg("Read battery power error", block: failedBlock)
                return
            }
            guard self.readMacAddress() else {
                self.operationFailedBlockWithMsg("Read mac address error", block: failedBlock)
                return
            }
            guard self.readProduce() else {
                self.operationFailedBlockWithMsg("Read product model error", block: failedBlock)
                return
            }
            guard self.readSoftware() else {
                self.operationFailedBlockWithMsg("Read software error", block: failedBlock)
                return
            }
            guard self.readFirmware() else {
                self.operationFailedBlockWithMsg("Read firmware error", block: failedBlock)
                return
            }
            guard self.readHardware() else {
                self.operationFailedBlockWithMsg("Read hardware error", block: failedBlock)
                return
            }
            guard self.readManuDate() else {
                self.operationFailedBlockWithMsg("Read manufacture date error", block: failedBlock)
                return
            }
            guard self.readManu() else {
                self.operationFailedBlockWithMsg("Read manufacture error", block: failedBlock)
                return
            }

            DispatchQueue.main.async {
                sucBlock()
            }
        }
    }

    // MARK: - Private：读取接口

    private func readBatteryPower() -> Bool {
        var success = false
        MKBXPInterface.bxp_readBattery { [weak self] returnData in
            guard let self = self else {
                self?.semaphore.signal()
                return
            }
            success = true
            if let result = (returnData as? [String: Any])?["result"] as? [String: Any] {
                self.battery = result["battery"] as? String ?? ""
            }
            self.semaphore.signal()
        } failedBlock: { [weak self] _ in
            self?.semaphore.signal()
        }
        semaphore.wait()
        return success
    }

    private func readMacAddress() -> Bool {
        var success = false
        MKBXPInterface.bxp_readMacAddres { [weak self] returnData in
            guard let self = self else {
                self?.semaphore.signal()
                return
            }
            success = true
            if let result = (returnData as? [String: Any])?["result"] as? [String: Any] {
                self.macAddress = result["macAddress"] as? String ?? ""
            }
            self.semaphore.signal()
        } failedBlock: { [weak self] _ in
            self?.semaphore.signal()
        }
        semaphore.wait()
        return success
    }

    private func readProduce() -> Bool {
        var success = false
        MKBXPInterface.bxp_readModeID { [weak self] returnData in
            guard let self = self else {
                self?.semaphore.signal()
                return
            }
            success = true
            if let result = (returnData as? [String: Any])?["result"] as? [String: Any] {
                self.produce = result["modeID"] as? String ?? ""
            }
            self.semaphore.signal()
        } failedBlock: { [weak self] _ in
            self?.semaphore.signal()
        }
        semaphore.wait()
        return success
    }

    private func readSoftware() -> Bool {
        var success = false
        MKBXPInterface.bxp_readSoftware { [weak self] returnData in
            guard let self = self else {
                self?.semaphore.signal()
                return
            }
            success = true
            if let result = (returnData as? [String: Any])?["result"] as? [String: Any] {
                self.software = result["software"] as? String ?? ""
            }
            self.semaphore.signal()
        } failedBlock: { [weak self] _ in
            self?.semaphore.signal()
        }
        semaphore.wait()
        return success
    }

    private func readFirmware() -> Bool {
        var success = false
        MKBXPInterface.bxp_readFirmware { [weak self] returnData in
            guard let self = self else {
                self?.semaphore.signal()
                return
            }
            success = true
            if let result = (returnData as? [String: Any])?["result"] as? [String: Any] {
                self.firmware = result["firmware"] as? String ?? ""
            }
            self.semaphore.signal()
        } failedBlock: { [weak self] _ in
            self?.semaphore.signal()
        }
        semaphore.wait()
        return success
    }

    private func readHardware() -> Bool {
        var success = false
        MKBXPInterface.bxp_readHardware { [weak self] returnData in
            guard let self = self else {
                self?.semaphore.signal()
                return
            }
            success = true
            if let result = (returnData as? [String: Any])?["result"] as? [String: Any] {
                self.hardware = result["hardware"] as? String ?? ""
            }
            self.semaphore.signal()
        } failedBlock: { [weak self] _ in
            self?.semaphore.signal()
        }
        semaphore.wait()
        return success
    }

    private func readManuDate() -> Bool {
        var success = false
        MKBXPInterface.bxp_readProductionDate { [weak self] returnData in
            guard let self = self else {
                self?.semaphore.signal()
                return
            }
            success = true
            if let result = (returnData as? [String: Any])?["result"] as? [String: Any] {
                self.manuDate = result["productionDate"] as? String ?? ""
            }
            self.semaphore.signal()
        } failedBlock: { [weak self] _ in
            self?.semaphore.signal()
        }
        semaphore.wait()
        return success
    }

    private func readManu() -> Bool {
        var success = false
        MKBXPInterface.bxp_readVendor { [weak self] returnData in
            guard let self = self else {
                self?.semaphore.signal()
                return
            }
            success = true
            if let result = (returnData as? [String: Any])?["result"] as? [String: Any] {
                self.manu = result["vendor"] as? String ?? ""
            }
            self.semaphore.signal()
        } failedBlock: { [weak self] _ in
            self?.semaphore.signal()
        }
        semaphore.wait()
        return success
    }

    // MARK: - Private：失败处理

    private func operationFailedBlockWithMsg(_ msg: String,
                                             block: @escaping (Error) -> Void) {
        DispatchQueue.main.async {
            let error = NSError(domain: "deviceInformation",
                                code: -999,
                                userInfo: ["errorInfo": msg])
            block(error)
        }
    }
}
