//
//  ImageFileModel.swift
//  HashCamera
//
//  Created by Anto-Yang on 9/15/24.
//

import Foundation
import UIKit
import QuickLookThumbnailing

class ImageFileModel {
    
    let url: URL
    let fileName: String
    let fileSize:Int
    let creationDate: Date
    let modificationDate: Date
    let photoTakenDate: Date
    
    var thumbnailRequest: QLThumbnailGenerator.Request?
    var thumbnailImage: UIImage?

    init(url: URL,
         thumbnailRequest: QLThumbnailGenerator.Request? = nil) {
        
        self.url = url
        self.thumbnailRequest = thumbnailRequest
        
            let fileURL = url
            let resourceKeys: Set<URLResourceKey> = [.nameKey, .fileSizeKey, .creationDateKey, .contentModificationDateKey]
            
        var resourceValues:URLResourceValues?
        do {
            // 파일의 속성 가져오기
            resourceValues = try fileURL.resourceValues(forKeys: resourceKeys)
        } catch {
            hcLog("Error reading file: \(error.localizedDescription)")
        }
        
        fileName = resourceValues?.name ?? url.lastPathComponent
        fileSize = resourceValues?.fileSize ?? 0
        creationDate = resourceValues?.creationDate ?? Date.distantPast
        modificationDate = resourceValues?.contentModificationDate ?? creationDate
        
//        hcLog("File: \(fileName)")
//        hcLog("File Size: \(fileSize) bytes")
//        hcLog("Creation Date: \(creationDate)")
//        hcLog("Modification Date: \(modificationDate)")
//        
        // 이미지의 메타데이터에서 사진 찍은 날짜 가져오기
        if let imageSource = CGImageSourceCreateWithURL(fileURL as CFURL, nil),
           let metadata = CGImageSourceCopyPropertiesAtIndex(imageSource, 0, nil) as? [String: Any],
           let exif = metadata[kCGImagePropertyExifDictionary as String] as? [String: Any],
           let dateTimeOriginal = exif[kCGImagePropertyExifDateTimeOriginal as String] as? String,
           let offsetTimeOriginal = exif[kCGImagePropertyExifOffsetTimeOriginal as String] as? String {
            photoTakenDate = Self.exifDate(dateTime: dateTimeOriginal, offsetTime: offsetTimeOriginal) ?? Date()
            hcLog("Photo Taken Date: \(photoTakenDate)")
            hcLog("---------")
        } else {
            photoTakenDate = creationDate
            hcLog("No EXIF data for photo taken date")
            hcLog("---------")
        }
        
    }
    
    /// exif 날짜정보를 Date 형식으로 변환한다.
    /// - Parameters:
    ///   - dateTime: 2024:01:24 18:19:01 > yyyy:MM:dd HH:mm:ss
    ///   - offsetTime: +09:00 > ZZZZZ
    /// - Returns:
    static func exifDate(dateTime: String, offsetTime: String) -> Date? {
        let dateString = dateTime + offsetTime
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy:MM:dd HH:mm:ssZZZZZ"
        return formatter.date(from: dateString)
    }
    
    
    /// 파일 URL로부터 UTType을 반환한다.
    var fileUTType: UTType? {
        return try? url.resourceValues(forKeys: [.contentTypeKey]).contentType
    }
    
    
    /// 파일이 이미지인지 여부
    var isImage: Bool {
        guard let type = try? url.resourceValues(forKeys: [.contentTypeKey]).contentType else { return false }
        return type.conforms(to: .image)
    }

    /// 파일이 비디오인지 여부
    var isVideo: Bool {
        guard let type = try? url.resourceValues(forKeys: [.contentTypeKey]).contentType else { return false }
        return type.conforms(to: .movie)
    }
}
