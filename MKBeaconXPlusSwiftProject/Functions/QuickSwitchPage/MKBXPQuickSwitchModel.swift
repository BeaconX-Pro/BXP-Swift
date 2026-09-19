//
//  MKBXPQuickSwitchModel.swift
//  MKBeaconXPlusSwiftProject
//
//  Created by aa on 2026/9/18.
//

import Foundation
import MKBaseSwiftModule

/// 快速开关配置模型
public final class MKBXPQuickSwitchModel: NSObject {

    /// 是否可连接
    public var connectable: Bool = false

    /// 是否支持 LED 触发
    public var supportLED: Bool = false

    /// LED 触发状态
    public var triggerLED: Bool = false

    /// 是否支持按键关机
    public var turnOffByButton: Bool = false

    /// 是否支持按键恢复出厂设置
    public var supportResetByButton: Bool = false

    /// 按键恢复出厂设置状态
    public var resetByButton: Bool = false

    /// 密码验证状态
    public var passwordVerification: Bool = false

    /// 回应包开关状态（固件版本 V3.0.6 以后才支持该功能）
    public var scanPacket: Bool = false

    // MARK: - 私有

    private lazy var readQueue: DispatchQueue = {
        DispatchQueue(label: "quickSwitchQueue")
    }()

    private lazy var semaphore: DispatchSemaphore = {
        DispatchSemaphore(value: 0)
    }()

    // MARK: - 公开方法

    /// 固件版本 V3.0.6 以后才支持回应包功能
    public func supportScanPackage() -> Bool {
        let firmwareVersion = MKBXPConnectManager.shared.firmware
            .replacingOccurrences(of: ".", with: "")
            .replacingOccurrences(of: "V", with: "")
        return (Int(firmwareVersion) ?? 0) >= 306
    }

    /// 读取数据
    public func read(sucBlock: @escaping () -> Void,
                     failedBlock: @escaping (Error) -> Void) {
        readQueue.async { [weak self] in
            guard let self = self else { return }
            guard self.readConnectable() else {
                self.operationFailedBlockWithMsg("Read Connectable Error", block: failedBlock)
                return
            }
            // 注意：OC 中 readTriggerLED 没有检查返回值，读取失败也不影响整体流程
            _ = self.readTriggerLED()
            guard self.readTurnOffByButton() else {
                self.operationFailedBlockWithMsg("Read Turn off Beacon by button Error", block: failedBlock)
                return
            }
            // 注意：OC 中 readResetByButton 没有检查返回值
            _ = self.readResetByButton()
            self.passwordVerification = MKBXPConnectManager.shared.passwordVerification
            if self.supportScanPackage() {
                guard self.readScanPacket() else {
                    self.operationFailedBlockWithMsg("Read Scan Packet Error", block: failedBlock)
                    return
                }
            }
            DispatchQueue.main.async {
                sucBlock()
            }
        }
    }

    // MARK: - Private：读取

    private func readConnectable() -> Bool {
        var success = false

        MKBXPInterface.bxp_readConnectEnableStatus { [weak self] returnData in
            guard let self = self else {
                self?.semaphore.signal()
                return
            }
            success = true
            if let result = (returnData as? [String: Any])?["result"] as? [String: Any] {
                self.connectable = (result["connectEnable"] as? Bool) ?? false
            }
            self.semaphore.signal()
        } failedBlock: { [weak self] _ in
            self?.semaphore.signal()
        }

        semaphore.wait()
        return success
    }

    private func readTriggerLED() -> Bool {
        var success = false

        MKBXPInterface.bxp_readLEDTriggerStatus { [weak self] returnData in
            guard let self = self else {
                self?.semaphore.signal()
                return
            }
            success = true
            if let result = (returnData as? [String: Any])?["result"] as? [String: Any] {
                self.triggerLED = (result["isOn"] as? Bool) ?? false
                self.supportLED = true
            }
            self.semaphore.signal()
        } failedBlock: { [weak self] _ in
            self?.semaphore.signal()
        }

        semaphore.wait()
        return success
    }

    private func readTurnOffByButton() -> Bool {
        var success = false

        MKBXPInterface.bxp_readButtonPowerStatus { [weak self] returnData in
            guard let self = self else {
                self?.semaphore.signal()
                return
            }
            success = true
            if let result = (returnData as? [String: Any])?["result"] as? [String: Any] {
                self.turnOffByButton = (result["isOn"] as? Bool) ?? false
            }
            self.semaphore.signal()
        } failedBlock: { [weak self] _ in
            self?.semaphore.signal()
        }

        semaphore.wait()
        return success
    }

    private func readResetByButton() -> Bool {
        var success = false

        MKBXPInterface.bxp_readResetBeaconByButtonStatus { [weak self] returnData in
            guard let self = self else {
                self?.semaphore.signal()
                return
            }
            success = true
            if let result = (returnData as? [String: Any])?["result"] as? [String: Any] {
                self.resetByButton = (result["isOn"] as? Bool) ?? false
                self.supportResetByButton = true
            }
            self.semaphore.signal()
        } failedBlock: { [weak self] _ in
            self?.semaphore.signal()
        }

        semaphore.wait()
        return success
    }

    private func readScanPacket() -> Bool {
        var success = false

        MKBXPInterface.bxp_readScanResponsePacket { [weak self] returnData in
            guard let self = self else {
                self?.semaphore.signal()
                return
            }
            success = true
            if let result = (returnData as? [String: Any])?["result"] as? [String: Any] {
                self.scanPacket = (result["isOn"] as? Bool) ?? false
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
            let error = NSError(domain: "quickSwitchParams",
                                code: -999,
                                userInfo: ["errorInfo": msg])
            block(error)
        }
    }
}
