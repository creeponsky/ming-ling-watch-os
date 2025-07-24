# 健康助手 Watch App

一个基于五行理论的 Apple Watch 健康监测应用，根据用户的生日计算五行属性，提供个性化的健康建议和提醒。

## 功能特性

### 核心功能
- **五行属性计算**: 通过生日计算用户的五行属性（金、木、水、火、土）
- **个性化健康建议**: 根据五行属性提供针对性的健康建议
- **实时健康监测**: 监测心率、HRV、步数、睡眠等健康数据
- **智能提醒系统**: 基于触发条件发送个性化健康提醒
- **环境感知**: 监测环境光和位置信息，提供晒太阳建议

### 健康监测项目
1. **晒太阳提醒**: 基于UV指数、时间和环境光
2. **压力监测**: 基于HRV数据
3. **久坐提醒**: 基于步数监测
4. **运动检测**: 基于心率变化
5. **睡眠监测**: 基于睡眠时长

## 项目结构

```
ming-ling-watch-os Watch App/
├── Models/
│   ├── UserProfile.swift          # 用户档案模型
│   └── HealthReminders.swift      # 健康提醒模型
├── Services/
│   ├── BaziAPIService.swift       # 八字API服务
│   ├── UserProfileManager.swift   # 用户档案管理
│   ├── HealthMonitoringService.swift # 健康监测服务
│   ├── NotificationManager.swift  # 通知管理
│   └── EnvironmentSensorManager.swift # 环境传感器管理
├── Views/
│   ├── BirthdaySelectionView.swift # 生日选择界面
│   ├── NewMainDashboardView.swift # 主界面
│   └── SettingsView.swift         # 设置界面
└── Managers/
    ├── HealthKitManager.swift     # HealthKit管理
    ├── LocationManager.swift      # 位置管理
    └── MotionManager.swift        # 运动管理
```

## 技术架构

### 数据层
- **UserProfile**: 用户档案数据模型
- **HealthReminders**: 健康提醒配置模型
- **FiveElements**: 五行属性模型

### 服务层
- **BaziAPIService**: 调用八字API获取五行属性
- **HealthMonitoringService**: 后台健康监测服务
- **NotificationManager**: 本地通知管理
- **EnvironmentSensorManager**: 环境传感器管理

### 界面层
- **BirthdaySelectionView**: 首次使用时的生日选择
- **NewMainDashboardView**: 主界面，显示健康卡片
- **SettingsView**: 设置和数据概览

## 使用流程

1. **首次启动**: 用户选择生日，系统调用API计算五行属性
2. **主界面**: 显示个性化问候语和五个健康监测卡片
3. **后台监测**: 持续监测健康数据，触发条件时发送通知
4. **设置界面**: 查看数据概览和修改设置

## 五行理论应用

### 五行属性对应
- **金**: 主肺气，喜清润
- **木**: 主肝气，喜舒展  
- **水**: 主肾气，喜温润
- **火**: 主心气，喜清凉
- **土**: 主脾气，喜温和

### 个性化建议
每个健康提醒都根据用户的五行属性提供不同的建议内容，确保建议的针对性和有效性。

## 开发环境

- **平台**: watchOS 9.0+
- **语言**: Swift 5.0+
- **框架**: SwiftUI, HealthKit, CoreLocation
- **API**: 八字测算API (https://doc.yuanfenju.com/bazi/cesuan.html)

## 注意事项

1. 需要用户授权HealthKit、位置和通知权限
2. 八字API需要网络连接
3. 环境传感器数据在模拟器中为模拟数据
4. 后台监测服务需要设备支持

## 未来扩展

- 支持更多健康指标监测
- 增加数据分析和趋势图表
- 支持自定义提醒规则
- 增加社交分享功能 