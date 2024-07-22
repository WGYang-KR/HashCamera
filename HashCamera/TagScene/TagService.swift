//
//  TagService.swift
//  HashCamera
//
//  Created by Anto-Yang on 7/22/24.
//

import Foundation


class TagService {
    static let shared = TagService()
    private init() { }
    
    var tags: [TagObject] = []
    
    ///태그 추가
    func addNewTag(_ newName: String) {
        
    }
    
    ///태그 목록 조회
    func fetchTags() {
        
    }
    
    ///태그 이름 수정
    func editTagName(_ newName: String) {
        
    }
    ///태그 순서 수정
    func editTagOrder(to newIndex: Int) {
        
    }
    ///태그 삭제
    func deleteTag(at index: Int) {
        
    }
    
    
    /// 사진에서 태그가 추가됨 리스너
    /// - Parameter filePath: /Document 다음의 파일경로
    func didRemoveTag(at tagIndex: Int, in filePath: String) {
        
    }
    
    
    /// 사진에서 태그가 제거됨 리스너
    /// - Parameter filePath: /Document 다음의 파일 경로
    func didAddTag(at tagIndex: Int, in filePath: String) {
        
    }
    
}
