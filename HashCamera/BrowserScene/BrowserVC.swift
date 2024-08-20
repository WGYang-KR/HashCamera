//
//  BrowserVC.swift
//  HashCamera
//
//  Created by Anto-Yang on 7/18/24.
//

import UIKit
import RxSwift
import SideMenu

class BrowserVC: UIViewController, UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout {

    var disposeBag = DisposeBag()
    let vm = BrowserVM()
    
    @IBOutlet weak var collectionView: UICollectionView!
    @IBOutlet weak var bottomBarLabel: UILabel!
    var itemSize: CGSize = .zero
    var itemSpacing: CGFloat = 2.0
    
    let menu  = SideMenuNavigationController(rootViewController: SideMenuVC())
    
    override func viewDidLoad() {
        super.viewDidLoad()
        initUI()
        initCollectionView()
        initVM()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        navigationController?.setNavigationBarHidden(false, animated: false)
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        let width = (self.view.bounds.width - (itemSpacing * 2) ) / 3
        self.itemSize = CGSize(width: width, height: width)
        vm.thumbnailSize = self.itemSize
    }
    
    func initUI() {
        // Navi Bar
        let naviLeftItems = [naviBackBarButtonItem(),
                             UIBarButtonItem(image: SystemUIImage.listBullet,
                                             style: .plain,
                                             target: self,
                                             action: #selector(naviListBtnTapped))]
        
        let naviRightItems = [UIBarButtonItem(image: SystemUIImage.checkmarkCircle,
                                              style: .plain,
                                              target: self,
                                              action: #selector(naviSelectionBtnTapped))]
        setNaviBar("Browser", leftItems: naviLeftItems, rightItems: naviRightItems)
        
        // Side Bar
        menu.leftSide = true
    }
    
    
    func initVM() {
        vm.fileList.subscribe { [weak self] list in
            self?.collectionView.reloadData()
        }.disposed(by: disposeBag)

        vm.initFileList()
    }
    
    func initCollectionView() {
        
        collectionView.dataSource = self
        collectionView.delegate = self
        
        collectionView.register(UINib(nibName: "\(BrowserItemCell.self)",
                                      bundle: nil),
                                forCellWithReuseIdentifier: "\(BrowserItemCell.self)")
        
    
        //콜렉션뷰
        if let collectionLayout = collectionView.collectionViewLayout as?  UICollectionViewFlowLayout {
            collectionLayout.scrollDirection = .vertical
            collectionLayout.minimumLineSpacing = .zero
            collectionLayout.minimumInteritemSpacing = .zero
        }
    
    }

    //MARK: - CollectionView DataSource
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return vm.fileList.value.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {

        guard let cell =  collectionView
            .dequeueReusableCell(withReuseIdentifier: "\(BrowserItemCell.self)", for: indexPath)
                as? BrowserItemCell else { return UICollectionViewCell()}
        hcLog("썸네일 로드요청 index:\(indexPath.item) imageSize: \(itemSize)")
        vm.startFetchingThumb(index: indexPath.item) { image in
            DispatchQueue.main.async {
                //셀 indexPath가 바뀌었는지 확인
                if collectionView.indexPath(for: cell) == indexPath, let image {
                    cell.imageView.image = image
                    hcLog("썸네일 로드완 index:\(indexPath.item) imageSize: \(image.size)")
                } else {
                    hcLog("Cell 위치 변함 or image == nil")
                }
            }
        }
        
        return cell
    }
    
    //MARK: - CollectionView Delegate
    func collectionView(_ collectionView: UICollectionView, didEndDisplaying cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
        vm.stopFetchingThumb(index: indexPath.item)
    }
    
    //MARK: - CollectionView Delegate FlowLayout
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return itemSize
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
        return UIEdgeInsets.zero
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        return itemSpacing
    }
    
    //MARK: -
    
    @objc func naviListBtnTapped() {
        present(menu, animated: true)
    }
    
    @objc func naviSelectionBtnTapped() {
        
    }
    
    @IBAction func shareBtnTapped(_ sender: Any) {
        
    }
    
    @IBAction func trashBtnTapped(_ sender: Any) {
        
    }
    
    @IBAction func tagBtnTapped(_ sender: Any) {
        
    }
    


}
