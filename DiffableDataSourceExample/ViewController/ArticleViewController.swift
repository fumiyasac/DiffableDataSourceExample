//
//  ArticleViewController.swift
//  DiffableDataSourceExample
//
//  Created by 酒井文也 on 2019/11/26.
//  Copyright © 2019 酒井文也. All rights reserved.
//

import UIKit
import Combine

// MARK: - Enum

enum ArticleSection: Int, CaseIterable {
    case RegularArticle
}

final class ArticleViewController: UIViewController {

    // MARK: - Variables

    // UICollectionViewに設置するRefreshControl
    private let articleRefrashControl = UIRefreshControl()

    // MEMO: API経由の非同期通信からデータを取得するためのViewModel
    private let viewModel: ArticleViewModel = ArticleViewModel(api: APIRequestManager.shared)

    private var cancellables: [AnyCancellable] = []

    // MEMO: UICollectionViewCompositionalLayout & DiffableDataSourceの設定
    private var snapshot: NSDiffableDataSourceSnapshot<ArticleSection, Article>!
    private var dataSource: UITableViewDiffableDataSource<ArticleSection, Article>! = nil
    
    // MARK: - @IBOutlets

    @IBOutlet weak private var articleTableView: UITableView!

    // MARK: - Override

    override func viewDidLoad() {
        super.viewDidLoad()

        // NavigationBar等の設定
        setupNavigationBarTitle("Articles", shouldPrefersLargeTitles: false)
        removeBackButtonText()

        // UITableViewに関する設定
        setupArticleTableView()
        bindToViewModelOutputs()
    }

    // MARK: - Private Function

    // UICollectionViewにおけるPullToRefresh実行時の処理
    @objc private func executeRefresh() {

        // MEMO: ViewModelに定義した表示データのリフレッシュ処理を実行する
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.36) {
            self.viewModel.inputs.refreshArticleTrigger.send()
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

    // UITableViewに関する初期設定
    private func setupArticleTableView() {

        // MEMO: UITableViewで表示するセルの登録
        articleTableView.registerCustomCell(ArticleTableViewCell.self)

        // MEMO: UITableViewでのRefreshControlに関する設定
        articleTableView.refreshControl = articleRefrashControl
        articleRefrashControl.addTarget(self, action: #selector(executeRefresh), for: .valueChanged)

        // MEMO: UITableViewDelegateの設定
        articleTableView.delegate = self

        // MEMO: UITableViewCellの高さ設定
        articleTableView.estimatedRowHeight = UITableView.automaticDimension

        // MEMO: DataSourceはUITableViewDiffableDataSourceを利用してUITableViewCellを継承したクラスを組み立てる
        dataSource = UITableViewDiffableDataSource<ArticleSection, Article>(tableView: articleTableView) { (tableView: UITableView, indexPath: IndexPath, article: Article) -> UITableViewCell? in

            let cell = tableView.dequeueReusableCustomCell(with: ArticleTableViewCell.self)
            cell.setCell(article)
            return cell
        }

        // MEMO: NSDiffableDataSourceSnapshotの初期設定
        snapshot = NSDiffableDataSourceSnapshot<ArticleSection, Article>()
        snapshot.appendSections(ArticleSection.allCases)
        for section in ArticleSection.allCases {
            snapshot.appendItems([], toSection: section)
        }
        dataSource.apply(snapshot, animatingDifferences: false)

        // MEMO: ViewModelのInputsを経由したAPIでのデータ取得処理を実行する
        viewModel.inputs.fetchArticleTrigger.send()
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
                        self.articleRefrashControl.beginRefreshing()
                    case .requestFailure:
                        // MEMO: 通信失敗時はアラート表示 & RefreshControlの状態変更
                        self.articleRefrashControl.endRefreshing()
                        self.showAlertWith(completionHandler: nil)
                    default:
                        self.articleRefrashControl.endRefreshing()
                    }
                }
            )
            .store(in: &cancellables)

        // MEMO: APIへのリクエスト状態に合わせたUI側の表示におけるハンドリングを実行する
        viewModel.outputs.articles
            .subscribe(on: RunLoop.main)
            .sink(
                receiveValue: { [weak self] articles in

                    guard let self = self else { return }
                    // MEMO: ID(Identifier)が重複する場合における衝突の回避をする
                    let beforePhoto = self.snapshot.itemIdentifiers(inSection: .RegularArticle)
                    self.snapshot.deleteItems(beforePhoto)
                    self.snapshot.appendItems(articles, toSection: .RegularArticle)
                    self.dataSource.apply(self.snapshot, animatingDifferences: false)
                }
            )
            .store(in: &cancellables)
    }
}

// MARK: - UITableViewDelegate

extension ArticleViewController: UITableViewDelegate {

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {

        // MEMO: 該当のセクションとIndexPathからNSDiffableDataSourceSnapshot内の該当する値を取得する
        if let targetSection = ArticleSection(rawValue: indexPath.section) {
            let targetSnapshot = snapshot.itemIdentifiers(inSection: .RegularArticle)
            print("Section: ", targetSection)
            print("IndexPath.row: ", indexPath.row)
            print("Model: ", targetSnapshot[indexPath.row])
        }
    }
}

// MARK: - UIScrollViewDelegate

extension ArticleViewController: UIScrollViewDelegate {

    // MEMO: NSCollectionLayoutSectionのScroll(section.orthogonalScrollingBehavior)ではUIScrollViewDelegateは呼ばれない
    func scrollViewDidScroll(_ scrollView: UIScrollView) {

        // MEMO: UIRefreshControl表示時は以降の処理を行わない(※APIリクエストの状態とRefreshControlの状態を連動させている点がポイント)
        if articleRefrashControl.isRefreshing {
            return
        }

        // MEMO: UIScrollViewが一番下の状態に達した時にAPIリクエストを実行する
        if scrollView.contentOffset.y + scrollView.frame.size.height > scrollView.contentSize.height {
            viewModel.inputs.fetchArticleTrigger.send()
        }
    }
}
