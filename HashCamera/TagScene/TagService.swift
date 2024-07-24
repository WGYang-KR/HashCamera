//
//  TagService.swift
//  HashCamera
//
//  Created by Anto-Yang on 7/22/24.
//

import Foundation
import RealmSwift
import RxSwift
import RxRelay

class TagService {
    static let shared = TagService()
    private init() { }
    
    let tags = BehaviorRelay<[TagObject]>(value: [])
    
    ///태그 추가
    func addNewTag(_ newName: String) {
        fetchTags()
        let lastOrder = tags.value.last?.order ?? 0
        let newTag = TagObject(order: lastOrder + 1, name: newName)
        
        do {
            let realm = try Realm()
            try realm.write {
                realm.add(newTag)
            }
            hcLog("태그 추가 완료")
        } catch {
            hcLog("\(error) \(error.localizedDescription)")
        }
        
        fetchTags()
        
        
    }
    
    ///태그 목록 갱신
    func fetchTags() {
        do {
            let realm = try Realm()
            let results = realm.objects(TagObject.self).sorted(byKeyPath: "index", ascending: true)
            tags.accept(Array(results))
            hcLog("태그 목록 갱신 완료")
        } catch {
            hcLog("\(error) \(error.localizedDescription)")
            tags.accept([])
        }
    }
    
    ///태그 이름 수정
    func editTagName(at index: Int, newName: String) {
        guard index < tags.value.count else {
            hcLog("바운드 오류")
            return
        }
        
        let tag = tags.value[index]
        tag.name = newName
        do {
            let realm = try Realm()
            try realm.write {
                realm.add(tag, update: .modified)
            }
            hcLog("태그 이름 수정 완료: \(newName)")
        } catch {
            hcLog("\(error) \(error.localizedDescription)")
        }
    }
    
    ///태그 순서 수정
    func editTagOrder(at oldIndex: Int, to newIndex: Int) {
        guard oldIndex < tags.value.count, newIndex < tags.value.count, oldIndex != newIndex else {
            hcLog("바운드 오류")
            return
        }
        
        let tags = tags.value
        let tag = tags[oldIndex]
        do {
            let realm = try Realm()
            try realm.write {
                
                // 순서를 변경할 때 임시로 중간 순서를 부여
                let newOrder = tags[newIndex].order
                
                if oldIndex < newIndex {
                    for i in oldIndex+1...newIndex {
                        tags[i].order -= 1
                    }
                } else { // oldIndex >= newIndex
                    for i in (newIndex..<oldIndex).reversed() {
                        tags[i].order += 1
                    }
                }
                
                tag.order = newOrder
            }
            hcLog("태그 순서 변경 DB 반영 완료. \(tag.name): \(oldIndex) -> \(tag.order)")
            
            var tags = tags
            Utils.moveItem(array: &tags, fromIndex: oldIndex, toIndex: newIndex)
            hcLog("태그 순서 변경 Service 반영 완료. \(tag.name): \(oldIndex) -> \(tag.order)")
        } catch {
            hcLog("\(error) \(error.localizedDescription)")
        }
        
    }

    ///태그 삭제
    func deleteTag(at index: Int) {
        guard index < tags.value.count else {
            hcLog("바운드 오류")
            return
        }
        

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
