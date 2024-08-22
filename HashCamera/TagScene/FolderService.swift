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
    private init() { }
    
    deinit {
        folderMonitor?.stopMonitoring()
    }
    
    ///폴더 변경 감시자
    var folderMonitor: FolderMonitor?

    let fileManager = FileManager.default
    
    let folders = BehaviorRelay<[URL]>(value: [])
 
    var rootURL: URL? {
        if let baseURL =  FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first {
            return URL(string: "./", relativeTo: baseURL)
        } else {
            return nil
        }
    }
    
    func prepare() {
        guard let rootURL else { return }
        
        if folderMonitor == nil {
            folderMonitor = FolderMonitor(url: rootURL)
        }
        
        folderMonitor?.folderDidChange = {
            self.fetchFolders()
        }
        folderMonitor?.startMonitoring()
    }
    
    ///새폴더 만들기. 성공시 생성된 URL 반환. 실패시 에러반환
    func createFolder(folderName: String ) async -> Result<URL, CreationError> {
        guard let baseURL =  FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first,
              let rootURL = URL(string: "./", relativeTo: baseURL) else { return .failure(.unknown) }
        
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
    
    ///폴더 조회
    func fetchFolders() {
        ///로컬폴더 rootURL 세팅
        Task {
            guard let baseURL =  FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first,
                  let rootURL = URL(string: "./", relativeTo: baseURL) else { return }
            
            do {
                let list =  try fileManager.contentsOfDirectory(at: rootURL,
                                                                includingPropertiesForKeys: nil).filter { $0.isDirectory }
                    .sorted{ $0.lastPathComponent < $1.lastPathComponent }
                hcLog("fetched folders count = \(list.count)")
                await MainActor.run { [weak self] in
                    self?.folders.accept(list)
                }
            }
            catch {
                hcLog("폴더 읽기 실패", error: error)
                await MainActor.run { [weak self] in
                    self?.folders.accept([])
                }
            }
         
        }
    }
    
    ///폴더 이름바꾸기. 성공시 바뀐 URL 반환. 실패시 에러 반환.
    func renameFolder(at index: Int, newName: String) async -> Result<URL,RenameError> {
        guard index < folders.value.count else { return .failure(.outOfBound)}
        
        let originURL = folders.value[index]
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
    }
    
    func deleteFolder(at index: Int) async -> Result<Void,DeleteError> {
        guard index < folders.value.count else { return .failure(.outOfBound)}
        let url = folders.value[index]
        
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
    }


}
