//
//  MainViewController.swift
//  DiffableDataSourceExample
//
//  Created by 酒井文也 on 2019/11/26.
//  Copyright © 2019 酒井文也. All rights reserved.
//

import UIKit
import Combine

final class MainViewController: UIViewController {

    // MARK: - @IBOutlets

    // MEMO: API経由の非同期通信からデータを取得するためのViewModel
    private let viewModel: PhotoViewModel = PhotoViewModel(api: APIRequestManager.shared)

    private var cancellables: [AnyCancellable] = []

    // MARK: - @IBOutlets

    @IBOutlet weak private var mainCollectionView: UICollectionView!

    // MARK: - Override

    override func viewDidLoad() {
        super.viewDidLoad()

        setupNavigationBarTitle("Photos", shouldPrefersLargeTitles: false)
        removeBackButtonText()

        viewModel.inputs.fetchPhotoTrigger.send()
        DispatchQueue.main.asyncAfter(deadline: .now() + 8.0) {
            self.viewModel.inputs.fetchPhotoTrigger.send()
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 16.0) {
            self.viewModel.inputs.fetchPhotoTrigger.send()
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 24.0) {
            self.viewModel.inputs.fetchPhotoTrigger.send()
        }

        viewModel.outputs.photos
            .subscribe(on: RunLoop.main)
            .sink(
                receiveValue: { [weak self] photos in

                    guard let self = self else { return }
                    print("個数: ", photos.count)
                    print("データ: ", photos)
                }
            )
            .store(in: &cancellables)
    }

    // MARK: - deinit

    deinit {
        cancellables.forEach { $0.cancel() }
    }
}

// MARK: - StoryboardInstantiatable

extension MainViewController: StoryboardInstantiatable {

    // このViewControllerに対応するStoryboard名
    static var storyboardName: String {
        return "Main"
    }

    // このViewControllerに対応するViewControllerのIdentifier名
    static var viewControllerIdentifier: String? {
        return nil
    }
}
