//
//  FileService.swift
//  HashCamera
//
//  Created by WG-Yang on 8/28/24.
//

import Foundation
import RxSwift
import RxRelay

class FileService {
    
    let fileManager = FileManager.default
    var folderMonitor: FolderMonitor?
    
    var rootURL: URL?
    var fileList: [URL] = []
    var fileListUpdated: ((FolderMonitor.FolderUpdateData) -> Void)?

    init() { }
    deinit {
        folderMonitor?.stopMonitoring()
    }
    
    ///파일 목록 불러오기. 파일 변경 감시 시작. 호출할 때마다 reset 된다.
    func configure(rootURL: URL, fileListUpdated: ((FolderMonitor.FolderUpdateData) -> Void)? ) {
        folderMonitor?.stopMonitoring()
        
        self.rootURL = rootURL
        self.fileList = []
        self.fileListUpdated = fileListUpdated
    
        folderMonitor = FolderMonitor(folderURL: rootURL,
                                      contentType: [.jpeg, .png, .heic,],
                                      eventMask: [.all],
                                      folderListUpdated: { [weak self] updateData in
            guard let self else { return }
            fileList = updateData.newFileList
            fileListUpdated?(updateData) })
        folderMonitor?.startMonitoring()
    }
    
    static func moveFile(at fileURLs: [URL], to folderURL: URL) async -> Result<Void,MoveFileError> {

        var successCount = 0
        fileURLs.forEach { fileURL in
            if let newFileURL = URL(string: folderURL.absoluteString + fileURL.lastPathComponent) {
                do {
                    try FileManager.default.moveItem(at: fileURL, to: newFileURL)
                    successCount += 1
                } catch(let error) {
                    hcLog(nil, error: error)
                }
            }
        }
        
        if successCount == fileURLs.count {
            return .success(Void())
        } else {
            return .failure(.unknown)
        }
    }
    enum MoveFileError:Error {
        case unknown
    }
    
    
    func deleteFiles(_ indices:[Int]) async -> Result<Void,DeleteError> {
        

        var deletingURLs = indices.compactMap({ index in
           return index < fileList.count ? fileList[index] : nil
        })
        
        var failedURLs = [URL]() //삭제 실패한 파일목록
        var lastError:Error? = nil //삭제 실패 에러
        
        deletingURLs.forEach { url in
            do {
                try fileManager.removeItem(at: url)
            } catch(let error) {
                failedURLs.append(url)
                lastError = error
            }
        }
        
        if let lastError {
            hcLog("삭제 실패: \(lastError) | \(lastError.localizedDescription)")
            hcLog(failedURLs.map({"\($0.lastPathComponent)"}).reduce("", {$0 + $1}))
            return .failure(.system(lastError))
        } else {
            return .success(())
        }
        

    }
    enum DeleteError: Error {
        case unknown
        case system(Error)
    }
    
}
