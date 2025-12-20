# PocketMind 局域网同步模块 (LanSync)

本模块负责 PocketMind 在局域网（LAN）环境下的多端数据同步。它采用了去中心化的点对点（P2P）架构，支持自动设备发现、双向实时同步以及复杂的网络环境自适应。

## 核心架构

同步流程分为三个阶段：**发现 (Discovery)** -> **连接 (Connection)** -> **同步 (Synchronization)**。

### 1. 设备发现 (UDP Discovery)
*   **机制**：基于 UDP 广播。
*   **端口**：`54323`
*   **逻辑**：每个运行中的设备会定期向局域网发送宣告包（Announce），包含自己的设备 ID、名称和 WebSocket 端口。其他设备收到后会将其加入对等节点（Peer）列表。

### 2. 实时通信 (WebSocket Bi-directional)
*   **机制**：基于长连接的 WebSocket。
*   **端口**：默认 `54322`
*   **双工模式**：
    *   **服务端 (Server)**：每个设备都运行一个 WebSocket 服务端，准备接收连接。
    *   **客户端 (Client)**：设备根据策略主动连接其他设备。
    *   一旦连接建立，双方均可作为发送方或接收方，实现数据变更的实时推送。

### 3. 连接策略与容错
*   **确定性发起 (Deterministic Initiation)**：为了避免重复连接，系统会比较双方的 Device ID。ID 较小的一方作为“发起者”主动建立连接。
*   **出站回退 (Outbound Fallback)**：如果发起者因为防火墙或系统限制无法连接，另一方在等待 4 秒后会尝试反向连接，确保链路打通。
*   **代理绕过 (Proxy Bypass)**：自动识别并绕过系统 HTTP 代理（如 Clash），确保局域网流量不被错误转发。

### 4. 数据同步逻辑
*   **增量同步**：利用时间戳记录每个 Peer 的最后同步状态，仅传输变更数据。
*   **冲突解决**：基于 `updatedAt` 时间戳和 `isDeleted` 标记，由 `SyncManager` 确保多端数据的最终一致性。

## 目录结构

```
lib/lan_sync/
├── lan_sync_service.dart    # Riverpod Provider，对外暴露的统一接口
├── lan_sync_engine.dart     # 同步流程协调引擎
├── sync_manager.dart        # 核心数据同步与冲突处理逻辑
├── model/                   # 数据模型 (DeviceInfo, SyncLog, etc.)
├── realtime/                # WebSocket 服务端与客户端实现
├── udp/                     # UDP 发现协议实现
├── mapper/                  # 数据库模型与同步 JSON 的映射
├── repository/              # 同步状态持久化
└── util/                    # 网络工具类 (IP 获取、代理绕过)
```

## 开发注意事项

1.  **端口占用**：确保 `54322` 和 `54323` 端口未被其他应用占用。
2.  **权限**：在 Android 上需要 `INTERNET` 和 `ACCESS_WIFI_STATE` 权限。
3.  **调试**：可以通过 `PMlog` 查看以 `[UdpLanDiscovery]` 或 `[SyncWebSocket]` 开头的日志来追踪同步过程。
