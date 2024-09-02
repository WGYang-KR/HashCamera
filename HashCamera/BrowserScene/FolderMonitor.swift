//
//  FolderMonitor.swift
//  HashCamera
//
//  Created by Anto-Yang on 3/18/24.
//

import Foundation

class FolderMonitor {
    // MARK: Properties
    
    private let folderMonitorQueue = DispatchQueue(label: "FolderMonitorQueue", attributes: .concurrent)
    private var folderDescriptor: CInt = -1
    private var source: DispatchSourceFileSystemObject?
    private let folderURL: URL?
    private var previousFileDictionary: [String: Date] = [:]
    
    var folderDidChange: ((FolderChangeData)-> Void)?
    struct FolderChangeData {
        let addedFiles: [URL]
        let removedFiles: [URL]
    }
    
    init(folderPath: String, folderDidChange: ((FolderChangeData)-> Void)?) {
        self.folderURL = URL(string: folderPath)
        self.folderDidChange = folderDidChange
    }
    
    func startMonitoring() {
        
        guard let folderURL, source == nil, folderDescriptor == -1 else { return }
        // 폴더 파일 디스크립터 생성
        folderDescriptor = open(folderURL.path, O_EVTONLY)
        guard folderDescriptor != -1 else {
            print("폴더를 열 수 없습니다.")
            return
        }
        
        // 디스패치 소스 생성
        source = DispatchSource.makeFileSystemObjectSource(
            fileDescriptor: folderDescriptor,
            eventMask: [.write, .rename, .delete],
            queue: folderMonitorQueue
        )
        
        // 변경 감지 핸들러
        source?.setEventHandler { [weak self] in
            self?.detectChanges()
        }
        
        // 에러 핸들러
        source?.setCancelHandler { [weak self] in
            guard let self = self else { return }
            close(self.folderDescriptor)
            self.folderDescriptor = -1
        }
        
        // 감시 시작
        source?.resume()
        print("폴더 감시를 시작합니다: \(folderURL.path)")
        
        // 초기 파일 상태 저장
        updatePreviousFileDictionary()
    }
    
    func stopMonitoring() {
        source?.cancel()
        print("폴더 감시를 중단합니다: \(folderURL?.path ?? "nil")")
    }
    
    private func updatePreviousFileDictionary() {
        guard let folderURL else { return }
        do {
            // 폴더 내 파일 목록과 수정 날짜 저장
            let fileList = try FileManager.default.contentsOfDirectory(at: folderURL, includingPropertiesForKeys: [.contentModificationDateKey], options: [])
            previousFileDictionary = Dictionary(uniqueKeysWithValues: fileList.map { ($0.lastPathComponent, (try? $0.resourceValues(forKeys: [.contentModificationDateKey]).contentModificationDate) ?? Date.distantPast) })
        } catch {
            print("폴더 내용을 불러올 수 없습니다: \(error)")
        }
    }
    
    private func detectChanges() {
        guard let folderURL else { return }
        do {
            // 현재 파일 목록과 수정 날짜 가져오기
            let currentFileList = try FileManager.default.contentsOfDirectory(at: folderURL, includingPropertiesForKeys: [.contentModificationDateKey], options: [])
            let currentFileDictionary = Dictionary(uniqueKeysWithValues: currentFileList.map { ($0.lastPathComponent, (try? $0.resourceValues(forKeys: [.contentModificationDateKey]).contentModificationDate) ?? Date.distantPast) })
            
            // 키를 Set으로 변환하여 집합 연산 수행
            let previousKeys = Set(previousFileDictionary.keys)
            let currentKeys = Set(currentFileDictionary.keys)
            
            
            // 추가된 파일
            let addedFiles = currentKeys.subtracting(previousKeys).map{ folderURL.appendingPathComponent($0)}
            for file in addedFiles {
                print("새 파일이 추가되었습니다: \(file.lastPathComponent)")
            }
            
            // 삭제된 파일
            let removedFiles = previousKeys.subtracting(currentKeys).map{ folderURL.appendingPathComponent($0)}
            for file in removedFiles {
                print("파일이 삭제되었습니다: \(file.lastPathComponent)")
            }
            
            // 현재 상태를 이전 상태로 갱신
            previousFileDictionary = currentFileDictionary
            
            folderDidChange?(FolderChangeData(addedFiles: addedFiles, removedFiles: removedFiles))
        } catch {
            print("폴더 변경을 감지할 수 없습니다: \(error)")
        }
    }
    
    deinit {
        stopMonitoring()
    }
}
