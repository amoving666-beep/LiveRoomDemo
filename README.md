# LiveRoomDemo

## 项目简介

LiveRoomDemo 是一个基于 Swift + UIKit 构建的直播间客户端学习项目。

项目目标不是实现真实直播功能，而是通过搭建直播业务骨架，学习和实践直播客户端常见架构设计，包括：

- MVVM
- 事件驱动
- 状态管理
- IM 消息流
- 长连接概念
- 拉流 / 推流基础
- 弱网重连思维
- 直播间客户端架构设计

---

## 技术栈

- Swift
- UIKit
- SnapKit
- MVVM
- Protocol Oriented Programming

---

## 当前进度

### Phase1：直播业务骨架（已完成）

已实现：

- 房间列表
- 点击进入直播间
- 主播信息区域
- 模拟播放器区域
- 聊天消息列表
- 输入框发送消息
- AppRouter 页面路由
- RoomService
- ChatService
- LiveStreamService
- RoomListViewModel
- LiveRoomViewModel

---

## 工程结构

text LiveRoomDemo ├── App │   ├── SceneDelegate.swift │   └── AppRouter.swift │ ├── Modules │   ├── RoomList │   │   ├── View │   │   ├── ViewModel │   │   └── Cell │   │ │   └── LiveRoom │       ├── View │       └── ViewModel │ ├── Services │   ├── Protocols │   └── Mock │ ├── Models │ └── Common 

---

## 核心数据流

### 房间列表

text RoomListViewController         ↓ RoomListViewModel         ↓ RoomServiceProtocol         ↓ MockRoomService 

### 聊天消息

text ChatInputView         ↓ LiveRoomViewController         ↓ LiveRoomViewModel         ↓ ChatServiceProtocol         ↓ MockChatService         ↓ ChatMessage 

### 模拟直播流

text LiveRoomViewController         ↓ LiveRoomViewModel         ↓ LiveStreamServiceProtocol         ↓ MockLiveStreamService         ↓ LiveStreamState 

---

## 当前页面结构

text LiveRoomViewController  ├── LiveRoomHeaderView ├── LivePlayerPlaceholderView ├── UITableView └── ChatInputView 

---

## 后续规划

### Phase2

直播间状态机

计划实现：

- Idle
- Connecting
- Playing
- Reconnecting
- Failed

学习目标：

- 状态机设计
- 状态驱动 UI

### Phase3

聊天室消息流

计划实现：

- 模拟长连接
- 系统消息
- 用户消息
- 进入房间消息
- 离开房间消息

学习目标：

- 事件驱动架构
- IM 消息流设计

### Phase4

弱网重连

计划实现：

- 自动重连
- 重连状态展示
- 重连次数控制

学习目标：

- 长连接稳定性设计
- 弱网恢复策略
:::  然后提交： bash
git add .
git commit -m "补充 Phase1 README"
git push
```

这样你的 LiveRoomDemo 就已经具备一个完整项目仓库该有的样子了。