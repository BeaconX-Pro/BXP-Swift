//
//  MKBXDAdopter.swift
//  MKBeaconXPlusSwiftProject
//
//  Created by aa on 2026/9/18.
//

import Foundation
import MKSwiftBleModule
import CommonCrypto

/// BXP 协议参数解析工具(对应 OC MKBXPAdopter)
public enum MKBXPAdopter {

    /// 校验密码长度(1~16 字符)
    public static func isPassword(_ password: String) -> Bool {
        guard !password.isEmpty, password.count <= 16 else {
            return false
        }
        return true
    }

    /// 校验 URL 是否合法
    private static func checkUrl(_ url: String) -> Bool {
        let regex = "[a-zA-z]+://[^\\s]*"
        let predicate = NSPredicate(format: "SELF MATCHES %@", regex)
        return predicate.evaluate(with: url)
    }

    /// 校验 namespace 是否合法(20 位十六进制)
    public static func isNameSpace(_ nameSpace: String) -> Bool {
        let regex = "^[a-fA-F0-9]{20}$"
        let predicate = NSPredicate(format: "SELF MATCHES %@", regex)
        return predicate.evaluate(with: nameSpace)
    }

    /// 校验 instanceID 是否合法(12 位十六进制)
    public static func isInstanceID(_ instanceID: String) -> Bool {
        let regex = "^[a-fA-F0-9]{12}$"
        let predicate = NSPredicate(format: "SELF MATCHES %@", regex)
        return predicate.evaluate(with: instanceID)
    }

    /// 校验 URL 内容是否合法(不能是预定义的纯后缀)
    public static func checkUrlContent(_ urlContent: String) -> Bool {
        guard !urlContent.isEmpty else {
            return false
        }
        let contentList = [".com/", ".org/", ".edu/", ".net/", ".info/", ".biz/", ".gov/",
                           ".com", ".org", ".edu", ".net", ".info", ".biz", ".gov"]
        return !contentList.contains(urlContent)
    }

    /// URL scheme 字符转可读字符串
    public static func getUrlscheme(_ hexChar: CChar) -> String {
        switch hexChar {
        case 0x00: return "http://www."
        case 0x01: return "https://www."
        case 0x02: return "http://"
        case 0x03: return "https://"
        default:   return ""
        }
    }

    /// URL encoded 字符转可读字符串
    public static func getEncodedString(_ hexChar: CChar) -> String {
        switch hexChar {
        case 0x00: return ".com/"
        case 0x01: return ".org/"
        case 0x02: return ".edu/"
        case 0x03: return ".net/"
        case 0x04: return ".info/"
        case 0x05: return ".biz/"
        case 0x06: return ".gov/"
        case 0x07: return ".com"
        case 0x08: return ".org"
        case 0x09: return ".edu"
        case 0x0a: return ".net"
        case 0x0b: return ".info"
        case 0x0c: return ".biz"
        case 0x0d: return ".gov"
        default:
            // OC: [NSString stringWithFormat:@"%c", hexChar]
            return String(UnicodeScalar(UInt8(bitPattern: hexChar)))
        }
    }

    /// AES128 加密(对应 OC AES128EncryptWithSourceData:keyData:)
    /// - Note: OC 在 key 长度不为 16 或加密失败时返回 nil;Swift 以 Optional 表达同一语义
    public static func aes128Encrypt(sourceData: Data, keyData: Data) -> Data? {
        guard keyData.count == 16 else {
            return nil
        }
        var paddedData = sourceData
        let dataLength = paddedData.count
        let excess = dataLength % 16
        if excess != 0 {
            let padding = 16 - excess
            paddedData.append(Data(repeating: 0, count: padding))
        }
        let totalLength = paddedData.count

        var returnData = Data()
        let bufferSize = 16
        var start = 0
        while start < totalLength {
            let end = start + bufferSize
            let chunk = paddedData.subdata(in: start..<end)
            var buffer = Data(count: bufferSize)
            var numBytesDecrypted = 0
            var status: CCCryptorStatus = 0
            chunk.withUnsafeBytes { chunkPtr in
                keyData.withUnsafeBytes { keyPtr in
                    buffer.withUnsafeMutableBytes { bufferPtr in
                        status = CCCrypt(
                            CCOperation(kCCEncrypt),
                            CCAlgorithm(kCCAlgorithmAES128),
                            CCOptions(0),
                            keyPtr.baseAddress,
                            kCCKeySizeAES128,
                            nil,
                            chunkPtr.baseAddress,
                            bufferSize,
                            bufferPtr.baseAddress,
                            bufferSize,
                            &numBytesDecrypted
                        )
                    }
                }
            }
            if status == kCCSuccess {
                returnData.append(buffer.prefix(numBytesDecrypted))
            }
            start += bufferSize
        }
        return returnData
    }

    /// 生成 unlock key(对应 OC fetchKeyToUnlockWithPassword:randKey:)
    /// - Note: OC 在参数非法或加密失败时返回 nil;Swift 以 Optional 表达同一语义
    public static func fetchKeyToUnlock(password: String, randKey: Data) -> Data? {
        guard !password.isEmpty, password.count <= 16, randKey.count == 16 else {
            return nil
        }
        let supplementByte: [UInt8] = Array(repeating: 0xff, count: 16)
        // 与 OC 完全一致:逐字符按 ASCII 取 hex 拼接,再走 hex 字符串转 Data
        var tempString = ""
        for scalar in password.unicodeScalars {
            tempString += String(format: "%lx", UInt(scalar.value))
        }
        let passwordData = MKSwiftBleSDKAdopter.stringToData(tempString)
        let supplement = Data(supplementByte.prefix(max(0, 16 - passwordData.count)))
        var aesKeyData = Data()
        aesKeyData.append(passwordData)
        aesKeyData.append(supplement)
        return aes128Encrypt(sourceData: randKey, keyData: aesKeyData)
    }

    /// 拼接完整 URL 字符串(对应 OC fetchUrlStringWithHeader:urlContent:)
    public static func fetchUrlString(header: String, urlContent: String) -> String {
        let url = header + urlContent
        if checkUrl(url) {
            // 合法的 url
            return getUrlIllegalContent(urlContent) ?? ""
        }
        // 不合法
        if urlContent.count > 17 || urlContent.count < 2 {
            return ""
        }
        var content = ""
        for scalar in urlContent.unicodeScalars {
            content += String(format: "%lx", UInt(scalar.value))
        }
        return content
    }

    // MARK: - private

    /// URL 后缀转 hex 编码(对应 OC getUrlIllegalContent:)
    private static func getUrlIllegalContent(_ urlContent: String) -> String? {
        guard !urlContent.isEmpty else {
            return nil
        }
        let tempList = urlContent.components(separatedBy: ".")
        guard !tempList.isEmpty else {
            return nil
        }
        var content = ""
        if let expansion = getExpansionHex("." + (tempList.last ?? "")),
           !expansion.isEmpty {
            // 符合官方要求的后缀名
            var tempString = ""
            for i in 0..<(tempList.count - 1) {
                tempString += ".\(tempList[i])"
            }
            if !tempString.isEmpty {
                tempString.removeFirst()
            }
            if tempString.count > 16 || tempString.count < 1 {
                return nil
            }
            for scalar in tempString.unicodeScalars {
                content += String(format: "%lx", UInt(scalar.value))
            }
            content += expansion
        } else {
            // 不符合官方要求的后缀名
            if urlContent.count > 17 || urlContent.count < 2 {
                return nil
            }
            for scalar in urlContent.unicodeScalars {
                content += String(format: "%lx", UInt(scalar.value))
            }
        }
        return content
    }

    /// 后缀名转 hex(对应 OC getExpansionHex:)
    private static func getExpansionHex(_ expansion: String) -> String? {
        guard !expansion.isEmpty else {
            return nil
        }
        switch expansion {
        case ".com/": return "00"
        case ".org/": return "01"
        case ".edu/": return "02"
        case ".net/": return "03"
        case ".info/": return "04"
        case ".biz/":  return "05"
        case ".gov/":  return "06"
        case ".com":   return "07"
        case ".org":   return "08"
        case ".edu":   return "09"
        case ".net":   return "0a"
        case ".info":  return "0b"
        case ".biz":   return "0c"
        case ".gov":   return "0d"
        default:       return nil
        }
    }

    /// 发射功率 hex 转可读字符串(对应 OC fetchTxPowerWithContent:)
    public static func fetchTxPower(content: String) -> String {
        guard !content.isEmpty, content.count == 2 else {
            return ""
        }
        switch content {
        case "04": return "4dBm"
        case "03": return "3dBm"
        case "00": return "0dBm"
        case "fc": return "-4dBm"
        case "f8": return "-8dBm"
        case "f4": return "-12dBm"
        case "f0": return "-16dBm"
        case "ec": return "-20dBm"
        case "d8": return "-40dBm"
        default:  return ""
        }
    }

    /// RSSI 解析(对应 OC fetchRSSIWithContent:)
    public static func fetchRSSI(contentData: Data) -> NSNumber {
        guard !contentData.isEmpty else {
            return NSNumber(value: 0)
        }
        var txPowerChar: UInt8 = 0
        contentData.withUnsafeBytes { ptr in
            if let base = ptr.baseAddress {
                txPowerChar = base.assumingMemoryBound(to: UInt8.self).pointee
            }
        }
        if (txPowerChar & 0x80) != 0 {
            return NSNumber(value: Int(-0x100 + Int(txPowerChar)))
        } else {
            return NSNumber(value: Int(txPowerChar))
        }
    }

    /// 设备时间解析(对应 OC deviceTime:)
    public static func deviceTime(_ content: String) -> String {
        let year = String(MKSwiftBleSDKAdopter.getDecimalWithHex(content,
                                                                  range: NSRange(location: 0, length: 2)) + 2000)
        var month = MKSwiftBleSDKAdopter.getDecimalStringWithHex(content,
                                                                range: NSRange(location: 2, length: 2))
        if month.count == 1 {
            month = "0" + month
        }
        var day = MKSwiftBleSDKAdopter.getDecimalStringWithHex(content,
                                                              range: NSRange(location: 4, length: 2))
        if day.count == 1 {
            day = "0" + day
        }
        var hour = MKSwiftBleSDKAdopter.getDecimalStringWithHex(content,
                                                               range: NSRange(location: 6, length: 2))
        if hour.count == 1 {
            hour = "0" + hour
        }
        var minutes = MKSwiftBleSDKAdopter.getDecimalStringWithHex(content,
                                                                  range: NSRange(location: 8, length: 2))
        if minutes.count == 1 {
            minutes = "0" + minutes
        }
        var sec = MKSwiftBleSDKAdopter.getDecimalStringWithHex(content,
                                                              range: NSRange(location: 10, length: 2))
        if sec.count == 1 {
            sec = "0" + sec
        }
        return "\(year)-\(month)-\(day)-\(hour)-\(minutes)-\(sec)"
    }

    /// 解析历史温湿度数据(对应 OC parseHistoryHTData:)
    public static func parseHistoryHTData(_ content: String) -> [String: Any] {
        let total = MKSwiftBleSDKAdopter.getDecimalStringWithHex(content,
                                                                range: NSRange(location: 0, length: 4))
        let index = MKSwiftBleSDKAdopter.getDecimalStringWithHex(content,
                                                                 range: NSRange(location: 4, length: 4))

        let subContent = content.bleSubstring(from: 10, length: (content.count - 10))
        let num = subContent.count / 16
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd-HH-mm-ss"
        var tempList: [[String: Any]] = []
        for i in 0..<num {
            let htData = subContent.bleSubstring(from: i * 16, length: 16)
            let timeStamp = MKSwiftBleSDKAdopter.getDecimalWithHex(htData,
                                                                  range: NSRange(location: 0, length: 8))
            let date = Date(timeIntervalSince1970: TimeInterval(timeStamp))
            let timeString = formatter.string(from: date)
            let tempTemp = MKSwiftBleSDKAdopter.signedHexTurnToInt(htData.bleSubstring(from: 8, length: 4))
            let tempHui = MKSwiftBleSDKAdopter.getDecimalWithHex(htData,
                                                                range: NSRange(location: 12, length: 4))
            let temperature = String(format: "%.1f", Double(tempTemp) * 0.1)
            let humidity = String(format: "%.1f", Double(tempHui) * 0.1)
            let dic: [String: Any] = [
                "temperature": temperature,
                "humidity": humidity,
                "date": timeString
            ]
            tempList.append(dic)
        }
        return [
            "totalNum": total,
            "index": index,
            "dataList": tempList
        ]
    }
}
