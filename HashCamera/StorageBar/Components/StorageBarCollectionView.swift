//
//  StorageBarCollectionView.swift
//  HashCamera
//
//  Created by WG-Yang on 10/24/23.
//

import UIKit
import SnapKit

class StorageBarCollectionView: UICollectionView,UICollectionViewDelegate, UICollectionViewDataSource {
  
    
    let cellSize = CGSize(width: 60, height: 60)
    var storageList: [StorageType] = [.iCloudDrive, .localDrive, .photoLibrary]
    

    func initView() {
        self.delegate = self
        self.dataSource = self
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return storageList.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "\(StorageBarItemCell.self)", for: indexPath) as? StorageBarItemCell else { return UICollectionViewCell() }
        
        return cell
    }
    
}
