//
//  FolderMonitor.swift
//  HashCamera
//
//  Created by Anto-Yang on 3/18/24.
//

import Foundation

class FolderMonitor {
    // MARK: Properties
    
    private let folderMonitorQueue = DispatchQueue(label: "FolderMonitorQueue", qos: .default, attributes: .concurrent)
    private var folderDescriptor: CInt = -1
    private var source: DispatchSourceFileSystemObject?
    private let folderURL: URL?
    private var fileDictionary: [String: Date] = [:]
    var folderList: [URL] = []
    var folderListUpdated: ((FolderUpdateData)-> Void)?
    
    struct FolderUpdateData {
        let newFileList: [URL]
        let addedFiles: [URL]
        let removedFiles: [URL]
    }
    
    
    /// 폴더 모니터를 초기화한다.
    /// - Parameters:
    ///   - folderPath: 감시할 폴더
    ///   - folderListUpdated: 폴더 목록 갱신 시에 불려질 클로저
    init(folderPath: String, folderListUpdated: ((FolderUpdateData)-> Void)?) {
        self.folderURL = URL(string: folderPath)
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
        print("폴더 감시를 시작합니다: \(folderURL.lastPathComponent)")
        
        //폴더변경 -> 폴더 갱신 ->
        // 초기 파일 상태 저장
        initFileListDictionary()
    }
    
    func stopMonitoring() {
        source?.cancel()
        print("폴더 감시를 중단합니다: \(folderURL?.lastPathComponent ?? "nil")")
    }
    
    ///파일 상태를 가져온다.
    private func fetchFileListDictionary() -> (fileList: [URL], fileDictionary: [String: Date]) {
        guard let folderURL else { return ([],[:])}
        guard FileManager.default.fileExists(atPath: folderURL.absoluteString) else {
            hcLog("폴더가 존재하지 않습니다.\(folderURL.lastPathComponent)")
            stopMonitoring()
            return([],[:])
        }
        
        // 폴더 내 파일 목록과 수정 날짜 저장
        do {
            let fileList = try FileManager.default.contentsOfDirectory(at: folderURL, includingPropertiesForKeys: [.contentModificationDateKey], options: [])
            let fileDictionary = Dictionary(uniqueKeysWithValues: fileList.map { ($0.lastPathComponent, (try? $0.resourceValues(forKeys: [.contentModificationDateKey]).contentModificationDate) ?? Date.distantPast) })
            return (fileList, fileDictionary)
        } catch {
            //폴더 변경/삭제 시에 이벤트 발생하여 detectChnage() 호출됨. contentsOfDirectory 에서 없는 폴더라서 오류 발생.
            //새로운 폴더 경로로 Monitor를 새로 시작해야한다.
            print("폴더 내용을 불러올 수 없습니다: \(error)")
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
                folderListUpdated?(FolderUpdateData(newFileList: folderList, addedFiles: [], removedFiles: []))
            }
        }
    }
    
    ///파일 상태 변경 감지시에 변경사항을 탐지하여 업데이트 사항을 전달한다.
    private func detectChanges() {
        guard let folderURL else { return }
        guard FileManager.default.fileExists(atPath: folderURL.absoluteString) else {
            hcLog("폴더가 존재하지 않습니다.\(folderURL.lastPathComponent)")
            stopMonitoring()
            return
        }
        
        let fileListDictionary = fetchFileListDictionary()
        let newFileDictionary = fileListDictionary.fileDictionary
        let newFileList = fileListDictionary.fileList
        
        // 키를 Set으로 변환하여 집합 연산 수행
        let previousKeys = Set(fileDictionary.keys)
        let currentKeys = Set(newFileDictionary.keys)
        
        
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
        
        // 새로운 상태로 갱신
        fileDictionary = newFileDictionary
        folderList = newFileList
        DispatchQueue.main.async { [weak self] in
            self?.folderListUpdated?(FolderUpdateData(newFileList: newFileList, addedFiles: addedFiles, removedFiles: removedFiles))
        }
        
    }
    
}
