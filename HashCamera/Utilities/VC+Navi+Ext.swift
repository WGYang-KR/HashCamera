//
//  VC+Ext.swift
//  HashCamera
//
//  Created by Anto-Yang on 11/30/24.
//
import UIKit

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
    
    static func removeAllViewControllersAbove(_ baseViewController: UIViewController, completion: (() -> Void)? = nil) {
        // 1. 내비게이션 스택을 정리 (pop)
        if let navigationController = baseViewController.navigationController {
            navigationController.popToViewController(baseViewController, animated: true)
        }
        
        // 2. presentedViewController를 재귀적으로 dismiss
        if let presented = baseViewController.presentedViewController {
            presented.dismiss(animated: true) {
                self.removeAllViewControllersAbove(baseViewController, completion: completion)
            }
        } else {
            // 모든 뷰 컨트롤러가 정리된 후 completion 호출
            completion?()
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
