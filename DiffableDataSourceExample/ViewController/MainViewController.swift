//
//  MainViewController.swift
//  DiffableDataSourceExample
//
//  Created by 酒井文也 on 2019/11/26.
//  Copyright © 2019 酒井文也. All rights reserved.
//

import UIKit
import Combine

// MARK: - Enum

enum PhotoSection: Int, CaseIterable {
    case WaterFallLayout
}

final class MainViewController: UIViewController {

    // MARK: - Variables

    // UICollectionViewに設置するRefreshControl
    private let mainRefrashControl = UIRefreshControl()

    // MEMO: API経由の非同期通信からデータを取得するためのViewModel
    private let viewModel: PhotoViewModel = PhotoViewModel(api: APIRequestManager.shared)

    // MEMO: Cancellableの保持用(※RxSwiftでいうところのDisposeBagの様なイメージ)
    private var cancellables: [AnyCancellable] = []

    // MEMO: UICollectionViewを差分更新するためのNSDiffableDataSourceSnapshot
    private var snapshot: NSDiffableDataSourceSnapshot<PhotoSection, Photo>!

    // MEMO: UICollectionViewを組み立てるためのDataSource
    private var dataSource: UICollectionViewDiffableDataSource<PhotoSection, Photo>! = nil

    // MEMO: UICollectionViewCompositionalLayoutの設定（※Sectionごとに読み込ませて利用する）
    private lazy var compositionalLayout: UICollectionViewCompositionalLayout = {
        let layout = UICollectionViewCompositionalLayout { [weak self] (sectionIndex: Int, layoutEnvironment: NSCollectionLayoutEnvironment) -> NSCollectionLayoutSection? in

            switch sectionIndex {

            // MainSection: 0
            case PhotoSection.WaterFallLayout.rawValue:
                return self?.createWaterFallLayoutSection()

            default:
                fatalError()
            }
        }
        return layout
    }()
    
    // MARK: - @IBOutlets

    @IBOutlet weak private var mainCollectionView: UICollectionView!

    // MARK: - Override

    override func viewDidLoad() {
        super.viewDidLoad()

        // NavigationBar等の設定
        setupNavigationBarTitle("Photos", shouldPrefersLargeTitles: false)
        removeBackButtonText()

        // UICollectionViewに関する設定
        setupCollectionView()
        bindToViewModelOutputs()
    }

    // MARK: - Private Function (for UICollectionView Setup)

    // UICollectionViewにおけるPullToRefresh実行時の処理
    @objc private func executeRefresh() {

        // MEMO: ViewModelに定義した表示データのリフレッシュ処理を実行する
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.36) {
            self.viewModel.inputs.refreshPhotoTrigger.send()
        }
    }

    // エラー発生時のアラート表示を設定をする
    private func showAlertWith(completionHandler: (() -> ())? = nil) {

        let alert = UIAlertController(
            title: "エラーが発生しました",
            message: "データの取得に失敗しました。通信環境等を確認の上再度お試し下さい。",
            preferredStyle: .alert
        )
        let okAction = UIAlertAction(title: "OK", style: .default, handler: { _ in
            completionHandler?()
        })
        alert.addAction(okAction)
        self.present(alert, animated: true, completion: nil)
    }

    // UICollectionViewに関する初期設定
    private func setupCollectionView() {
        
        // MEMO: UICollectionViewで表示するセルの登録
        mainCollectionView.registerCustomCell(MainCollectionViewCell.self)

        // MEMO: UICollectionViewでのRefreshControlに関する設定
        mainCollectionView.refreshControl = mainRefrashControl
        mainRefrashControl.addTarget(self, action: #selector(executeRefresh), for: .valueChanged)

        // MEMO: UICollectionViewDelegateの設定
        mainCollectionView.delegate = self

        // MEMO: UICollectionViewCompositionalLayoutを利用してレイアウトを組み立てる
        mainCollectionView.collectionViewLayout = compositionalLayout

        // MEMO: DataSourceはUICollectionViewDiffableDataSourceを利用してUICollectionViewCellを継承したクラスを組み立てる
        dataSource = UICollectionViewDiffableDataSource<PhotoSection, Photo>(collectionView: mainCollectionView) { (collectionView: UICollectionView, indexPath: IndexPath, photo: Photo) -> UICollectionViewCell? in

            let cell = collectionView.dequeueReusableCustomCell(with: MainCollectionViewCell.self, indexPath: indexPath)
            cell.setCell(photo)
            return cell
        }

        // MEMO: NSDiffableDataSourceSnapshotの初期設定
        snapshot = NSDiffableDataSourceSnapshot<PhotoSection, Photo>()
        snapshot.appendSections(PhotoSection.allCases)
        for section in PhotoSection.allCases {
            snapshot.appendItems([], toSection: section)
        }
        dataSource.apply(snapshot, animatingDifferences: false)

        // MEMO: ViewModelのInputsを経由したAPIでのデータ取得処理を実行する
        viewModel.inputs.fetchPhotoTrigger.send()
    }

    // ViewModelのOutputとこのViewControllerでのUIに関する処理をバインドする
    private func bindToViewModelOutputs() {

        // MEMO: APIへのリクエスト状態に合わせたUI側の表示におけるハンドリングを実行する
        viewModel.outputs.apiRequestStatus
            .subscribe(on: RunLoop.main)
            .sink(
                receiveValue: { [weak self] status in

                    guard let self = self else { return }
                    switch status {
                    case .requesting:
                        self.mainRefrashControl.beginRefreshing()
                    case .requestFailure:
                        // MEMO: 通信失敗時はアラート表示 & RefreshControlの状態変更
                        self.mainRefrashControl.endRefreshing()
                        self.showAlertWith(completionHandler: nil)
                    default:
                        self.mainRefrashControl.endRefreshing()
                    }
                }
            )
            .store(in: &cancellables)

        // MEMO: APIへのリクエスト状態に合わせたUI側の表示におけるハンドリングを実行する
        viewModel.outputs.photos
            .subscribe(on: RunLoop.main)
            .sink(
                receiveValue: { [weak self] photos in

                    guard let self = self else { return }
                    // MEMO: ID(Identifier)が重複する場合における衝突の回避をする
                    let beforePhoto = self.snapshot.itemIdentifiers(inSection: .WaterFallLayout)
                    self.snapshot.deleteItems(beforePhoto)
                    self.snapshot.appendItems(photos, toSection: .WaterFallLayout)
                    self.dataSource.apply(self.snapshot, animatingDifferences: false)
                }
            )
            .store(in: &cancellables)
    }

    // UICollectionViewCompositionalLayoutを利用したレイアウトを組み立てる処理
    private func createWaterFallLayoutSection() -> NSCollectionLayoutSection {

        if snapshot.numberOfItems == 0 {
            return applyForNoItemLayoutSection()
        } else {
            return applyForWaterFallLayoutSection()
        }
    }

    private func applyForNoItemLayoutSection() -> NSCollectionLayoutSection {

        // MEMO: .absoluteや.estimatedを設定する場合で0を入れると下記のようなログが出ます。
        // → Invalid estimated dimension, must be > 0. NOTE: This will be a hard-assert soon, please update your call site.

        // 1. Itemのサイズ設定
        let itemSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0), heightDimension: .estimated(0.5))
        let item = NSCollectionLayoutItem(layoutSize: itemSize)
        item.contentInsets = .zero

        // 2. Groupのサイズ設定
        let groupSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0), heightDimension: .estimated(0.5))
        let group = NSCollectionLayoutGroup.vertical(layoutSize: groupSize, subitems: [item])
        group.contentInsets = .zero

        // 3. Sectionのサイズ設定
        let section = NSCollectionLayoutSection(group: group)
        section.contentInsets = .zero

        return section
    }

    private func applyForWaterFallLayoutSection() -> NSCollectionLayoutSection {

        // MEMO: 表示するアイテムが存在する場合は各セルの高さの適用とそれに基くUICollectionView全体の高さを計算する

        // Model内で持っているheightの値を適用することでWaterFallLayoutの様な見た目を実現する
        var leadingGroupHeight: CGFloat = 0.0
        var trailingGroupHeight: CGFloat = 0.0
        var leadingGroupItems: [NSCollectionLayoutItem] = []
        var trailingGroupItems: [NSCollectionLayoutItem] = []

        let photos = snapshot.itemIdentifiers(inSection: .WaterFallLayout)
        let totalHeight = photos.reduce(CGFloat(0)) { $0 + $1.height }
        let columnHeight = CGFloat(totalHeight / 2.0)

        var runningHeight = CGFloat(0.0)

        // 1. Itemのサイズ設定
        for index in 0..<snapshot.numberOfItems {

            let photo = photos[index]
            let isLeading = runningHeight < columnHeight
            let itemSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0), heightDimension: .absolute(photo.height))
            let item = NSCollectionLayoutItem(layoutSize: itemSize)

            runningHeight += photo.height

            if isLeading {
                leadingGroupItems.append(item)
                leadingGroupHeight += photo.height
            } else {
                trailingGroupItems.append(item)
                trailingGroupHeight += photo.height
            }
        }

        // 2. Groupのサイズ設定
        let leadingGroupSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(0.5), heightDimension: .absolute(leadingGroupHeight))
        let leadingGroup = NSCollectionLayoutGroup.vertical(layoutSize: leadingGroupSize, subitems: leadingGroupItems)

        let trailingGroupSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(0.5), heightDimension: .absolute(trailingGroupHeight))
        let trailingGroup = NSCollectionLayoutGroup.vertical(layoutSize: trailingGroupSize, subitems: trailingGroupItems)

        let groupSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0), heightDimension: .absolute(max(leadingGroupHeight, trailingGroupHeight)))
        let group = NSCollectionLayoutGroup.horizontal(layoutSize: groupSize, subitems: [leadingGroup, trailingGroup])

        // 3. Sectionのサイズ設定
        let section = NSCollectionLayoutSection(group: group)

        return section
    }

    // MARK: - deinit

    deinit {
        cancellables.forEach { $0.cancel() }
    }
}

// MARK: - UICollectionViewDelegate

extension MainViewController: UICollectionViewDelegate {

    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {

        // MEMO: 該当のセクションとIndexPathからNSDiffableDataSourceSnapshot内の該当する値を取得する
        if let targetSection = MainSection(rawValue: indexPath.section) {
            let targetSnapshot = snapshot.itemIdentifiers(inSection: .WaterFallLayout)
            print("Section: ", targetSection)
            print("IndexPath.row: ", indexPath.row)
            print("Model: ", targetSnapshot[indexPath.row])
        }
    }
}

// MARK: - UIScrollViewDelegate

extension MainViewController: UIScrollViewDelegate {

    // MEMO: NSCollectionLayoutSectionのScroll(section.orthogonalScrollingBehavior)ではUIScrollViewDelegateは呼ばれない
    func scrollViewDidScroll(_ scrollView: UIScrollView) {

        // MEMO: UIRefreshControl表示時は以降の処理を行わない(※APIリクエストの状態とRefreshControlの状態を連動させている点がポイント)
        if mainRefrashControl.isRefreshing {
            return
        }

        // MEMO: UIScrollViewが一番下の状態に達した時にAPIリクエストを実行する
        if scrollView.contentOffset.y + scrollView.frame.size.height > scrollView.contentSize.height {
            viewModel.inputs.fetchPhotoTrigger.send()
        }
    }
}
