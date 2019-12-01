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

enum MainSection: Int, CaseIterable {
    case WatarFallPhotoLayout
}

final class ArticleViewController: UIViewController {

    // MARK: - Variables

    private var cancellables: [AnyCancellable] = []

    // MEMO: UICollectionViewCompositionalLayout & DiffableDataSourceの設定
    private var snapshot: NSDiffableDataSourceSnapshot<MainSection, AnyHashable>!
    private var dataSource: UICollectionViewDiffableDataSource<MainSection, AnyHashable>! = nil
    private lazy var compositionalLayout: UICollectionViewCompositionalLayout = {
        let layout = UICollectionViewCompositionalLayout { [weak self] (sectionIndex: Int, layoutEnvironment: NSCollectionLayoutEnvironment) -> NSCollectionLayoutSection? in

            switch sectionIndex {

            // MainSection: 0 (WatarFallPhotoLayout)
            case MainSection.WatarFallPhotoLayout.rawValue:
                return self?.createWatarFallPhotoLayout()

            default:
                fatalError()
            }
        }
        return layout
    }()
    
    // MARK: - @IBOutlets

    @IBOutlet weak private var articleTableView: UITableView!

    // MARK: - Override

    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupNavigationBarTitle("Articles", shouldPrefersLargeTitles: false)
        removeBackButtonText()
    }

    // MARK: - Private Function

    private func createWatarFallPhotoLayout() -> NSCollectionLayoutSection {

        // MEMO: 該当のセルを基準にした高さを設定する
        let absoluteHeight = UIScreen.main.bounds.width * 0.5 + 90.0

        // 1. Itemのサイズ設定
        let itemSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0), heightDimension: .fractionalHeight(1.0))
        let item = NSCollectionLayoutItem(layoutSize: itemSize)
        item.contentInsets = NSDirectionalEdgeInsets(top: 0.5, leading: 0.5, bottom: 0.5, trailing: 0.5)

        // 2. Groupのサイズ設定
        let groupSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0), heightDimension: .absolute(absoluteHeight))
        let group = NSCollectionLayoutGroup.horizontal(layoutSize: groupSize, subitem: item, count: 2)

        // 3. Sectionのサイズ設定
        let section = NSCollectionLayoutSection(group: group)
        // MEMO: HeaderとFooterのレイアウトを決定する
        let headerSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0), heightDimension: .estimated(65.0))
        let header = NSCollectionLayoutBoundarySupplementaryItem(layoutSize: headerSize, elementKind: UICollectionView.elementKindSectionHeader, alignment: .top)
        section.boundarySupplementaryItems = [header]

        return section
    }
}

// MARK: - StoryboardInstantiatable

extension ArticleViewController: StoryboardInstantiatable {

    // このViewControllerに対応するStoryboard名
    static var storyboardName: String {
        return "Article"
    }

    // このViewControllerに対応するViewControllerのIdentifier名
    static var viewControllerIdentifier: String? {
        return nil
    }
}
