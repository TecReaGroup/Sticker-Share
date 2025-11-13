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

class MessagingSharePlugin : FlutterPlugin, MethodChannel.MethodCallHandler {
    private lateinit var channel: MethodChannel
    private lateinit var context: Context

    companion object {
        private val SUPPORTED_APPS = mapOf(
            "com.tencent.mm" to "WeChat",
            "com.tencent.mobileqq" to "QQ",
            "com.whatsapp" to "WhatsApp",
            "org.telegram.messenger" to "Telegram",
            "com.discord" to "Discord",
            "com.facebook.orca" to "Messenger",
            "jp.naver.line.android" to "LINE",
            "com.twitter.android" to "X"
        )
    }

    override fun onAttachedToEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        context = binding.applicationContext
        channel = MethodChannel(binding.binaryMessenger, "com.stickershare/messaging_share")
        channel.setMethodCallHandler(this)
    }

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "shareGif" -> shareGif(call, result)
            "shareGifGeneric" -> shareGifGeneric(call, result)
            "getInstalledApps" -> result.success(getInstalledApps())
            "isAppInstalled" -> {
                val packageName = call.argument<String>("packageName")
                result.success(packageName?.let { isAppInstalled(it) } ?: false)
            }
            else -> result.notImplemented()
        }
    }

    private fun shareGif(call: MethodCall, result: MethodChannel.Result) {
        val gifData = call.argument<ByteArray>("gifData")
        val packageName = call.argument<String>("packageName")

        if (gifData == null || packageName == null) {
            result.error("INVALID_ARGS", "Missing required arguments", null)
            return
        }

        try {
            val gifUri = saveGifToCache(gifData)
            val intent = Intent(Intent.ACTION_SEND).apply {
                type = "image/gif"
                putExtra(Intent.EXTRA_STREAM, gifUri)
                setPackage(packageName)
                addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION)
            }

            if (context.packageManager.resolveActivity(intent, 0) != null) {
                context.startActivity(intent)
                result.success(true)
            } else {
                result.error("APP_NOT_AVAILABLE", "App is not available", null)
            }
        } catch (e: Exception) {
            result.error("SHARE_ERROR", "Failed to share: ${e.message}", null)
        }
    }

    private fun shareGifGeneric(call: MethodCall, result: MethodChannel.Result) {
        val gifData = call.argument<ByteArray>("gifData")

        if (gifData == null) {
            result.error("INVALID_ARGS", "Missing required arguments", null)
            return
        }

        try {
            val gifUri = saveGifToCache(gifData)
            val intent = Intent(Intent.ACTION_SEND).apply {
                type = "image/gif"
                putExtra(Intent.EXTRA_STREAM, gifUri)
                addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION)
            }

            val chooser = Intent.createChooser(intent, "Share GIF")
            chooser.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
            context.startActivity(chooser)
            result.success(true)
        } catch (e: Exception) {
            result.error("SHARE_ERROR", "Failed to share: ${e.message}", null)
        }
    }

    private fun saveGifToCache(data: ByteArray): Uri {
        val cacheDir = File(context.cacheDir, "shared_gifs")
        if (!cacheDir.exists()) {
            cacheDir.mkdirs()
        }

        val gifFile = File(cacheDir, "share_${System.currentTimeMillis()}.gif")
        FileOutputStream(gifFile).use { fos ->
            fos.write(data)
        }

        return FileProvider.getUriForFile(
            context,
            "${context.packageName}.fileprovider",
            gifFile
        )
    }

    private fun getInstalledApps(): List<String> {
        val installed = SUPPORTED_APPS.keys.filter { isAppInstalled(it) }
        android.util.Log.d("MessagingSharePlugin", "Detected ${installed.size} apps: $installed")
        return installed
    }

    private fun isAppInstalled(packageName: String): Boolean {
        return try {
            context.packageManager.getPackageInfo(packageName, 0)
            true
        } catch (e: Exception) {
            false
        }
    }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        channel.setMethodCallHandler(null)
    }
}