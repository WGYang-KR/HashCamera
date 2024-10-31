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
    var selectionModeBtn: UIBarButtonItem!
    var shareBtn: UIBarButtonItem!
    var trashBtn: UIBarButtonItem!
    var folderBtn: UIBarButtonItem!

    
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
        
        menu.menuWidth = view.bounds.width / 3 * 2
    }
    
    func initUI() {
        // Navi Bar
        let naviLeftItems = [naviBackBarButtonItem(),
                             UIBarButtonItem(image: SystemUIImage.listBullet,
                                             style: .plain,
                                             target: self,
                                             action: #selector(naviListBtnTapped))]
        
        selectionModeBtn = UIBarButtonItem(title: "선택",
                                              style: .plain,
                                              target: self,
                                              action: #selector(naviSelectionBtnTapped))
        setNaviBar("", leftItems: naviLeftItems, rightItems: [selectionModeBtn])
        
        // Side Bar
        menu.leftSide = true
        menu.enableSwipeToDismissGesture = false
        SideMenuManager.default.leftMenuNavigationController = menu
//        let sideBarGesture = menu.sideMenuManager.addScreenEdgePanGesturesToPresent(toView: self.view, forMenu: .left)
        menu.sideMenuManager.addPanGestureToPresent(toView: self.view)
        
        // Tool Bar
        shareBtn = UIBarButtonItem(image: SystemUIImage.squareAndArrowUp,
                                       style: .plain,
                                       target: self,
                                       action: #selector(shareBtnTapped))
        trashBtn = UIBarButtonItem(image: SystemUIImage.trash,
                                       style: .plain,
                                       target: self,
                                       action: #selector(trashBtnTapped))
        folderBtn = UIBarButtonItem(title: "이동",
                                    style: .done,
                                    target: self,
                                    action: #selector(moveBtnTapped))
        
        let dummyBtn = UIBarButtonItem(image: nil,
                                       style: .plain,
                                       target: nil,
                                       action: nil)
        
        let labelItem = UIBarButtonItem(customView: toolBarLabel)
        toolBarLabel.font = .systemFont(ofSize: 14.0, weight: .regular)
        toolBarLabel.textColor = .label
        toolBarLabel.lineBreakMode = .byTruncatingTail
        toolBarLabel.numberOfLines = 1
      
   
        let iconColor = UIColor.systemCyan
        let spacing = 10.0
        let items: [UIBarButtonItem] = [shareBtn, .fixedSpace(spacing), dummyBtn, .fixedSpace(spacing), .flexibleSpace(), labelItem, .flexibleSpace(),  .fixedSpace(spacing), trashBtn, .fixedSpace(spacing), folderBtn]
        
        for item in items {
            item.tintColor = iconColor
            item.setTitleTextAttributes([.foregroundColor: iconColor], for: .normal)
        }
        
        setToolbarItems(items, animated: false)
        updateToolbarUI()

    }
    
    func initVM() {
        
        ///파일 목록 갱신시 처리
        vm.fileListUpdatedRx.bind { [weak self] updateData in
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
        .disposed(by: disposeBag)
        
        //선택 폴더 갱신시 처리
        folderListVC.vm.selectedFolderUpdated = { [weak self] folderListItemModel in
            guard let self, let folderListItemModel else {return }
            //네비바 타이틀
            navigationItem.title = folderListItemModel.name
            
            setSelectionMode(false)
            
            //vm root폴더 지정
            vm.configure(rootFolder: folderListItemModel)
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
    }
    
    //MARK: - CollectionView Delegate
    func collectionView(_ collectionView: UICollectionView, didEndDisplaying cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
        vm.stopFetchingThumb(index: indexPath.item)
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        if collectionView.allowsMultipleSelection {
            vm.selectedIndexPaths.append(indexPath)
            updateToolbarUI()
        } else {
            collectionView.deselectItem(at: indexPath, animated: true)
            
            //뷰어이동
            guard let cell = collectionView.cellForItem(at: indexPath) as? PhotoListItemCell else { return }
            let sourceView: UIImageView = cell.imageView
            let imageCarousel = ImageCarouselViewController(sourceView: sourceView, photoListVM: vm, initialIndex: indexPath.item)
            let naviVC = UINavigationController(rootViewController: imageCarousel)
            naviVC.modalPresentationStyle = .custom
            naviVC.modalPresentationCapturesStatusBarAppearance = true
            present(naviVC, animated: true)
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, didDeselectItemAt indexPath: IndexPath) {
        guard let deselectedIndex = vm.selectedIndexPaths.firstIndex(where: {$0 == indexPath}) else { return }
        vm.selectedIndexPaths.remove(at: deselectedIndex)
        updateToolbarUI()
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
        selectionModeBtn.title = selectionMode ? "취소" : "선택"
        
        collectionView.indexPathsForSelectedItems?.forEach{collectionView.deselectItem(at: $0, animated: false)}
        vm.selectedIndexPaths.removeAll()
        
        collectionView.allowsMultipleSelection = selectionMode
        
        updateToolbarUI()
    }
    
    @objc func naviListBtnTapped() {
        present(menu, animated: true)
    }
    
    @objc func naviSelectionBtnTapped() {
        selectionMode = !selectionMode
    }
    
    @objc func shareBtnTapped(_ sender: Any) {
        
        ShareHelper.shared
            .share(files: vm.selectedFiles()
                .map({ FileShareItem(fileURL: $0.url,
                                     previewImage: $0.thumbnailImage,
                                     fileTitle: $0.fileName) }),
                   viewController: self)
        toolBarLabel.sizeToFit()
    }
    
    @objc func trashBtnTapped(_ sender: Any) {

        let itemIndexPaths = vm.selectedIndexPaths
        guard itemIndexPaths.count > 0 else { return }
        
        AlertHelper.alertConfirm(baseVC: self, title: "\(itemIndexPaths.count)개의 사진을 삭제하시겠습니까?", message: "") {
            Task {
                let result = await self.vm.deleteFiles(at: itemIndexPaths)
                switch result {
                case .success:
                    AlertHelper.notesInform(message: "사진 삭제 완료됨", color: .systemCyan)
                case .failure(let error):
                    AlertHelper.notesInform(message: "사진 삭제 실패", color: .systemRed)
                }
            }
        }
    }
    
    @objc func moveBtnTapped(_ sender: Any) {
        let nextVC = MoveToFolderVC()
        nextVC.configure(initialSelectedFolder: vm.rootFolder, targetFileList: vm.selectedFiles())
        present(UINavigationController(rootViewController: nextVC), presentationStyle: .pageSheet, transitionStyle: nil, animated: true)
    }
    
    @objc func updateToolbarUI() {
        toolBarLabel.text = "\(vm.selectedFiles().count)개 선택"
        toolBarLabel.sizeToFit()
        
        let hasSelection = vm.selectedFiles().count > 0
        shareBtn.isEnabled = hasSelection
        trashBtn.isEnabled = hasSelection
        folderBtn.isEnabled = hasSelection

    }

}
