//
//  Utils.swift
//  HashCamera
//
//  Created by Anto-Yang on 7/24/24.
//

import UIKit
import os.log

class Utils {
    
    // 특정 요소를 다른 위치로 이동하는 함수
    static func moveItem<T>(array: inout [T], fromIndex: Int, toIndex: Int) {
        let element = array.remove(at: fromIndex)
        array.insert(element, at: toIndex)
    }
    
}


//MARK: - 로그
public func hcLog(_ message: String?, file: String = #file, functionName: String = #function , line: UInt = #line) {
    
#if RELEASE
    return
#endif
    
    let className = (file as NSString).lastPathComponent
    os_log("%@",type:.default ,"\(Timestamp.timestamp())<\(className)> \(functionName) [#\(line)] \(message ?? "")")
}

class Timestamp {
    static let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yy/MM/dd HH:mm:ss.SSS "
        return formatter
    }()
    
    static func timestamp() -> String{
        return dateFormatter.string(from: Date())
    }
    
}

//MARK: - 네비바
extension UIViewController {

    func naviBackBarButtonItem() -> UIBarButtonItem {
        return UIBarButtonItem(image: SystemUIImage.chevronLeft,
                               style: .plain,
                               target: self,
                               action: #selector(naviBackBtnTapped))
    }
    
    @objc func naviBackBtnTapped() {
        moveBackVC(animated: true)
    }

    func setNaviBar(_ title: String, leftItems: [UIBarButtonItem]?, rightItems: [UIBarButtonItem]?) {
        
        //아이콘 세팅
        self.navigationItem.title = title
        self.navigationItem.leftBarButtonItems = leftItems
        self.navigationItem.rightBarButtonItems = rightItems

        
        // 네비게이션 바 색상 설정
        let defaultColor = UIColor.colorTeal02
        self.navigationController?.navigationBar.titleTextAttributes = [
            .foregroundColor: defaultColor // 타이틀 텍스트 색상 변경
        ]
        
        if let leftBarButtonItems = self.navigationItem.leftBarButtonItems {
            for item in leftBarButtonItems {
                item.tintColor = defaultColor
                item.setTitleTextAttributes([.foregroundColor: defaultColor], for: .normal)
            }
        }
        
        if let rightBarButtonItems = self.navigationItem.rightBarButtonItems {
            for item in rightBarButtonItems {
                item.tintColor = defaultColor
                item.setTitleTextAttributes([.foregroundColor: defaultColor], for: .normal)
            }
        }
        
    }
}

//MARK: - 화면 전환
extension UIViewController {
    
    func presentFull(_ vcToPresent: UIViewController, animated: Bool, completion: (() -> Void)? = nil) {
        vcToPresent.modalPresentationStyle = .fullScreen
        self.present(vcToPresent, animated: animated, completion: completion)
    }
    
    func presentOverFull(_ vcToPresent: UIViewController, animated: Bool, completion: (() -> Void)? = nil) {
        vcToPresent.modalPresentationStyle = .overFullScreen
        self.present(vcToPresent, animated: animated, completion: completion)
    }
    
    func present(_ vcToPresent: UIViewController, modalStyle: UIModalPresentationStyle, animated: Bool, completion: (() -> Void)? = nil) {
        vcToPresent.modalPresentationStyle = modalStyle
        self.present(vcToPresent, animated: animated, completion: completion)
    }
    
    ///popVC / dismiss 를 자동으로 결정하여 수행.
    func moveBackVC(animated: Bool, completion: (()-> Void)? = nil) {
        if let naviVC = self.navigationController,
           let rootVC = naviVC.viewControllers.first,
           rootVC != self {
            naviVC.popViewController(animated: animated, completion: completion)
        } else {
            dismiss(animated: animated, completion: completion)
        }
    }
    
    func doAfterAnimatingTransition(animated: Bool,
                                    completion: (() -> Void)? ) {
        if let coordinator = transitionCoordinator, animated {
            coordinator.animate(alongsideTransition: nil, completion: { _ in
                completion?()
            })
        } else {
            DispatchQueue.main.async {
                completion?()
            }
        }
    }
    
    //현재 보여지는 가장 Top VC를 찾아서 반환한다
    static func getTopViewController() -> UIViewController? {
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

extension UINavigationController { //navigation controller completion 추가
    
    func pushViewController(viewController: UIViewController,
                            animated: Bool,
                            completion: (() -> Void)? ) {
        pushViewController(viewController, animated: animated)
        doAfterAnimatingTransition(animated: animated, completion: completion)
    }
    
    func popViewController(animated: Bool, completion: (() -> Void)? = nil) {
        popViewController(animated: animated)
        doAfterAnimatingTransition(animated: animated, completion: completion)
    }
    
    func popToRootViewController(animated: Bool, completion: (() -> Void)? = nil) {
        popToRootViewController(animated: animated)
        doAfterAnimatingTransition(animated: animated, completion: completion)
    }
    
    func pushToTopRootViewController(viewController: UIViewController,
                                     animated: Bool,
                                     completion: (() -> Void)?)  {
        
        self.pushViewController(viewController: viewController, animated: animated, completion: {
            self.viewControllers = [viewController]
            completion?()
        })
        
    }
    
}

// UIColor+Utils
extension UIColor {
    static func by(r: Int, g: Int, b: Int, a: CGFloat = 1) -> UIColor {
        let d = CGFloat(255)
        return UIColor(red: CGFloat(r) / d, green: CGFloat(g) / d, blue: CGFloat(b) / d, alpha: a)
    }
    
    convenience init(red: Int, green: Int, blue: Int) {
        assert(red >= 0 && red <= 255, "Invalid red component")
        assert(green >= 0 && green <= 255, "Invalid green component")
        assert(blue >= 0 && blue <= 255, "Invalid blue component")
        
        self.init(red: CGFloat(red) / 255.0, green: CGFloat(green) / 255.0, blue: CGFloat(blue) / 255.0, alpha: 1.0)
    }
    
    convenience init(rgb: Int) {
        self.init(
            red: (rgb >> 16) & 0xFF,
            green: (rgb >> 8) & 0xFF,
            blue: rgb & 0xFF
        )
    }
}
