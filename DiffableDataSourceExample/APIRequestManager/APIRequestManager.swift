//
//  APIRequestManager.swift
//  DiffableDataSourceExample
//
//  Created by 酒井文也 on 2019/11/27.
//  Copyright © 2019 酒井文也. All rights reserved.
//

import Foundation
import Combine

// MARK: - Enum

enum APIError : Error {
    case error(String)
}

// MARK: - Protocol

protocol APIRequestManagerProtocol {}

class APIRequestManager {

    // MEMO: MockサーバーへのURLに関する情報
    private static let host = "http://localhost:3000/api/mock"
    private static let version = "v1"
    private static let path = "special"

    private let session = URLSession.shared

    // MARK: - Singleton Instance

    static let shared = APIRequestManager()

    private init() {}

    // MARK: - Enum

    private enum EndPoint: String {

        case photos = "photos"
        case articles = "articles"
        case detail = "detail"
        case detailDescriptions = "detail_description"
        case detailThumbnails = "detail_thumbnails"

        func getBaseUrl() -> String {
            return [host, version, path, self.rawValue].joined(separator: "/")
        }
    }

    // MARK: - Private Function

    private func makeUrlForGetRequest(_ urlString: String) -> URLRequest {
        guard let url = URL(string: urlString) else {
            fatalError()
        }
        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = "GET"
        urlRequest.addValue("application/json", forHTTPHeaderField: "Content-Type")
        return urlRequest
    }
}

// MARK: - APIRequestManagerProtocol

extension APIRequestManager: APIRequestManagerProtocol {}
