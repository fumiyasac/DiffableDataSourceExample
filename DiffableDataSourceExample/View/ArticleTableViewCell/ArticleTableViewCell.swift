//
//  ArticleTableViewCell.swift
//  DiffableDataSourceExample
//
//  Created by 酒井文也 on 2019/11/28.
//  Copyright © 2019 酒井文也. All rights reserved.
//

import UIKit
import AlamofireImage

final class ArticleTableViewCell: UITableViewCell {

    @IBOutlet weak private var articleImageView: UIImageView!
    @IBOutlet weak private var articleTitleLabel: UILabel!
    @IBOutlet weak private var articleSummaryLabel: UILabel!
    @IBOutlet weak private var articleDateLabel: UILabel!

    // MARK: - Override

    override func awakeFromNib() {
        super.awakeFromNib()
        
        self.accessoryType = .none
        self.selectionStyle = .none
    }

    // MARK: - Function

    func setCell(_ article: Article) {

        articleTitleLabel.text = article.title
        articleSummaryLabel.text = article.summary
        articleDateLabel.text = article.date

        articleImageView.image = nil
        if let articleImageUrl = URL(string: article.imageUrl) {
            articleImageView.af_setImage(withURL: articleImageUrl)
        }
    }
}
