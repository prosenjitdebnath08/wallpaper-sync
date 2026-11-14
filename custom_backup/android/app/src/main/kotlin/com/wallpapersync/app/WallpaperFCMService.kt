package com.wallpapersync.app

import android.app.WallpaperManager
import android.os.Build
import android.util.Log
import com.google.firebase.messaging.FirebaseMessagingService
import com.google.firebase.messaging.RemoteMessage
import java.io.InputStream
import java.net.HttpURLConnection
import java.net.URL
import kotlin.concurrent.thread

class WallpaperFCMService : FirebaseMessagingService() {

    private val TAG = "WallpaperFCMService"

    override fun onMessageReceived(remoteMessage: RemoteMessage) {
        super.onMessageReceived(remoteMessage)
        Log.d(TAG, "From: ${remoteMessage.from}")

        // Check if message contains high-priority data payload
        if (remoteMessage.data.isNotEmpty()) {
            val action = remoteMessage.data["action"]
            val imageUrl = remoteMessage.data["url"]

            if (action == "SET_WALLPAPER" && !imageUrl.isNullOrEmpty()) {
                Log.d(TAG, "Auto-sync wallpaper triggered in background from: $imageUrl")
                applyWallpaperInBackground(imageUrl)
            }
        }
    }

    private fun applyWallpaperInBackground(imageUrl: String) {
        thread {
            var inputStream: InputStream? = null
            try {
                val url = URL(imageUrl)
                val connection = url.openConnection() as HttpURLConnection
                connection.doInput = true
                connection.connectTimeout = 15000
                connection.readTimeout = 15000
                connection.connect()

                if (connection.responseCode == HttpURLConnection.HTTP_OK) {
                    inputStream = connection.inputStream
                    val wallpaperManager = WallpaperManager.getInstance(applicationContext)

                    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.N) {
                        val flags = WallpaperManager.FLAG_SYSTEM or WallpaperManager.FLAG_LOCK
                        wallpaperManager.setStream(inputStream, null, true, flags)
                    } else {
                        wallpaperManager.setStream(inputStream)
                    }
                    Log.i(TAG, "✓ Background wallpaper successfully updated without user interaction!")
                } else {
                    Log.e(TAG, "HTTP error downloading wallpaper: ${connection.responseCode}")
                }
            } catch (e: Exception) {
                Log.e(TAG, "Failed to apply wallpaper in background: ${e.localizedMessage}", e)
            } finally {
                try {
                    inputStream?.close()
                } catch (ignored: Exception) {}
            }
        }
    }

    override fun onNewToken(token: String) {
        super.onNewToken(token)
        Log.d(TAG, "Refreshed FCM token: $token")
        // App will push token to Firestore on active session
    }
}
