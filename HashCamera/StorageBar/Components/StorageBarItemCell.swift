//
//  StorageBarItemCell.swift
//  HashCamera
//
//  Created by WG-Yang on 10/24/23.
//

import UIKit
import SnapKit
import Photos

class StorageBarItemCell: UICollectionViewCell {
    
    var storageType: StorageType = .photoLibrary
    
    ///스토리지 아이콘 이미지 표시뷰
    private var thumbnailImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFill
        return imageView
    }()
    
    //MARK: - init
    override init(frame: CGRect) {
        super.init(frame: frame)
        initView()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        initView()
    }
    
    private func initView() {
        self.addSubview(thumbnailImageView)
        
        thumbnailImageView.snp.makeConstraints { make in
            make.edges.equalTo(self)
        }
        
    }
    //MARK: - configure
    
    func configure(storageType: StorageType) {
        self.storageType = storageType
        self.thumbnailImageView.image = iconImage(storageType: storageType)
    }
    
    private func iconImage(storageType: StorageType) -> UIImage {
        switch storageType {
        case .iCloudDrive:
            return UIImage(named: "iconiCloud")!
        case .localDrive:
            return  UIImage(named: "iconFile")!
        case .photoLibrary:
            return UIImage(named: "iconPhotoLibrary")!
        }
    }
    
}

