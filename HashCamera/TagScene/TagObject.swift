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
    @Persisted var index: Int
    @Persisted var name: String
    ///파일 URL 목록(ex: /Media/FileName.jpeg)
    @Persisted var filePaths: List<String>
}
