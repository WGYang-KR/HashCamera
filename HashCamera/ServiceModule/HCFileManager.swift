//
//  HCFileManager.swift
//  HashCamera
//
//  Created by WG-MacHome on 10/24/23.
//

import Foundation
import UIKit
import QuickLookThumbnailing

class HCFileManager {
    let fileManager = FileManager.default
    
    //MARK: - iClud 다운로드 관련 변수
    var queryNotifications = [UUID: QueryNotification]() //원격저장소 다운로드에 사용되는 Notifcation을 저장.
    struct QueryNotification {
        let query: NSMetadataQuery //노티피케이션에 사용된 쿼리
        let notification: NSObjectProtocol //쿼리가 사용된 노티피케이션
    }
    
    //MARK: - 기초 함수
    func iCloudBaseURL() -> URL? {
        guard let baseURL = fileManager.url(forUbiquityContainerIdentifier:nil)?.appendingPathComponent("Documents")
        else { return nil}
        return URL(string: "./", relativeTo: baseURL)
    }
    
    func localBaseURL() -> URL? {
        guard let baseURL = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first
        else { return nil}
        return URL(string: "./", relativeTo: baseURL)
    }
    

    ///폴더 내 컨텐츠 가져오기
    func fetchContentList(source: URL) -> [URL] {
        do {
            let list =  try fileManager.contentsOfDirectory(at: source,
                                                            includingPropertiesForKeys: nil)
            hcLog("fetched list count = \(list.count)")
            return list
        } catch {
            hcLog("fetched list count = 0")
            return [URL]()
        }
    }
    
    ///폴더 내 가장 첫번째 미디어 파일 가져오기
    func fetchFirstMediaFile(source: URL) -> URL? {
        return fetchContentList(source: source).filter({$0.isMedia}).first
    }
  
    ///새폴더 만들기. 성공시 생성된 URL 반환. 실패시 nil 반환.
    func makeNewFolder(destination: URL, folderName : String ) -> URL? {

        let newFolderURL = destination.appendingPathComponent(folderName)
        guard let uniqueURL = makeUniqueFileURL(url: newFolderURL) else { return nil }
        
        do {
            try fileManager.createDirectory(atPath: uniqueURL.path, withIntermediateDirectories: true, attributes: nil)
            return uniqueURL
        } catch {
            print(error.localizedDescription)
            return nil
        }
    }
    
    ///폴더 이름바꾸기. 성공시 바뀐 URL 반환. 실패시 nil 반환.
    func renameFolder(target: URL, newName: String) -> URL? {
        let newURL = target.deletingLastPathComponent().appendingPathComponent(newName)
        do {
            return try fileManager.replaceItemAt(target, withItemAt: newURL)
        }
        catch { return nil}
    }
    
    ///데이터를 폴더에 저장.  fileName에 확장자를 포함해야함. 성공시 해당 URL 반환. 실패시 nil 반환.
    func saveFile(destination: URL, data: Data, fileName: String) -> URL? {
        
        let newFileURL = destination.appendingPathComponent(fileName)
        guard let uniqueURL = makeUniqueFileURL(url: newFileURL) else { return nil }
        return fileManager.createFile(atPath: uniqueURL.path, contents: data) ? uniqueURL : nil
    }
    
    ///이미 같은 이름의 파일이나 폴더가 있는지 검사. 중복일 경우 뒤에 숫자를 덧붙인 url을 반환한다. ex /.././fileName (1).jpg
    private func makeUniqueFileURL(url originURL:URL) -> URL? {
        let fileFullName = NSString(string:originURL.lastPathComponent) //파일이름 + 확장자
        let fileName = fileFullName.deletingPathExtension //파일이름
        let fileFormat = fileFullName.pathExtension //확장자
        let baseURL = originURL.deletingLastPathComponent() // ./
        
        var uniqueURL = originURL
        for i in 1...100 {
            if !fileManager.fileExists(atPath: uniqueURL.path) {
                return uniqueURL
            } else {
                var newName = fileName + " (\(i))"
                if fileFormat != "" {
                    newName += "." + fileFormat // fileName (1).jpg
                }
                uniqueURL = baseURL.appendingPathComponent(newName)
            }
        }
        print("Error \(#function)")
        return nil
    }
    
    /// 파일을 삭제한다. 일부 파일이 삭제 실패했을 경우에는 false를 반환하면서 error와 실패한 url 리스트를 반환한다.
    /// - Parameter urlList: 삭제할 파일 url 배열
    /// - Returns: (모든 파일 삭제 성공여부, 실패시 에러, 실패한 파일목록)
    func deleteFile(urlList: [URL]) -> (success: Bool, error: Error?, failedURLs: [URL]) {
        
        var failedURLs = [URL]() //삭제 실패한 파일목록
        var lastError:Error? = nil //삭제 실패 에러
        
        urlList.forEach { url in
            do {
                try fileManager.removeItem(at: url)
            } catch(let error) {
                failedURLs.append(url)
                lastError = error
            }
        }
        
        return (success: failedURLs.count == 0 , error: lastError, failedURLs: failedURLs)
        
    }
    //여기까지 작업 To do
    
    //MARK: - 이미지 로드
    
    //MARK: 썸네일
    ///파일의 썸네일을 가져온다. (completion은 여러번 호출 될 수 있다.) lowQuality -> HighQuality
    func generateThumbnail(url: URL, size: CGSize, 
                           completion: @escaping ( QLThumbnailRepresentation.RepresentationType? , UIImage?) -> Void ) {
        
        let scale = UIScreen.main.scale
        
        // Create the thumbnail request.
        let request = QLThumbnailGenerator.Request(fileAt: url,
                                                   size: size,
                                                   scale: scale,
                                                   representationTypes: .all)
        
        // Retrieve the singleton instance of the thumbnail generator and generate the thumbnails.
        let generator = QLThumbnailGenerator.shared
        
        generator.generateRepresentations(for: request) { thumbnail, type, error in
            if let error {
                hcLog("\(error) : \(error.localizedDescription)")
            }
            if let thumbnail {
                completion(type, thumbnail.uiImage)
            } else {
                hcLog("\(url.lastPathComponent) Thumnail = nil")
                completion(nil,nil)
            }
        }

    }

    
    ///폴더의 대표파일의 썸네일을 가져온다.
    func generateFolderThumbnail(url: URL, size: CGSize,
                                 completion: @escaping (QLThumbnailRepresentation.RepresentationType?, UIImage?) -> Void )  {
        if let firstURL = fetchFirstMediaFile(source: url) {
            generateThumbnail(url: firstURL, size: size, completion: completion)
        } else {
            hcLog("firstURL = nil")
            completion(nil, nil)
        }
    }
    
    func stopGeneratingThumbnail(request: QLThumbnailGenerator.Request ) {
        QLThumbnailGenerator.shared.cancel(request)
    }

    //MARK:
    ///파일의 원본 이미지를 가져온다. 실패시 nil 반환
    func fetchBestImage(url: URL, completion: @escaping (UIImage?) -> Void ) {
        
        
        if fileManager.isUbiquitousItem(at: url) {  //iCloud 파일 일때
            fetchBestImage(iCloudURL: url, completion: completion)
            
        } else {    //로컬 파일일때
            completion(UIImage(contentsOfFile: url.absoluteString) )
        }
    }
    
    ///iCloud의 사진을 다운로드하여 반환한다. 실패시 nil 반환
    func fetchBestImage(iCloudURL url: URL, completion: @escaping (UIImage?) -> Void ) {
        
        let uuid = UUID()
        let query = NSMetadataQuery()
        query.predicate = NSPredicate(format: "%K == %@", NSMetadataItemPathKey, url.absoluteString) // create predicate to search for you files
        
        let observer = NotificationCenter.default.addObserver(forName: .NSMetadataQueryDidUpdate, object: query, queue: nil) { [weak self] notification in
            guard let self else { completion(nil); return }
            
            for i in 0..<query.resultCount {
                if let item = query.result(at: i) as? NSMetadataItem {
                    let downloadingStatus = item.value(forAttribute: NSMetadataUbiquitousItemDownloadingStatusKey) as! String
                    hcLog("URL:\(url.relativeString) Downloading Status:\(downloadingStatus)")
                    
                    if downloadingStatus == URLUbiquitousItemDownloadingStatus.current.rawValue {
                        // file is donwloaded, call your function
                        removeQueryNotification(uuid)
                        
                        let image = UIImage(contentsOfFile: url.absoluteString)
                        completion(image)
                        
                    }
                }
            } //.for
        } //./NotificationCenter
        
        queryNotifications[uuid] = QueryNotification(query: query, notification: observer) //쿼리와 노티피케이션 저장.
        query.start() // starts the search query, updates will come through notifications
        
        // Once we are listening for download updates we can start the downloading process
        do {
            try fileManager.startDownloadingUbiquitousItem(at: url)
        } catch {
            removeQueryNotification(uuid)
            completion(nil)
          
        }
      
    }
    ///쿼리 노티피케이션을 중지하고 등록해제 한다.
    func removeQueryNotification(_ uuid: UUID) {
        if let observer = queryNotifications.removeValue(forKey: uuid) {
            observer.query.stop() //쿼리 중지
            NotificationCenter.default.removeObserver(observer.notification) //노티피케이션 등록해제
        }
    }
    
    deinit {
        
        //사용하던 QueryNotifcation 제거
        for ( _ , value) in queryNotifications {
            value.query.stop() //쿼리 중지
            NotificationCenter.default.removeObserver(value.notification) //노티피케이션 등록해제
        }
        queryNotifications = [:] //목록 할당해제
    }
    
  
}


extension URL {
    var typeIdentifier: String? { (try? resourceValues(forKeys: [.typeIdentifierKey]))?.typeIdentifier }
    var isMP3: Bool { typeIdentifier == "public.mp3" }
    var isJPG: Bool { typeIdentifier == "public.jpg" || typeIdentifier == "public.JPG"  }
    var isJPEG: Bool { typeIdentifier == "public.jpeg" || typeIdentifier == "public.JPEG"}
    var isPNG: Bool { typeIdentifier == "public.png" }
    var isMP4: Bool { typeIdentifier == "public.mp4" }
    var isMOV: Bool { typeIdentifier == "public.mov" }
    var isHEIC: Bool { typeIdentifier == "public.heic" || typeIdentifier == "public.HEIC"}
    var isMedia: Bool { isJPG || isJPEG || isPNG || isMP4 || isMOV }
    var isPhoto: Bool { isJPG || isJPEG || isPNG || isHEIC }
    var isDirectory: Bool { (try? resourceValues(forKeys: [.isDirectoryKey]))?.isDirectory == true }
    var localizedName: String? { (try? resourceValues(forKeys: [.localizedNameKey]))?.localizedName }
    var hasHiddenExtension: Bool {
        get { (try? resourceValues(forKeys: [.hasHiddenExtensionKey]))?.hasHiddenExtension == true }
        set {
            var resourceValues = URLResourceValues()
            resourceValues.hasHiddenExtension = newValue
            try? setResourceValues(resourceValues)
        }
    }
}
