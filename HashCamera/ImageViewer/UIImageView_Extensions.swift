import UIKit

extension UIImageView {
    
    // Data holder tap recognizer
    private class TapWithDataRecognizer:UITapGestureRecognizer {
        weak var from: UIViewController?
        weak var photoListVM: PhotoListVM?
        var initialIndex:Int = 0
    }
    
    private var vc:UIViewController? {
        guard let rootVC = UIApplication.shared.keyWindow?.rootViewController
            else { return nil }
        return rootVC.presentedViewController != nil ? rootVC.presentedViewController : rootVC
    }
    
    /// ImageViewer를 세팅한다.
    /// - Parameters:
    ///   - photoListVM: ImageViewer를 띄울 VC의 VM (photoList와 변경이벤트 수신을 위함.)
    ///   - initialIndex: ImageViewer에 연결될 Index
    ///   - from: ImageView를 띄울 parentVC
    func setupImageViewer(photoListVM: PhotoListVM, initialIndex:Int = 0, from:UIViewController? = nil) {
        
        var _tapRecognizer:TapWithDataRecognizer?
        gestureRecognizers?.forEach {
            if let _tr = $0 as? TapWithDataRecognizer {
                // if found, just use existing
                _tapRecognizer = _tr
            }
        }
        
        isUserInteractionEnabled = true
        contentMode = .scaleAspectFill
        clipsToBounds = true
        
        if _tapRecognizer == nil {
            _tapRecognizer = TapWithDataRecognizer(
                target: self, action: #selector(showImageViewer(_:)))
            _tapRecognizer!.numberOfTouchesRequired = 1
            _tapRecognizer!.numberOfTapsRequired = 1
        }
        // Pass the Data
        _tapRecognizer!.from = from
        _tapRecognizer!.photoListVM = photoListVM
        _tapRecognizer!.initialIndex = initialIndex
        addGestureRecognizer(_tapRecognizer!)
    }
    
  
    
    @objc
    /// ImageView의 탭 이벤트를 수신하여 ImageCarouselViewController를 띄운다.
    /// - Parameter sender: 탭 이벤트 발생시킨 TapWithDataRecognizer
    private func showImageViewer(_ sender:TapWithDataRecognizer) {
        guard let sourceView = sender.view as? UIImageView else { return }
        let imageCarousel = ImageCarouselViewController(sourceView: sourceView, photoListVM: sender.photoListVM, initialIndex: sender.initialIndex)

        let presentFromVC = sender.from ?? vc
        presentFromVC?.present(imageCarousel, animated: true)
    }
}
