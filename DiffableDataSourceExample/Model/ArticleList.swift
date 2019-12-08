//
//  ArticleList.swift
//  DiffableDataSourceExample
//
//  Created by 酒井文也 on 2019/12/01.
//  Copyright © 2019 酒井文也. All rights reserved.
//

import Foundation

// MARK: - Struct (PhotoList)

struct ArticleList: Hashable, Decodable {

    private let uuid = UUID()

    let page: Int
    let articles: [Article]
    let hasNextPage: Bool

    // MARK: - Enum

    private enum Keys: String, CodingKey {
        case page
        case articles
        case hasNextPage = "has_next_page"
    }

    // MARK: - Initializer

    init(from decoder: Decoder) throws {

        // JSONの配列内の要素を取得する
        let container = try decoder.container(keyedBy: Keys.self)

        // JSONの配列内の要素にある値をDecodeして初期化する
        self.page = try container.decode(Int.self, forKey: .page)
        self.articles = try container.decode([Article].self, forKey: .articles)
        self.hasNextPage = try container.decode(Bool.self, forKey: .hasNextPage)
    }

    // MARK: - Hashable

    // MEMO: Hashableプロトコルに適合させるための処理
    func hash(into hasher: inout Hasher) {
        hasher.combine(uuid)
    }

    static func == (lhs: ArticleList, rhs: ArticleList) -> Bool {
        return lhs.uuid == rhs.uuid
    }
}

// MARK: - Struct (Article)

struct Article: Hashable, Decodable {

    let id: Int
    let title: String
    let summary: String
    let date: String
    let imageUrl: String

    // MARK: - Enum

    private enum Keys: String, CodingKey {
        case id
        case title
        case summary
        case date
        case imageUrl = "image_url"
    }

    // MARK: - Initializer

    init(from decoder: Decoder) throws {

        // JSONの配列内の要素を取得する
        let container = try decoder.container(keyedBy: Keys.self)

        // JSONの配列内の要素にある値をDecodeして初期化する
        self.id = try container.decode(Int.self, forKey: .id)
        self.title = try container.decode(String.self, forKey: .title)
        self.summary = try container.decode(String.self, forKey: .summary)
        self.date = try container.decode(String.self, forKey: .date)
        self.imageUrl = try container.decode(String.self, forKey: .imageUrl)
    }

    // MARK: - Hashable

    // MEMO: Hashableプロトコルに適合させるための処理
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }

    static func == (lhs: Article, rhs: Article) -> Bool {
        return lhs.id == rhs.id
    }
}
