import UIKit

extension UIImageView {
    
    // Data holder tap recognizer
    private class TapWithDataRecognizer:UITapGestureRecognizer {
        weak var from:UIViewController?
        var imageDatasource:ImageDataSource?
        var imageLoader:ImageLoader?
        var initialIndex:Int = 0
        var options:[ImageViewerOption] = []
    }
    
    private var vc:UIViewController? {
        guard let rootVC = UIApplication.shared.keyWindow?.rootViewController
            else { return nil }
        return rootVC.presentedViewController != nil ? rootVC.presentedViewController : rootVC
    }
    
    public func setupImageViewer(
        options:[ImageViewerOption] = [],
        from:UIViewController? = nil,
        imageLoader:ImageLoader? = nil) {
        setup(
            datasource: SimpleImageDatasource(imageItems: [.image(image)]),
            options: options,
            from: from,
            imageLoader: imageLoader)
    }

    public func setupImageViewer(
        url:URL,
        initialIndex:Int = 0,
        placeholder: UIImage? = nil,
        options:[ImageViewerOption] = [],
        from:UIViewController? = nil,
        imageLoader:ImageLoader? = nil) {
        
        let datasource = SimpleImageDatasource(
            imageItems: [url].compactMap {
                ImageItem.url($0, placeholder: placeholder)
        })
        setup(
            datasource: datasource,
            initialIndex: initialIndex,
            options: options,
            from: from,
            imageLoader: imageLoader)
    }
    
    public func setupImageViewer(
        images:[UIImage],
        initialIndex:Int = 0,
        options:[ImageViewerOption] = [],
        from:UIViewController? = nil,
        imageLoader:ImageLoader? = nil) {
        
        let datasource = SimpleImageDatasource(
            imageItems: images.compactMap {
                ImageItem.image($0)
        })
        setup(
            datasource: datasource,
            initialIndex: initialIndex,
            options: options,
            from: from,
            imageLoader: imageLoader)
    }

    /// ImageViewer를 세팅한다.
    /// - Parameters:
    ///   - urls: 사진 URL 목록
    ///   - initialIndex: 해당셀 index
    ///   - options: UI 옵션
    ///   - placeholder: placeholder 이미지
    ///   - from: ImageViewer를 사용하는 parent VC
    ///   - imageLoader: 이미지 로드할 때 사용할 클래스
    public func setupImageViewer(
        urls:[URL],
        initialIndex:Int = 0,
        options:[ImageViewerOption] = [],
        placeholder: UIImage? = nil,
        from:UIViewController? = nil,
        imageLoader:ImageLoader? = nil) {
        
            
        //url 을 ImageItem으로 변환하여, DataSource를 만듦
        let datasource = SimpleImageDatasource(
            imageItems: urls.compactMap {
                ImageItem.url($0, placeholder: placeholder)
        })
            
        setup(
            datasource: datasource,
            initialIndex: initialIndex,
            options: options,
            from: from,
            imageLoader: imageLoader)
    }
    
    public func setupImageViewer(
        datasource:ImageDataSource,
        initialIndex:Int = 0,
        options:[ImageViewerOption] = [],
        from:UIViewController? = nil,
        imageLoader:ImageLoader? = nil) {
        
        setup(
            datasource: datasource,
            initialIndex: initialIndex,
            options: options,
            from: from,
            imageLoader: imageLoader)
    }
    
    /// ImageView에 ImageViewer를 위한 TapGesture과 Data를 세팅한다
    /// - Parameters:
    ///   - datasource: ImageItem 목록
    ///   - initialIndex: 해당 이미지뷰 index
    ///   - options: UI 옵션
    ///   - from: 이 ImageView를 소유하는  VC
    ///   - imageLoader: 이미지 로드 클래스
    private func setup(
        datasource:ImageDataSource?,
        initialIndex:Int = 0,
        options:[ImageViewerOption] = [],
        from: UIViewController? = nil,
        imageLoader:ImageLoader? = nil) {
        
        var _tapRecognizer:TapWithDataRecognizer?
        gestureRecognizers?.forEach {
            if let _tr = $0 as? TapWithDataRecognizer {
                // if found, just use existing
                _tapRecognizer = _tr
            }
        }
        
        isUserInteractionEnabled = true
        
        var imageContentMode: UIView.ContentMode = .scaleAspectFill
        options.forEach {
            switch $0 {
            case .contentMode(let contentMode):
                imageContentMode = contentMode
            default:
                break
            }
        }
        contentMode = imageContentMode //ImageView 컨텐트 모드
        
        clipsToBounds = true
        
        if _tapRecognizer == nil {
            _tapRecognizer = TapWithDataRecognizer(
                target: self, action: #selector(showImageViewer(_:)))
            _tapRecognizer!.numberOfTouchesRequired = 1
            _tapRecognizer!.numberOfTapsRequired = 1
        }
        // Pass the Data
        _tapRecognizer!.imageDatasource = datasource
        _tapRecognizer!.imageLoader = imageLoader
        _tapRecognizer!.initialIndex = initialIndex
        _tapRecognizer!.options = options
        _tapRecognizer!.from = from
        addGestureRecognizer(_tapRecognizer!)
    }
    
    @objc
    /// ImageView의 탭 이벤트를 수신하여 ImageCarouselViewController를 띄운다.
    /// - Parameter sender: 탭 이벤트 발생시킨 TapWithDataRecognizer
    private func showImageViewer(_ sender:TapWithDataRecognizer) {
        guard let sourceView = sender.view as? UIImageView else { return }
        let imageCarousel = ImageCarouselViewController.init(
            sourceView: sourceView, //CarouselVC를 호출한 ImageView
            imageDataSource: sender.imageDatasource, //이미지 목록
            imageLoader: sender.imageLoader ?? URLSessionImageLoader(), //이미지 로더
            options: sender.options, //UI옵션
            initialIndex: sender.initialIndex) //CarouselVC를 호출한 셀 index
        
        let presentFromVC = sender.from ?? vc
        presentFromVC?.present(imageCarousel, animated: true)
    }
}
