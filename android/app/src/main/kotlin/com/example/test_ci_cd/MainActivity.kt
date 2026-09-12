package com.example.test_ci_cd

import android.content.Intent
import android.net.Uri
import android.os.Build
import android.provider.Settings
import androidx.core.content.FileProvider
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.File

class MainActivity : FlutterActivity() {

    private val CHANNEL = "apk_installer"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            CHANNEL
        ).setMethodCallHandler { call, result ->

            when (call.method) {

                "installApk" -> {

                    val apkPath = call.argument<String>("apkPath")

                    if (apkPath == null) {
                        result.error(
                            "INVALID_PATH",
                            "APK path is missing",
                            null
                        )
                        return@setMethodCallHandler
                    }

                    try {
                        installApk(apkPath)
                        result.success(true)
                    } catch (e: Exception) {
                        result.error(
                            "INSTALL_ERROR",
                            e.message,
                            null
                        )
                    }
                }

                else -> {
                    result.notImplemented()
                }
            }
        }
    }

    private fun installApk(apkPath: String) {

        val apkFile = File(apkPath)

        if (!apkFile.exists()) {
            throw Exception("APK file does not exist: $apkPath")
        }

        val apkUri: Uri = FileProvider.getUriForFile(
            this,
            "${applicationContext.packageName}.fileprovider",
            apkFile
        )

        val intent = Intent(Intent.ACTION_INSTALL_PACKAGE).apply {

            data = apkUri

            addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION)
            addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
        }

        startActivity(intent)
    }
}