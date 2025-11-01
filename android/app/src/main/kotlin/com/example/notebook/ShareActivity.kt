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
    
    private lateinit var editContainer: View // 编辑界面的根布局
    private lateinit var cardEdit: CardView
    private lateinit var editTextContent: TextView // 编辑框
    private lateinit var btnDone: Button // "Done" 按钮

    // 用于存储原始分享数据
    private var sharedTitle: String? = null
    private var sharedContent: String? = null

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

        editContainer = findViewById(R.id.editContainer)
        cardEdit = findViewById(R.id.cardEdit)
        editTextContent = findViewById(R.id.editTextContent)
        btnDone = findViewById(R.id.btnDone)
        
        btnDetail.setOnClickListener { onDetailClicked() }
        btnDone.setOnClickListener { onDoneClicked() }
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

        this.sharedTitle = title
        this.sharedContent = text

        displayPreview(title)
        sendToFlutterBackground(title, text)
        startCountdown()
    }

    private fun handleImageShare(intent: Intent) {
        val uri = intent.getParcelableExtra<android.net.Uri>(Intent.EXTRA_STREAM)
        if (uri == null) return finish()
        
        val title = "分享图片"

        this.sharedTitle = title
        this.sharedContent = uri.toString()

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
        
        // 显示编辑对话框
        // 1. 把分享数据显示到编辑框
        val fullText = "${sharedTitle ?: ""}\n\n${sharedContent ?: ""}"
        editTextContent.text = fullText.trim()

        Log.d(TAG, "开始切换detail")
        // 2. 执行切换动画
        // 淡出 "成功" 卡片
        cardView.animate()
            .alpha(0f)
            .scaleX(0.9f)
            .scaleY(0.9f)
            .setDuration(200)
            .setInterpolator(DecelerateInterpolator())
            .withEndAction {
                cardView.visibility = View.GONE // 隐藏成功卡片

                // 淡入 "编辑" 界面
                editContainer.visibility = View.VISIBLE
                editContainer.alpha = 0f
                editContainer.animate()
                    .alpha(1f)
                    .setDuration(200)
                    .start()
            }
            .start()
    }

    /**
     * 当点击 "Done" 按钮时调用
     */
    private fun onDoneClicked() {
        // 1. 获取编辑后的新内容
        val newContent = editTextContent.text.toString()

        // 2. (可选) 你可以把新旧内容对比
        // ...

        // 3. 把更新后的数据发送给 Flutter
        //    我们复用 sendToFlutterBackground
        //    或者调用一个新方法，比如 updateToFlutter

        Log.d(TAG, "发送更新后的数据到 Flutter")
        // 注意：我们只发送了更新后的 content。
        // 你也可以把 title 和 content 分开，在布局中用两个 EditText
        sendToFlutterBackground(sharedTitle ?: "已编辑", newContent)

        // 4. 执行关闭动画并结束 Activity
        //    我们为 editContainer 创建一个新的关闭动画
        editContainer.animate()
            .alpha(0f)
            .setDuration(300)
            .setInterpolator(DecelerateInterpolator())
            .withEndAction {
                finish() // 动画结束时, 关闭 Activity
            }
            .start()
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
