//
//  UniqueDataArrayBuilder.swift
//  DiffableDataSourceExample
//
//  Created by 酒井文也 on 2019/12/03.
//  Copyright © 2019 酒井文也. All rights reserved.
//

import Foundation

struct UniqueDataArrayBuilder {

    // MARK: - Static Function

    // モデル内に定義したハッシュ値の同一性を検証して一意な表示用データ配列を作成する
    static func fillDifferenceOfOldAndNewLists<T: Decodable & Hashable>(_ dataType: T.Type, oldDataList: [T], newDataList: [T]) -> [T] {

        // 引数より受け取った新しいデータ配列
        var newDataList = newDataList

        // 返却用の配列
        var dataList: [T] = []

        // 既存の表示データ配列をループさせて同一のものがある場合は新しいデータへ置き換える
        // ここはもっと綺麗に書ける余地がある部分だと思う...
        for oldData in oldDataList {
            var shouldAppendOldData = true
            for (newIndex, newData) in newDataList.enumerated() {

                // 同一データの確認(写真表示用のモデルはHashableとしているのでidの一致で判定できるようにしている部分がポイント)
                if oldData == newData {
                    shouldAppendOldData = false
                    dataList.append(newData)
                    newDataList.remove(at: newIndex)
                    break
                }
            }
            if shouldAppendOldData {
                dataList.append(oldData)
            }
        }

        // 置き換えたものを除外した新しいデータを後ろへ追加する
        for newData in newDataList {
            dataList.append(newData)
        }
        return dataList
    }
}
