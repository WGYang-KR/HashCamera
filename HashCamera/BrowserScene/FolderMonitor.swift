//
//  FolderMonitor.swift
//  HashCamera
//
//  Created by Anto-Yang on 3/18/24.
//

import Foundation
import UniformTypeIdentifiers

enum FileSystemChangeType {
    case initiate
    case add(newIndex: Int)
    case rename(oldIndex: Int, newIndex: Int)
    case delete(deletedIndex: Int)
}

class FolderMonitor {
    // MARK: Properties
    
    private let folderMonitorQueue = DispatchQueue(label: "FolderMonitorQueue", qos: .default, attributes: .concurrent)
    private var folderDescriptor: CInt = -1
    private var source: DispatchSourceFileSystemObject?
    private let folderURL: URL?
    private var fileDictionary: [String: Date] = [:]
    private var contentType: [UTType] = []
    private var eventMask: DispatchSource.FileSystemEvent
    var folderList: [URL] = []
    var folderListUpdated: ((FolderUpdateData)-> Void)?
    
    struct FolderUpdateData {
        let newFileList: [URL]
        let changeType: FileSystemChangeType
    }
    
    
    /// 폴더 모니터를 초기화한다.
    /// - Parameters:
    ///   - folderPath: 감시할 폴더
    ///   - contentType: 폴더 안에서 감시할 파일 유형
    ///   - eventMask: 감시할 이벤트. 폴더목록 감시는 write, 폴더 안 감시는 write, delete를 감시하여 자기자신이 삭제되는 것을 인식하면 될듯
    ///   - folderListUpdated: 폴더 목록 갱신 시에 불려질 클로저
    init(folderURL: URL, contentType: [UTType], eventMask: DispatchSource.FileSystemEvent, folderListUpdated: ((FolderUpdateData)-> Void)?) {
        self.folderURL = folderURL
        self.contentType = contentType
        self.eventMask = eventMask
        self.folderListUpdated = folderListUpdated
 
    }
    
    deinit {
        stopMonitoring()
    }
    
    /// 폴더 감시를 시작하고,  초기 파일 상태을 업데이트한다.
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
            hcLog("변경감지")
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
        print("폴더 감시 시작: \(folderURL.lastPathComponent)")
        
        //폴더변경 -> 폴더 갱신 ->
        // 초기 파일 상태 저장
        initFileListDictionary()
    }
    
    func stopMonitoring() {
        source?.cancel()
        print("폴더 감시 중단: \(folderURL?.lastPathComponent ?? "nil")")
    }
    
    ///파일 상태를 가져온다.
    private func fetchFileListDictionary() -> (fileList: [URL], fileDictionary: [String: Date]) {
        guard let folderURL else { return ([],[:])}
        guard FileManager.default.fileExists(atPath: folderURL.path) else {
            hcLog("폴더가 존재안함.\(folderURL.lastPathComponent)")
            stopMonitoring()
            return([],[:])
        }
        
        // 폴더 내 파일 목록과 수정 날짜 저장
        do {
            let fileList = try FileManager.default.contentsOfDirectory(at: folderURL, includingPropertiesForKeys: [.contentModificationDateKey], options: []).filter { url in
                //설정된 파일유형만 필터링
                guard let type = try? url.resourceValues(forKeys: [.contentTypeKey]).contentType else { return false}
                return contentType.contains(type)
            }.sorted(by: {$0.lastPathComponent < $1.lastPathComponent})
            
            let fileDictionary = Dictionary(uniqueKeysWithValues: fileList.map { ($0.lastPathComponent, (try? $0.resourceValues(forKeys: [.contentModificationDateKey]).contentModificationDate) ?? Date.distantPast) })
            return (fileList, fileDictionary)
        } catch {
            //폴더 변경/삭제 시에 이벤트 발생하여 detectChnage() 호출됨. contentsOfDirectory 에서 없는 폴더라서 오류 발생.
            //새로운 폴더 경로로 Monitor를 새로 시작해야한다.
            print("폴더목록 Fetch 실패: \(error)")
            return ([],[:])
        }
    }
    
    ///초기파일상태를 업데이트 한다.
    private func initFileListDictionary() {
        guard let folderURL else { return }
        folderMonitorQueue.async { [weak self] in //감시 Queue
            guard let self else { return }
            let fileListDictionary = fetchFileListDictionary() //파일 목록 가져오기
            fileDictionary = fileListDictionary.fileDictionary
            folderList = fileListDictionary.fileList
            DispatchQueue.main.async { [weak self] in
                guard let self else { return }
                //파일목록 업데이트 전달
                folderListUpdated?(FolderUpdateData(newFileList: folderList, changeType: .initiate ))
            }
        }
    }
    
    ///파일 상태 변경 감지시에 변경사항을 탐지하여 업데이트 사항을 전달한다.
    private func detectChanges() {
        guard let folderURL else { return }
        guard FileManager.default.fileExists(atPath: folderURL.path) else {
            hcLog("폴더가 존재하지 않습니다.\(folderURL.lastPathComponent)")
            stopMonitoring()
            return
        }
        
        let currentFileDictionary = fileDictionary
        let currentFileList = folderList
        
        let fileListDictionary = fetchFileListDictionary()
        let newFileDictionary = fileListDictionary.fileDictionary
        let newFileList = fileListDictionary.fileList
        
        // 키를 Set으로 변환하여 집합 연산 수행
        let previousKeys = Set(currentFileDictionary.keys)
        let currentKeys = Set(newFileDictionary.keys)
        
        
        // 추가된 파일
        let addedFiles = currentKeys.subtracting(previousKeys).map{ folderURL.appendingPathComponent($0)}
        for file in addedFiles {
            hcLog("새 파일 추가됨: \(file.lastPathComponent)")
        }
        
        // 추가된 파일 Index
        //TODO: URL 형식이 달라 index 못 찾는중
        var addedFileIndex: Int?
        if let fileURL = addedFiles.first, let fileIndex = newFileList.firstIndex(where: {$0.lastPathComponent == fileURL.lastPathComponent }) {
            addedFileIndex = fileIndex
            hcLog("새 파일 Index: \(fileIndex)")
        }
        
        // 삭제된 파일
        let deletedFiles = previousKeys.subtracting(currentKeys).map{ folderURL.appendingPathComponent($0)}
        for file in deletedFiles {
            print("파일 삭제됨: \(file.lastPathComponent)")
        }
        
        // 삭제된 파일 Index
        //TODO: URL 형식이 달라 index 못 찾는중
        var deletedFileIndex: Int?
        if let fileURL = deletedFiles.first, let fileIndex = currentFileList.firstIndex(where: {$0.lastPathComponent == fileURL.lastPathComponent }) {
            deletedFileIndex = fileIndex
            hcLog("삭제 파일 Index: \(fileIndex)")
        }
        
        // 새로운 상태로 갱신
        fileDictionary = newFileDictionary
        folderList = newFileList
        
        DispatchQueue.main.async { [weak self] in
            guard let self else  { return }
            if addedFiles.count > 0, deletedFiles.count > 0 { //이름 변경
                guard let addedFileIndex, let deletedFileIndex else { return }
                folderListUpdated?(FolderUpdateData(newFileList: newFileList, changeType: .rename(oldIndex: deletedFileIndex, newIndex: addedFileIndex)))
            } else if addedFiles.count > 0 { //추가
                guard let addedFileIndex else { return }
                folderListUpdated?(FolderUpdateData(newFileList: newFileList, changeType: .add(newIndex: addedFileIndex)))
            } else if deletedFiles.count > 0 { //삭제
                guard let deletedFileIndex else { return }
                folderListUpdated?(FolderUpdateData(newFileList: newFileList, changeType: .delete(deletedIndex: deletedFileIndex)))
            } else {
                //무시
            }
        }
        
        hcLog("감시 1개 이벤트 완료")
        
    }
    
}


