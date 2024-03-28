//
//  EmailHelper.swift
//  HashCamera
//
//  Created by Anto-Yang on 3/28/24.
//

import Foundation
import UIKit
import MessageUI

class EmailHelper: NSObject, MFMailComposeViewControllerDelegate {
    public static let shared = EmailHelper()
    private override init() {
        //
    }
    
    func sendEmail(subject:String, body:String, to:String){
        if !MFMailComposeViewController.canSendMail() {
            print("No mail account found")
            // Todo: Add a way to show banner to user about no mail app found or configured
            // Utilities.showErrorBanner(title: "No mail account found", subtitle: "Please setup a mail account")
            return //EXIT
        }
        
        let picker = MFMailComposeViewController()
        
        picker.setSubject(subject)
        picker.setMessageBody(body, isHTML: false)
        picker.setToRecipients([to])
        picker.mailComposeDelegate = self
        
        EmailHelper.getRootViewController()?.present(picker, animated: true, completion: nil)
    }
    
    func mailComposeController(_ controller: MFMailComposeViewController, didFinishWith result: MFMailComposeResult, error: Error?) {
        EmailHelper.getRootViewController()?.dismiss(animated: true, completion: nil)
    }
    
    static func getRootViewController() -> UIViewController? {
        if let viewController = UIApplication.shared.windows.first?.rootViewController {
            if let presentedViewController = viewController.presentedViewController {
                // 현재 Modal로 표시되고 있는 뷰 컨트롤러
                print("Presented view controller: \(presentedViewController)")
                return presentedViewController
            } else if let navigationController = viewController as? UINavigationController {
                // Navigation Controller의 현재 뷰 컨트롤러
                print("Top view controller in navigation stack: \(String(describing: navigationController.topViewController))")
                return navigationController
            } else {
                // 현재 화면에 표시되고 있는 뷰 컨트롤러
                print("Visible view controller: \(viewController)")
                return viewController
            }
        } else {
            print("No Visible view controller")
            return nil
        }
    }
}
