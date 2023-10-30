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
    
    ///스토리지 종류
    var storageType: StorageType = .photoLibrary
    
    ///스토리지 아이콘 이미지 표시뷰
    private var thumbnailImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFill
        return imageView
    }()
    
    ///셀 선택 효과 뷰
    private var selectionCoverView: UIView = makeCoverView()
    
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
        self.addSubview(selectionCoverView)
        
        self.backgroundColor = .white //하얀색 바탕
        self.layer.cornerRadius = 3.0 //라운드 코너
        self.clipsToBounds = true //자식뷰도 라운드 코너 적용

        
        thumbnailImageView.snp.makeConstraints { make in
            make.edges.equalTo(self).inset(8) //상하좌우 여백 8
        }
        
        selectionCoverView.snp.makeConstraints { make in
            make.edges.equalTo(self)
        }
        
        updateUI(isSelected: false) //선택안된 UI로 초기화
    }

    //MARK: - configure
    
    func configure(storageType: StorageType) {
        self.storageType = storageType
        self.thumbnailImageView.image = iconImage(storageType: storageType)
    }
    
    //MARK: - selection
    override var isSelected: Bool {
        willSet {
            updateUI(isSelected: isSelected)
        }
    }
    
    private func updateUI(isSelected: Bool) {
            self.selectionCoverView.isHidden = !isSelected
    }
    
    //MARK: -
    private func iconImage(storageType: StorageType) -> UIImage {
        switch storageType {
        case .iCloudDrive:
            return UIImage(named: "tabIconiCloud")!
        case .localDrive:
            return  UIImage(named: "tabIconFile")!
        case .photoLibrary:
            return UIImage(named: "tabIconPhotoLibrary")!
        }
    }
    
    static private func makeCoverView() -> UIView {
        let view = UIView()
        view.backgroundColor = UIColor(white: 1.0, alpha: 0.5) //배경 불투명
        
        let imageView = UIImageView()
        imageView.image = UIImage(systemName: "checkmark")?.withTintColor(.white)
        imageView.contentMode = .scaleAspectFit
        
        view.addSubview(imageView)
        imageView.snp.makeConstraints { make in
            make.centerX.centerY.equalTo(view) //컨테이너의 중앙
            make.width.equalTo(view).multipliedBy(0.25) // 컨테이너의 1/4
        }
        
        return view
    }
    
}

