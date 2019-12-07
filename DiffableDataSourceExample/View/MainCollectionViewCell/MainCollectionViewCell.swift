//
//  MainCollectionViewCell.swift
//  DiffableDataSourceExample
//
//  Created by 酒井文也 on 2019/11/28.
//  Copyright © 2019 酒井文也. All rights reserved.
//

import UIKit
import AlamofireImage

final class MainCollectionViewCell: UICollectionViewCell {

    @IBOutlet weak private var giftFlagLabel: UILabel!
    @IBOutlet weak private var giftPriceLabel: UILabel!
    
    @IBOutlet weak private var photoImageView: UIImageView!
    @IBOutlet weak private var photoTitleLabel: UILabel!
    @IBOutlet weak private var photoSummaryLabel: UILabel!

    // MARK: - Function

    func setCell(_ photo: Photo) {

        giftFlagLabel.isHidden = !photo.gift.flag
        giftPriceLabel.isHidden = !photo.gift.flag

        if let price = photo.gift.price {
            giftPriceLabel.text = "\(price)"
        }

        photoTitleLabel.text = photo.title
        photoSummaryLabel.text = photo.summary

        photoImageView.image = nil
        if let photoImageUrl = URL(string: photo.image.url) {
            photoImageView.af_setImage(withURL: photoImageUrl)
        }
    }
}
