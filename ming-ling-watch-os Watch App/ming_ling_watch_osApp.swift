//
//  ming_ling_watch_osApp.swift
//  ming-ling-watch-os Watch App
//
//  Created by CreepOnSky on 2025/7/24.
//

import SwiftUI
import WatchKit

@main
struct ming_ling_watch_os_Watch_AppApp: App {
    @StateObject private var profileManager = UserProfileManager.shared
    @StateObject private var monitoringService = HealthMonitoringService.shared
    @StateObject private var demoManager = DemoManager.shared
    @WKApplicationDelegateAdaptor var appDelegate: WatchOSAppDelegate
    
    var body: some Scene {
        WindowGroup {
            // 优先检查Demo模式
            if demoManager.isDemo {
                demoAppFlow
            } else if profileManager.isProfileComplete {
                // 用户已完成档案设置，显示主界面
                NavigationView {
                    MainPetView()
                }
                .navigationViewStyle(StackNavigationViewStyle())
                .onAppear {
                    // 启动后台健康监测
                    monitoringService.startMonitoring()
                }
            } else {
                // 用户未完成档案设置，显示生日选择界面
                BirthdaySelectionView()
            }
        }
        
        // 配置自定义通知界面
        WKNotificationScene(controller: NotificationController.self, category: "PET_NOTIFICATION")
    }
    
    // MARK: - Demo应用流程
    private var demoAppFlow: some View {
        NavigationStack {
            if demoManager.demoState == .birthdaySelection {
                DemoBirthdaySelectionView()
            } else {
                DemoMainPetView()
            }
        }
        .navigationViewStyle(StackNavigationViewStyle())
        .animation(.easeInOut(duration: 0.8), value: demoManager.demoState)
    }
}
