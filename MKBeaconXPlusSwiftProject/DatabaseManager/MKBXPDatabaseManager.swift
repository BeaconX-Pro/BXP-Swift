//
//  MKBXPDatabaseManager.swift
//  MKBeaconXPlusSwiftProject
//
//  Created by aa on 2026/9/18.
//

import Foundation
import GRDB

/// 温湿度本地数据存储管理器（基于 GRDB 7）
public enum MKBXPDatabaseManager {

    // MARK: - 数据库路径与队列

    /// 数据库文件路径（对应 OC 的 kFilePath(@"HTDB")）
    /// - Note: OC 的 kFilePath 实际生成的路径需与旧版本兼容。若旧版使用无扩展名文件，
    ///         请将 "HTDB.sqlite" 改为 "HTDB" 以复用已有数据。
    private static var databasePath: String {
        let documentsPath = NSSearchPathForDirectoriesInDomains(.documentDirectory,
                                                                .userDomainMask,
                                                                true)[0]
        return (documentsPath as NSString).appendingPathComponent("HTDB.sqlite")
    }

    /// 数据库队列（懒加载，线程安全）
    /// - Note: `DatabaseQueue` 对应 OC 的 `FMDatabaseQueue`，串行化所有数据库访问
    private static let dbQueue: DatabaseQueue = {
        do {
            let queue = try DatabaseQueue(path: databasePath)
            try queue.write { db in
                try db.create(table: "HTDataTable", ifNotExists: true) { t in
                    t.column("temperature", .text)
                    t.column("humidity", .text)
                }
            }
            return queue
        } catch {
            // 与 OC 一致：初始化失败时后续操作会走 failedBlock
            // 此处用 fatalError 会崩溃，故改为打印日志并返回一个不可用的空队列
            // 实际调用时 catch 会捕获错误并回调 failedBlock
            NSLog("MKBXPDatabaseManager setup error: \(error)")
            // 返回一个内存数据库作为兜底，保证单例不为 nil；所有写读会失败并回调 failedBlock
            return try! DatabaseQueue()
        }
    }()

    // MARK: - 公开方法

    /// 批量插入温湿度数据
    /// - Parameters:
    ///   - htList: 温湿度字典数组，每项包含 "temperature" 和 "humidity"
    ///   - sucBlock: 成功回调（主线程）
    ///   - failedBlock: 失败回调（主线程）
    public static func insertDeviceList(_ htList: [[String: Any]],
                                        sucBlock: (() -> Void)?,
                                        failedBlock: ((Error) -> Void)?) {
        guard !htList.isEmpty else {
            operationInsertFailedBlock(failedBlock)
            return
        }

        do {
            try dbQueue.write { db in
                for data in htList {
                    let temperature = data["temperature"] as? String ?? ""
                    let humidity = data["humidity"] as? String ?? ""
                    try db.execute(
                        sql: "INSERT INTO HTDataTable (temperature, humidity) VALUES (?, ?)",
                        arguments: [temperature, humidity]
                    )
                }
            }
            DispatchQueue.main.async {
                sucBlock?()
            }
        } catch {
            operationInsertFailedBlock(failedBlock)
        }
    }

    /// 读取本地存储的温湿度数据
    /// - Parameters:
    ///   - sucBlock: 成功回调（主线程），返回温湿度数组
    ///   - failedBlock: 失败回调（主线程）
    public static func readLocalDevice(sucBlock: @escaping ([[String: Any]]) -> Void,
                                       failedBlock: ((Error) -> Void)?) {
        do {
            let dataList = try dbQueue.read { db -> [[String: Any]] in
                let rows = try Row.fetchAll(db, sql: "SELECT * FROM HTDataTable")
                return rows.map { row in
                    [
                        "temperature": row["temperature"] as? String ?? "",
                        "humidity": row["humidity"] as? String ?? ""
                    ]
                }
            }
            DispatchQueue.main.async {
                sucBlock(dataList)
            }
        } catch {
            operationGetDataFailedBlock(failedBlock)
        }
    }

    /// 删除所有温湿度数据
    /// - Parameters:
    ///   - sucBlock: 成功回调（主线程）
    ///   - failedBlock: 失败回调（主线程）
    public static func deleteDatas(sucBlock: (() -> Void)?,
                                   failedBlock: ((Error) -> Void)?) {
        do {
            try dbQueue.write { db in
                try db.execute(sql: "DELETE FROM HTDataTable")
            }
            DispatchQueue.main.async {
                sucBlock?()
            }
        } catch {
            operationDeleteFailedBlock(failedBlock)
        }
    }

    // MARK: - Private：失败回调

    private static func operationFailedBlock(_ block: ((Error) -> Void)?,
                                             msg: String) {
        guard let block = block else { return }
        let error = NSError(domain: "com.moko.databaseOperation",
                            code: -111111,
                            userInfo: ["errorInfo": msg])
        DispatchQueue.main.async {
            block(error)
        }
    }

    private static func operationInsertFailedBlock(_ block: ((Error) -> Void)?) {
        operationFailedBlock(block, msg: "insert data error")
    }

    private static func operationDeleteFailedBlock(_ block: ((Error) -> Void)?) {
        operationFailedBlock(block, msg: "fail to delete")
    }

    private static func operationGetDataFailedBlock(_ block: ((Error) -> Void)?) {
        operationFailedBlock(block, msg: "get data error")
    }
}
