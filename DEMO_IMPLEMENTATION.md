# Demo模式实现文档

## 概述

Demo模式是一个完整的功能演示流程，创建了一个隔离的环境来展示应用的核心功能，类似于苹果展示台的App功能。

## 实现的文件

### 1. 核心管理器
- `ming-ling-watch-os Watch App/Services/DemoManager.swift` - Demo状态管理和数据隔离

### 2. 视图组件
- `ming-ling-watch-os Watch App/Views/DemoBirthdaySelectionView.swift` - Demo专用生日选择视图
- `ming-ling-watch-os Watch App/Views/DemoMainPetView.swift` - Demo专用主宠物视图

### 3. 修改的现有文件
- `ming-ling-watch-os Watch App/Views/HealthDashboardPageView.swift` - 添加了Demo按钮
- `ming-ling-watch-os Watch App/ming_ling_watch_osApp.swift` - 集成Demo流程

## 功能特性

### 1. Demo状态管理
- **状态枚举**: 定义了8个Demo状态，从初始化到完成
- **数据隔离**: 使用独立的DemoUserProfile模型，与正常用户数据完全隔离
- **持久化**: Demo状态在应用重启后保持，直到手动重置

### 2. Demo流程

#### 阶段1: 生日选择 (`birthdaySelection`)
- 简化的性别和生日选择界面
- 木属性主题设计
- 模拟API调用（1.5秒延迟）
- 固定返回木属性结果

#### 阶段2: 主页面 (`mainPage`)
- 显示通知栏："Hello，我是木木；今天是你坚持健康的1天"
- 2级亲密度的木属性宠物显示
- 上滑手势替代左滑，显示健康检测面板
- 淡入淡出动画效果

#### 阶段3: 久坐触发 (`sedentaryTrigger`)
- 点击健康检测按钮后10秒触发
- 自动进入步数检测阶段

#### 阶段4: 步数检测 (`stepDetection`)
- 发送久坐提醒通知
- 30秒后自动完成步数目标（模拟走了20步）

#### 阶段5: 亲密度升级 (`intimacyUpgrade`)
- 显示完成通知
- 播放升级动画（使用happy文件夹GIF）
- 亲密度从2级升级到3级
- 3秒动画播放时间

#### 阶段6: 语音交互 (`voiceInteraction`)
- 3级宠物可点击触发戳一戳动画
- 左下角麦克风按钮
- 按住开始录音，2秒后自动停止
- 模拟播放回复音频
- 显示退出按钮

#### 阶段7: 完成 (`completed`)
- Demo流程结束
- 可以重置或退出Demo

### 3. 用户界面增强

#### HealthDashboardPageView新增功能
- Demo状态显示区域
- Demo进行中时显示当前阶段
- 开始/重置Demo按钮
- 退出Demo按钮（在可退出阶段显示）

#### 交互设计
- 所有Demo界面都使用木属性主题（绿色）
- 流畅的过渡动画
- 直观的状态反馈
- 无缝的手势交互

### 4. 技术实现

#### 数据隔离
```swift
struct DemoUserProfile: Codable {
    var birthday: Date?
    var sex: Int = 0
    var intimacyLevel: Int = 50  // 固定2级开始
    var stepCount: Int = 0
    var isWoodElement: Bool = true  // 固定木属性
    
    var intimacyGrade: Int {
        // 自动计算等级
    }
}
```

#### 状态管理
```swift
enum DemoState: String, CaseIterable, Codable {
    case inactive, birthdaySelection, mainPage, 
         sedentaryTrigger, stepDetection, 
         intimacyUpgrade, voiceInteraction, completed
}
```

#### 持久化存储
- 使用UserDefaults存储Demo状态
- 独立的存储键值避免与正常数据冲突
- 支持应用重启后恢复Demo状态

## 使用方式

### 1. 启动Demo
1. 在健康数据页面点击"开始Demo"按钮
2. 系统自动切换到Demo模式
3. 显示生日选择界面

### 2. Demo流程体验
1. 选择性别和生日
2. 进入主页面，查看通知栏
3. 上滑显示健康检测面板
4. 点击"开始久坐检测"
5. 等待通知和自动完成
6. 观看亲密度升级动画
7. 体验语音交互功能

### 3. 退出Demo
- 在语音交互阶段或完成后点击"退出"按钮
- 或在健康页面重置Demo

## 技术亮点

### 1. 完全隔离的环境
- Demo数据与真实用户数据完全分离
- 独立的状态管理系统
- 不影响正常应用功能

### 2. 状态恢复机制
- 支持中途退出应用后继续Demo
- 持久化存储确保状态不丢失
- 智能的状态同步

### 3. 用户体验优化
- 流畅的动画过渡
- 直观的状态反馈
- 简化的操作流程

### 4. 可扩展性
- 易于添加新的Demo阶段
- 灵活的状态管理架构
- 组件化的视图设计

## 注意事项

### 1. 通知权限
- Demo需要通知权限来发送提醒
- 确保在应用启动时请求权限

### 2. GIF资源
- 需要确保GIF文件正确放置在Bundle中
- 路径格式：`GIFs/mumu/happy/[1-3].gif`

### 3. 性能考虑
- Demo模式下禁用了真实的健康监测
- 使用模拟数据减少系统资源消耗

## 后续扩展

### 1. 音频功能
- 集成真实的语音识别和合成
- 添加预录的宠物回复音频

### 2. 更多动画
- 专门的Demo升级动画
- 更丰富的交互反馈动画

### 3. 自定义Demo流程
- 允许用户选择不同的Demo路径
- 添加更多的健康监测演示

---

这个Demo模式实现了一个完整的功能演示流程，为用户提供了深度体验应用核心功能的机会，同时保持了与正常使用模式的完全隔离。