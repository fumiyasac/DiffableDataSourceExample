//
//  ArticleViewController.swift
//  DiffableDataSourceExample
//
//  Created by 酒井文也 on 2019/11/26.
//  Copyright © 2019 酒井文也. All rights reserved.
//

import UIKit

final class ArticleViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
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
