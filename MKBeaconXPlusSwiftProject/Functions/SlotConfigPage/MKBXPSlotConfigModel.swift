//
//  MKBXPSlotConfigModel.swift
//  MKBeaconXPlusSwiftProject
//
//  Created by aa on 2026/9/18.
//

import Foundation
import MKBaseSwiftModule
import MKSwiftBeaconXCustomUI

/// Slot 配置模型
public final class MKBXPSlotConfigModel: NSObject {

    /// 所有通道类型列表（2025/08/26 新增需求：如果所有通道为 NO Data 则不允许设置）
    public var slotTypeList: [String] = []

    /// 通道 index
    public var slotIndex: Int = 0

    /// 数据通道类型
    public var slotType: MKSwiftBXSlotFrameType = .null

    /// 发射功率
    /// 0:-40dBm, 1:-20dBm, 2:-16dBm, 3:-12dBm, 4:-8dBm, 5:-4dBm, 6:0dBm, 7:3dBm, 8:4dBm
    public var txPower: Int = 0

    public var rssi0M: Int = 0

    public var advInterval: String = ""

    /// 当前通道广播的数据内容
    public var advSlotData: [String: Any] = [:]

    /// 触发条件
    public var triggerConditions: [String: Any] = [:]

    /// 触发条件是否打开
    public var triggerIsOn: Bool = false

    // MARK: - 私有

    private lazy var readQueue: DispatchQueue = {
        DispatchQueue(label: "slotConfigParamsQueue")
    }()

    private lazy var semaphore: DispatchSemaphore = {
        DispatchSemaphore(value: 0)
    }()

    /// 固件某个版本存在 bug：如果设置的广播间隔与当前值相同，则不再设置
    private var originAdvInterval: String = ""

    // MARK: - 公开方法

    /// 读取当前通道的广播参数
    public func read(sucBlock: @escaping () -> Void,
                     failedBlock: @escaping (Error) -> Void) {
        readQueue.async { [weak self] in
            guard let self = self else { return }
            guard self.readSlotTypeList() else {
                self.operationFailedBlockWithMsg("Read Slot Type List Error", block: failedBlock)
                return
            }
            guard self.configActiveSlot(self.slotIndex) else {
                self.operationFailedBlockWithMsg("Config Active Slot Error", block: failedBlock)
                return
            }
            if self.slotType == .null {
                DispatchQueue.main.async { sucBlock() }
                return
            }
            guard self.readTxPower() else {
                self.operationFailedBlockWithMsg("Read Tx Power Error", block: failedBlock)
                return
            }
            guard self.readRssi() else {
                self.operationFailedBlockWithMsg("Read RSSI Error", block: failedBlock)
                return
            }
            guard self.readAdvInterval() else {
                self.operationFailedBlockWithMsg("Read Adv Interval Error", block: failedBlock)
                return
            }
            guard self.readSlotAdvData() else {
                self.operationFailedBlockWithMsg("Read Slot Adv Data Error", block: failedBlock)
                return
            }
            guard self.readTriggerConditions() else {
                self.operationFailedBlockWithMsg("Read Trigger Conditions Error", block: failedBlock)
                return
            }
            DispatchQueue.main.async { sucBlock() }
        }
    }

    /// 配置当前通道参数
    public func configSlotParams(_ params: [String: Any],
                                  sucBlock: @escaping () -> Void,
                                  failedBlock: @escaping (Error) -> Void) {
        readQueue.async { [weak self] in
            guard let self = self else { return }
            guard self.configActiveSlot(self.slotIndex) else {
                self.operationFailedBlockWithMsg("Config Active Slot Error", block: failedBlock)
                return
            }
            if self.slotType == .null {
                guard self.configAdvNoDatas() else {
                    self.operationFailedBlockWithMsg("Config Adv Data Error", block: failedBlock)
                    return
                }
                DispatchQueue.main.async { sucBlock() }
                return
            }

            var advResult = false
            let advContent = params[MKSwiftBXSlotConfigKey.advContentType] as? [String: Any] ?? [:]
            switch self.slotType {
            case .beacon:
                advResult = self.configBeacon(advContent)
            case .uid:
                advResult = self.configUID(advContent)
            case .url:
                advResult = self.configURL(advContent)
            case .tlm:
                advResult = self.configTLM()
            case .info:
                advResult = self.configDeviceInfo(advContent)
            case .threeASensor:
                advResult = self.configThreeAxis()
            case .thSensor:
                advResult = self.configHTAdvData()
            default:
                break
            }

            guard advResult else {
                self.operationFailedBlockWithMsg("Config Adv Data Error", block: failedBlock)
                return
            }

            let advParams = params[MKSwiftBXSlotConfigKey.advParamType] as? [String: Any] ?? [:]
            _ = self.configTxPower(Int(advParams["txPower"] as? String ?? "0") ?? 0)
            if self.slotType != .tlm {
                _ = self.configRssi(Int(advParams["rssi"] as? String ?? "0") ?? 0)
            }
            let interval = advParams["interval"] as? String ?? ""
            if self.originAdvInterval != interval {
                _ = self.configAdvInterval(Int(interval) ?? 10)
            }

            let advTrigger = params[MKSwiftBXSlotConfigKey.advTriggerType] as? [String: Any] ?? [:]
            guard self.configTriggerConditions(advTrigger) else {
                self.operationFailedBlockWithMsg("Config Adv Trigger Error", block: failedBlock)
                return
            }
            DispatchQueue.main.async { sucBlock() }
        }
    }

    // MARK: - Private：读取接口

    private func readSlotTypeList() -> Bool {
        var success = false
        MKBXPInterface.bxp_readSlotDataType { [weak self] returnData in
            guard let self = self else {
                self?.semaphore.signal()
                return
            }
            success = true
            if let result = (returnData as? [String: Any])?["result"] as? [String: Any] {
                self.slotTypeList = result["slotTypeList"] as? [String] ?? []
                // ✅ 关键：根据 slotIndex 从 slotTypeList 中取出当前 slot 的帧类型
                if self.slotIndex >= 0 && self.slotIndex < self.slotTypeList.count {
                    let typeStr = self.slotTypeList[self.slotIndex]
                    self.slotType = MKSwiftBXSlotDataAdopter.fetchSlotFrameType(typeStr)
                }
            }
            self.semaphore.signal()
        } failedBlock: { [weak self] _ in
            // 注意 OC 中失败时也设置 success = YES
            success = true
            self?.semaphore.signal()
        }
        semaphore.wait()
        return success
    }

    private func configActiveSlot(_ slotIndex: Int) -> Bool {
        var success = false
        let slotNo = MKBXPActiveSlotNo(rawValue: slotIndex) ?? .slot1
        MKBXPInterface.bxp_configActiveSlot(slotNo) { [weak self] _ in
            success = true
            self?.semaphore.signal()
        } failedBlock: { [weak self] _ in
            self?.semaphore.signal()
        }
        semaphore.wait()
        return success
    }

    private func readTxPower() -> Bool {
        var success = false
        MKBXPInterface.bxp_readRadioTxPower { [weak self] returnData in
            guard let self = self else {
                self?.semaphore.signal()
                return
            }
            success = true
            if let result = (returnData as? [String: Any])?["result"] as? [String: Any],
               let power = result["radioTxPower"] as? String {
                self.txPower = self.getTxPowerValue(power)
            }
            self.semaphore.signal()
        } failedBlock: { [weak self] _ in
            self?.semaphore.signal()
        }
        semaphore.wait()
        return success
    }

    private func configTxPower(_ txPower: Int) -> Bool {
        var success = false
        let power = MKBXPSlotRadioTxPower(rawValue: txPower) ?? .neg40dBm
        MKBXPInterface.bxp_configRadioTxPower(power) { [weak self] _ in
            success = true
            self?.semaphore.signal()
        } failedBlock: { [weak self] _ in
            self?.semaphore.signal()
        }
        semaphore.wait()
        return success
    }

    private func readRssi() -> Bool {
        var success = false
        MKBXPInterface.bxp_readAdvTxPower { [weak self] returnData in
            guard let self = self else {
                self?.semaphore.signal()
                return
            }
            success = true
            if let result = (returnData as? [String: Any])?["result"] as? [String: Any],
               let advTxPower = result["advTxPower"] as? String {
                self.rssi0M = Int(advTxPower) ?? 0
            }
            self.semaphore.signal()
        } failedBlock: { [weak self] _ in
            self?.semaphore.signal()
        }
        semaphore.wait()
        return success
    }

    private func configRssi(_ rssi: Int) -> Bool {
        var success = false
        MKBXPInterface.bxp_configAdvTxPower(rssi) { [weak self] _ in
            success = true
            self?.semaphore.signal()
        } failedBlock: { [weak self] _ in
            self?.semaphore.signal()
        }
        semaphore.wait()
        return success
    }

    private func readAdvInterval() -> Bool {
        var success = false
        MKBXPInterface.bxp_readAdvInterval { [weak self] returnData in
            guard let self = self else {
                self?.semaphore.signal()
                return
            }
            success = true
            if let result = (returnData as? [String: Any])?["result"] as? [String: Any],
               let intervalStr = result["advertisingInterval"] as? String {
                let tempInterval = (Int(intervalStr) ?? 0) / 100
                self.advInterval = "\(tempInterval)"
                self.originAdvInterval = "\(tempInterval)"
            }
            self.semaphore.signal()
        } failedBlock: { [weak self] _ in
            self?.semaphore.signal()
        }
        semaphore.wait()
        return success
    }

    private func configAdvInterval(_ interval: Int) -> Bool {
        var success = false
        MKBXPInterface.bxp_configAdvInterval(interval) { [weak self] _ in
            success = true
            self?.semaphore.signal()
        } failedBlock: { [weak self] _ in
            self?.semaphore.signal()
        }
        semaphore.wait()
        return success
    }

    private func readSlotAdvData() -> Bool {
        var success = false
        MKBXPInterface.bxp_readAdvData { [weak self] returnData in
            guard let self = self else {
                self?.semaphore.signal()
                return
            }
            success = true
            if let result = (returnData as? [String: Any])?["result"] as? [String: Any] {
                self.advSlotData = result
            }
            self.semaphore.signal()
        } failedBlock: { [weak self] _ in
            self?.semaphore.signal()
        }
        semaphore.wait()
        return success
    }

    private func readTriggerConditions() -> Bool {
        var success = false
        MKBXPInterface.bxp_readTriggerConditions { [weak self] returnData in
            guard let self = self else {
                self?.semaphore.signal()
                return
            }
            success = true
            if let result = (returnData as? [String: Any])?["result"] as? [String: Any] {
                self.triggerConditions = result
                let type = result["type"] as? String ?? "00"
                self.triggerIsOn = (type != "00")
            }
            self.semaphore.signal()
        } failedBlock: { [weak self] _ in
            self?.semaphore.signal()
        }
        semaphore.wait()
        return success
    }

    // MARK: - Private：广播通道设置

    private func configAdvNoDatas() -> Bool {
        var success = false
        MKBXPInterface.bxp_configNODATAAdvData { [weak self] _ in
            success = true
            self?.semaphore.signal()
        } failedBlock: { [weak self] _ in
            self?.semaphore.signal()
        }
        semaphore.wait()
        return success
    }

    private func configBeacon(_ dic: [String: Any]) -> Bool {
        var success = false
        let major = Int(dic["major"] as? String ?? "0") ?? 0
        let minor = Int(dic["minor"] as? String ?? "0") ?? 0
        let uuid = dic["uuid"] as? String ?? ""
        MKBXPInterface.bxp_configiBeaconAdvData(major: major, minor: minor, uuid: uuid) { [weak self] _ in
            success = true
            self?.semaphore.signal()
        } failedBlock: { [weak self] _ in
            self?.semaphore.signal()
        }
        semaphore.wait()
        return success
    }

    private func configUID(_ dic: [String: Any]) -> Bool {
        var success = false
        let nameSpace = dic["nameSpace"] as? String ?? ""
        let instanceID = dic["instanceID"] as? String ?? ""
        MKBXPInterface.bxp_configUIDAdvDataWithNameSpace(nameSpace, instanceID: instanceID) { [weak self] _ in
            success = true
            self?.semaphore.signal()
        } failedBlock: { [weak self] _ in
            self?.semaphore.signal()
        }
        semaphore.wait()
        return success
    }

    private func configURL(_ dic: [String: Any]) -> Bool {
        var success = false
        var headerType: MKBXPURLHeaderType = .type1
        let urlHeader = dic["urlHeader"] as? String ?? ""
        if urlHeader == "https://www." {
            headerType = .type2
        } else if urlHeader == "http://" {
            headerType = .type3
        } else if urlHeader == "https://" {
            headerType = .type4
        }
        let urlContent = (dic["urlContent"] as? String ?? "") + (dic["urlExpansion"] as? String ?? "")
        MKBXPInterface.bxp_configURLAdvData(headerType, urlContent: urlContent) { [weak self] _ in
            success = true
            self?.semaphore.signal()
        } failedBlock: { [weak self] _ in
            self?.semaphore.signal()
        }
        semaphore.wait()
        return success
    }

    private func configTLM() -> Bool {
        var success = false
        MKBXPInterface.bxp_configTLMAdvData { [weak self] _ in
            success = true
            self?.semaphore.signal()
        } failedBlock: { [weak self] _ in
            self?.semaphore.signal()
        }
        semaphore.wait()
        return success
    }

    private func configDeviceInfo(_ dic: [String: Any]) -> Bool {
        var success = false
        let deviceName = dic["deviceName"] as? String ?? ""
        MKBXPInterface.bxp_configDeviceInfoAdvData(deviceName: deviceName) { [weak self] _ in
            success = true
            self?.semaphore.signal()
        } failedBlock: { [weak self] _ in
            self?.semaphore.signal()
        }
        semaphore.wait()
        return success
    }

    private func configThreeAxis() -> Bool {
        var success = false
        MKBXPInterface.bxp_configThreeAxisAdvData { [weak self] _ in
            success = true
            self?.semaphore.signal()
        } failedBlock: { [weak self] _ in
            self?.semaphore.signal()
        }
        semaphore.wait()
        return success
    }

    private func configHTAdvData() -> Bool {
        var success = false
        MKBXPInterface.bxp_configHTAdvData { [weak self] _ in
            success = true
            self?.semaphore.signal()
        } failedBlock: { [weak self] _ in
            self?.semaphore.signal()
        }
        semaphore.wait()
        return success
    }

    // MARK: - Private：触发设置

    private func configTriggerConditions(_ conditions: [String: Any]) -> Bool {
        let isOn = conditions["isOn"] as? Bool ?? false
        guard isOn else {
            return closeTrigger()
        }
        guard let triggerParams = conditions["triggerParams"] as? [String: Any] else {
            return false
        }
        let triggerType = triggerParams["triggerType"] as? String ?? "00"
        let subConditions = triggerParams["conditions"] as? [String: Any] ?? [:]

        switch triggerType {
        case "01":
            return configTriggerTemperature(above: subConditions["above"] as? Bool ?? false,
                                            temperature: Int(subConditions["temperature"] as? String ?? "0") ?? 0,
                                            start: subConditions["start"] as? Bool ?? false)
        case "02":
            return configTriggerHumidity(above: subConditions["above"] as? Bool ?? false,
                                         humidity: Int(subConditions["humidity"] as? String ?? "0") ?? 0,
                                         start: subConditions["start"] as? Bool ?? false)
        case "03":
            return configTriggerDoubleTap(time: Int(subConditions["time"] as? String ?? "0") ?? 0,
                                          start: subConditions["start"] as? Bool ?? false)
        case "04":
            return configTriggerTripleTap(time: Int(subConditions["time"] as? String ?? "0") ?? 0,
                                          start: subConditions["start"] as? Bool ?? false)
        case "05":
            return configTriggerMoves(time: Int(subConditions["time"] as? String ?? "0") ?? 0,
                                      start: subConditions["start"] as? Bool ?? false)
        case "06":
            return configTriggerLight(time: Int(subConditions["time"] as? String ?? "0") ?? 0,
                                      start: subConditions["start"] as? Bool ?? false)
        case "07":
            return configTriggerSingle(time: Int(subConditions["time"] as? String ?? "0") ?? 0,
                                       start: subConditions["start"] as? Bool ?? false)
        case "08":
            return configTriggerTamperDetect(time: Int(subConditions["time"] as? String ?? "0") ?? 0,
                                              start: subConditions["start"] as? Bool ?? false)
        default:
            return false
        }
    }

    private func closeTrigger() -> Bool {
        var success = false
        MKBXPInterface.bxp_configTriggerConditionsNone { [weak self] _ in
            success = true
            self?.semaphore.signal()
        } failedBlock: { [weak self] _ in
            self?.semaphore.signal()
        }
        semaphore.wait()
        return success
    }

    private func configTriggerTemperature(above: Bool, temperature: Int, start: Bool) -> Bool {
        var success = false
        MKBXPInterface.bxp_configTriggerConditionsWithTemperature(above: above,
                                                                  temperature: temperature,
                                                                  startAdvertising: start) { [weak self] _ in
            success = true
            self?.semaphore.signal()
        } failedBlock: { [weak self] _ in
            self?.semaphore.signal()
        }
        semaphore.wait()
        return success
    }

    private func configTriggerHumidity(above: Bool, humidity: Int, start: Bool) -> Bool {
        var success = false
        MKBXPInterface.bxp_configTriggerConditionsWithHudimity(above: above,
                                                               humidity: humidity,
                                                               startAdvertising: start) { [weak self] _ in
            success = true
            self?.semaphore.signal()
        } failedBlock: { [weak self] _ in
            self?.semaphore.signal()
        }
        semaphore.wait()
        return success
    }

    private func configTriggerDoubleTap(time: Int, start: Bool) -> Bool {
        var success = false
        MKBXPInterface.bxp_configTriggerConditionsWithDoubleTap(time, start: start) { [weak self] _ in
            success = true
            self?.semaphore.signal()
        } failedBlock: { [weak self] _ in
            self?.semaphore.signal()
        }
        semaphore.wait()
        return success
    }

    private func configTriggerTripleTap(time: Int, start: Bool) -> Bool {
        var success = false
        MKBXPInterface.bxp_configTriggerConditionsWithTripleTap(time, start: start) { [weak self] _ in
            success = true
            self?.semaphore.signal()
        } failedBlock: { [weak self] _ in
            self?.semaphore.signal()
        }
        semaphore.wait()
        return success
    }

    private func configTriggerMoves(time: Int, start: Bool) -> Bool {
        var success = false
        MKBXPInterface.bxp_configTriggerConditionsWithMoves(time, start: start) { [weak self] _ in
            success = true
            self?.semaphore.signal()
        } failedBlock: { [weak self] _ in
            self?.semaphore.signal()
        }
        semaphore.wait()
        return success
    }

    private func configTriggerLight(time: Int, start: Bool) -> Bool {
        var success = false
        MKBXPInterface.bxp_configTriggerConditionsWithAmbientLightDetected(time, start: start) { [weak self] _ in
            success = true
            self?.semaphore.signal()
        } failedBlock: { [weak self] _ in
            self?.semaphore.signal()
        }
        semaphore.wait()
        return success
    }

    private func configTriggerSingle(time: Int, start: Bool) -> Bool {
        var success = false
        MKBXPInterface.bxp_configTriggerConditionsWithSingleTap(time, start: start) { [weak self] _ in
            success = true
            self?.semaphore.signal()
        } failedBlock: { [weak self] _ in
            self?.semaphore.signal()
        }
        semaphore.wait()
        return success
    }

    private func configTriggerTamperDetect(time: Int, start: Bool) -> Bool {
        var success = false
        MKBXPInterface.bxp_configTriggerConditionsWithTamperDetect(time, start: start) { [weak self] _ in
            success = true
            self?.semaphore.signal()
        } failedBlock: { [weak self] _ in
            self?.semaphore.signal()
        }
        semaphore.wait()
        return success
    }

    // MARK: - Private：工具方法

    private func getTxPowerValue(_ power: String) -> Int {
        switch power {
        case "-40dBm": return 0
        case "-20dBm": return 1
        case "-16dBm": return 2
        case "-12dBm": return 3
        case "-8dBm": return 4
        case "-4dBm": return 5
        case "0dBm": return 6
        case "3dBm": return 7
        case "4dBm": return 8
        default: return 0
        }
    }

    private func operationFailedBlockWithMsg(_ msg: String,
                                             block: @escaping (Error) -> Void) {
        DispatchQueue.main.async {
            let error = NSError(domain: "slotConfigParams",
                                code: -999,
                                userInfo: ["errorInfo": msg])
            block(error)
        }
    }
}
