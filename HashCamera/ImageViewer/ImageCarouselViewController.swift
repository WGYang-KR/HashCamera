import UIKit

class ImageCarouselViewController:UIPageViewController, ImageViewerTransitionViewControllerConvertible {
    
    unowned var initialSourceView: UIImageView?
    weak var photoListVM: PhotoListVM?
    
    
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
    
    var theme:ImageViewerTheme = .light {
        didSet {
            navItem.leftBarButtonItem?.tintColor = theme.tintColor
            backgroundView?.backgroundColor = theme.color
        }
    }
    
    var imageContentMode: UIView.ContentMode = .scaleAspectFill
    
    private var onRightNavBarTapped:((Int) -> Void)?
    
    var navBar: UINavigationBar {
        self.navigationController!.navigationBar
    }
    
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
//        navItem.leftBarButtonItem = closeBarButton
//        navItem.leftBarButtonItem?.tintColor = .systemCyan
//        navBar.alpha = 1.0
//        navBar.items = [navItem]
//        navBar.insert(to: view)
    }
    
    private func addBackgroundView() {
        guard let backgroundView = backgroundView else { return }
        view.addSubview(backgroundView)
        backgroundView.bindFrameToSuperview()
        view.sendSubviewToBack(backgroundView)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        addBackgroundView()
        addNavBar()
        
        dataSource = self
        delegate = self
        
        //첫번째 사진을 세팅한다
        if let photoListVM, let item = photoListVM.fileList[safe: initialIndex] {
            let initialVC:ImageViewerController = .init(index: initialIndex,
                                                        imageItem: item,
                                                        imageLoader: SDWebImageLoader())
            navBar.topItem?.title = item.fileName
            setViewControllers([initialVC], direction: .forward, animated: true)
        }
        
    }

    @objc
    private func dismiss(_ sender:UIBarButtonItem) {
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
            navBar.topItem?.title = currentVC.imageItem.fileName
        }
    }
    
}
