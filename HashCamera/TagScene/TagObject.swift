//
//  TagObject.swift
//  HashCamera
//
//  Created by Anto-Yang on 7/22/24.
//

import Foundation
import RealmSwift

class TagObject:Object {

    @Persisted(primaryKey: true) var _id: ObjectId
    @Persisted var order: Int
    @Persisted var name: String
    ///파일 URL 목록(ex: /Media/FileName.jpeg)
    @Persisted var filePaths: List<String>

    convenience init(_id: ObjectId = ObjectId.generate(), order: Int, name: String, filePaths: List<String> = List()) {
        self.init()
        self._id = _id
        self.order = order
        self.name = name
        self.filePaths = filePaths
    }
    
    
}
