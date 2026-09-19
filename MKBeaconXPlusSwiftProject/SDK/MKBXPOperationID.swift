//
//  MKBXPOperationID.swift
//  MKBeaconXPlusSwiftProject
//
//  Created by aa on 2026/9/18.
//

import Foundation

/// BXP 通信任务 ID
public enum MKBXPTaskOperationID: Int {
    case `default` = 0

    // MARK: - eddystone 基础读取
    /// 读取厂商信息
    case readVendor
    /// 读取产品型号信息
    case readModeID
    /// 读取生产日期
    case readProductionDate
    /// 读取硬件信息
    case readHardware
    /// 读取固件信息
    case readFirmware
    /// 读取软件版本
    case readSoftware

    // MARK: - eddystone 配置读取
    /// 获取 capabilities 数据
    case readCapabilities
    /// 获取 activeSlot 数据
    case readActiveSlot
    /// 获取广播间隔
    case readAdvertisingInterval
    /// 获取发射功率
    case readRadioTxPower
    /// 获取广播功率
    case readAdvTxPower
    /// 获取 eddystone 的 lock 状态
    case readLockState
    case readUnlock
    case readPublicECDHKey
    case readEidIdentityKey
    case readAdvSlotData

    // MARK: - eddystone 配置写入
    /// 设置 activeSlot 数据
    case configActiveSlot
    /// 设置广播间隔
    case configAdvertisingInterval
    /// 设置发射功率
    case configRadioTxPower
    /// 设置广播功率
    case configAdvTxPower
    /// 设置 eddystone 的 lock 状态
    case configLockState
    case configUnlock
    case configPublicECDHKey
    case configEidIdentityKey
    case configAdvSlotData
    case configFactoryReset

    // MARK: - custom 读取
    /// 获取 eddystone 的 mac 地址
    case readMacAddress
    /// 读取三轴传感器参数
    case readThreeAxisParams
    /// 读取温湿度存储条件
    case readHTStorageConditions
    /// 读取温湿度采样率
    case readHTSamplingRate
    /// 删除已存储的温湿度数据
    case deleteRecordHTData
    /// 读取设备当前时间
    case readDeviceTime
    /// 关机命令
    case configPowerOff
    /// 读取按键关机状态
    case readButtonPowerStatus
    /// 读取触发条件
    case readTriggerConditions
    /// 读取回应包开关状态
    case readScanResponsePacket
    /// 设置三轴传感器参数
    case configThreeAxisParams
    /// 设置温湿度存储条件
    case configHTStorageConditions
    /// 设置温湿度采样率
    case configHTSamplingRate
    /// 设置设备当前时间
    case configDeviceTime
    /// 设置按键关机状态
    case configButtonPowerStatus
    /// 设置触发条件
    case configTriggerConditions
    /// 配置回应包开关状态
    case configScanResponsePacket
    /// 配置远程 LED 控制参数
    case configRemoteReminderLEDNotiParams
    /// 配置远程 buzzer 控制参数
    case configRemoteReminderBuzzerNotiParams
    /// 删除已存储的光感数据
    case deleteRecordLightSensorData
    /// 读取 LED 触发提醒状态
    case readLEDTriggerStatus
    /// 读取设备是否可以按键开关机
    case readResetBeaconByButtonStatus
    /// 读取按键间隔时长
    case readEffectiveClickInterval
    /// 读取当前 BXP-CL-a 设备的时间戳
    case readTimeStamp
    /// 设置 LED 触发提醒状态
    case configLEDTriggerStatus
    /// 设置设备是否可以按键开关机
    case configResetBeaconByButtonStatus
    /// 设置按键间隔时长
    case configEffectiveClickInterval
    /// 读取 LED 远程提醒参数
    case readRemoteReminderLEDNotiParams
    /// 读取 buzzer 远程提醒参数
    case readRemoteReminderBuzzerNotiParams

    // MARK: - 通道与连接
    /// 获取 eddystone 的通道类型
    case readSlotType
    /// 获取 eddystone 的可连接状态
    case readConnectEnable
    /// 设置 eddystone 的可连接状态
    case configConnectEnable

    // MARK: - 设备信息
    /// 读取 battery
    case readBattery
    /// 读取设备类型
    case readDeviceType

    /// 读取光感状态
    case readLightSensorStatus

    /// 读取 100 条历史数据（多包数据）
    case readHundredHistoryData
}
