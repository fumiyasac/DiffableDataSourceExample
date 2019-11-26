//
//  UIColorExtension.swift
//  DiffableDataSourceExample
//
//  Created by 酒井文也 on 2019/11/27.
//  Copyright © 2019 酒井文也. All rights reserved.
//

import Foundation
import UIKit

// UIColorの拡張
extension UIColor {

    // 16進数のカラーコードをiOSの設定に変換するメソッド
    // 参考：【Swift】Tips: あると便利だったextension達(UIColor編)
    // https://dev.classmethod.jp/smartphone/utilty-extension-uicolor/
    // iOS13での変更点: scanHexInt32がdeprecatedとなったのでscanHexInt64を使用する
    convenience init(code: String, alpha: CGFloat = 1.0) {
        var color: UInt64 = 0
        var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0
        if Scanner(string: code.replacingOccurrences(of: "#", with: "")).scanHexInt64(&color) {
            r = CGFloat((color & 0xFF0000) >> 16) / 255.0
            g = CGFloat((color & 0x00FF00) >>  8) / 255.0
            b = CGFloat( color & 0x0000FF       ) / 255.0
        }
        self.init(red: r, green: g, blue: b, alpha: alpha)
    }
}
