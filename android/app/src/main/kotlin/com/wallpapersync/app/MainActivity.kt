package com.wallpapersync.app

import android.app.WallpaperManager
import android.graphics.BitmapFactory
import android.os.Build
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.File
import java.io.FileInputStream

class MainActivity: FlutterActivity() {
    private val CHANNEL = "com.wallpapersync.app/wallpaper"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "setWallpaper" -> {
                    val filePath = call.argument<String>("filePath")
                    val setHome = call.argument<Boolean>("setHome") ?: true
                    val setLock = call.argument<Boolean>("setLock") ?: true

                    if (filePath == null) {
                        result.error("INVALID_ARGS", "filePath is required", null)
                        return@setMethodCallHandler
                    }

                    Thread {
                        try {
                            val success = applyWallpaper(filePath, setHome, setLock)
                            runOnUiThread {
                                result.success(success)
                            }
                        } catch (e: Exception) {
                            runOnUiThread {
                                result.error("WALLPAPER_ERROR", e.localizedMessage, null)
                            }
                        }
                    }.start()
                }
                else -> result.notImplemented()
            }
        }
    }

    private fun applyWallpaper(filePath: String, setHome: Boolean, setLock: Boolean): Boolean {
        val file = File(filePath)
        if (!file.exists()) return false

        val wallpaperManager = WallpaperManager.getInstance(applicationContext)

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.N) {
            var flags = 0
            if (setHome) flags = flags or WallpaperManager.FLAG_SYSTEM
            if (setLock) flags = flags or WallpaperManager.FLAG_LOCK

            FileInputStream(file).use { stream ->
                wallpaperManager.setStream(stream, null, true, flags)
            }
        } else {
            val bitmap = BitmapFactory.decodeFile(file.absolutePath)
            wallpaperManager.setBitmap(bitmap)
        }
        return true
    }
}
