//
//  ArticleViewModel.swift
//  DiffableDataSourceExample
//
//  Created by 酒井文也 on 2019/12/01.
//  Copyright © 2019 酒井文也. All rights reserved.
//

import Foundation
import Combine

// MARK: - Protocol

protocol ArticleViewModelInputs {
    var fetchArticleTrigger: PassthroughSubject<Void, Never> { get }
    var refreshArticleTrigger: PassthroughSubject<Void, Never> { get }
}

protocol ArticleViewModelOutputs {
    var articles: AnyPublisher<[Article], Never> { get }
    var apiRequestStatus: AnyPublisher<APIRequestStatus, Never> { get }
}

protocol ArticleViewModelType {
    var inputs: ArticleViewModelInputs { get }
    var outputs: ArticleViewModelOutputs { get }
}

final class ArticleViewModel: ArticleViewModelType, ArticleViewModelInputs, ArticleViewModelOutputs {

    // MARK: - ArticleViewModelType

    var inputs: ArticleViewModelInputs { return self }
    var outputs: ArticleViewModelOutputs { return self }

    // MARK: - PhotoViewModelInputs

    let fetchArticleTrigger = PassthroughSubject<Void, Never>()
    let refreshArticleTrigger = PassthroughSubject<Void, Never>()

    // MARK: - MainViewModelOutputs

    var articles: AnyPublisher<[Article], Never> {
        return $_articles.eraseToAnyPublisher()
    }
    var apiRequestStatus: AnyPublisher<APIRequestStatus, Never> {
        return $_apiRequestStatus.eraseToAnyPublisher()
    }

    private let api: APIRequestManagerProtocol

    private var nextPageNumber: Int = 1
    private var hasNextPage: Bool = true

    private var cancellables: [AnyCancellable] = []

    // MARK: - @Published

    // MEMO: このコードではNSDiffableDataSourceSnapshotの差分更新部分で利用する
    @Published private var _articles: [Article] = []
    @Published private var _apiRequestStatus: APIRequestStatus = .none

    // MARK: - Initializer

    init(api: APIRequestManagerProtocol) {

        // MEMO: 適用するAPIリクエスト用の処理
        self.api = api

        // MEMO: ページング処理を伴うAPIリクエスト
        // → 実行時はViewController側でviewModel.inputs.fetchArticleTrigger.send()で実行する
        fetchArticleTrigger
            .sink(
                receiveValue: { [weak self] in
                    guard let self = self else { return }

                    // MEMO: 次のページが存在しない場合は以降の処理を実施しないようにする
                    guard self.hasNextPage else {
                        return
                    }
                    self.fetchArticleList()
                }
            )
            .store(in: &cancellables)

        // MEMO: 現在まで取得したデータのリフレッシュ処理を伴うAPIリクエスト
        // → 実行時はViewController側でviewModel.inputs.refreshArticleTrigger.send()で実行する
        refreshArticleTrigger
            .sink(
                receiveValue: { [weak self] in
                    guard let self = self else { return }
                    self.nextPageNumber = 1
                    self.hasNextPage = true
                    self._articles = []
                    self.fetchArticleList()
                }
            )
            .store(in: &cancellables)
    }

    // MARK: - deinit

    deinit {
        cancellables.forEach { $0.cancel() }
    }

    // MARK: - Privete Function

    private func fetchArticleList() {

        // APIとの通信処理ステータスを「実行中」へ切り替える
        _apiRequestStatus = .requesting

        // APIとの通信処理を実行する
        api.getArticleList(perPage: nextPageNumber)
            .receive(on: RunLoop.main)
            .sink(
                receiveCompletion: {  [weak self] completion in
                    guard let self = self else { return }

                    switch completion {

                    // MEMO: 値取得に成功した場合のハンドリング
                    case .finished:

                        // MEMO: APIリクエストの処理結果を成功の状態に更新する
                        self._apiRequestStatus = .requestSuccess
                        print("receiveCompletion finished fetchArticleList(): \(completion)")

                    // MEMO: 値取得に失敗した場合のハンドリング
                    case .failure(let error):

                        // MEMO: APIリクエストの処理結果を失敗の状態に更新する
                        self._apiRequestStatus = .requestFailure
                        print("receiveCompletion error fetchArticleList(): \(error.localizedDescription)")
                    }
                },
                receiveValue: { [weak self] hashableObjects in
                    guard let self = self else { return }

                    if let articleList = hashableObjects.first {

                        // MEMO: ViewModel内部処理用の変数を更新する
                        self.nextPageNumber = articleList.page + 1
                        self.hasNextPage = articleList.hasNextPage

                        // MEMO: 表示対象データを差分更新する
                        self._articles = UniqueDataArrayBuilder.fillDifferenceOfOldAndNewLists(Article.self, oldDataList: self._articles, newDataList: articleList.articles)
                        print("receiveValue fetchArticleList(): \(articleList)")
                    }
                }
            )
            .store(in: &cancellables)
    }
}
