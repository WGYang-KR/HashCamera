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
    static let shared = FolderService()
    
    let fileManager = FileManager.default

    ///대상 폴더
    private(set) var rootURL: URL?
    ///폴더 내 폴더 변경 감시자
    private var folderMonitor: FolderMonitor?
    ///폴더 내 폴더 목록
    var folderList: [URL] = []
    ///폴더 내 폴더 변경 이벤트 핸들러
    let folderListUpdatedRx = PublishRelay<FolderMonitor.FolderUpdateData>()
    
    var isMonitoring: Bool {
        folderMonitor?.isMonitoring ?? false
    }
    
    private init() {}
    
    deinit {
        folderMonitor?.stopMonitoring()
    }
    
    ///Root 폴더 지정. 폴더 목록 불러오고. 변경 감시 시작하기.
    func configure(rootURL: URL) {
        
        self.rootURL = rootURL
        
        folderMonitor?.stopMonitoring()
        folderMonitor = FolderMonitor(folderURL: rootURL,
                                      contentType: [.directory, .folder],
                                      eventMask: [.write],
                                      folderListUpdated: { [weak self] updateData in
            guard let self else { return }
            folderList = updateData.newFileList
            folderListUpdatedRx.accept(updateData)
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
