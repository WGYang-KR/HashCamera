//
//  FolderCRUDAlert.swift
//  HashCamera
//
//  Created by Anto-Yang on 11/7/24.
//

import UIKit
import RxSwift
import RxRelay

class FolderCRUDAlert {
    
    private var disBag = DisposeBag()
    private static var folderNames: [String] = []
    
    init() {
        Self.folderNames = FolderService.shared.folderList.map({ $0.lastPathComponent })
        FolderService.shared.folderListUpdatedRx.subscribe(onNext: {_ in
            Self.folderNames = FolderService.shared.folderList.map({ $0.lastPathComponent })
        }).disposed(by: disBag)
    }
    
    deinit{
        Self.folderNames = []
        disBag = DisposeBag()
    }

    func beginCreateAlert(baseVC: UIViewController, completion: @escaping (Bool)-> Void ) {
        let alert = UIAlertController(title: "새 폴더 생성", message: nil, preferredStyle: .alert)
        alert.addTextField { textField in
            textField.placeholder = "새 폴더 이름을 입력하세요"
        }
        
        let confirmAction = UIAlertAction(title: "확인", style: .default) { _ in
            guard let newName = alert.textFields?.first?.text else { return }
            Task {
                
                let result = await FolderService.shared.createFolder(folderName: newName)
                await MainActor.run {
                    switch result {
                    case .success(_):
                        AlertHelper.notesInform(message: "폴더 생성 성공")
                        completion(true)
                    case .failure(let error):
                        AlertHelper.notesInform(message: "폴더명 생성 실패", color: .systemRed) //TODO:색상
                        completion(false)
                    }
                }
            }
        }
        confirmAction.isEnabled = false  // 초기에는 비활성화
        
        alert.addAction(UIAlertAction(title: "취소", style: .cancel, handler: {_ in 
            completion(false)
        }))
        alert.addAction(confirmAction)
        
        // 텍스트 필드 변경 감지
        NotificationCenter.default.addObserver(forName: UITextField.textDidChangeNotification, object: alert.textFields?.first, queue: .main) { _ in
            let text = alert.textFields?.first?.text ?? ""
            confirmAction.isEnabled = !text.isEmpty && !Self.folderNames.contains(text) && Self.isFolderNameValid(text)
        }
        
        baseVC.present(alert, animated: true, completion: nil)
    }
    
    func beginRenameAlert(baseVC: UIViewController, originURL: URL, completion: ((Bool) -> Void)? ) {
        let alert = UIAlertController(title: "폴더 이름 변경", message: nil, preferredStyle: .alert)
        alert.addTextField { textField in
            textField.placeholder = "변경할 폴더 이름을 입력하세요"
            textField.text = originURL.lastPathComponent
        }
        
        let confirmAction = UIAlertAction(title: "확인", style: .default) { _ in
            guard let newName = alert.textFields?.first?.text else { return }
            Task {
                let result = await FolderService.shared.renameFolder(originURL: originURL, newName: newName)
                await MainActor.run {
                    switch result {
                    case .success(_):
                        AlertHelper.notesInform(message: "폴더명 변경 성공")
                        completion?(true)
                    case .failure(let error):
                        AlertHelper.notesInform(message: "폴더명 변경 실패", color: .systemRed) //TODO:색상
                        completion?(false)
                    }
                  
                }
              
            }
        }
        confirmAction.isEnabled = false  // 초기에는 비활성화
        
        alert.addAction(UIAlertAction(title: "취소", style: .cancel) { _ in
            completion?(false)
        })
        alert.addAction(confirmAction)
        
        // 텍스트 필드 변경 감지
        NotificationCenter.default.addObserver(forName: UITextField.textDidChangeNotification, object: alert.textFields?.first, queue: .main) { _ in
            let text = alert.textFields?.first?.text ?? ""
            confirmAction.isEnabled = !text.isEmpty && !Self.folderNames.contains(text) && Self.isFolderNameValid(text)
        }
        
        baseVC.present(alert, animated: true, completion: nil)
    }
   
    private static func isFolderNameValid(_ name: String) -> Bool {
        // 폴더 이름이 비어있지 않고 "."으로 시작하지 않는지 검사
        let invalidCharacters = CharacterSet(charactersIn: "/\\?%*:|\"<>") // 허용되지 않는 문자 목록
        return !name.isEmpty && !name.hasPrefix(".") && name.rangeOfCharacter(from: invalidCharacters) == nil
    }

}
