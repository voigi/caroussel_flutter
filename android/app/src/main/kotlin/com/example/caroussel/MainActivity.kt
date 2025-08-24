package com.example.caroussel

import android.content.ContentValues
import android.os.Build
import android.os.Environment
import android.provider.MediaStore
import androidx.annotation.NonNull
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.File
import java.io.FileInputStream
import java.io.OutputStream

class MainActivity: FlutterActivity() {
    private val CHANNEL = "com.example.caroussel/media"

    override fun configureFlutterEngine(@NonNull flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            if (call.method == "saveVideoToGallery") {
                val sourcePath = call.argument<String>("sourcePath")
                val fileName = call.argument<String>("fileName")

                if (sourcePath != null && fileName != null) {
                    try {
                        val file = File(sourcePath)
                        val resolver = applicationContext.contentResolver
                        val values = ContentValues().apply {
                            put(MediaStore.Video.Media.DISPLAY_NAME, fileName)
                            put(MediaStore.Video.Media.MIME_TYPE, "video/mp4")
                            // Pour Android Q+ : dossier relatif dans Movies
                            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
                                put(MediaStore.Video.Media.RELATIVE_PATH, Environment.DIRECTORY_MOVIES + "/Mes Vidéos")
                                put(MediaStore.Video.Media.IS_PENDING, 1)
                            }
                        }

                        val uri = resolver.insert(MediaStore.Video.Media.EXTERNAL_CONTENT_URI, values)

                        if (uri != null) {
                            resolver.openOutputStream(uri).use { out: OutputStream? ->
                                FileInputStream(file).use { input ->
                                    input.copyTo(out!!)
                                }
                            }
                            // Déclare que le fichier est fini pour Android Q+
                            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
                                values.clear()
                                values.put(MediaStore.Video.Media.IS_PENDING, 0)
                                resolver.update(uri, values, null, null)
                            }
                            result.success(true)
                        } else {
                            result.success(false)
                        }
                    } catch (e: Exception) {
                        result.error("SAVE_FAILED", "Erreur : ${e.message}", null)
                    }
                } else {
                    result.error("INVALID_ARGS", "Chemin invalide", null)
                }
            }
        }
    }
}
