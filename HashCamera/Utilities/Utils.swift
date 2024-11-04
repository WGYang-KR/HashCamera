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
    
    ///앱 SandBox documnets 디렉토리 URL, nil일 때는 '/' path를 반환한다.
    static var documentsFolderURL: URL {
        return FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first ?? URL(fileURLWithPath: "/")
    }
    
}


//MARK: - 로그
func hcLog(_ message: String?, file: String = #file, functionName: String = #function , line: UInt = #line) {
    
#if RELEASE
    return
#endif
    
    let className = (file as NSString).lastPathComponent
    os_log("%@",type:.default ,"\(Timestamp.timestamp())<\(className)> \(functionName) [#\(line)] \(message ?? "")")
}

func hcLog(_ message: String?, file: String = #file, functionName: String = #function , line: UInt = #line, error: Error?) {
    
#if RELEASE
    return
#endif
    if let error {
        let className = (file as NSString).lastPathComponent
        os_log("%@",type:.default ,"\(Timestamp.timestamp())<\(className)> \(functionName) [#\(line)] \(message ?? "") | \(error) | \(error.localizedDescription)")
    } else {
        hcLog(message,file: file, functionName: functionName, line: line)
    }
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
        let appearance = UINavigationBarAppearance()
        
        // 투명한 배경을 유지하고 색상을 설정
        appearance.configureWithTransparentBackground()
        appearance.backgroundColor = .naviBarBackground.withAlphaComponent(0.5)  // 반투명 효과
        appearance.backgroundEffect = UIBlurEffect(style: .light)  // Blur 효과 추가
        
        // 제목 텍스트 색상 설정
        appearance.titleTextAttributes = [.foregroundColor: UIColor.label]

        // 버튼 텍스트 색상 설정
        navigationController?.navigationBar.tintColor = .systemCyan
        
        // standardAppearance와 scrollEdgeAppearance 모두에 적용
        navigationController?.navigationBar.standardAppearance = appearance
        navigationController?.navigationBar.scrollEdgeAppearance = appearance
        
    }
    
    func setToolbar(items: [UIBarButtonItem]) {
        
        setToolbarItems(items, animated: false)
        
        // 네비게이션 바 색상 설정
        let appearance =  UIToolbarAppearance()
        
        // 투명한 배경을 유지하고 색상을 설정
        appearance.configureWithTransparentBackground()
        appearance.backgroundColor = .naviBarBackground.withAlphaComponent(0.5)  // 반투명 효과
        appearance.backgroundEffect = UIBlurEffect(style: .light)  // Blur 효과 추가
        
        // 버튼 텍스트 색상 설정
        navigationController?.toolbar.tintColor = .systemCyan
        
        // standardAppearance와 scrollEdgeAppearance 모두에 적용
        navigationController?.toolbar.standardAppearance = appearance
        navigationController?.toolbar.scrollEdgeAppearance = appearance
    
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
    
    func present(_ vcToPresent: UIViewController, presentationStyle: UIModalPresentationStyle?, transitionStyle: UIModalTransitionStyle?, animated: Bool, completion: (() -> Void)? = nil) {
        if let presentationStyle {
            vcToPresent.modalPresentationStyle = presentationStyle
        }
   
        if let transitionStyle {
            vcToPresent.modalTransitionStyle = transitionStyle
        }
       
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


//MARK: - UIColor+Utils
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

//MARK: - TableView
extension UITableView {
    func reloadData(completion: @escaping () -> Void) {
        UIView.animate(withDuration: 0, animations: {
            self.reloadData()
        }) { _ in
            completion()
        }
    }
}


//MARK: - 배열 OutOfBound 체크
extension Array {
    subscript(safe index: Int) -> Element? {
        return indices.contains(index) ? self[index] : nil
    }
}


//MARK: - 뷰 레이아웃
extension UIView {
    func roundCorners(corners: UIRectCorner, radius: CGFloat) {
        clipsToBounds = true
        layer.cornerRadius = radius
        layer.maskedCorners = CACornerMask(rawValue: corners.rawValue)
    }
}
