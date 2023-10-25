//
//  HCFileManager.swift
//  HashCamera
//
//  Created by WG-MacHome on 10/24/23.
//

import Foundation
import UIKit

class HCFileManager {
    let fileManager = FileManager.default
    
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
            return try fileManager.contentsOfDirectory(at: source,
                                                           includingPropertiesForKeys: nil)
        } catch {
            return [URL]()
        }
    }
    
    ///폴더 내 가장 첫번째 미디어 파일 가져오기
    func fetchFirstMediaFile(source: URL) -> URL? {
        return fetchContentList(source: source).filter({$0.isMedia}).first
    }
  
    ///새폴더 만들기. 성공시 생성된 URL 반환. 실패시 nil 반환.
    func makeNewFolder(source: URL, folderName : String ) -> URL? {

        let newFolderURL = source.appendingPathComponent(folderName)
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
    func saveFile(source: URL, data: Data, fileName: String) -> URL? {
        
        let newFileURL = source.appendingPathComponent(fileName)
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

    //여기까지 작업 To do
    
    //MARK: - 이미지 로드
    ///폴더의 대표파일의 썸네일을 가져온다.
    func fetchFolderThumbnailImage(folderUrl: URL) async -> UIImage? {
        return UIImage()
    }
    
    ///특정 파일의 썸네일을 가져온다.
    func fetchFileThumbnailImage(fileUrl: URL) async -> UIImage? {
        
        return UIImage()
    }
    
    ///특정 파일의 원본 이미지를 가져온다.
    func fetchFullScaleImage(ofURL: URL) async -> UIImage? {
        return UIImage()
    }
}

extension URL {
    var typeIdentifier: String? { (try? resourceValues(forKeys: [.typeIdentifierKey]))?.typeIdentifier }
    var isMP3: Bool { typeIdentifier == "public.mp3" }
    var isJPG: Bool { typeIdentifier == "public.jpg" }
    var isJPEG: Bool { typeIdentifier == "public.jpeg"}
    var isPNG: Bool { typeIdentifier == "public.png" }
    var isMP4: Bool { typeIdentifier == "public.mp4" }
    var isMOV: Bool { typeIdentifier == "public.mov" }
    var isMedia: Bool { isJPG || isJPEG || isPNG || isMP4 || isMOV }
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
