//
//  PhotoViewModel.swift
//  DiffableDataSourceExample
//
//  Created by 酒井文也 on 2019/12/01.
//  Copyright © 2019 酒井文也. All rights reserved.
//

import Foundation
import Combine

// MARK: - Protocol

protocol PhotoViewModelInputs {
    var fetchPhotoTrigger: PassthroughSubject<Void, Never> { get }
}

protocol PhotoViewModelOutputs {
    var photos: AnyPublisher<[Photo], Never> { get }
    var apiRequestStatus: AnyPublisher<APIRequestStatus, Never> { get }
}

protocol PhotoViewModelType {
    var inputs: PhotoViewModelInputs { get }
    var outputs: PhotoViewModelOutputs { get }
}

final class PhotoViewModel: PhotoViewModelType, PhotoViewModelInputs, PhotoViewModelOutputs {

    // MARK: - PhotoViewModelType

    var inputs: PhotoViewModelInputs { return self }
    var outputs: PhotoViewModelOutputs { return self }
    
    // MARK: - PhotoViewModelInputs

    let fetchPhotoTrigger = PassthroughSubject<Void, Never>()

    // MARK: - MainViewModelOutputs

    var photos: AnyPublisher<[Photo], Never> {
        return $_photos.eraseToAnyPublisher()
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
    @Published private var _photos: [Photo] = []
    @Published private var _apiRequestStatus: APIRequestStatus = .none

    // MARK: - Initializer

    init(api: APIRequestManagerProtocol) {

        // MEMO: 適用するAPIリクエスト用の処理
        self.api = api

        // MEMO: InputTriggerとAPIリクエストをするための処理を結合する
        fetchPhotoTrigger
            .sink(
                receiveValue: { [weak self] in
                    guard let self = self else { return }
                    self.fetchPhotoList()
                }
            )
            .store(in: &cancellables)
    }

    // MARK: - deinit

    deinit {
        cancellables.forEach { $0.cancel() }
    }

    // MARK: - Privete Function

    private func fetchPhotoList() {

        // 次のページが存在しない場合は以降の処理を実施しないようにする
        if !hasNextPage {
            return
        }

        // APIとの通信処理ステータスを「実行中」へ切り替える
        _apiRequestStatus = .requesting

        // APIとの通信処理を実行する
        api.getPhotoList(perPage: nextPageNumber)
            .receive(on: RunLoop.main)
            .sink(
                receiveCompletion: {  [weak self] completion in
                    guard let self = self else { return }
                    
                    switch completion {

                    // MEMO: 値取得に成功した場合のハンドリング
                    case .finished:

                        // MEMO: APIリクエストの処理結果を成功の状態に更新する
                        self._apiRequestStatus = .requestSuccess
                        print("receiveCompletion finished fetchPhotoList(): \(completion)")

                    // MEMO: 値取得に失敗した場合のハンドリング
                    case .failure(let error):

                        // MEMO: APIリクエストの処理結果を失敗の状態に更新する
                        self._apiRequestStatus = .requestFailure
                        print("receiveCompletion error fetchPhotoList(): \(error.localizedDescription)")
                    }
                },
                receiveValue: { [weak self] hashableObjects in
                    guard let self = self else { return }

                    if let photoList = hashableObjects.first {

                        // MEMO: ViewModel内部処理用の変数を更新する
                        self.nextPageNumber = photoList.page + 1
                        self.hasNextPage = photoList.hasNextPage

                        // MEMO: 表示対象データを差分更新する
                        self._photos = UniqueDataArrayBuilder.fillDifferenceOfOldAndNewLists(Photo.self, oldDataList: self._photos, newDataList: photoList.photos)
                        print("receiveValue fetchPhotoList(): \(photoList)")
                    }
                }
            )
            .store(in: &cancellables)
    }
}
