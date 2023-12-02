//
//  BrowseriCloudVC.swift
//  HashCamera
//
//  Created by WG-MacHome on 11/29/23.
//

import UIKit
import RxSwift
//import RxGesture
class BrowseriCloudVC: UIViewController, UICollectionViewDataSource, UICollectionViewDelegate , UICollectionViewDelegateFlowLayout{
  

    let browserModel = FileBrowserModel(storageType: .iCloudDrive)
    
    @IBOutlet weak var collectionView: UICollectionView!
    
    var disposeBag = DisposeBag()
    
    lazy var itemSize: CGSize =  {
        let itemLength = UIScreen.main.bounds.width / 3
        return CGSize(width: itemLength, height: itemLength)
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()

        
        initNavi()
        initView()
        initData()
    }
    
    
    func initNavi() {
        let backBtn = UIBarButtonItem.init(image: UIImage(systemName: "chevron.left")?.withTintColor(.black, renderingMode: .alwaysOriginal),
                                           style: .plain,
                                           target: nil,
                                           action: nil)
        
        backBtn.rx.tap.bind { [weak self] _ in
            self?.movePrevVC(animated: true)
        }.disposed(by: disposeBag)
        
        self.navigationItem.leftBarButtonItem = backBtn
    }
    
    func initView() {
        collectionView.dataSource = self
        collectionView.delegate = self

        collectionView.register(UINib(nibName: "\(BrowserItemCell.self)",
                                      bundle: nil),
                                forCellWithReuseIdentifier: "\(BrowserItemCell.self)")
    }
    
    func initData() {
        
        browserModel.thumbnailSize = CGSize(width: itemSize.width * 2, height: itemSize.height * 2)
        
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            guard let self else { return }
            browserModel.initFileList()
            DispatchQueue.main.async{ [weak self] in
                self?.collectionView.reloadData()

            }
        }

        
    }
    
    
    
    //MARK: - collection View
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return browserModel.fileList.count
    }
    

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return itemSize
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
        return UIEdgeInsets.zero
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        return .zero
    }
    
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        
        guard let cell =  collectionView
            .dequeueReusableCell(withReuseIdentifier: "\(BrowserItemCell.self)", for: indexPath)
                as? BrowserItemCell else { return UICollectionViewCell()}
        
        
        browserModel.startFetchingThumb(index: indexPath.item) { image in
            
            DispatchQueue.main.async {
                //셀 indexPath가 바뀌었는지 확인
                if collectionView.indexPath(for: cell) == indexPath {
                    cell.imageView.image = image
                    hcLog("imageSize: \(image?.size)")
                }
            }
        }
        
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, didEndDisplaying cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
        browserModel.stopFetchingThumb(index: indexPath.item)
    }
    
    
}
