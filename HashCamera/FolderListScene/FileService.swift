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
    
    static let shared = FileService()
    private init() { }
    deinit {
        folderMonitor?.stopMonitoring()
    }
    
    var rootURL: URL?
    let files = BehaviorRelay<[ImageFileModel]>(value: [])
    var folderMonitor: FolderMonitor? //폴더 변경 감시자

    
    func fetchFiles(of newRootURL: URL? = nil) async -> Void {
        if let newRootURL {
            rootURL = newRootURL
        }
        guard let rootURL else { return }
        
        folderMonitor?.stopMonitoring()
        folderMonitor = FolderMonitor(url: rootURL)
        folderMonitor?.folderDidChange = {
            hcLog("파일목록 갱신 감지")
            Task { [weak self] in
               await self?.fetchFiles()
            }
        }
        folderMonitor?.startMonitoring()
        
        
        do {
            let fetchedList =  try fileManager.contentsOfDirectory(at: rootURL,
                                                                   includingPropertiesForKeys: nil)
            let photoList = fetchedList.filter{$0.isPhoto}
            hcLog("파일 갯수: \(fetchedList.count), 사진파일갯수 \(photoList.count)")
            
            await MainActor.run {
                files.accept(photoList.map{ImageFileModel(url: $0)})
            }
        } catch {
            hcLog("fetch error")
            await MainActor.run {
                files.accept([])
            }
        }
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
