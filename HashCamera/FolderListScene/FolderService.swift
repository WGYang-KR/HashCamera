//
//  FolderService.swift
//  HashCamera
//
//  Created by Anto-Yang on 8/21/24.
//

import Foundation
import RxSwift
import RxRelay

class FolderService {
    
    let fileManager = FileManager.default
    var rootURL: URL?
    var folderMonitor: FolderMonitor?
    var folderList: [URL] = []
    var folderListUpdated: ((FolderMonitor.FolderUpdateData) -> Void)?
    
    init() { }
    
    deinit {
        folderMonitor?.stopMonitoring()
    }
    
    ///폴더 목록 불러오기. 폴더 변경 감시 시작.
    func configure(rootURL: URL, folderListUpdated: ((FolderMonitor.FolderUpdateData) -> Void)? ) {
        self.rootURL = rootURL
        self.folderListUpdated = folderListUpdated
        
        folderMonitor?.stopMonitoring()
        folderMonitor = FolderMonitor(folderPath: rootURL.absoluteString,
                                      folderListUpdated: { [weak self] folderUpdatedData in
            hcLog("파일목록 갱신 감지")
            guard let self else { return }
            self.folderList = folderUpdatedData.newFileList
            self.folderListUpdated?(folderUpdatedData)
        })
        
        folderMonitor?.startMonitoring()
    }
    
    ///새폴더 만들기. 성공시 생성된 URL 반환. 실패시 에러반환
    func createFolder(folderName: String ) async -> Result<URL, CreationError> {
        guard let rootURL else { return .failure(.unknown) }
        
        let newURL = rootURL.appendingPathComponent(folderName, conformingTo: .directory)
        guard fileManager.fileExists(atPath: newURL.path) == false else { return .failure(.duplicatedName)}

        do {
            try fileManager.createDirectory(atPath: newURL.path, withIntermediateDirectories: true, attributes: nil)
            return .success(newURL)
        } catch {
            hcLog("\(error): \(error.localizedDescription)")
            return .failure(.system(error))
        }
    }
    enum CreationError: Error {
        case unknown
        case system(Error)
        case duplicatedName
    }
    
    ///폴더 이름바꾸기. 성공시 바뀐 URL 반환. 실패시 에러 반환.
    func renameFolder(at index: Int, newName: String) async -> Result<URL,RenameError> {
        guard index < folderList.count else { return .failure(.outOfBound)}
        
        let originURL = folderList[index]
        let newURL = originURL.deletingLastPathComponent().appendingPathComponent(newName)
        guard fileManager.fileExists(atPath: newURL.path) == false else { return .failure(.duplicatedName) }
        do {
            try fileManager.moveItem(at: originURL, to: newURL)
        }
        catch {
            return .failure(.system(error))
        }
        
        return .success(newURL)
    }
    enum RenameError: Error {
        case unknown
        case duplicatedName
        case system(Error)
        case outOfBound
        case isNotRealFolder
    }
    
    func deleteFolder(at index: Int) async -> Result<Void,DeleteError> {
        guard index < folderList.count else { return .failure(.outOfBound)}
        let url = folderList[index]
        
        do {
            try fileManager.removeItem(at: url)
        } catch(let error){
            hcLog("\(error): \(error.localizedDescription)")
            return .failure(.system(error))
        }
        return .success(Void())
    }
    enum DeleteError: Error {
        case unknown
        case system(Error)
        case outOfBound
        case isNotRealFolder
    }


}
