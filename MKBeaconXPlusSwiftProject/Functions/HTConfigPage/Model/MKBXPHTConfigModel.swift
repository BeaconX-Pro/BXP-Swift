//
//  MKBXPHTConfigModel.swift
//  MKBeaconXPlusSwiftProject
//
//  Created by aa on 2026/9/18.
//

import Foundation
import MKBaseSwiftModule

// MARK: - 温湿度存储条件模型

/// 温湿度存储条件模型（实现 MKBXPHTStorageConditionsProtocol）
public final class MKBXPHTStorageConditionsModel: NSObject, MKBXPHTStorageConditionsProtocol {

    /// 存储条件
    public var condition: MKBXPHTStorageConditions = .temperature

    /// condition != .time 时有效，0~1000，代表 0°C ~ 100°C
    public var temperature: Int = 0

    /// condition != .time 时有效，0~1000，代表 0%~100%
    public var humidity: Int = 0

    /// condition == .time 时有效，1~255
    public var time: Int = 0

    public override init() {
        super.init()
    }
}

// MARK: - 温湿度配置模型

/// 温湿度配置模型
public final class MKBXPHTConfigModel: NSObject {

    /// 采样间隔
    public var samplingInterval: String = ""

    /// 日期，格式 "yyyy/MM/dd"
    public var date: String = ""

    /// 时间，格式 "HH:mm:ss"
    public var time: String = ""

    /// 当前存储的触发条件
    /// 0: 温度, 1: 湿度, 2: 温湿度, 3: 时间
    public var triggerType: Int = 0

    /// triggerType = 0 或 2 才有值
    public var temperature: String = ""

    /// triggerType = 1 或 2 才有值
    public var humidity: String = ""

    /// triggerType = 3 才有值
    public var storageTime: String = ""

    // MARK: - 私有

    private lazy var readQueue: DispatchQueue = {
        DispatchQueue(label: "HTConfigQueue")
    }()

    private lazy var semaphore: DispatchSemaphore = {
        DispatchSemaphore(value: 0)
    }()

    // MARK: - 公开方法

    /// 读取数据
    public func readData(sucBlock: @escaping () -> Void,
                         failedBlock: @escaping (Error) -> Void) {
        readQueue.async { [weak self] in
            guard let self = self else { return }
            guard self.readSamplingRate() else {
                self.operationFailedBlockWithMsg("Read Sampling Rate Error", block: failedBlock)
                return
            }
            guard self.readDeviceTime() else {
                self.operationFailedBlockWithMsg("Config Device Time Error", block: failedBlock)
                return
            }
            guard self.readHTStorageConditions() else {
                self.operationFailedBlockWithMsg("Read Storage Conditions Error", block: failedBlock)
                return
            }
            DispatchQueue.main.async {
                sucBlock()
            }
        }
    }

    /// 配置参数
    /// - Parameters:
    ///   - interval: 采样间隔
    ///   - conditionsModel: 存储条件模型
    ///   - sucBlock: 成功回调
    ///   - failedBlock: 失败回调
    public func configData(samplingInterval interval: Int,
                           triggerConditions conditionsModel: MKBXPHTStorageConditionsModel,
                           sucBlock: @escaping () -> Void,
                           failedBlock: @escaping (Error) -> Void) {
        readQueue.async { [weak self] in
            guard let self = self else { return }
            guard self.configSamplingRate(interval) else {
                self.operationFailedBlockWithMsg("Config Sampling Rate Error", block: failedBlock)
                return
            }
            guard self.configHTStorageConditions(conditionsModel) else {
                self.operationFailedBlockWithMsg("Config Storage Conditions Error", block: failedBlock)
                return
            }
            DispatchQueue.main.async {
                sucBlock()
            }
        }
    }

    // MARK: - Private：读取

    private func readSamplingRate() -> Bool {
        var success = false

        MKBXPInterface.bxp_readHTSamplingRate { [weak self] returnData in
            guard let self = self else {
                self?.semaphore.signal()
                return
            }
            success = true
            if let result = (returnData as? [String: Any])?["result"] as? [String: Any] {
                self.samplingInterval = result["samplingRate"] as? String ?? ""
            }
            self.semaphore.signal()
        } failedBlock: { [weak self] _ in
            self?.semaphore.signal()
        }

        semaphore.wait()
        return success
    }

    private func readDeviceTime() -> Bool {
        var success = false

        MKBXPInterface.bxp_readDeviceTime { [weak self] returnData in
            guard let self = self else {
                self?.semaphore.signal()
                return
            }
            success = true
            if let result = (returnData as? [String: Any])?["result"] as? [String: Any],
               let deviceTime = result["deviceTime"] as? String {
                let dateList = deviceTime.components(separatedBy: "-")
                if dateList.count >= 6 {
                    self.date = "\(dateList[2])/\(dateList[1])/\(dateList[0])"
                    self.time = "\(dateList[3]):\(dateList[4]):\(dateList[5])"
                }
            }
            self.semaphore.signal()
        } failedBlock: { [weak self] _ in
            self?.semaphore.signal()
        }

        semaphore.wait()
        return success
    }

    private func readTimeStamp() -> Bool {
        var success = false

        MKBXPInterface.bxp_readTimeStamp { [weak self] returnData in
            guard let self = self else {
                self?.semaphore.signal()
                return
            }
            success = true
            if let result = (returnData as? [String: Any])?["result"] as? [String: Any],
               let deviceTime = result["deviceTime"] as? String {
                let dateList = deviceTime.components(separatedBy: "-")
                if dateList.count >= 6 {
                    self.date = "\(dateList[2])/\(dateList[1])/\(dateList[0])"
                    self.time = "\(dateList[3]):\(dateList[4]):\(dateList[5])"
                }
            }
            self.semaphore.signal()
        } failedBlock: { [weak self] _ in
            self?.semaphore.signal()
        }

        semaphore.wait()
        return success
    }

    private func readHTStorageConditions() -> Bool {
        var success = false

        MKBXPInterface.bxp_readHTStorageConditions { [weak self] returnData in
            guard let self = self else {
                self?.semaphore.signal()
                return
            }
            success = true
            if let result = (returnData as? [String: Any])?["result"] as? [String: Any] {
                self.triggerType = Int(result["functionType"] as? String ?? "0") ?? 0
                self.temperature = result["temperature"] as? String ?? ""
                self.humidity = result["humidity"] as? String ?? ""
                self.storageTime = result["storageTime"] as? String ?? ""
            }
            self.semaphore.signal()
        } failedBlock: { [weak self] _ in
            self?.semaphore.signal()
        }

        semaphore.wait()
        return success
    }

    // MARK: - Private：配置

    private func configSamplingRate(_ interval: Int) -> Bool {
        var success = false

        MKBXPInterface.bxp_configHTSamplingRate(interval) { [weak self] _ in
            success = true
            self?.semaphore.signal()
        } failedBlock: { [weak self] _ in
            self?.semaphore.signal()
        }

        semaphore.wait()
        return success
    }

    private func configHTStorageConditions(_ conditionsModel: MKBXPHTStorageConditionsModel) -> Bool {
        var success = false

        MKBXPInterface.bxp_configHTStorageConditions(conditionsModel) { [weak self] _ in
            success = true
            self?.semaphore.signal()
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
            let error = NSError(domain: "HTConfig",
                                code: -999,
                                userInfo: ["errorInfo": msg])
            block(error)
        }
    }
}
