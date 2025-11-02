package com.example.notebook

import android.content.Context
import android.content.Intent
import android.os.Build
import android.os.Bundle
import android.util.Log
import io.flutter.FlutterInjector
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.embedding.engine.FlutterEngineCache
import io.flutter.embedding.engine.dart.DartExecutor
import io.flutter.plugin.common.MethodChannel

/**
 * 透明的分享接收 Activity (单一 FlutterActivity 架构)
 * 
 * 职责：
 * 1. 作为 Manifest.xml 中的分享入口 (ACTION_SEND)
 * 2. 使用 singleTask 模式，支持冷启动和热启动
 * 3. 预热并缓存 Flutter 引擎（仅在冷启动时）
 * 4. 通过 MethodChannel 通知 Dart 端显示新的分享 UI
 * 
 * 架构说明：
 * - 冷启动：onCreate() -> 初始化引擎 -> 调用 handleShare()
 * - 热启动：onNewIntent() -> 直接调用 handleShare()
 */
class ShareActivity : FlutterActivity() {

    companion object {
        private const val TAG = "ShareActivity"
        private const val CHANNEL = "com.example.notebook/share"
        private const val ENGINE_ID = "share_engine"
    }

    private var methodChannel: MethodChannel? = null
    private var pendingShareData: ShareData? = null // 保存待处理的分享数据
    private var isEngineReady = false // 引擎是否已准备好

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        Log.d(TAG, "ShareActivity onCreate - 冷启动")
        
        // 不立即处理分享，而是保存数据，等待引擎准备好
        val shareData = parseShareIntent(intent)
        if (shareData != null) {
            pendingShareData = shareData
            Log.d(TAG, "保存待处理的分享数据: title:${shareData.title},content:${shareData.content}")
            
            // 如果引擎已经准备好（热启动），立即处理
            // onCreate 在 provideFlutterEngine 之后执行，所以此时 isEngineReady 可能已经为 true
            if (isEngineReady && methodChannel != null) {
                Log.d(TAG, "onCreate: 引擎已就绪（热启动），立即处理分享")
                notifyDartToShowShare(shareData)
                pendingShareData = null
            }
        } else {
            Log.w(TAG, "无法解析的分享数据")
            finish()
        }
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        Log.d(TAG, "ShareActivity onNewIntent - 热启动")
        
        // 解析并保存分享数据
        val shareData = parseShareIntent(intent)
        if (shareData != null) {
            Log.d(TAG, "保存待处理的分享数据: ${shareData.title}")
            pendingShareData = shareData
            
            // 如果引擎已经准备好，立即处理
            if (isEngineReady && methodChannel != null) {
                Log.d(TAG, "引擎已就绪，立即处理分享")
                notifyDartToShowShare(shareData)
                pendingShareData = null
            } else {
                Log.d(TAG, "等待引擎准备就绪")
            }
        } else {
            Log.w(TAG, "无法解析的分享数据，关闭 Activity")
            finish()
        }
    }

    /**
     * 提供缓存的 Flutter 引擎
     * 仅在冷启动时创建引擎，热启动时直接复用
     */
    override fun provideFlutterEngine(context: Context): FlutterEngine? {
        var engine = FlutterEngineCache.getInstance().get(ENGINE_ID)
        val isHotStart = engine != null // 引擎存在说明是热启动
        
        if (engine == null) {
            Log.d(TAG, "创建新的 Flutter 引擎 (main_share)")
            

            val flutterLoader = FlutterInjector.instance().flutterLoader()
            // 确保 FlutterLoader 已初始化
            if (!flutterLoader.initialized()) {
                Log.d(TAG, "初始化 FlutterLoader")
                flutterLoader.startInitialization(applicationContext)
                flutterLoader.ensureInitializationComplete(context, null)
            }
            
            val appBundlePath = flutterLoader.findAppBundlePath()
            // flutterLoader 以及初始化了的话 appBundlePath 不会为空
            engine = FlutterEngine(this).apply {
                dartExecutor.executeDartEntrypoint(
                    DartExecutor.DartEntrypoint(
                        appBundlePath,
                        // 启动flutter应用的第二个入口
                        "package:notebook/main_share.dart",
                        "main_share"
                    )
                )
            }
            
            // 缓存引擎供后续使用
            FlutterEngineCache.getInstance().put(ENGINE_ID, engine)
            
            Log.d(TAG, "Flutter 引擎已创建并缓存")
        } else {
            Log.d(TAG, "复用缓存的 Flutter 引擎（热启动）")
            // 热启动时，引擎已经存在，Dart 端也已经准备好了
            isEngineReady = true
        }
        
        // 关键无论冷启动还是热启动，都重新设置 MethodChannel
        // 因为 Activity 重新创建后，methodChannel 实例变量会被重置为 null
        setupMethodChannel(engine)
        
        return engine
    }

    /**
     * 设置 MethodChannel
     */
    private fun setupMethodChannel(engine: FlutterEngine) {
        engine.dartExecutor.binaryMessenger.let { messenger ->
            methodChannel = MethodChannel(messenger, CHANNEL)
            
            // 设置方法调用处理器，监听 Dart 端的"准备好"信号
            methodChannel?.setMethodCallHandler { call, result ->
                when (call.method) {
                    "engineReady" -> {
                        Log.d(TAG, "收到 Dart 端准备就绪信号")
                        isEngineReady = true
                        result.success(null)
                        
                        // 引擎准备好后，处理待处理的分享数据
                        pendingShareData?.let { data ->
                            Log.d(TAG, "处理待处理的分享数据: ${data.title}")
                            notifyDartToShowShare(data)
                            pendingShareData = null // 清除已处理的数据
                        }
                    }
                    else -> result.notImplemented()
                }
            }
            
            Log.d(TAG, "MethodChannel 已重新设置，isEngineReady=$isEngineReady")
            
            // 如果引擎已经准备好（热启动场景），且有待处理的数据，立即处理
            if (isEngineReady) {
                pendingShareData?.let { data ->
                    Log.d(TAG, "热启动：引擎已准备好，立即处理分享: ${data.title}")
                    notifyDartToShowShare(data)
                    pendingShareData = null
                }
            }
            
            // 注册日志通道（可选）
            val loggerChannel = MethodChannel(messenger, "com.example.notebook/logger")
            loggerChannel.setMethodCallHandler { call, result ->
                if (call.method == "log") {
                    Log.d(call.argument("tag") ?: "FlutterLog", call.argument("message") ?: "")
                    result.success(null)
                } else {
                    result.notImplemented()
                }
            }
        }
    }

    /**
     * 解析分享 Intent 并返回数据
     */
    private fun parseShareIntent(intent: Intent?): ShareData? {
        val action = intent?.action
        val type = intent?.type

        Log.d(TAG, "解析 Intent: action=$action, type=$type")

        when {
            action == Intent.ACTION_SEND && type != null -> {
                return when {
                    type.startsWith("text/") -> {
                        val text = intent.getStringExtra(Intent.EXTRA_TEXT) ?: return null
                        val title = intent.getStringExtra(Intent.EXTRA_SUBJECT) ?: "分享内容"
                        ShareData(title, text)
                    }
                    type.startsWith("image/") -> {
                        val uri: android.net.Uri? = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
                            // Android 13 (API 33) 及以上使用新方法
                            intent.getParcelableExtra(Intent.EXTRA_STREAM, android.net.Uri::class.java)
                        } else {
                            // Android 13 以下使用旧方法
                            @Suppress("DEPRECATION")
                            intent.getParcelableExtra(Intent.EXTRA_STREAM)
                        }
                        if (uri == null) return null
                        ShareData(title = "分享图片", content = uri.toString())
                    }
                    else -> {
                        val text = intent.getStringExtra(Intent.EXTRA_TEXT) ?: return null
                        val title = intent.getStringExtra(Intent.EXTRA_SUBJECT) ?: "分享内容"
                        ShareData(title, text)
                    }
                }
            }
            action == Intent.ACTION_SEND_MULTIPLE && type != null -> {
                val uris = intent.getParcelableArrayListExtra<android.net.Uri>(Intent.EXTRA_STREAM) ?: return null
                if (uris.isEmpty()) return null
                val title = "分享 ${uris.size} 项"
                val content = uris.joinToString("\n") { it.toString() }
                return ShareData(title, content)
            }
            else -> return null
        }
    }

    /**
     * 通过 MethodChannel 通知 Dart 端显示分享 UI
     */
    private fun notifyDartToShowShare(data: ShareData) {
        // 确保 MethodChannel 已初始化
        if (methodChannel == null) {
            flutterEngine?.let { setupMethodChannel(it) }
        }
        
        val payload = mapOf(
            "title" to data.title,
            "content" to data.content,
            "timestamp" to System.currentTimeMillis()
        )

        Log.d(TAG, "发送 showShare 到 Dart: ${data.title}")
        
        methodChannel?.invokeMethod("showShare", payload, object : MethodChannel.Result {
            override fun success(result: Any?) {
                Log.d(TAG, "✅ Dart 已接收 showShare")
            }
            override fun error(errorCode: String, errorMessage: String?, errorDetails: Any?) {
                Log.e(TAG, "❌ Dart 处理失败: $errorMessage")
            }
            override fun notImplemented() {
                Log.w(TAG, "❌ showShare 方法未实现")
            }
        })
    }

    /**
     * 用于封装分享数据的简单类
     */
    data class ShareData(val title: String, val content: String)

    override fun onDestroy() {
        super.onDestroy()
        Log.d(TAG, "ShareActivity onDestroy")
        // 注意：引擎不销毁，保持缓存供下次使用
    }
}