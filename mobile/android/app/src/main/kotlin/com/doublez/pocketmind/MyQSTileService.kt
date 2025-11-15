package com.doublez.pocketmind

import android.app.PendingIntent
import android.content.Intent
import android.graphics.drawable.Icon
import android.os.Build
import android.service.quicksettings.Tile
import android.service.quicksettings.TileService
import androidx.annotation.RequiresApi

@RequiresApi(Build.VERSION_CODES.N) // TileService 需要 Android 7.0 (API 24)
class MyQSTileService : TileService() {

    // 当用户将磁贴添加到面板时调用
    override fun onTileAdded() {
        super.onTileAdded()
        // 可以在这里做一些初始化
    }

    // 当用户点击磁贴时调用 (最核心的方法)
    override fun onClick() {
        super.onClick()

        // 1. 创建一个 Intent 启动你的透明 ShareActivity
        val intent = Intent(this, ShareActivity::class.java).apply {
            // **关键：** 添加一个自定义 Flag，告诉 ShareActivity 它是来读剪贴板的
            putExtra("action", "read_clipboard")

            // 从 Service 启动 Activity 必须加这个 Flag
            addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
        }

        // 2. 启动 Activity 并关闭下拉面板
        //    (注意：Android 10+ 对后台启动 Activity 有限制，但 QSTileService 是系统UI触发的，有权限)
        try {
            // 使用 startActivityAndCollapse() 可以启动 Activity 并自动收起下拉菜单
            // 2. [关键修改] 根据 Android 版本选择不同的启动方法
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.UPSIDE_DOWN_CAKE) {
                // === 适用于 Android 14 (API 34) 及以上 ===

                // A. 将 Intent 包装成 PendingIntent
                val pendingIntent = PendingIntent.getActivity(
                    this,
                    0, // requestCode, 0 即可
                    intent,
                    PendingIntent.FLAG_IMMUTABLE or PendingIntent.FLAG_UPDATE_CURRENT
                )

                // B. 调用新的 API
                startActivityAndCollapse(pendingIntent)

            } else {
                // === 适用于 Android 7 (API 24) 到 Android 13 (API 33) ===

                // A. 使用旧的 API，并压制“弃用”警告
                @Suppress("startActivityAndCollapseDeprecated")
                startActivityAndCollapse(intent)
            }
        } catch (e: Exception) {
            // 处理异常，例如可能没有悬浮窗权限等
        }
    }

    // 当磁贴变为“可见”时调用（每次下拉都会调用）
    override fun onStartListening() {
        super.onStartListening()
        val tile = qsTile ?: return

        // 3. 更新磁贴的状态
        tile.state = Tile.STATE_ACTIVE // 保持激活状态，表示可点击
        tile.label = "PocketMind" // 设置磁贴的标签
         tile.icon = Icon.createWithResource(this, R.drawable.ic_qs_tile_icon) // 设置图标
        tile.updateTile()
    }

    // 当磁贴变为“不可见”时调用
    override fun onStopListening() {
        super.onStopListening()
    }
}