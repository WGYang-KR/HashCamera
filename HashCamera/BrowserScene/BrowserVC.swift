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
    let toolBarLabel = UILabel()
    var selectionModeBtn: UIBarButtonItem?
    let menu  = SideMenuNavigationController(rootViewController: FolderListVC())
    
    var itemSize: CGSize = .zero
    var itemSpacing: CGFloat = 2.0
    
    var selectionMode: Bool = false {
        didSet {
            setSelectionMode(selectionMode)
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        initUI()
        initCollectionView()
        initVM()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        navigationController?.setNavigationBarHidden(false, animated: false)
        selectionMode = false
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
        
        let selectionModeBtn = UIBarButtonItem(image: SystemUIImage.checkmarkCircle,
                                              style: .plain,
                                              target: self,
                                              action: #selector(naviSelectionBtnTapped))
        self.selectionModeBtn = selectionModeBtn
        let naviRightItems = [selectionModeBtn]
        setNaviBar("Browser", leftItems: naviLeftItems, rightItems: naviRightItems)
        
        // Side Bar
        menu.leftSide = true
        menu.enableSwipeToDismissGesture = false
        //TODO: '왼쪽 스와이프해서 사이드바 열기' 동작 범위 넓혀야함
        SideMenuManager.default.leftMenuNavigationController = menu
        let sideBarGesture = menu.sideMenuManager.addScreenEdgePanGesturesToPresent(toView: self.view, forMenu: .left)
        self.collectionView.panGestureRecognizer.require(toFail: sideBarGesture)
        
        // Tool Bar
        let defaultColor = UIColor.colorTeal02
        let spacing = 8.0
        let shareBtn = UIBarButtonItem(image: SystemUIImage.squareAndArrowUp,
                                       style: .plain,
                                       target: self,
                                       action: #selector(shareBtnTapped))
        let dummyBtn = UIBarButtonItem(image: nil,
                                       style: .plain,
                                       target: nil,
                                       action: nil)
        let labelItem = UIBarButtonItem(customView: toolBarLabel)
        toolBarLabel.font = .systemFont(ofSize: 14.0, weight: .regular)
        toolBarLabel.textColor = defaultColor
        toolBarLabel.lineBreakMode = .byTruncatingTail
        toolBarLabel.numberOfLines = 1
        let trashBtn = UIBarButtonItem(image: SystemUIImage.trash,
                                       style: .plain,
                                       target: self,
                                       action: #selector(trashBtnTapped))
        let tagBtn =  UIBarButtonItem(image: SystemUIImage.tag,
                                      style: .done,
                                      target: self,
                                      action: #selector(tagBtnTapped))
   
        let items = [shareBtn, .fixedSpace(spacing), dummyBtn, .fixedSpace(spacing), .flexibleSpace(), labelItem, .flexibleSpace(),  .fixedSpace(spacing), trashBtn, .fixedSpace(spacing), tagBtn]
        
     
        for item in items {
            item.tintColor = defaultColor
            item.setTitleTextAttributes([.foregroundColor: defaultColor], for: .normal)
        }
        
        self.setToolbarItems(items, animated: false)

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
        collectionView.allowsMultipleSelection = true
    
        collectionView.register(UINib(nibName: "\(BrowserItemCell.self)",
                                      bundle: nil),
                                forCellWithReuseIdentifier: "\(BrowserItemCell.self)")
        
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
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        if collectionView.allowsMultipleSelection {
            
        } else {
            collectionView.deselectItem(at: indexPath, animated: true)
            //뷰어이동
        }
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
    
    ///선택모드를 키고, 끈다.
    func setSelectionMode(_ selectionMode: Bool) {
        guard let navigationController else { return }
        navigationController.setToolbarHidden(!selectionMode, animated: true)
        selectionModeBtn?.image = selectionMode ? SystemUIImage.checkmarkCircleFill : SystemUIImage.checkmarkCircle
        
        collectionView.indexPathsForSelectedItems?.forEach{collectionView.deselectItem(at: $0, animated: false)}
       
        collectionView.allowsMultipleSelection = selectionMode
    }
    
    @objc func naviListBtnTapped() {
        present(menu, animated: true)
    }
    
    @objc func naviSelectionBtnTapped() {
        selectionMode = !selectionMode
    }
    
    @IBAction func shareBtnTapped(_ sender: Any) {
        toolBarLabel.text = "공유버튼 클릭"
        toolBarLabel.sizeToFit()
    }
    
    @IBAction func trashBtnTapped(_ sender: Any) {
        toolBarLabel.text = "삭제버튼 클릭 레이블 내용이 굉장히 길 때를 테스트해 보겠습니다. Ipsem lorem"
        toolBarLabel.sizeToFit()
    }
    
    @IBAction func tagBtnTapped(_ sender: Any) {
        toolBarLabel.text = "태그버튼 클릭"
        toolBarLabel.sizeToFit()
    }
    


}
