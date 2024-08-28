//
//  MoveFolderVM.swift
//  HashCamera
//
//  Created by Anto-Yang on 8/28/24.
//

import Foundation
import RxSwift
import RxRelay
class MoveFolderVM: FolderListVMProtocol {
    private var disposeBag = DisposeBag()
    
    private let folderService = FolderService.shared
    private let fileService = FileService.shared
    let selectedFolderIndexPath = BehaviorRelay<IndexPath>(value:.init(row: 0, section: 0))
    let folders = BehaviorRelay<[[FolderListItemModel]]>(value: [[]])
    
    let fileURLs: [URL]
    
    init(fileURLs: [URL]) {
        self.fileURLs = fileURLs
    }
    
    func prepare() {
        
        folderService.folders.withUnretained(self).subscribe{owner, list in
            guard let rootURL = owner.folderService.rootURL else { return }
            //분류안됨 폴더를 section 0에 추가하면서 폴더 목록 갱신한다.
            let virtualFolders: [FolderListItemModel] = [.init(type: .unclassified, url: rootURL)]
            owner.folders.accept([virtualFolders, list])
            owner.selectedFolderIndexPath.accept(.init(row: 0, section: 0))
        }.disposed(by: disposeBag)
        
        ///선택된 폴더 index가 바뀌면, 바뀐 폴더의 파일목록을 가져온다.
        selectedFolderIndexPath.skip(2).subscribe{ [weak self] indexPath in
            guard let self else { return }
            guard indexPath.section < folders.value.count,
                  indexPath.row < folders.value[indexPath.section].count
            else { return }
            let newFolder = folders.value[indexPath.section][indexPath.row]
            let fileURLs = self.fileURLs
            Task {
                await self.fileService.moveFile(at: fileURLs, to: newFolder.url)
            }
        }.disposed(by: disposeBag)
        
    }
    
    
    //MARK: FolderListVMProtocol
    func createFolder(folderName: String) async -> Result<URL, FolderService.CreationError> {
        await folderService.createFolder(folderName: folderName)
    }
    
    func renameFolder(at indexPath: IndexPath, newName: String) async -> Result<URL, FolderService.RenameError> {
        guard folders.value[indexPath.section][indexPath.row].type == .folder else { return .failure(.isNotRealFolder) }
        return await folderService.renameFolder(at: indexPath.row, newName: newName)
    }
    
    func deleteFolder(at indexPath: IndexPath) async -> Result<Void, FolderService.DeleteError> {
        guard folders.value[indexPath.section][indexPath.row].type == .folder else { return .failure(.isNotRealFolder) }
        return await folderService.deleteFolder(at: indexPath.row)
    }
    
    
}
