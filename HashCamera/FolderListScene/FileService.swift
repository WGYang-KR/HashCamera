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

    static let shared = FileService()
    let fileManager = FileManager.default
    var rootURL: URL?
    var folderMonitor: FolderMonitor?
    var fileList: [URL] = []
    var fileListUpdated: ((FolderMonitor.FolderUpdateData) -> Void)?

    private init() { }
    deinit {
        folderMonitor?.stopMonitoring()
    }
    
    ///폴더 목록 불러오기. 폴더 변경 감시 시작.
    func configure(rootURL: URL, fileListUpdated: ((FolderMonitor.FolderUpdateData) -> Void)? ) {
        self.rootURL = rootURL
        self.fileListUpdated = fileListUpdated
        
        folderMonitor?.stopMonitoring()
        folderMonitor = FolderMonitor(folderPath: rootURL.absoluteString,
                                      folderListUpdated: { [weak self] folderUpdatedData in
            hcLog("파일목록 갱신 감지")
            guard let self else { return }
            let newFileList = folderUpdatedData.newFileList.filter { $0.isPhoto }
            let addedList = folderUpdatedData.addedFiles.filter { $0.isPhoto }
            let deletedList = folderUpdatedData.removedFiles.filter{$0.isPhoto}
            self.fileList = newFileList
            self.fileListUpdated?(.init(newFileList: newFileList, addedFiles: addedList, removedFiles: deletedList))
        })
        
        folderMonitor?.startMonitoring()
    }
    
    func moveFile(at fileURLs: [URL], to folderURL: URL) async -> Result<Void,MoveFileError> {

        var successCount = 0
        fileURLs.forEach { fileURL in
            if let newFileURL = URL(string: folderURL.absoluteString + fileURL.lastPathComponent) {
                do {
                    try fileManager.moveItem(at: fileURL, to: newFileURL)
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
    
}
