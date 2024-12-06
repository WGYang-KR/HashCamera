//
//  SceneDelegate.swift
//  HashCamera
//
//  Created by WG-Yang on 10/24/23.
//

import UIKit

class SceneDelegate: UIResponder, UIWindowSceneDelegate {

    var window: UIWindow?


    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        // Use this method to optionally configure and attach the UIWindow `window` to the provided UIWindowScene `scene`.
        // If using a storyboard, the `window` property will automatically be initialized and attached to the scene.
        // This delegate does not imply the connecting scene or session are new (see `application:configurationForConnectingSceneSession` instead).
        guard let windowScene = (scene as? UIWindowScene) else { return }

        //위젯에서 url이 전달되었는지 확인
        if let url = connectionOptions.urlContexts.first?.url {
            hcLog("\(url.absoluteString)")
            handleIncomingURL(url)
        }
        
        window = UIWindow(windowScene: windowScene)
        window?.rootViewController = CamVC()
        window?.makeKeyAndVisible()
    }

    func sceneDidDisconnect(_ scene: UIScene) {
        // Called as the scene is being released by the system.
        // This occurs shortly after the scene enters the background, or when its session is discarded.
        // Release any resources associated with this scene that can be re-created the next time the scene connects.
        // The scene may re-connect later, as its session was not necessarily discarded (see `application:didDiscardSceneSessions` instead).
    }

    func sceneDidBecomeActive(_ scene: UIScene) {
        // Called when the scene has moved from an inactive state to an active state.
        // Use this method to restart any tasks that were paused (or not yet started) when the scene was inactive.
        AppLifeCycle.sceneDidBecomeActive.accept(Void())
    }

    func sceneWillResignActive(_ scene: UIScene) {
        // Called when the scene will move from an active state to an inactive state.
        // This may occur due to temporary interruptions (ex. an incoming phone call).
        AppLifeCycle.sceneWillResignActive.accept(Void())
    }

    func sceneWillEnterForeground(_ scene: UIScene) {
        // Called as the scene transitions from the background to the foreground.
        // Use this method to undo the changes made on entering the background.
        AppLifeCycle.sceneWillEnterForeground.accept(Void())
    }

    func sceneDidEnterBackground(_ scene: UIScene) {
        // Called as the scene transitions from the foreground to the background.
        // Use this method to save data, release shared resources, and store enough scene-specific state information
        // to restore the scene back to its current state.
        AppLifeCycle.sceneDidEnterBackground.accept(Void())
    }
    
    func scene(_ scene: UIScene, openURLContexts URLContexts: Set<UIOpenURLContext>) {
        // URL이 전달되었을 때 처리하는 코드
        if let url = URLContexts.first?.url {
            hcLog("\(url.absoluteString)")
            handleIncomingURL(url)
        }
    }
    
    func handleIncomingURL(_ url: URL) {
        // URL을 파싱하여 액션을 실행
        if url.scheme == "hashcamera" {
            // URL을 파싱하여 필요한 동작 수행
            if let host = url.host {
                if host == "widget_select_folder" {
                    if let indexString = url.path.split(separator: "/").last {
                        let index = Int(indexString) ?? 0
                        
                        let folder = WidgetSetting.folderList[index]
                        hcLog("widget_select_folder index: \(index), name: \(folder.name)")
                        WidgetSettingManager.shared.widgetOrder = .selectFolder
                        WidgetSettingManager.shared.widgetSelectedFolder = folder
                        
                        NotificationCenter.default.post(name: .widgetFolderTapped, object: nil, userInfo: nil)
                    }
                    
                } else if host == "widget_select_camera" {
                    hcLog("widget_select_camera")
                    WidgetSettingManager.shared.widgetOrder = .camera
                    NotificationCenter.default.post(name: .widgetCameraTapped, object: nil, userInfo: nil)
                } else if host == "widget_select_settings" {
                    hcLog("widget_select_setting")
                    WidgetSettingManager.shared.widgetOrder = .setting
                    NotificationCenter.default.post(name: .widgetSettingTapped, object: nil, userInfo: nil)
                } else if host == "widget_add_folder" {
                    hcLog("widget_add_folder")
                    WidgetSettingManager.shared.widgetOrder = .addFolder
                    NotificationCenter.default.post(name: .widgetSettingTapped, object: nil, userInfo: nil)
                }
            }
        }
    }


}

