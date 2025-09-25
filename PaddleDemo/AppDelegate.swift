//
//  AppDelegate.swift
//  PaddleDemo
//
//  Created by boss on 2025/7/7.
//

import UIKit
import Network



@main
class AppDelegate: UIResponder, UIApplicationDelegate {

    let monitor = NWPathMonitor()
    
    // 启动监视器
    func startNetworkMonitoring() {
        monitor.pathUpdateHandler = { path in
            if path.status == .satisfied {
                print("网络已连接")
                // 具体网络类型判断
                if path.usesInterfaceType(.wifi) {
                    print("当前使用 WiFi")
                } else if path.usesInterfaceType(.cellular) {
                    print("当前使用蜂窝网络")
                }
            } else {
                print("网络不可用")
            }
        }
        
        let queue = DispatchQueue(label: "NetworkMonitor")
        monitor.start(queue: queue)
    }

    // 停止监视器
    func stopNetworkMonitoring() {
        monitor.cancel()
    }

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        // Override point for customization after application launch.
        
        startNetworkMonitoring()
        
        return true
    }

    // MARK: UISceneSession Lifecycle

    func application(_ application: UIApplication, configurationForConnecting connectingSceneSession: UISceneSession, options: UIScene.ConnectionOptions) -> UISceneConfiguration {
        // Called when a new scene session is being created.
        // Use this method to select a configuration to create the new scene with.
        return UISceneConfiguration(name: "Default Configuration", sessionRole: connectingSceneSession.role)
    }

    func application(_ application: UIApplication, didDiscardSceneSessions sceneSessions: Set<UISceneSession>) {
        // Called when the user discards a scene session.
        // If any sessions were discarded while the application was not running, this will be called shortly after application:didFinishLaunchingWithOptions.
        // Use this method to release any resources that were specific to the discarded scenes, as they will not return.
    }


}

