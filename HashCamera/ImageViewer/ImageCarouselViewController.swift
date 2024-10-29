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
    
    private var onRightNavBarTapped:((Int) -> Void)?
    
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
    
    private func addNavBar() {
        // Add Navigation Bar
        let closeBarButton = naviBackBarButtonItem()
        setNaviBar("", leftItems: [closeBarButton], rightItems: nil)
    }
    
    private func addToolBar() {
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
        
        let spacing = 10.0
        let items: [UIBarButtonItem] = [shareBtn , .fixedSpace(spacing), dummyBtn, .flexibleSpace(), trashBtn, .fixedSpace(spacing), folderBtn]

        setToolbar(items: items)
        navigationController?.setToolbarHidden(false, animated: true)
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
            setViewControllers([initialVC], direction: .forward, animated: true)
        }
        
    }

    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        dataSource = self
        delegate = self
        
        addBackgroundView()
        addNavBar()
        addToolBar()
        setInitialPage(initialIndex)
      
        photoListVM?.fileListUpdatedRx.bind(onNext: { [weak self] updateData in
            guard let self else { return }
            guard updateData.folderUpdateData.newFileList.count > 0 else { dismiss(nil); return }
            
            switch updateData.folderUpdateData.changeType {
            case .initiate:
                //initialIndex로 초기화
                setInitialPage(initialIndex)
            case .add(let newIndex):
                //newIndex부터 끝까지 존재하는 vc들 index + 1
                children.forEach({ vc in
                    if let imageViewerVC = vc as? ImageViewerController, imageViewerVC.index >= newIndex {
                        imageViewerVC.index += 1
                    }
                })
                
            case .delete(let deletedIndex):
                //현재 사진 삭제되었으면 앞의 사진으로 initialIndex 세팅
                guard let currentVC = viewControllers?.first as? ImageViewerController else { dismiss(nil); return }
                
                var shouldReinit = false
                if deletedIndex == currentVC.index {
                    shouldReinit = true
                    initialIndex = currentVC.index - 1 >= 0 ? currentVC.index - 1 : 0
                }
                
                //deletedIndex부터 끝까지 존재하는 vc들 index - 1
                children.forEach({ vc in
                    if let imageViewerVC = vc as? ImageViewerController, imageViewerVC.index >= deletedIndex {
                        imageViewerVC.index -= 1
                    }
                })
                
                //initialIndex로 재세팅
                if shouldReinit {
                    setInitialPage(initialIndex)
                }
            case .rename(let oldIndex, _):
                //현재 사진이면 이름 레이블 갱신
                guard let currentVC = viewControllers?.first as? ImageViewerController else { dismiss(nil); return}
                if oldIndex == currentVC.index {
                    if let photoListVM, let item = photoListVM.fileList[safe: currentVC.index] {
                        navigationController?.navigationBar.topItem?.title = item.fileName
                    }
                    
                }
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
    
    @objc
    func diTapRightNavBarItem(_ sender:UIBarButtonItem) {
        guard let onTap = onRightNavBarTapped,
            let _firstVC = viewControllers?.first as? ImageViewerController
            else { return }
        onTap(_firstVC.index)
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
        nextVC.configure(initialSelectedFolder: photoListVM.rootURL, targetFileList: [currentItem])
        present(UINavigationController(rootViewController: nextVC), presentationStyle: .pageSheet, transitionStyle: nil, animated: true)
    }
    
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        if theme == .dark {
            return .lightContent
        }
        return .default
    }
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
