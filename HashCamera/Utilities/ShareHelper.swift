//
//  ShareHelper.swift
//  HashCamera
//
//  Created by WG-Yang on 9/23/24.
//

import UIKit
import LinkPresentation
import UniformTypeIdentifiers

class ShareHelper {
    static let shared = ShareHelper()
    
    // 2. 파일을 임시 디렉토리로 복사한 후 공유
    func share(files: [FileShareItem], viewController: UIViewController) {
        // 임시 디렉토리 경로 가져오기
        let temporaryDirectory = FileManager.default.temporaryDirectory
        
        var newFiles: [FileShareItem] = []
        files.forEach { file in
            let fileURL = file.fileURL
            
            let tempFileURL = temporaryDirectory.appendingPathComponent(fileURL.lastPathComponent)
            
            do {
                // 파일이 이미 임시 디렉토리에 있는 경우 삭제
                if FileManager.default.fileExists(atPath: tempFileURL.path) {
                    try FileManager.default.removeItem(at: tempFileURL)
                }
                
                // 파일을 임시 디렉토리에 복사
                try FileManager.default.copyItem(at: fileURL, to: tempFileURL)
                
                
            } catch {
                print("파일 공유 중 오류 발생: \(error.localizedDescription)")
            }
            newFiles.append(.init(fileURL: tempFileURL, previewImage: file.previewImage, fileTitle: file.fileTitle))
            
        }
    
        // FileShareItem 생성 (미리보기 이미지와 타이틀 포함)
        let shareItems = newFiles
        
        // UIActivityViewController 생성
        
        let activityVC = UIActivityViewController(activityItems: shareItems, applicationActivities: nil)
        
        // iPad에서 충돌 방지 (iPad에서는 팝오버 스타일이 필요함)
        if let popoverController = activityVC.popoverPresentationController {
            popoverController.sourceView = viewController.view
            popoverController.sourceRect = CGRect(x: viewController.view.bounds.midX,
                                                  y: viewController.view.bounds.midY,
                                                  width: 0, height: 0)
            popoverController.permittedArrowDirections = []
        }
        
        // 공유 화면 표시
        viewController.present(activityVC, animated: true, completion: nil)
    }
}

// 1. UIActivityItemSource를 구현하여 미리보기 이미지와 타이틀을 지정
class FileShareItem: NSObject, UIActivityItemSource {
    let fileURL: URL
    let previewImage: UIImage?
    let fileTitle: String
    let data: Data?
    
    init(fileURL: URL, previewImage: UIImage?, fileTitle: String) {
        self.fileURL = fileURL
        self.previewImage = previewImage
        self.fileTitle = fileTitle
        self.data = try? Data(contentsOf: fileURL)
    }
    
    // 공유할 예비 파일 반환
    func activityViewControllerPlaceholderItem(_ activityViewController: UIActivityViewController) -> Any {
        return UIImage() //data ?? fileURL
    }
    
    // 공유할 실제 URL을 반환
    func activityViewController(_ activityViewController: UIActivityViewController, itemForActivityType activityType: UIActivity.ActivityType?) -> Any? {
        return fileURL
    }
    
    // 미리보기 이미지 제공
    func activityViewController(_ activityViewController: UIActivityViewController, thumbnailImageForActivityType activityType: UIActivity.ActivityType?, suggestedSize size: CGSize) -> UIImage? {
        return previewImage
    }
    
    // 공유할 파일의 타이틀 제공
    func activityViewController(_ activityViewController: UIActivityViewController, subjectForActivityType activityType: UIActivity.ActivityType?) -> String {
        return fileTitle
    }
    
   func activityViewController(_ activityViewController: UIActivityViewController, dataTypeIdentifierForActivityType activityType: UIActivity.ActivityType?) -> String {
        return UTType.image.identifier
    }
    
    func activityViewControllerLinkMetadata(_ activityViewController: UIActivityViewController) -> LPLinkMetadata? {
        let metadata = LPLinkMetadata()
        metadata.title = fileTitle
        metadata.originalURL = fileURL
        metadata.url = metadata.originalURL
        if let provider = NSItemProvider(contentsOf: fileURL) {
            provider.suggestedName = fileTitle
            metadata.imageProvider = provider
        }
        if let previewImage {
            metadata.iconProvider = NSItemProvider(object: previewImage)
        }
        
        
        return metadata
    }

}


