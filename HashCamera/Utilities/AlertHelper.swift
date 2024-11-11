//
//  AlertHelper.swift
//  SwipeHanja
//
//  Created by Anto-Yang on 5/6/24.
//

import UIKit
import SwiftEntryKit

class AlertHelper {
    
    static func alertConfirm(baseVC: UIViewController,
                      title:String,
                      message: String,
                      confirmCompletion: @escaping ()->Void,
                      cancelCompletion: (()->Void)? = nil,
                      animated: Bool = true) {
        
        
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        
        let confirmAction = UIAlertAction(title: "확인", style: .default) { (_) in
            confirmCompletion()
        }
        let cancelAction = UIAlertAction(title: "취소", style: .cancel) { (_) in
            cancelCompletion?()
        }
        
        alert.addAction(cancelAction)
        alert.addAction(confirmAction)

               
        baseVC.present(alert, animated: animated, completion: nil)
    }
    
    static func alertInform(baseVC: UIViewController,
                      title:String,
                      message: String,
                      confirmCompletion: @escaping ()->Void,
                      animated: Bool = true) {
        
        
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        let confirmAction = UIAlertAction(title: "확인", style: .default) { (_) in
            confirmCompletion()
        }
        alert.addAction(confirmAction)
        
        baseVC.present(alert, animated: animated, completion: nil)
    }
    
    
    static func notesInform(message text: String, color: UIColor = .systemCyan) {
        var attributes: EKAttributes

        attributes = .topNote
        attributes.positionConstraints.size = .init(
            width: .fill,
            height:.constant(value: 48)
        )
        attributes.displayDuration = 0.8
        attributes.displayMode = .inferred
        attributes.hapticFeedbackType = .success
        attributes.popBehavior = .animated(animation: .translation)
        attributes.entryBackground = .color(color: EKColor(color))
        attributes.shadow = .active(
            with: .init(
                color: EKColor(UIColor(red: 48, green: 47, blue: 48)),
                opacity: 0.5,
                radius: 2
            )
        )
        attributes.statusBar = .inferred
        attributes.lifecycleEvents.willAppear = {
//            print("will appear action goes here")
        }
        attributes.lifecycleEvents.didAppear = {
//            print("did appear action goes here")
        }
        attributes.lifecycleEvents.willDisappear = {
//            print("will disappear action goes here")
        }
        attributes.lifecycleEvents.didDisappear = {
//            print("did disappear action goes here")
        }
            
        let style = EKProperty.LabelStyle(
            font: UIFont.systemFont(ofSize: 15.0, weight: .light),
            color: .white,
            alignment: .center
        )
        let labelContent = EKProperty.LabelContent(
            text: text,
            style: style
        )
        let contentView = EKNoteMessageView(with: labelContent)
        SwiftEntryKit.display(entry: contentView, using: attributes)
    }
}
