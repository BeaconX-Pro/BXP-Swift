//
//  MKBXPD04DFUModule.swift
//  MKBeaconXPlusSwiftProject
//
//  Created by aa on 2026/9/18.
//

import Foundation
@preconcurrency import CoreBluetooth
import NordicDFU

/// BXP-D04 专用 DFU 升级模块
/// 与标准 DFU 的区别：需要先断开连接，等待 4 秒后重新连接，再启动 DFU
public final class MKBXPD04DFUModule: NSObject {

    private static let dfuUpdateDomain = "com.moko.dfuUpdateDomain"

    private var progressBlock: ((Float) -> Void)?
    private var updateSucBlock: (() -> Void)?
    private var updateFailedBlock: ((Error) -> Void)?

    private var dfuController: DFUServiceController?
    private var peripheral: CBPeripheral?

    deinit {
        NSLog("MKBXPD04DFUModule销毁")
    }

    // MARK: - Public

    /// 开始 DFU 升级
    public func updateWithFileUrl(_ url: String,
                                   progressBlock: @escaping (Float) -> Void,
                                   sucBlock: @escaping () -> Void,
                                   failedBlock: @escaping (Error) -> Void) {
        guard !url.isEmpty else {
            operationFailedBlock(failedBlock, msg: "The url is invalid!")
            return
        }
        guard let zipData = try? Data(contentsOf: URL(fileURLWithPath: url)) else {
            operationFailedBlock(failedBlock, msg: "Dfu upgrade failure!")
            return
        }
        guard let selectedFirmware = try? DFUFirmware(zipFile: zipData) else {
            operationFailedBlock(failedBlock, msg: "Dfu upgrade failure!")
            return
        }

        self.peripheral = MKBXPCentralManager.shared.peripheral()
        // 先断开连接
        MKBXPCentralManager.shared.disconnect()
        // 等待短暂时间后重新连接
        DispatchQueue.main.asyncAfter(deadline: .now() + 4.0) { [weak self] in
            guard let self = self, let peripheral = self.peripheral else {
                self?.operationFailedBlock(failedBlock, msg: "Dfu upgrade failure!")
                return
            }
            MKBXPCentralManager.shared.dfuconnectPeripheral(peripheral) { [weak self] _ in
                guard let self = self else { return }
                self.progressBlock = progressBlock
                self.updateSucBlock = sucBlock
                self.updateFailedBlock = failedBlock
                self.startDFUProcess(selectedFirmware)
            } failedBlock: { [weak self] _ in
                self?.operationFailedBlock(failedBlock, msg: "Dfu upgrade failure!")
            }
        }
    }

    // MARK: - Private

    private func startDFUProcess(_ selectedFirmware: DFUFirmware) {
        let queue = DispatchQueue.global(qos: .default)
        let initiator = DFUServiceInitiator(queue: queue,
                                             delegateQueue: queue,
                                             progressQueue: queue,
                                             loggerQueue: queue,
                                             centralManagerOptions: [:])
        _ = initiator.with(firmware: selectedFirmware)
        initiator.logger = self
        initiator.delegate = self
        initiator.progressDelegate = self

        guard let peripheral = MKBXPCentralManager.shared.peripheral() else {
            operationFailedBlock(updateFailedBlock, msg: "Dfu upgrade failure!")
            return
        }
        self.dfuController = initiator.start(target: peripheral)
    }

    private func operationFailedBlock(_ failedBlock: ((Error) -> Void)?,
                                      msg: String) {
        DispatchQueue.main.async {
            guard let failedBlock = failedBlock else { return }
            let error = NSError(domain: Self.dfuUpdateDomain,
                                code: -999,
                                userInfo: ["errorInfo": msg])
            failedBlock(error)
        }
    }
}

// MARK: - DFUServiceDelegate

extension MKBXPD04DFUModule: DFUServiceDelegate {
    public func dfuStateDidChange(to state: DFUState) {
        if state == .completed {
            DispatchQueue.main.async {
                self.updateSucBlock?()
            }
        }
        if state == .uploading {
            MKBXPCentralManager.sharedDealloc()
        }
    }

    public func dfuError(_ error: DFUError,
                         didOccurWithMessage message: String) {
        operationFailedBlock(updateFailedBlock, msg: message)
    }
}

// MARK: - DFUProgressDelegate

extension MKBXPD04DFUModule: DFUProgressDelegate {
    public func dfuProgressDidChange(for part: Int,
                                     outOf totalParts: Int,
                                     to progress: Int,
                                     currentSpeedBytesPerSecond: Double,
                                     avgSpeedBytesPerSecond: Double) {
        let currentProgress = Float(progress) / Float(totalParts)
        DispatchQueue.main.async {
            self.progressBlock?(currentProgress)
        }
    }
}

// MARK: - LoggerDelegate

extension MKBXPD04DFUModule: LoggerDelegate {
    public func logWith(_ level: LogLevel, message: String) {
        NSLog("DFU logWith \(level.rawValue): \(message)")
    }
}
