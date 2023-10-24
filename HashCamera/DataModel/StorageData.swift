//
//  StorageData.swift
//  HashCamera
//
//  Created by WG-MacHome on 10/24/23.
//

import Foundation

class StorageData: Hashable,Codable { //유저디폴츠에 저장되는 스토리지 데이터 모델
    
    let uuid: UUID
    let type: StorageType
    var localIdentifier: String? //libraray일때 사용
    
    var relativePath: String? //localDrive 또는 icloudDrive 일때 사용
    //FileManager.default.url(forUbiquityContainerIdentifier: nil)? 다음에 붙일 경로
    
    init(uuid: UUID, type: StorageType, localIdentifier: String? = nil, relativePath: String? = nil) {
        self.uuid = uuid
        self.type = type
        self.localIdentifier = localIdentifier
        self.relativePath = relativePath
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(uuid)
    }
    
    static func == (lhs: StorageData, rhs: StorageData) -> Bool {
        lhs.uuid == rhs.uuid ? true : false
    }
    //Endable, Decodable
    enum CodingKeys: String,CodingKey {
        case uuid
        case type
        case localIdentifier
        case relativePath
    }
    
    func encode(to encoder: Encoder) throws{
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(uuid, forKey: .uuid)
        try container.encode(type, forKey: .type)
        try container.encode(localIdentifier, forKey: .localIdentifier)
        try container.encode(relativePath, forKey: .relativePath)
    }
    
    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        uuid = try container.decode(UUID.self, forKey: .uuid)
        type = try container.decode(StorageType.self, forKey: .type)
        localIdentifier = try container.decodeIfPresent(String.self, forKey: .localIdentifier)
        relativePath = try container.decodeIfPresent(String.self, forKey: .relativePath)
    }
}
