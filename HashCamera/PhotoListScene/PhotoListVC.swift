//
//  PhotoListVC.swift
//  HashCamera
//
//  Created by Anto-Yang on 7/18/24.
//

import UIKit
import RxSwift
import SideMenu

class PhotoListVC: UIViewController, UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout {
    
    var disposeBag = DisposeBag()
    let vm = PhotoListVM()
    let folderListVC = FolderListVC()
    
    @IBOutlet weak var collectionView: UICollectionView!
    let toolBarLabel = UILabel()
    var selectionModeBtn: UIBarButtonItem?
    lazy var menu = {
        return SideMenuNavigationController(rootViewController: folderListVC)
    }()

    
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
        
        let selectionModeBtn = UIBarButtonItem(image: SystemUIImage.checkmarkRectangleStack,
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
        
        //선택 폴더 갱신시 처리
        folderListVC.vm.selectedFolderUpdated = { [weak self] url in
            guard let self, let url else {return }
            
            //폴더 내 파일 변경 이벤트 처리
            vm.configure(rootURL: url){ [weak self] updateData in
                guard let self else { return }
                
                //모든 셀 선택해제
                if let indexPaths = self.collectionView.indexPathsForSelectedItems {
                    let _ = indexPaths.map({self.collectionView.deselectItem(at: $0, animated: false)})
                }
                
                //이벤트별 갱신
                switch updateData.folderUpdateData.changeType {
                case .initiate:
                    collectionView.reloadData()
                case .add(let newIndex):
                    collectionView.performBatchUpdates {
                        self.collectionView.insertItems(at: [.init(item: newIndex, section: 0)])
                    }
                    
                case .delete(let deletedIndex):
                    collectionView.performBatchUpdates {
                        self.collectionView.deleteItems(at: [.init(item: deletedIndex, section: 0)])
                    }
                    
                case .rename(let oldIndex, let newIndex):
                    collectionView.performBatchUpdates {
                        self.collectionView.moveItem(at: .init(item: oldIndex, section: 0),
                                                to: .init(item: newIndex, section: 0))
                    }
                    
                }
            }
        }
        
        let _ = folderListVC.view //폴더 목록 VM 활성화.

    }

  
    
    //MARK: - CollectionView Delegate
    func initCollectionView() {
        
        collectionView.dataSource = self
        collectionView.delegate = self
        collectionView.allowsMultipleSelection = true
    
        collectionView.register(UINib(nibName: "\(PhotoListItemCell.self)",
                                      bundle: nil),
                                forCellWithReuseIdentifier: "\(PhotoListItemCell.self)")
        
        if let collectionLayout = collectionView.collectionViewLayout as?  UICollectionViewFlowLayout {
            collectionLayout.scrollDirection = .vertical
            collectionLayout.minimumLineSpacing = .zero
            collectionLayout.minimumInteritemSpacing = .zero
        }
        
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return vm.fileList.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {

        guard let cell =  collectionView
            .dequeueReusableCell(withReuseIdentifier: "\(PhotoListItemCell.self)", for: indexPath)
                as? PhotoListItemCell else { return UICollectionViewCell()}
       
        
        return cell
    }
    func collectionView(_ collectionView: UICollectionView, willDisplay cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
        guard let cell = cell as? PhotoListItemCell else { return }
        
//        hcLog("썸네일 로드요청 index:\(indexPath.item) imageSize: \(itemSize)")
        
        //썸네일 설정
        vm.startFetchingThumb(index: indexPath.item) { image in
            DispatchQueue.main.async {
                //셀 indexPath가 바뀌었는지 확인
                if collectionView.indexPath(for: cell) == indexPath, let image {
                    cell.imageView.image = image
//                    hcLog("썸네일 로드완 index:\(indexPath.item) imageSize: \(image.size)")
                } else {
                    hcLog("Cell 위치 변함 or image == nil")
                }
            }
        }
        
        // 이미지뷰어에 정보를 셋팅
        cell.imageView.setupImageViewer(photoListVM: vm,
                                        initialIndex: indexPath.item,
                                        from: self)
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
        selectionModeBtn?.image = selectionMode ? SystemUIImage.checkmarkRectangleStackFill : SystemUIImage.checkmarkRectangleStack
        
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
//        guard let selectedURLs = collectionView.indexPathsForSelectedItems?.map({ vm.files.value[$0.item].url }) else {return}
//        self.moveFolderVM = MoveFolderVM(fileURLs: selectedURLs)
//        self.moveFolderVM.prepare()
//        let movingFolderList = FolderListVC()
//        movingFolderList.sceneType = .moveFolder
//        movingFolderList.vm = self.moveFolderVM
//        present(UINavigationController(rootViewController: movingFolderList), presentationStyle: .pageSheet, transitionStyle: .coverVertical, animated: true)
    }

}
