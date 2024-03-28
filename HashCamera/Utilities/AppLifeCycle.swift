//
//  AppLifeCycle.swift
//  HashCamera
//
//  Created by WG-MacHome on 11/15/23.
//

import Foundation
import RxSwift
import RxRelay

class AppLifeCycle {
 
    static let sceneDidBecomeActive = PublishRelay<Void>()
    static let sceneWillResignActive = PublishRelay<Void>()
    static let sceneWillEnterForeground = PublishRelay<Void>()
    static let sceneDidEnterBackground = PublishRelay<Void>()
   
}
