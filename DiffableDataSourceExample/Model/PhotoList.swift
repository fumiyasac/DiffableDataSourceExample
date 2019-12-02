//
//  PhotoList.swift
//  DiffableDataSourceExample
//
//  Created by 酒井文也 on 2019/12/01.
//  Copyright © 2019 酒井文也. All rights reserved.
//

import Foundation

struct PhotoList: Hashable, Decodable {

    private let uuid = UUID()

    let page: Int
    let photos: [Photo]
    let hasNextPage: Bool

    // MARK: - Enum

    private enum Keys: String, CodingKey {
        case page
        case photos
        case hasNextPage = "has_next_page"
    }

    // MARK: - Initializer

    init(from decoder: Decoder) throws {

        // JSONの配列内の要素を取得する
        let container = try decoder.container(keyedBy: Keys.self)

        // JSONの配列内の要素にある値をDecodeして初期化する
        self.page = try container.decode(Int.self, forKey: .page)
        self.photos = try container.decode([Photo].self, forKey: .photos)
        self.hasNextPage = try container.decode(Bool.self, forKey: .hasNextPage)
    }

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
        let price: Int?
    }
}
