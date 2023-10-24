//
//  StorageBarItemCell.swift
//  HashCamera
//
//  Created by WG-Yang on 10/24/23.
//

import UIKit
import SnapKit

class StorageBarItemCell: UICollectionViewCell {
    
    
    enum ColorType {
        
    }
    
    enum IconType {
        case library, iCloud, locale
    }
    var iconImageView:  UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFill
        imageView.backgroundColor = .white
        return imageView
    }()
    
    var thumbnailImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFill
        return imageView
    }()
    
    
    //
    
    
    func initView() {
        self.addSubview(thumbnailImageView)
        self.addSubview(iconImageView)
        
        thumbnailImageView.snp.makeConstraints { make in
            make.edges.equalTo(self)
        }
        
        iconImageView.snp.makeConstraints { make in
            make.width.equalTo(iconImageView.snp.height)
            make.width.equalTo(thumbnailImageView).multipliedBy(0.25)
        }
    }
}

