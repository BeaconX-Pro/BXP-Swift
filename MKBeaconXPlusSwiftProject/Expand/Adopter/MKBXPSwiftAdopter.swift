//
//  MKBXPSwiftAdopter.swift
//  MKBeaconXPlusSwiftProject
//
//  Created by aa on 2026/9/18.
//

import UIKit

// MARK: - 富文本 / 尺寸计算 / 动画工具

public enum MKBXPSwiftAdopter {

    // MARK: - 富文本

    /// 获取富文本
    /// - Parameters:
    ///   - strings: 富文本内容数组
    ///   - fonts: 富文本内容字体大小数组
    ///   - colors: 富文本字体颜色数组
    /// - Returns: 拼接后的富文本
    public static func createAttributedString(strings: [String],
                                               fonts: [UIFont],
                                               colors: [UIColor]) -> NSMutableAttributedString {
        guard !strings.isEmpty, !fonts.isEmpty, !colors.isEmpty else {
            return NSMutableAttributedString(string: "")
        }
        guard strings.count == fonts.count,
              strings.count == colors.count,
              fonts.count == colors.count else {
            return NSMutableAttributedString(string: "")
        }

        let sourceString = strings.joined()
        guard !sourceString.isEmpty else {
            return NSMutableAttributedString(string: "")
        }

        let resultString = NSMutableAttributedString(string: sourceString)
        var originPosition = 0
        for i in 0..<strings.count {
            let tempString = strings[i]
            let length = (tempString as NSString).length
            let range = NSRange(location: originPosition, length: length)
            resultString.addAttribute(.foregroundColor,
                                       value: colors[i],
                                       range: range)
            resultString.addAttribute(.font,
                                       value: fonts[i],
                                       range: range)
            originPosition += length
        }
        return resultString
    }

    // MARK: - 尺寸计算

    /// 求富文本字符串所在控件的高度
    /// - Parameters:
    ///   - string: 富文本
    ///   - viewWidth: 当前富文本所在控件的最大宽度
    /// - Returns: 高度（向上取整）
    public static func strHeight(forAttributeStr string: NSAttributedString,
                                  viewWidth: CGFloat) -> CGFloat {
        guard string.length > 0 else { return 0 }
        let size = string.boundingRect(
            with: CGSize(width: viewWidth, height: .greatestFiniteMagnitude),
            options: [.usesLineFragmentOrigin, .usesFontLeading],
            context: nil
        ).size
        return ceil(size.height)
    }

    /// 求富文本字符串所在控件的宽度
    /// - Parameters:
    ///   - string: 富文本
    ///   - viewHeight: 当前富文本所在控件的最大高度
    /// - Returns: 宽度（向上取整）
    public static func strWidth(forAttributeStr string: NSAttributedString,
                                 viewHeight: CGFloat) -> CGFloat {
        guard string.length > 0 else { return 0 }
        let size = string.boundingRect(
            with: CGSize(width: .greatestFiniteMagnitude, height: viewHeight),
            options: [.usesLineFragmentOrigin, .usesFontLeading],
            context: nil
        ).size
        return ceil(size.width)
    }

    // MARK: - 动画

    /// 旋转动画
    /// - Parameter duration: 旋转一周时长
    /// - Returns: 绕 z 轴旋转的 `CABasicAnimation`
    public static func refreshAnimation(_ duration: TimeInterval) -> CABasicAnimation {
        let transformAnima = CABasicAnimation(keyPath: "transform.rotation.z")
        transformAnima.duration = duration
        transformAnima.fromValue = 0
        transformAnima.toValue = 2 * Double.pi
        transformAnima.autoreverses = false
        transformAnima.repeatCount = .greatestFiniteMagnitude
        transformAnima.isRemovedOnCompletion = false
        return transformAnima
    }
}
