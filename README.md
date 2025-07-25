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
│   ├── SystemNotificationManager.swift # 系统通知管理
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
- **BaziAPIService**: 八字API服务，获取五行属性
- **UserProfileManager**: 用户档案管理，包括亲密值系统
- **HealthMonitoringService**: 健康监测服务，处理各种健康数据
- **SystemNotificationManager**: 系统通知管理，支持建议和完成通知
- **EnvironmentSensorManager**: 环境传感器管理，监测光线和位置

### 管理层
- **HealthKitManager**: HealthKit数据管理
- **LocationManager**: 位置服务管理
- **MotionManager**: 运动数据管理

### 视图层
- **BirthdaySelectionView**: 生日选择界面
- **NewMainDashboardView**: 主仪表板界面
- **SettingsView**: 设置界面

## 通知系统

### 通知类型
1. **建议通知**: 当检测到健康问题时发送个性化建议
2. **完成通知**: 当用户完成建议后发送鼓励和亲密度奖励

### 通知特性
- 支持GIF动画显示
- 自动处理亲密度奖励
- 支持延时发送
- 支持随机建议/完成通知
- 自定义Long Look界面

## 亲密值系统

### 等级划分
- **等级1（0-49分）**: 陌生
- **等级2（50-79分）**: 友好
- **等级3（80-100分）**: 亲密

### 获取方式
- 完成健康建议：+20点
- 改善压力状态：+20点
- 开始活动：+20点

## 开发环境

- **平台**: watchOS 10.0+
- **语言**: Swift 5.9
- **框架**: SwiftUI, HealthKit, UserNotifications
- **设备**: Apple Watch Series 4+

## 安装和运行

1. 克隆项目到本地
2. 使用Xcode打开项目
3. 选择Apple Watch模拟器或真机
4. 运行项目

## 注意事项

- 需要HealthKit权限来访问健康数据
- 需要通知权限来发送提醒
- 需要位置权限来提供环境相关建议 