import Foundation
#if canImport(SDWebImage)
import SDWebImage
#endif

protocol ImageLoader {
    func loadImage(_ url: URL, placeholder: UIImage?, imageView: UIImageView, completion: @escaping (_ image: UIImage?) -> Void)
    func deleteCache(_ url: URL)
}

struct URLSessionImageLoader: ImageLoader {
    init() {}

    func loadImage(_ url: URL, placeholder: UIImage?, imageView: UIImageView, completion: @escaping (UIImage?) -> Void) {
        if let placeholder = placeholder {
            imageView.image = placeholder
        }

        DispatchQueue.global(qos: .background).async {
            guard let data = try? Data(contentsOf: url), let image = UIImage(data: data) else {
                completion(nil)
                return
            }

            DispatchQueue.main.async {
                imageView.image = image
                completion(image)
            }
        }
    }
    
    func deleteCache(_ url: URL) {
        
    }
}

#if canImport(SDWebImage)
struct SDWebImageLoader: ImageLoader {
    func loadImage(_ url: URL, placeholder: UIImage?, imageView: UIImageView, completion: @escaping (UIImage?) -> Void) {
        imageView.sd_setImage(
            with: url,
            placeholderImage: placeholder,
            options: [],
            progress: nil) {(img, err, type, url) in
                DispatchQueue.main.async {
                    completion(img)
                }
        }
    }
    
    func deleteCache(_ url: URL) {
        SDImageCache.shared.removeImage(forKey: url.absoluteString, withCompletion: nil)
    }
    
}
#endif
