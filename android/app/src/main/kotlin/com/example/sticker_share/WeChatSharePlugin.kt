package com.example.sticker_share

import android.content.Context
import android.content.Intent
import android.net.Uri
import androidx.core.content.FileProvider
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import java.io.File
import java.io.FileOutputStream

class WeChatSharePlugin : FlutterPlugin, MethodChannel.MethodCallHandler {
    private lateinit var channel: MethodChannel
    private lateinit var context: Context

    override fun onAttachedToEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        context = binding.applicationContext
        channel = MethodChannel(binding.binaryMessenger, "com.stickershare/wechat_share")
        channel.setMethodCallHandler(this)
    }

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "shareGif" -> shareGif(call, result)
            "isWeChatInstalled" -> result.success(isWeChatInstalled())
            "getWeChatVersion" -> result.success(getWeChatVersion())
            else -> result.notImplemented()
        }
    }

    private fun shareGif(call: MethodCall, result: MethodChannel.Result) {
        val gifData = call.argument<ByteArray>("gifData")
        val appId = call.argument<String>("appId")
        val scene = call.argument<String>("scene") ?: "session"

        if (gifData == null || appId == null) {
            result.error("INVALID_ARGS", "Missing required arguments", null)
            return
        }

        try {
            // 保存GIF到缓存目录
            val gifUri = saveGifToCache(gifData)

            // 创建分享Intent
            val intent = Intent(Intent.ACTION_SEND).apply {
                type = "image/gif"
                putExtra(Intent.EXTRA_STREAM, gifUri)
                setPackage("com.tencent.mm") // 微信包名
                addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION)
            }

            // 检查微信是否可用
            if (context.packageManager.resolveActivity(intent, 0) != null) {
                context.startActivity(intent)
                result.success(true)
            } else {
                result.error("WECHAT_NOT_INSTALLED", "WeChat is not installed", null)
            }
        } catch (e: Exception) {
            result.error("SHARE_ERROR", "Failed to share: ${e.message}", null)
        }
    }

    private fun saveGifToCache(data: ByteArray): Uri {
        // 创建缓存文件
        val cacheDir = File(context.cacheDir, "shared_gifs")
        if (!cacheDir.exists()) {
            cacheDir.mkdirs()
        }

        val gifFile = File(cacheDir, "share_${System.currentTimeMillis()}.gif")
        FileOutputStream(gifFile).use { fos ->
            fos.write(data)
        }

        // 使用FileProvider获取Uri
        return FileProvider.getUriForFile(
            context,
            "${context.packageName}.fileprovider",
            gifFile
        )
    }

    private fun isWeChatInstalled(): Boolean {
        return try {
            context.packageManager.getPackageInfo("com.tencent.mm", 0)
            true
        } catch (e: Exception) {
            false
        }
    }

    private fun getWeChatVersion(): String? {
        return try {
            val packageInfo = context.packageManager.getPackageInfo("com.tencent.mm", 0)
            packageInfo.versionName
        } catch (e: Exception) {
            null
        }
    }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        channel.setMethodCallHandler(null)
    }
}