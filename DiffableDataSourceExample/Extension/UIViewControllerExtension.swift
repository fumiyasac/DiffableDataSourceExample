//
//  UIViewControllerExtension.swift
//  DiffableDataSourceExample
//
//  Created by 酒井文也 on 2019/11/27.
//  Copyright © 2019 酒井文也. All rights reserved.
//

import Foundation
import UIKit

// UIViewControllerの拡張
extension UIViewController {

    // この画面のナビゲーションバーを設定するメソッド
    func setupNavigationBarTitle(_ title: String, shouldPrefersLargeTitles: Bool = true) {

        // NavigationControllerのデザイン調整を行う（※Normal NavigationBar）
        var attributes: [NSAttributedString.Key : Any] = [:]
        attributes[NSAttributedString.Key.font] = UIFont(name: "HiraKakuProN-W6", size: 14.0)
        attributes[NSAttributedString.Key.foregroundColor] = UIColor.white

        // NavigationControllerのデザイン調整を行う（※Large NavigationBar）
        var largeAttributes = [NSAttributedString.Key : Any]()
        largeAttributes[NSAttributedString.Key.font] = UIFont(name: "HiraKakuProN-W6", size: 26.0)
        largeAttributes[NSAttributedString.Key.foregroundColor] = UIColor.white
        
        // NavigationBarをタイトル配色を決定する
        self.navigationController?.navigationBar.isTranslucent = false
        self.navigationController?.navigationBar.barTintColor = UIColor(code: "#dd7700")
        self.navigationController?.navigationBar.titleTextAttributes = attributes

        // タイトルを入れる
        self.navigationItem.title = title

        // ラージタイトルの表示設定に関する設定やデザイン調整を行う
        // 下記リンクも参考に!
        // http://bit.ly/2TXCbd7
        if !shouldPrefersLargeTitles {
            return
        }
        self.navigationItem.largeTitleDisplayMode = .always
        self.navigationController?.navigationBar.prefersLargeTitles = true

        // MEMO: iOS13以降では設定方法が変化する点に注意！
        // https://qiita.com/MilanistaDev/items/6181495e8504612ec053
        if #available(iOS 13.0, *) {
            let appearance = UINavigationBarAppearance()
            appearance.configureWithDefaultBackground()
            appearance.backgroundColor = UIColor(code: "#dd7700")
            appearance.largeTitleTextAttributes = largeAttributes
            appearance.titleTextAttributes = attributes
            self.navigationController?.navigationBar.scrollEdgeAppearance = appearance
            self.navigationController?.navigationBar.standardAppearance = appearance
        } else {
            self.navigationController?.navigationBar.largeTitleTextAttributes = largeAttributes
        }
    }

    // 戻るボタンの「戻る」テキストを削除した状態にするメソッド
    func removeBackButtonText() {

        // 戻るボタンの文言を消す
        let backButtonItem = UIBarButtonItem(title: "", style: .plain, target: nil, action: nil)
        self.navigationController?.navigationBar.tintColor = UIColor.white
        self.navigationItem.backBarButtonItem = backButtonItem
    }
}
