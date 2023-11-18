//
//  StorageBarCollectionView.swift
//  HashCamera
//
//  Created by WG-Yang on 10/24/23.
//

import UIKit
import RxSwift
import RxRelay
import SnapKit

@IBDesignable
class StorageBarCollectionView: UICollectionView, UICollectionViewDelegate, UICollectionViewDataSource {
  
    
    let selectedStorage: BehaviorRelay<StorageType> //선택된 저장소
    
    var storageList: [StorageType] = [.iCloudDrive, .localDrive, .photoLibrary]

    
    init(frame: CGRect, selectedStorage: StorageType) {
        self.selectedStorage = BehaviorRelay<StorageType>(value: selectedStorage)
        super.init(frame: frame, collectionViewLayout: UICollectionViewLayout())
        initView()
    
    }
    
    init(frame: CGRect) {
        self.selectedStorage = BehaviorRelay<StorageType>(value: .photoLibrary)
        super.init(frame: frame, collectionViewLayout: UICollectionViewLayout())
        initView()
    }
    
    required init?(coder: NSCoder) {
        self.selectedStorage = BehaviorRelay<StorageType>(value: .photoLibrary)
        super.init(coder: coder)
        initView()
    }
    
    func initView() {
        self.delegate = self
        self.dataSource = self
        self.register(StorageBarItemCell.self, forCellWithReuseIdentifier: "\(StorageBarItemCell.self)")
        self.allowsMultipleSelection = false
        
        let layout = UICollectionViewFlowLayout()
        let spacing: CGFloat = 8 //아이템 사이의 공간 값
        let cellSize = CGSize(width: 70, height: 70)
        
        let itemCount = CGFloat(integerLiteral: storageList.count )
        let collectionWidth = cellSize.width * itemCount + spacing * ( itemCount + 1 )
        let collectionHeight = cellSize.height + spacing * 2
        let collectionViewSize = CGSize(width: collectionWidth,
                                        height: collectionHeight) //콜렉션뷰 크기
        self.snp.makeConstraints { make in
            make.size.equalTo(collectionViewSize)
        }
        
        layout.itemSize = cellSize //아이템 사이즈 초기화
        layout.scrollDirection = .horizontal // 아이템 스크롤 방향
        layout.sectionInset = UIEdgeInsets(top: spacing, left: spacing, bottom: spacing, right: spacing) //아이템 상하좌우 사이값 초기화
        layout.minimumLineSpacing = spacing //아이템 라인 사이값 초기화
        layout.minimumInteritemSpacing = spacing //아이템 섹션 사이값 초기화
        
        self.collectionViewLayout = layout //CollctionView의 Layout 적용
        self.backgroundColor = UIColor(white: 0.8, alpha: 0.8)
        
        self.layer.cornerRadius = 6.0
        
        if let selectedIndex = storageList.firstIndex(where: {$0 == selectedStorage.value }) {
            selectItem(at: IndexPath(item: selectedIndex, section: 0),
                       animated: true, scrollPosition: .left)
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return storageList.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "\(StorageBarItemCell.self)", for: indexPath) as? StorageBarItemCell else { return UICollectionViewCell() }
        cell.configure(storageType: storageList[indexPath.item])
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        selectedStorage.accept(storageList[indexPath.item])
    }
    
//    override var intrinsicContentSize: CGSize {
//        var s = super.intrinsicContentSize
//        s.height = 40
//        s.width = 40
//        return s
//    }
//    
//    override func prepareForInterfaceBuilder() {
//        invalidateIntrinsicContentSize()
//    }
}
