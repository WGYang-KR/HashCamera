//
//  MoveToFolderVM.swift
//  HashCamera
//
//  Created by Anto-Yang on 9/23/24.
//

import Foundation

class MoveToFolderVM: SelectableFolderListVM {
  
    let fileManager = FileManager.default
    
    ///이동 진행할 파일목록
    var targetFileList: [ImageFileModel] = []
    
    ///1. 중복 파일을 미리 체크하는 함수
    func checkDuplicateFiles() throws  -> [String] {
        guard let destination = selectedFolder?.url else { throw FileMoveError.unknown}
        let files = targetFileList.map({ $0.url })

        var duplicateFiles = [String]()
        
        for file in files {
            let destinationFile = destination.appendingPathComponent(file.lastPathComponent)
            if fileManager.fileExists(atPath: destinationFile.path) {
                duplicateFiles.append(file.lastPathComponent)
            }
        }
        
        return duplicateFiles
    }
    
    ///2. 파일 이동을 진행하는 함수 (Result로 반환)
    func moveFiles(overwrite: Bool) async throws -> [Result<URL, FileMoveError>] {
        guard let destFolderURL = selectedFolder?.url else { throw FileMoveError.unknown }
        let files = targetFileList.map({ $0.url })
        
        var results = [Result<URL, FileMoveError>]() // 이동 결과를 저장하는 리스트
        
        for file in files {
            let newFileURL = destFolderURL.appendingPathComponent(file.lastPathComponent)
            
            // 파일이 이미 존재할 경우 처리
            if fileManager.fileExists(atPath: newFileURL.path) {
                if overwrite {
                    // 덮어쓰기
                    do {
                        try fileManager.removeItem(at: newFileURL)
                        try fileManager.moveItem(at: file, to: newFileURL)
                        hcLog("Overwritten: \(newFileURL.lastPathComponent)")
                        results.append(.success(newFileURL)) // 성공한 파일 추가
                    } catch {
                        hcLog("Error overwriting \(file.lastPathComponent): \(error)")
                        results.append(.failure(.fileOverwriteFailed(file: file, error: error))) // 실패한 파일과 에러 추가
                    }
                } else {
                    // 이름 변경
                    var newNoExistFileURL = newFileURL
                    var count = 1
                    
                    while fileManager.fileExists(atPath: newNoExistFileURL.path) {
                        let newName = "\(newFileURL.deletingPathExtension().lastPathComponent) (\(count))"
                        newNoExistFileURL = destFolderURL.appendingPathComponent(newName).appendingPathExtension(file.pathExtension)
                        count += 1
                    }
                    
                    do {
                        try fileManager.moveItem(at: file, to: newNoExistFileURL)
                        hcLog("Renamed and moved: \(newNoExistFileURL.lastPathComponent)")
                        results.append(.success(newNoExistFileURL)) // 성공한 파일 추가
                    } catch {
                        hcLog("Error renaming \(file.lastPathComponent): \(error)")
                        results.append(.failure(.fileRenameFailed(file: file, error: error))) // 실패한 파일과 에러 추가
                    }
                }
            } else {
                // 파일이 존재하지 않으면 그냥 이동
                do {
                    try fileManager.moveItem(at: file, to: newFileURL)
                    hcLog("Moved: \(file.lastPathComponent)")
                    results.append(.success(newFileURL)) // 성공한 파일 추가
                } catch {
                    hcLog("Error moving \(file.lastPathComponent): \(error)")
                    results.append(.failure(.fileMoveFailed(file: file, error: error))) // 실패한 파일과 에러 추가
                }
            }
        }
        
        return results // 파일 이동 결과 반환
    }
    /// 파일 이동의 결과를 나타낼 Result 타입 정의
    enum FileMoveError: Error {
        case unknown
        case fileOverwriteFailed(file: URL, error: Error)
        case fileRenameFailed(file: URL, error: Error)
        case fileMoveFailed(file: URL, error: Error)
    }
    
}
