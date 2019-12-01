//
//  PhotoList.swift
//  DiffableDataSourceExample
//
//  Created by 酒井文也 on 2019/12/01.
//  Copyright © 2019 酒井文也. All rights reserved.
//

import Foundation

struct PhotoList: Hashable, Decodable {

    let uuid = UUID()

    let page: Int
    let photos: [Photo]
    let hasNextPage: Bool

    // MARK: - Hashable

    // MEMO: Hashableプロトコルに適合させるための処理
    func hash(into hasher: inout Hasher) {
        hasher.combine(uuid)
    }

    static func == (lhs: PhotoList, rhs: PhotoList) -> Bool {
        return lhs.uuid == rhs.uuid
    }
}

// MARK: - Photo Extension

struct Photo: Hashable, Decodable {

    let id: Int
    let title: String
    let summary: String
    let image: Image
    let gift: Gift

    // MARK: - Hashable

    // MEMO: Hashableプロトコルに適合させるための処理
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }

    static func == (lhs: Photo, rhs: Photo) -> Bool {
        return lhs.id == rhs.id
    }
}

// MARK: - Photo Extension

extension Photo {

    struct Image: Decodable {
        let url: String
        let width: Int
        let height: Int
    }

    struct Gift: Decodable {
        let flag: Bool
        let price: Int
    }
}
