package com.example.notebook

import android.animation.ObjectAnimator
import android.content.Intent
import android.os.Bundle
import android.os.CountDownTimer
import android.os.Handler
import android.os.Looper
import android.util.Log
import android.view.View
import android.view.animation.DecelerateInterpolator
import android.widget.Button
import android.widget.TextView
import androidx.appcompat.app.AppCompatActivity
import androidx.cardview.widget.CardView
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.embedding.engine.FlutterEngineCache
import io.flutter.embedding.engine.dart.DartExecutor
import io.flutter.plugin.common.MethodChannel

/**
 * 优雅的分享接收 Activity
 * 纯原生 UI + Flutter 后台引擎
 * 
 * 特性：
 * - 完全透明，不离开原应用
 * - 精美的原生动画
 * - Flutter 后台处理数据
 * - 立即同步到后端
 */
class ShareActivity : AppCompatActivity() {

    companion object {
        private const val TAG = "ShareActivity"
        private const val CHANNEL = "com.example.notebook/share"
        private const val ENGINE_ID = "share_background_engine"
        private const val COUNTDOWN_DURATION = 3000L
    }

    private lateinit var cardView: CardView
    private lateinit var textPreview: TextView
    private lateinit var textCountdown: TextView
    private lateinit var btnDetail: Button
    
    private var flutterEngine: FlutterEngine? = null
    private var methodChannel: MethodChannel? = null
    private var countdownTimer: CountDownTimer? = null

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        setContentView(R.layout.activity_share_native)
        
        initViews()
        initFlutterBackgroundEngine()
        startEnterAnimation()
        
        // 延迟处理数据，等待 Flutter 引擎就绪
        Handler(Looper.getMainLooper()).postDelayed({
            handleShareIntent(intent)
        }, 300)
    }

    private fun initViews() {
        cardView = findViewById(R.id.cardSuccess)
        textPreview = findViewById(R.id.textPreview)
        textCountdown = findViewById(R.id.textCountdown)
        btnDetail = findViewById(R.id.btnDetail)
        
        btnDetail.setOnClickListener { onDetailClicked() }
    }

    private fun initFlutterBackgroundEngine() {
        // 尝试复用缓存的引擎
        flutterEngine = FlutterEngineCache.getInstance().get(ENGINE_ID)
        
        if (flutterEngine == null) {
            Log.d(TAG, "Creating background Flutter engine")
            flutterEngine = FlutterEngine(this).apply {
                dartExecutor.executeDartEntrypoint(
                    DartExecutor.DartEntrypoint.createDefault()
                )
            }
            FlutterEngineCache.getInstance().put(ENGINE_ID, flutterEngine)
        } else {
            Log.d(TAG, "Reusing cached Flutter engine")
        }
        
        // 创建 MethodChannel
        flutterEngine?.dartExecutor?.binaryMessenger?.let { messenger ->
            methodChannel = MethodChannel(messenger, CHANNEL)
        }
    }

    private fun handleShareIntent(intent: Intent?) {
        val action = intent?.action
        val type = intent?.type
        
        when {
            action == Intent.ACTION_SEND && type != null -> {
                when {
                    type.startsWith("text/") -> handleTextShare(intent)
                    type.startsWith("image/") -> handleImageShare(intent)
                    else -> handleTextShare(intent)
                }
            }
            action == Intent.ACTION_SEND_MULTIPLE && type != null -> {
                handleMultipleShare(intent)
            }
            else -> {
                Log.w(TAG, "Unsupported share type")
                finish()
            }
        }
    }

    private fun handleTextShare(intent: Intent) {
        val text = intent.getStringExtra(Intent.EXTRA_TEXT)
        if (text.isNullOrBlank()) return finish()
        
        val title = intent.getStringExtra(Intent.EXTRA_SUBJECT) ?: "分享内容"
        
        displayPreview(title)
        sendToFlutterBackground(title, text)
        startCountdown()
    }

    private fun handleImageShare(intent: Intent) {
        val uri = intent.getParcelableExtra<android.net.Uri>(Intent.EXTRA_STREAM)
        if (uri == null) return finish()
        
        val title = "分享图片"
        
        displayPreview(title)
        sendToFlutterBackground(title, uri.toString())
        startCountdown()
    }

    private fun handleMultipleShare(intent: Intent) {
        val uris = intent.getParcelableArrayListExtra<android.net.Uri>(Intent.EXTRA_STREAM)
        if (uris.isNullOrEmpty()) return finish()
        
        val title = "分享 ${uris.size} 项"
        val content = uris.joinToString("\n") { it.toString() }
        
        displayPreview(title)
        sendToFlutterBackground(title, content)
        startCountdown()
    }

    private fun displayPreview(title: String) {
        textPreview.text = title
    }

    private fun sendToFlutterBackground(title: String, content: String) {
        val data = mapOf(
            "title" to title,
            "content" to content,
            "timestamp" to System.currentTimeMillis()
        )
        
        methodChannel?.invokeMethod("saveAndSync", data, object : MethodChannel.Result {
            override fun success(result: Any?) {
                Log.d(TAG, "✅ Data saved and synced")
            }

            override fun error(code: String, message: String?, details: Any?) {
                Log.e(TAG, "❌ Error: $message")
            }

            override fun notImplemented() {
                Log.w(TAG, "Method not implemented")
            }
        })
    }

    private fun startEnterAnimation() {
        // 初始状态
        cardView.apply {
            alpha = 0f
            translationY = 200f
            scaleX = 0.85f
            scaleY = 0.85f
        }
        
        // 组合动画
        cardView.animate()
            .alpha(1f)
            .translationY(0f)
            .scaleX(1f)
            .scaleY(1f)
            .setDuration(500)
            .setInterpolator(DecelerateInterpolator(1.5f))
            .start()
    }

    private fun startCountdown() {
        countdownTimer = object : CountDownTimer(COUNTDOWN_DURATION, 1000) {
            override fun onTick(millisUntilFinished: Long) {
                val seconds = (millisUntilFinished / 1000).toInt()
                textCountdown.text = seconds.toString()
            }

            override fun onFinish() {
                closeWithAnimation()
            }
        }.start()
    }

    private fun onDetailClicked() {
        countdownTimer?.cancel()
        
        // TODO: 显示编辑对话框或 Flutter 页面
        // 这里可以选择：
        // 1. 原生 Dialog 编辑
        // 2. 启动 Flutter 编辑页面
        
        Log.d(TAG, "Detail clicked")
        
        // 暂时直接关闭
        closeWithAnimation()
    }

    private fun closeWithAnimation() {
        cardView.animate()
            .alpha(0f)
            .translationY(200f)
            .scaleX(0.85f)
            .scaleY(0.85f)
            .setDuration(300)
            .setInterpolator(DecelerateInterpolator())
            .withEndAction { finish() }
            .start()
    }

    override fun onDestroy() {
        super.onDestroy()
        countdownTimer?.cancel()
        // 不销毁 Flutter 引擎，保持缓存
    }
}
