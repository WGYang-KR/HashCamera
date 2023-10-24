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
    
    var storageData: StorageData?
    
    ///icon 표시 뷰
    var iconImageView:  UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFill
        imageView.backgroundColor = .white
        return imageView
    }()
    
    ///이미지 표시부
    var thumbnailImageView: UIImageView = {
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
        self.addSubview(iconImageView)
        
        thumbnailImageView.snp.makeConstraints { make in
            make.edges.equalTo(self)
        }
        
        iconImageView.snp.makeConstraints { make in
            make.top.trailing.equalTo(self) //상단우측 정렬
            make.width.equalTo(iconImageView.snp.height) // 1:1 비율
            make.width.equalTo(self).multipliedBy(0.25) // superView의 1/4 사이즈
        }
    }
    
    //MARK: - configure
    
    func configure(storageData: StorageData) {
        self.storageData = storageData
        self.iconImageView.image = iconImage(storageType: storageData.type)
        
        //To do 썸네일 가져오기
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

