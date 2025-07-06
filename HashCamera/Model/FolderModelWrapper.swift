//
//  FolderModelWrapper.swift
//  HashCamera
//
//  Created by Anto-Yang on 6/29/25.
//

///Published, UserDefaults 에서 사용하기 위해서 enum화
enum FolderModelWrapper: Codable, FolderModelProtocol {
    case local(LocalFolderModel)
    case google(GoogleDriveFolderModel)

    var base: any FolderModelProtocol {
        switch self {
        case .local(let model): return model
        case .google(let model): return model
        }
    }

    var name: String {
        base.name
    }

    var type: FolderType {
        base.type
    }

    func isSame(as other: any FolderModelProtocol) -> Bool {
        switch (self, other) {
        case let (.local(l), other as LocalFolderModel):
            return l.isSame(as: other)
        case let (.google(g), other as GoogleDriveFolderModel):
            return g.isSame(as: other)
        default:
            return false
        }
    }

    // MARK: - Codable
    enum CodingKeys: String, CodingKey {
        case type
        case payload
    }

    enum ModelType: String, Codable {
        case local
        case google
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let type = try container.decode(ModelType.self, forKey: .type)

        switch type {
        case .local:
            let model = try container.decode(LocalFolderModel.self, forKey: .payload)
            self = .local(model)
        case .google:
            let model = try container.decode(GoogleDriveFolderModel.self, forKey: .payload)
            self = .google(model)
        }
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)

        switch self {
        case .local(let model):
            try container.encode(ModelType.local, forKey: .type)
            try container.encode(model, forKey: .payload)
        case .google(let model):
            try container.encode(ModelType.google, forKey: .type)
            try container.encode(model, forKey: .payload)
        }
    }
}

extension FolderModelProtocol {
    var asWrapper: FolderModelWrapper? {
        switch self {
        case let model as LocalFolderModel:
            return .local(model)
        case let model as GoogleDriveFolderModel:
            return .google(model)
        default:
            return nil
        }
    }
}
