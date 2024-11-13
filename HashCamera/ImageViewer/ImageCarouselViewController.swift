import UIKit
import RxSwift
import RxRelay

class ImageCarouselViewController:UIPageViewController, ImageViewerTransitionViewControllerConvertible {
    
    var disBag = DisposeBag()
    weak var photoListVM: PhotoListVM?
    
    unowned var initialSourceView: UIImageView?
    
    ///이 VC를 호출한 ImageView
    var sourceView: UIImageView? {
        guard let vc = viewControllers?.first as? ImageViewerController else {
            return nil
        }
        return initialIndex == vc.index ? initialSourceView : nil
    }
    
    var targetView: UIImageView? {
        guard let vc = viewControllers?.first as? ImageViewerController else {
            return nil
        }
        return vc.imageView
    }
    
 
    var initialIndex = 0
    ///현재 보여지고 있는 뷰어
    var currentVC: ImageViewerController? {
        return (viewControllers?.first) as? ImageViewerController
    }
    ///현재보여지고 있는 이미지 정보
    var currentItem: ImageFileModel? {
        guard let currentVC else { return nil }
        return photoListVM?.fileList[safe: currentVC.index]
    }
    
    var theme:ImageViewerTheme = .light {
        didSet {
            navItem.leftBarButtonItem?.tintColor = theme.tintColor
            backgroundView?.backgroundColor = theme.color
        }
    }
    
    var imageContentMode: UIView.ContentMode = .scaleAspectFill

    private(set) lazy var backgroundView:UIView? = {
        let _v = UIView()
        _v.backgroundColor = theme.color
        _v.alpha = 1.0
        return _v
    }()
    
    private(set) lazy var navItem = UINavigationItem()
    
    private let imageViewerPresentationDelegate: ImageViewerTransitionPresentationManager
    
    init(sourceView: UIImageView, photoListVM: PhotoListVM?, initialIndex:Int = 0) {
        
        self.initialSourceView = sourceView
        self.initialIndex = initialIndex
        self.photoListVM = photoListVM
        
        let pageOptions = [UIPageViewController.OptionsKey.interPageSpacing: 20]
        
        imageContentMode = .scaleAspectFill
        
        self.imageViewerPresentationDelegate = ImageViewerTransitionPresentationManager(imageContentMode: imageContentMode)
       
        super.init(
            transitionStyle: .scroll,
            navigationOrientation: .horizontal,
            options: pageOptions)
        
        transitioningDelegate = imageViewerPresentationDelegate
        modalPresentationStyle = .custom
        modalPresentationCapturesStatusBarAppearance = true
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        dataSource = self
        delegate = self
        
        addBackgroundView()
        initNavBar()
        initToolBar()
        setInitialPage(initialIndex)
      
        photoListVM?.fileListUpdatedRx.bind(onNext: { [weak self] updateData in
            guard let self else { return }
            guard updateData.folderUpdateData.newFileList.count > 0 else { dismiss(nil); return }
            
            switch updateData.folderUpdateData.changeType {
            case .initiate:
                //initialIndex로 초기화
                setInitialPage(initialIndex)
                
            case .changed(let deletedIndice, let addedIndice):
                
                //현재 vc없으면 dismiss
                guard let currentVC = viewControllers?.first as? ImageViewerController else { dismiss(nil); return}
                
                var shouldReinit = false
                
                
                if deletedIndice.contains(currentVC.index) &&
                    addedIndice.contains(currentVC.index) { //Rename
                    //현재 vc 인덱스가 deletedIndice, addedIndice에 모두에 해당하면 현재 initial Index로 갱신 예약을 한다.
                    shouldReinit = true
                    
                } else if deletedIndice.contains(currentVC.index) { // Deleted
                    //현재 vc 인덱스가 deletedIndice에만 해당하면 앞의 사진으로 initialIndex로 갱신 예약한다.
                    shouldReinit = true
                    initialIndex = currentVC.index - 1 >= 0 ? currentVC.index - 1 : 0
                }
                
                
             
                deletedIndice.reversed().forEach{ deletedIndex in
                    //현재 vc들 뒤에서 부터 deletedIndex가 존재하면 index가 크거나 같은 vc들 index -1 한다.
                    self.children.forEach({ vc in
                        if let imageViewerVC = vc as? ImageViewerController, imageViewerVC.index >= deletedIndex {
                            imageViewerVC.index -= 1
                        }
                    })
                }
                addedIndice.reversed().forEach { addedIndex in
                    //현재 vc들 뒤에서 부터 addedIndex가 존재하면 index가 크거나 작은 vc들 index + 1 한다.
                    self.children.forEach({ vc in
                        if let imageViewerVC = vc as? ImageViewerController, imageViewerVC.index >= addedIndex {
                            imageViewerVC.index += 1
                        }
                    })
                }
                
                //필요 시에 initialIndex로 재세팅
                if shouldReinit {
                    setInitialPage(initialIndex)
                }
                
            case .filesUpdated:
                break
            }
            
        })
        .disposed(by: disBag)
        
    }

    @objc
    private func dismiss(_ sender: UIBarButtonItem?) {
        self.dismiss(animated: true, completion: nil)
    }
    
    deinit {
        initialSourceView?.alpha = 1.0
    }
    
    private func addBackgroundView() {
        guard let backgroundView = backgroundView else { return }
        view.addSubview(backgroundView)
        backgroundView.bindFrameToSuperview()
        view.sendSubviewToBack(backgroundView)
    }
    
    private func setInitialPage(_ index: Int) {
        //첫번째 사진을 세팅한다
        if let photoListVM, let item = photoListVM.fileList[safe: initialIndex] {
            let initialVC:ImageViewerController = .init(index: initialIndex,
                                                        imageItem: item,
                                                        imageLoader: SDWebImageLoader())
            navigationController?.navigationBar.topItem?.title = item.fileName
            setViewControllers([initialVC], direction: .reverse, animated: true)
        }
        
    }

    //MARK: - 네비바, 툴바, StatusBar
    //네비바 버튼
    var closeBarBtn: UIBarButtonItem!
    var editBarBtn: UIBarButtonItem!
    var cancelBarBtn: UIBarButtonItem!
    var confirmBarBtn: UIBarButtonItem!
    
    //툴바
    var normalToolBar: [UIBarButtonItem]!
    var editToolBar: [UIBarButtonItem]!
    

    override var preferredStatusBarStyle: UIStatusBarStyle {
        if theme == .dark {
            return .lightContent
        }
        return .default
    }
    
    ///네비바를 초기화한다
    private func initNavBar() {
        editBarBtn = UIBarButtonItem(title: "편집",
                                  style: .plain,
                                  target: self,
                                  action: #selector(editBarBtnTapped))
        cancelBarBtn = UIBarButtonItem(title: "취소",
                                    style: .plain,
                                    target: self,
                                    action: #selector(cancelBarBtnTapped))
        cancelBarBtn.tintColor = .orange
        confirmBarBtn = UIBarButtonItem(title: "확인",
                                     style: .plain,
                                     target: self,
                                     action: #selector(confirmBarBtnTapped))
        closeBarBtn = naviBackBarButtonItem()
        
        // 네비게이션 바 색상 설정
        let appearance = UINavigationBarAppearance()
        
        // 투명한 배경을 유지하고 색상을 설정
        appearance.configureWithTransparentBackground()
        appearance.backgroundColor = .naviBarBackground.withAlphaComponent(0.5)  // 반투명 효과
        appearance.backgroundEffect = UIBlurEffect(style: .light)  // Blur 효과 추가
        
        // 제목 텍스트 색상 설정
        appearance.titleTextAttributes = [.foregroundColor: UIColor.label]

        // 버튼 텍스트 색상 설정
        navigationController?.navigationBar.tintColor = .systemCyan
        
        // standardAppearance와 scrollEdgeAppearance 모두에 적용
        navigationController?.navigationBar.standardAppearance = appearance
        navigationController?.navigationBar.scrollEdgeAppearance = appearance
        
        //아이콘 세팅
        self.navigationItem.leftBarButtonItems = [closeBarBtn]
        self.navigationItem.rightBarButtonItems = [editBarBtn]
    
    }

    ///툴바를 초기화한다.
    private func initToolBar() {
        // Tool Bar
        let shareBtn = UIBarButtonItem(image: SystemUIImage.squareAndArrowUp,
                                       style: .plain,
                                       target: self,
                                       action: #selector(shareBtnTapped))
        let trashBtn = UIBarButtonItem(image: SystemUIImage.trash,
                                       style: .plain,
                                       target: self,
                                       action: #selector(trashBtnTapped))
        let folderBtn = UIBarButtonItem(title: "이동",
                                    style: .done,
                                    target: self,
                                    action: #selector(moveBtnTapped))
        
        let dummyBtn = UIBarButtonItem(image: nil,
                                       style: .plain,
                                       target: nil,
                                       action: nil)
        
        let rotateBtn = UIBarButtonItem(image: SystemUIImage.rotateLeft,
                                        style: .plain,
                                        target: self,
                                        action: #selector(rotateBtnTapped))
        let spacing = 10.0
        
        normalToolBar = [shareBtn , .fixedSpace(spacing), dummyBtn, .flexibleSpace(), trashBtn, .fixedSpace(spacing), folderBtn]

        editToolBar = [.flexibleSpace(), rotateBtn, .flexibleSpace()]
        
        setToolbar(items: normalToolBar)
        navigationController?.setToolbarHidden(false, animated: true)
    }
    
    ///편집 모드를 선택/해제 한다.
    func setEditMode(_ isEditing: Bool) {
        //아이콘 세팅
        self.navigationItem.leftBarButtonItems = [closeBarBtn]
        self.navigationItem.rightBarButtonItems = [editBarBtn]
        if isEditing {
            navigationItem.setLeftBarButtonItems([cancelBarBtn], animated: true)
            navigationItem.setRightBarButtonItems([confirmBarBtn], animated: true)
            setToolbarItems(editToolBar, animated: true)
            currentVC?.view.isUserInteractionEnabled = false
            self.view.isUserInteractionEnabled = false
        } else {
            navigationItem.setLeftBarButtonItems([closeBarBtn], animated: true)
            navigationItem.setRightBarButtonItems([editBarBtn], animated: true)
            setToolbarItems(normalToolBar, animated: true)
            currentVC?.view.isUserInteractionEnabled = true
            self.view.isUserInteractionEnabled = true
        }
        
        currentVC?.zoomOut()
    }
    
    
    @objc func shareBtnTapped(_ sender: Any) {
        guard let photoListVM, let currentItem else { return }
        ShareHelper.shared
            .share(files: [currentItem]
                .map({ FileShareItem(fileURL: $0.url,
                                     previewImage: $0.thumbnailImage,
                                     fileTitle: $0.fileName) }),
                   viewController: self)
    }
    
    @objc func trashBtnTapped(_ sender: Any) {
        guard let currentVC = viewControllers?.first as? ImageViewerController else { dismiss(nil); return}
        guard let photoListVM else { return }
        AlertHelper.alertConfirm(baseVC: self, title: "사진을 삭제하시겠습니까?", message: "") {
            Task {
                let result = await photoListVM.deleteFiles(at: [IndexPath(row: currentVC.index, section: 0)])
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
        guard let photoListVM, let currentItem else { return }
        let nextVC = MoveToFolderVC()
        nextVC.configure(initialSelectedFolder: photoListVM.rootFolder, targetFileList: [currentItem])
        present(UINavigationController(rootViewController: nextVC), presentationStyle: .pageSheet, transitionStyle: nil, animated: true)
    }
    
    
    
    @objc func editBarBtnTapped(_ sender: Any) {
        setEditMode(true)
    }
    
    @objc func cancelBarBtnTapped(_ sender: Any) {
        setEditMode(false)
        //원본 방향과 같지 않으면
        //원래 방향으로 imageViewer 복구
        currentVC?.cancelRotate()
    }
    
    @objc func confirmBarBtnTapped (_ sender: Any) {
        //원본 방향과 같지 않으면
        //변경된 방향 값으로 파일 저장
        currentVC?.confirmRotate()
        setEditMode(false)
    }
    
    @objc func rotateBtnTapped(_ sender: Any) {
        //이미지 회전(회전한 값은 imageViewer 클래스에 저장)
        
        //기본 줌 값 갱신
        currentVC?.rotateLeft()
                
    }
    
    //MARK: -

}

extension ImageCarouselViewController:UIPageViewControllerDataSource, UIPageViewControllerDelegate {
    
    func pageViewController(_ pageViewController: UIPageViewController, viewControllerBefore viewController: UIViewController) -> UIViewController? {
        
        guard let vc = viewController as? ImageViewerController else { return nil }
        guard let photoListVM else { return nil }
        guard vc.index > 0 else { return nil }
        
        let newIndex = vc.index - 1
        guard let item = photoListVM.fileList[safe: newIndex] else { return nil}
        return ImageViewerController.init(
            index: newIndex,
            imageItem: item,
            imageLoader: vc.imageLoader)
    }
    
    func pageViewController( _ pageViewController: UIPageViewController, viewControllerAfter viewController: UIViewController) -> UIViewController? {
        
        guard let vc = viewController as? ImageViewerController else { return nil }
        guard let photoListVM else { return nil }
        guard vc.index <= (photoListVM.fileList.count - 2) else { return nil }
        
        let newIndex = vc.index + 1
        guard let item = photoListVM.fileList[safe: newIndex] else { return nil}
        return ImageViewerController.init(
            index: newIndex,
            imageItem: item,
            imageLoader: vc.imageLoader)
    }
    
    func pageViewController(_ pageViewController: UIPageViewController, didFinishAnimating: Bool, previousViewControllers: [UIViewController], transitionCompleted: Bool) {
        
        if transitionCompleted {
            guard let currentVC = pageViewController.viewControllers?.first as? ImageViewerController else { return }
            navigationController?.navigationBar.topItem?.title = currentVC.imageItem.fileName
        }
    }
    
}
