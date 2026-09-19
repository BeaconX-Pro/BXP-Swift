//
//  MKBXPScanInfoCellModel.swift
//  MKBeaconXPlusSwiftProject
//
//  Created by aa on 2026/9/18.
//

import Foundation
@preconcurrency import CoreBluetooth

/// 扫描设备信息 Cell 模型
public final class MKBXPScanInfoCellModel: NSObject {

    /// 设备信息帧的广播数组，TLM、UID、URL、iBeacon、温湿度、三轴这些广播帧会被添加到对应的设备信息帧的广播数组里面来
    public lazy var advertiseList: [Any] = []

    /// peripheral 标识符，用来筛选当前设备列表是否已经存在某一个设备
    public var identifier: String = ""

    /// 上一次扫描到的时间
    public var lastScanDate: TimeInterval = 0

    // MARK: - MKBXScanInfoCellProtocol

    public var peripheral: CBPeripheral?

    /// 设备广播名称
    public var deviceName: String = ""

    /// 设备可连接状态
    public var connectable: Bool = false

    /// 信号值强度，会动态变化
    public var rssi: String = ""

    /// 记录本次扫到该设备距离上次扫到该设备的时间差，单位 ms
    public var displayTime: String = ""

    /// 设备是否有光感
    public var lightSensor: Bool = false

    /// lightSensor 必须为 true 才有效
    public var lightSensorStatus: Bool = false

    // MARK: - 设备信息帧属性

    /// dBm，当 lightSensor = true 时显示 lightSensorStatus，否则显示 rangingData
    public var rangingData: String = ""

    public var txPower: String = ""

    public var macAddress: String = ""

    /// 电池电压
    public var battery: String = ""

    /// 设备是否有防拆传感器
    public var tamperSensor: Bool = false

    /// 防拆状态，只有当 tamperSensor = true 才有效
    public var tamperAlert: Bool = false

    /// 设备是否处于 OTA 模式
    public var otaMode: Bool = false

    public var lockState: String = ""

    /// 广播间隔，单位：100ms
    public var interval: String = ""

    public var softVersion: String = ""

    public override init() {
        super.init()
    }
}
