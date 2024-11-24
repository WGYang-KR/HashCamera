import UIKit

///이미지 핀치줌을 지원하는 뷰컨트롤러
class ImageViewerController:UIViewController,
UIGestureRecognizerDelegate {
    
    var imageView: UIImageView = UIImageView(frame: .zero)
    let imageLoader: ImageLoader
    
    var backgroundView:UIView? {
        guard let _parent = parent as? ImageCarouselViewController
            else { return nil}
        return _parent.backgroundView
    }
    
    var index:Int = 0
    var imageItem:ImageFileModel!

    var navController: UINavigationController? {
        return (parent as? ImageCarouselViewController)?.navigationController
   
    }
    
    ///네비게이션바, 툴바 보이기/가리기 수행중에 layout() 함수가 실행 안되도록 하기 위한 플래그
    var isChangingNaviHidden = false
    
    // MARK: Layout Constraints
    private var top:NSLayoutConstraint!
    private var leading:NSLayoutConstraint!
    private var trailing:NSLayoutConstraint!
    private var bottom:NSLayoutConstraint!
    
    private var scrollView:UIScrollView!
    
    private var lastLocation:CGPoint = .zero
    private var isAnimating:Bool = false
    private var maxZoomScale:CGFloat = 1.0
    
    
    ///파일 상의 방향
    var originOrientation: UIImage.Orientation = .up
    ///현재 표시 방향
    var currentOrientation: UIImage.Orientation = .up
    
    init(
        index: Int,
        imageItem:ImageFileModel,
        imageLoader: ImageLoader) {

        self.index = index
        self.imageItem = imageItem
        self.imageLoader = imageLoader
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func loadView() {
        let view = UIView()
    
        view.backgroundColor = .clear
        self.view = view
        
        scrollView = UIScrollView()
        scrollView.delegate = self
        scrollView.showsVerticalScrollIndicator = false
        
        if #available(iOS 11.0, *) {
            scrollView.contentInsetAdjustmentBehavior = .never
        } else {
            // Fallback on earlier versions
        }
        view.addSubview(scrollView)
        scrollView.bindFrameToSuperview()
        scrollView.backgroundColor = .clear
        scrollView.addSubview(imageView)
        
        imageView.translatesAutoresizingMaskIntoConstraints = false
        top = imageView.topAnchor.constraint(equalTo: scrollView.topAnchor)
        leading = imageView.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor)
        trailing = scrollView.trailingAnchor.constraint(equalTo: imageView.trailingAnchor)
        bottom = scrollView.bottomAnchor.constraint(equalTo: imageView.bottomAnchor)
        
        top.isActive = true
        leading.isActive = true
        trailing.isActive = true
        bottom.isActive = true
        
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        imageLoader.loadImage(imageItem.url, placeholder: imageItem.thumbnailImage, imageView: imageView) {[weak self] (image) in
            guard let self else { return }
            //원본 방향 저장
            if let image {
                originOrientation = image.imageOrientation
            } else {
                hcLog("원본 사진 방향 누락")
            }
            
            DispatchQueue.main.async {[weak self] in
                self?.layout()
            }
        }
        
        addGestureRecognizers()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
    }
    
    override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()
        if isChangingNaviHidden {
            isChangingNaviHidden = false
            return
        }
        
        layout()
    }
    
    private func layout() {
        updateConstraintsForSize(view.bounds.size)
        updateMinMaxZoomScaleForSize(view.bounds.size)
    }
    
    // MARK: Add Gesture Recognizers
    func addGestureRecognizers() {
        
        let panGesture = UIPanGestureRecognizer(
            target: self, action: #selector(didPan(_:)))
        panGesture.cancelsTouchesInView = false
        panGesture.delegate = self
        scrollView.addGestureRecognizer(panGesture)
        
        let pinchRecognizer = UITapGestureRecognizer(
            target: self, action: #selector(didPinch(_:)))
        pinchRecognizer.numberOfTapsRequired = 1
        pinchRecognizer.numberOfTouchesRequired = 2
        scrollView.addGestureRecognizer(pinchRecognizer)
        
        let singleTapGesture = UITapGestureRecognizer(
            target: self, action: #selector(didSingleTap(_:)))
        singleTapGesture.numberOfTapsRequired = 1
        singleTapGesture.numberOfTouchesRequired = 1
        scrollView.addGestureRecognizer(singleTapGesture)
        
        let doubleTapRecognizer = UITapGestureRecognizer(
            target: self, action: #selector(didDoubleTap(_:)))
        doubleTapRecognizer.numberOfTapsRequired = 2
        doubleTapRecognizer.numberOfTouchesRequired = 1
        scrollView.addGestureRecognizer(doubleTapRecognizer)
        
        singleTapGesture.require(toFail: doubleTapRecognizer)
    }
    
    @objc
    func didPan(_ gestureRecognizer: UIPanGestureRecognizer) {
        guard
            isAnimating == false,
            scrollView.zoomScale == scrollView.minimumZoomScale
            else { return }
        
        let container:UIView! = imageView
        if gestureRecognizer.state == .began {
            lastLocation = container.center
        }
        
        if gestureRecognizer.state != .cancelled {
            let translation: CGPoint = gestureRecognizer
                .translation(in: view)
            container.center = CGPoint(
                x: lastLocation.x + translation.x,
                y: lastLocation.y + translation.y)
        }
        
        let diffY = view.center.y - container.center.y
        backgroundView?.alpha = 1.0 - abs(diffY/view.center.y)
        if gestureRecognizer.state == .ended {
            if abs(diffY) > 60 {
                dismiss(animated: true)
            } else {
                executeCancelAnimation()
            }
        }
    }
    
    @objc
    func didPinch(_ recognizer: UITapGestureRecognizer) {
        var newZoomScale = scrollView.zoomScale / 1.5
        newZoomScale = max(newZoomScale, scrollView.minimumZoomScale)
        scrollView.setZoomScale(newZoomScale, animated: true)
    }
    
    @objc
    func didSingleTap(_ recognizer: UITapGestureRecognizer) {
        
        guard let navController else { return }
        isChangingNaviHidden = true
        scrollView.backgroundColor = navController.isToolbarHidden ? .clear : .black
        navController.setToolbarHidden(!navController.isToolbarHidden, animated: true)
        navController.setNavigationBarHidden(!navController.isNavigationBarHidden, animated: true)
    }
    
    @objc
    func didDoubleTap(_ recognizer:UITapGestureRecognizer) {
        let pointInView = recognizer.location(in: imageView)
        zoomInOrOut(at: pointInView)
    }
    
    func gestureRecognizerShouldBegin(
        _ gestureRecognizer: UIGestureRecognizer) -> Bool {
        guard scrollView.zoomScale == scrollView.minimumZoomScale,
            let panGesture = gestureRecognizer as? UIPanGestureRecognizer
            else { return false }
        
        let velocity = panGesture.velocity(in: scrollView)
        return abs(velocity.y) > abs(velocity.x)
    }
    
    
}

// MARK: Adjusting the dimensions
extension ImageViewerController {
    
    func updateMinMaxZoomScaleForSize(_ size: CGSize) {
        
        let targetSize = imageView.bounds.size
        if targetSize.width == 0 || targetSize.height == 0 {
            return
        }
        
        let minScale = min(
            size.width/targetSize.width,
            size.height/targetSize.height)
        let maxScale = max(
            (size.width + 1.0) / targetSize.width,
            (size.height + 1.0) / targetSize.height)
        
        scrollView.minimumZoomScale = minScale
        scrollView.zoomScale = minScale
        maxZoomScale = maxScale
        scrollView.maximumZoomScale = maxZoomScale * 1.1
    }
    
    
    func zoomInOrOut(at point:CGPoint) {
        let newZoomScale = scrollView.zoomScale == scrollView.minimumZoomScale
            ? maxZoomScale : scrollView.minimumZoomScale
        let size = scrollView.bounds.size
        let w = size.width / newZoomScale
        let h = size.height / newZoomScale
        let x = point.x - (w * 0.5)
        let y = point.y - (h * 0.5)
        let rect = CGRect(x: x, y: y, width: w, height: h)
        scrollView.zoom(to: rect, animated: true)
    }
    
    ///줌을 해제한다
    func zoomOut() {
        scrollView.setZoomScale(scrollView.minimumZoomScale, animated: true)
    }
    
    func updateConstraintsForSize(_ size: CGSize) {
        let yOffset = max(0, (size.height - imageView.frame.height) / 2)
        top.constant = yOffset
        bottom.constant = yOffset
        
        let xOffset = max(0, (size.width - imageView.frame.width) / 2)
        leading.constant = xOffset
        trailing.constant = xOffset
        view.layoutIfNeeded()
    }
    
    //MARK: - 이미지 회전
    ///이미지를 왼쪽으로 회전
    func rotateLeft() {
        guard let image = imageView.image, let cgImage = image.cgImage else { return }
            
        // 현재 이미지의 orientation을 시계반대방향으로 한단계 회전
        let newOrientation: UIImage.Orientation
        switch image.imageOrientation {
        case .up: newOrientation = .left
        case .left: newOrientation = .down
        case .down: newOrientation = .right
        case .right: newOrientation = .up
        case .upMirrored: newOrientation = .leftMirrored
        case .leftMirrored: newOrientation = .downMirrored
        case .downMirrored: newOrientation = .rightMirrored
        case .rightMirrored: newOrientation = .upMirrored
        @unknown default: newOrientation = .up
        }
        
        // 새로운 orientation으로 UIImage 생성
        let newImage = UIImage(cgImage: cgImage, scale: image.scale, orientation: newOrientation)
        imageView.image = newImage
        //회전된 현재 방향 임시 저장
        currentOrientation = newOrientation
        //줌 재조정
        layout()
    }
    
    func cancelRotate() {
        guard let image = imageView.image, let cgImage = image.cgImage else { return }
        //원래 orientation으로 UIImage 생성
        let newImage = UIImage(cgImage: cgImage, scale: image.scale, orientation: originOrientation)
        imageView.image = newImage
        currentOrientation = originOrientation
        layout()
    }
    
    func confirmRotate() {
        //현재 orientation 원본 방향으로 설정
        originOrientation = currentOrientation

        if let image = imageView.image {
            //현재 orientation으로 사진EXIF 수정 저장
            let result = updateExifAttributes(imageURL: imageItem.url, newOrientation: .init(currentOrientation), newSize: image.size)
            hcLog("confirmRotate: \(result ? "success" : "fail")")
            //캐시 삭제
            imageLoader.deleteCache(imageItem.url)
        }
    }
    
    func updateExifAttributes(imageURL: URL, newOrientation: CGImagePropertyOrientation, newSize: CGSize) -> Bool {
        // 1. 이미지를 로드
        guard let imageSource = CGImageSourceCreateWithURL(imageURL as CFURL, nil) else {
            return false
        }
        
        // 2. 이미지 속성 읽기
        guard let imageProperties = CGImageSourceCopyPropertiesAtIndex(imageSource, 0, nil) as? [CFString: Any] else {
            return false
        }
        
        // 3. EXIF 데이터 수정
        var newProperties = imageProperties
        
        var exifDict = imageProperties[kCGImagePropertyExifDictionary] as? [CFString: Any] ?? [:]
        exifDict[kCGImagePropertyExifPixelXDimension] = Int32(newSize.width)
        exifDict[kCGImagePropertyExifPixelYDimension] = Int32(newSize.height)
        
        newProperties[kCGImagePropertyExifDictionary] = exifDict
        newProperties[kCGImagePropertyOrientation] = newOrientation.rawValue
        
        // 4. 이미지 타입 추출
        guard let uti = CGImageSourceGetType(imageSource) else {
            return false
        }
        
        // 5. 기존 파일을 덮어쓰는 방식으로 저장할 준비
        guard let imageDestination = CGImageDestinationCreateWithURL(imageURL as CFURL, uti, 1, nil) else {
            return false
        }
        
        // 6. 새 속성 적용하여 이미지 저장
        CGImageDestinationAddImageFromSource(imageDestination, imageSource, 0, newProperties as CFDictionary)
        
        if CGImageDestinationFinalize(imageDestination) {
            return true
        } else {
            return false
        }
    }
    
}

// MARK: Animation Related stuff
extension ImageViewerController {
    
    private func executeCancelAnimation() {
        self.isAnimating = true
        UIView.animate(
            withDuration: 0.237,
            animations: {
                self.imageView.center = self.view.center
                self.backgroundView?.alpha = 1.0
        }) {[weak self] _ in
            self?.isAnimating = false
        }
    }
}

extension ImageViewerController:UIScrollViewDelegate {
    
    func viewForZooming(in scrollView: UIScrollView) -> UIView? {
        return imageView
    }
    
    func scrollViewDidZoom(_ scrollView: UIScrollView) {
        updateConstraintsForSize(view.bounds.size)
    }
}

