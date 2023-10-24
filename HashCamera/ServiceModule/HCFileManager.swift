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
    
    var type: HCFileManagerType
    enum HCFileManagerType {
        case iCloudDrive, localDrive
    }
    init(type: HCFileManagerType) {
        self.type = type
    }
    
    //MARK: - 디렉토리 제어
    private func rootURL() -> URL? {
        switch type {
        case .iCloudDrive:
            return fileManager.url(forUbiquityContainerIdentifier:nil)?.appendingPathComponent("Documents") ?? nil
        case .localDrive:
            return fileManager.url(forUbiquityContainerIdentifier:nil)?.appendingPathComponent("Documents") ?? nil
        }
    }
    
    ////////여기까지 작업함.
    
    ///폴더 목록 가져오기
    func getFolderList() async -> [URL] {
        guard let rootURL = fileManager.url(forUbiquityContainerIdentifier:nil)?.appendingPathComponent("Documents") else { return [URL]()}
        var directoryContents = [URL]()
        do {
            directoryContents = try fileManager.contentsOfDirectory(at: rootURL, includingPropertiesForKeys: nil)
        } catch {
            return [URL]()
        }
        return directoryContents.filter{$0.isDirectory}
    }
    
    ///폴더 안의 미디어 파일목록만 가져오기
    func getMediaFileURLList(of folderURL: URL) -> [URL] {
        guard folderURL.isDirectory == true else { return [URL]() }
        var directoryContents = [URL]()
        do {
            directoryContents = try fileManager.contentsOfDirectory(at: folderURL, includingPropertiesForKeys: nil)
        } catch {
            return [URL]()
        }
        
        return directoryContents.filter({$0.isMedia})
    }
    
    ///폴더 안의 가장 첫번째 미디어 파일 가져오기
    func getFirstMediaFileURL(in folderURL: URL) -> URL? {
        self.getMediaFileURLList(of: folderURL).first
    }
    ///폴더 안의 가장 첫번째 미디어 파일 가져오기
    func getFirstMediaFileURL(in folderName: String) -> URL? {
        guard let folderURL = self.makeFullURL(with: folderName) else { return nil}
        guard let fileURL = self.getFirstMediaFileURL(in: folderURL) else { return nil }
        return fileURL
    }
    
    ///새폴더 만들기
    func makeNewFolder(_ folderName : String ) -> Bool {
        guard let path = self.rootURL() else { return false}
        let newFolderPath = path.appendingPathComponent(folderName)
        guard let uniquePath = makeUniqueFileURL(url: newFolderPath) else { return false}
        
        do {
            try fileManager.createDirectory(atPath: uniquePath.path, withIntermediateDirectories: true, attributes: nil)
            return true
        } catch {
            print(error.localizedDescription)
            return false
        }
    }
    
    ///폴더 이름바꾸기
    func renameFolder(from prevName: String, to destName: String) -> Bool {
        guard let path = self.rootURL() else { return false}
        let originalPath = path.appendingPathComponent(prevName)
        guard let destPath = makeUniqueFileURL(url: path.appendingPathComponent(destName)) else { return false}
        do {
            _ = try fileManager.replaceItemAt(originalPath, withItemAt: destPath)
            return true
        }
        catch { return false}
    }
    
    ///데이터를 폴더에 저장
    func saveFile( data: Data, fileName: String, at folderName: String?) -> Bool {
        guard let icloudURL = self.rootURL() else { return false }
        var fileURL = icloudURL
        if let folderName = folderName { fileURL = fileURL.appendingPathComponent(folderName).appendingPathComponent(fileName)}
        else { fileURL = fileURL.appendingPathComponent(fileName)}

        guard let destURL = makeUniqueFileURL(url: fileURL) else { return false }
        return fileManager.createFile(atPath: destURL.path, contents: data)
    }
    
    
    ///fileName을 iCloud URL을 만들어 반환한다.
    func makeFullURL(with lastPath:String) -> URL? {
        return self.rootURL()?.appendingPathComponent(lastPath)
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
