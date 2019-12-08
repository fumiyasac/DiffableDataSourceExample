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

//
enum APIRequestStatus {
    case none
    case requesting
    case requestSuccess
    case requestFailure
}

//
enum APIError: Error {
    case none
    case error(String)
}

// MARK: - Protocol

protocol APIRequestManagerProtocol {
    func getPhotoList(perPage: Int) -> Future<[PhotoList], APIError>
    func getArticleList(perPage: Int) -> Future<[ArticleList], APIError>
}

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

    // MARK: - Private Function

    private func handleSessionTask<T: Decodable & Hashable>(_ dataType: T.Type, request: URLRequest) -> Future<[T], APIError> {
        return Future { promise in

            let task = self.session.dataTask(with: request) { data, response, error in
                // MEMO: レスポンス形式やステータスコードを元にしたエラーハンドリングをする
                if let error = error {
                    promise(.failure(APIError.error(error.localizedDescription)))
                    return
                }
                guard let response = response as? HTTPURLResponse, response.statusCode == 200 else {
                    promise(.failure(APIError.error("Error: invalid HTTP response code")))
                    return
                }
                guard let data = data else {
                    promise(.failure(APIError.error("Error: missing response data")))
                    return
                }
                // MEMO: 取得できたレスポンスを引数で指定した型の配列に変換して受け取る
                do {
                    let hashableObjects = try JSONDecoder().decode([T].self, from: data)
                    promise(.success(hashableObjects))
                } catch {
                    promise(.failure(APIError.error(error.localizedDescription)))
                }
            }
            task.resume()
        }
    }
}

// MARK: - APIRequestManagerProtocol

extension APIRequestManager: APIRequestManagerProtocol {

    func getPhotoList(perPage: Int) -> Future<[PhotoList], APIError> {
        let endPointUrl = EndPoint.photos.getBaseUrl() + "?page=" + String(perPage)
        let photoListAPIRequest = makeUrlForGetRequest(endPointUrl)
        return handleSessionTask(PhotoList.self, request: photoListAPIRequest)
    }

    func getArticleList(perPage: Int) -> Future<[ArticleList], APIError> {
        let endPointUrl = EndPoint.articles.getBaseUrl() + "?page=" + String(perPage)
        let articleListAPIRequest = makeUrlForGetRequest(endPointUrl)
        return handleSessionTask(ArticleList.self, request: articleListAPIRequest)
    }
}
