# LiveRoomDemo

## 项目简介

LiveRoomDemo 是一个基于 Swift + UIKit 构建的直播间客户端学习项目。

项目目标不是实现真实直播，而是通过搭建直播业务骨架，学习直播客户端架构设计，包括：

- MVVM
- 状态管理
- 事件驱动
- IM 消息流
- 长连接概念
- 拉流基础
- 弱网重连思维

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
- AppRouter
- RoomService
- ChatService
- LiveStreamService
- RoomListViewModel
- LiveRoomViewModel

---

## 工程结构

```text
LiveRoomDemo
├── App
├── Modules
│   ├── RoomList
│   └── LiveRoom
├── Services
├── Models
└── Common
```
