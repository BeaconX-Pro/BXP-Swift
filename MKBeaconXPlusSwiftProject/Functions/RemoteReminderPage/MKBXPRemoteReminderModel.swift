//
//  MKBXPRemoteReminderModel.swift
//  MKBeaconXPlusSwiftProject
//
//  Created by aa on 2026/9/18.
//

import Foundation
import MKBaseSwiftModule

/// 远程提醒配置模型
public final class MKBXPRemoteReminderModel: NSObject {

    // MARK: - LED notification

    /// 0: Red, 1: Green, 2: Blue
    public var color: Int = 0

    public var blinkingTime: String = ""

    public var blinkingInterval: String = ""

    // MARK: - Buzzer notification

    public var frequent: String = ""

    public var ringingTime: String = ""

    public var ringingInterval: String = ""

    // MARK: - 私有

    private lazy var readQueue: DispatchQueue = {
        DispatchQueue(label: "ReminderQueue")
    }()

    private lazy var semaphore: DispatchSemaphore = {
        DispatchSemaphore(value: 0)
    }()

    // MARK: - 公开方法

    public func readData(sucBlock: @escaping () -> Void,
                         failedBlock: @escaping (Error) -> Void) {
        readQueue.async { [weak self] in
            guard let self = self else { return }
            guard self.readLEDParams() else {
                self.operationFailedBlockWithMsg("Read LED Params Error", block: failedBlock)
                return
            }
            guard self.readBuzzerParams() else {
                self.operationFailedBlockWithMsg("Read Buzzer Params Error", block: failedBlock)
                return
            }
            DispatchQueue.main.async {
                sucBlock()
            }
        }
    }

    // MARK: - Private：读取

    private func readLEDParams() -> Bool {
        var success = false

        MKBXPInterface.bxp_readRemoteReminderLEDNotiParams { [weak self] returnData in
            guard let self = self else {
                self?.semaphore.signal()
                return
            }
            success = true
            if let result = (returnData as? [String: Any])?["result"] as? [String: Any] {
                self.color = (Int(result["color"] as? String ?? "0") ?? 0) - 3
                self.blinkingTime = result["time"] as? String ?? ""
                self.blinkingInterval = result["interval"] as? String ?? ""
            }
            self.semaphore.signal()
        } failedBlock: { [weak self] _ in
            self?.semaphore.signal()
        }

        semaphore.wait()
        return success
    }

    private func readBuzzerParams() -> Bool {
        var success = false

        MKBXPInterface.bxp_readRemoteReminderBuzzerNotiParams { [weak self] returnData in
            guard let self = self else {
                self?.semaphore.signal()
                return
            }
            success = true
            if let result = (returnData as? [String: Any])?["result"] as? [String: Any] {
                self.frequent = result["frequent"] as? String ?? ""
                self.ringingTime = result["time"] as? String ?? ""
                self.ringingInterval = result["interval"] as? String ?? ""
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
            let error = NSError(domain: "ReminderParams",
                                code: -999,
                                userInfo: ["errorInfo": msg])
            block(error)
        }
    }
}
