//
//  MainViewController.swift
//  DiffableDataSourceExample
//
//  Created by 酒井文也 on 2019/11/26.
//  Copyright © 2019 酒井文也. All rights reserved.
//

import UIKit

final class MainViewController: UIViewController {

    // MARK: - @IBOutlets

    @IBOutlet weak private var mainCollectionView: UICollectionView!

    // MARK: - Override

    override func viewDidLoad() {
        super.viewDidLoad()

        setupNavigationBarTitle("Photos", shouldPrefersLargeTitles: false)
        removeBackButtonText()
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
