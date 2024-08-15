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
    
    ///스토리지 아이콘 이미지뷰 바탕뷰
    private let thumbnailContainerView: UIView = UIView()
    
    ///스토리지 아이콘 이미지뷰
    private let thumbnailImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFill
        return imageView
    }()
    
    ///스토리지 이름 표시 레이블
    private let titleLabel: UILabel = {
        let label = UILabel()
        label.numberOfLines = 1
        label.font = UIFont.systemFont(ofSize: 12)
        return label
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
    
    
        //사각형 저장소 버튼 아이콘
        thumbnailContainerView.addSubview(thumbnailImageView)
        thumbnailContainerView.addSubview(selectionCoverView)
        
        thumbnailImageView.snp.makeConstraints { make in
            make.edges.equalTo(thumbnailContainerView).inset(8) //상하좌우 여백 8
        }
        
        selectionCoverView.snp.makeConstraints { make in
            make.edges.equalTo(thumbnailContainerView)
        }
        
        thumbnailContainerView.backgroundColor = .white //하얀색 바탕
        thumbnailContainerView.clipsToBounds = true //자식뷰도 라운드 코너 적용
        thumbnailContainerView.layer.cornerRadius = 6.0 //라운드 코너
        //./
        
        contentView.addSubview(thumbnailContainerView)
        contentView.addSubview(titleLabel)
        
        thumbnailContainerView.snp.makeConstraints { make in
            make.width.equalTo(thumbnailContainerView.snp.height) // 1:1
            make.top.equalToSuperview()
            make.centerX.equalToSuperview()
            make.leading.greaterThanOrEqualToSuperview()
            make.trailing.lessThanOrEqualToSuperview()
        }
        
        titleLabel.snp.makeConstraints { make in
            make.top.equalTo(thumbnailContainerView.snp.bottom).offset(4)
            make.centerX.equalToSuperview()
            make.leading.greaterThanOrEqualToSuperview()
            make.trailing.lessThanOrEqualToSuperview()
            make.bottom.equalToSuperview()
        }
        
        
        updateUI(isSelected: false) //선택안된 UI로 초기화
    }

    //MARK: - configure
    
    func configure(storageType: StorageType) {
        self.storageType = storageType
        self.thumbnailImageView.image = iconImage(storageType: storageType)
        self.titleLabel.text = storageType.simpleString
    }
    
    //MARK: - selection
    override var isSelected: Bool {
        set(new){
            super.isSelected = new
            updateUI(isSelected: isSelected)
        }
        get {
            return super.isSelected
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

