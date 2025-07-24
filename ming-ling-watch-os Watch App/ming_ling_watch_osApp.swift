//
//  ming_ling_watch_osApp.swift
//  ming-ling-watch-os Watch App
//
//  Created by CreepOnSky on 2025/7/24.
//

import SwiftUI

@main
struct ming_ling_watch_os_Watch_AppApp: App {
    @StateObject private var profileManager = UserProfileManager.shared
    @StateObject private var monitoringService = HealthMonitoringService.shared
    
    var body: some Scene {
        WindowGroup {
            if profileManager.isProfileComplete {
                // 用户已完成档案设置，显示主界面
                NavigationView {
                    NewMainDashboardView()
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
    }
}
