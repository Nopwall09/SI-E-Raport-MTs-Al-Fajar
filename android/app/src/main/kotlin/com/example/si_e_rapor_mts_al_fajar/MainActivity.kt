package com.example.si_e_rapor_mts_al_fajar

import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.content.ContentValues
import android.content.Context
import android.content.Intent
import android.media.MediaScannerConnection
import android.net.Uri
import android.os.Build
import android.os.Environment
import android.provider.MediaStore
import androidx.core.content.FileProvider
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.File
import java.io.FileOutputStream

class MainActivity : FlutterActivity() {
    private val CHANNEL = "com.example.si_e_rapor_mts_al_fajar/downloader"
    private val NOTIF_CHANNEL_ID = "rapor_download_channel"
    private val NOTIF_ID = 2026

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "saveAndNotifyPdf" -> {
                    val fileName = call.argument<String>("fileName") ?: "Rapor.pdf"
                    val bytes = call.argument<ByteArray>("bytes")
                    val studentName = call.argument<String>("studentName") ?: "Siswa"

                    if (bytes == null) {
                        result.error("INVALID_BYTES", "Data PDF tidak boleh kosong", null)
                        return@setMethodCallHandler
                    }

                    try {
                        val saveResult = savePdfToPublicDownloads(fileName, bytes)
                        val uriString = saveResult["uri"]
                        val filePath = saveResult["path"]

                        // Tampilkan Notifikasi Sistem Android
                        showDownloadSuccessNotification(
                            title = "Unduhan Rapor Selesai",
                            message = "$fileName siap dibuka.",
                            uriString = uriString,
                            filePath = filePath
                        )

                        result.success(saveResult)
                    } catch (e: Exception) {
                        result.error("SAVE_FAILED", e.localizedMessage, e.stackTraceToString())
                    }
                }
                "openPdf" -> {
                    val uriString = call.argument<String>("uri")
                    val filePath = call.argument<String>("filePath")

                    try {
                        val openSuccess = openPdfFile(uriString, filePath)
                        result.success(openSuccess)
                    } catch (e: Exception) {
                        result.error("OPEN_FAILED", e.localizedMessage, null)
                    }
                }
                else -> result.notImplemented()
            }
        }
    }

    private fun savePdfToPublicDownloads(fileName: String, bytes: ByteArray): Map<String, String> {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
            // Android 10+ (API 29+): Gunakan MediaStore untuk menyimpan ke folder Download publik HP
            val values = ContentValues().apply {
                put(MediaStore.Downloads.DISPLAY_NAME, fileName)
                put(MediaStore.Downloads.MIME_TYPE, "application/pdf")
                put(MediaStore.Downloads.IS_PENDING, 1)
            }
            val collection = MediaStore.Downloads.getContentUri(MediaStore.VOLUME_EXTERNAL_PRIMARY)
            val uri = contentResolver.insert(collection, values)
                ?: throw IllegalStateException("Gagal membuat entri di folder Download")

            contentResolver.openOutputStream(uri)?.use { output ->
                output.write(bytes)
                output.flush()
            }

            values.clear()
            values.put(MediaStore.Downloads.IS_PENDING, 0)
            contentResolver.update(uri, values, null, null)

            val displayPath = "${Environment.DIRECTORY_DOWNLOADS}/$fileName"
            return mapOf("uri" to uri.toString(), "path" to displayPath)
        } else {
            // Android 9 kebawah: Environment.DIRECTORY_DOWNLOADS langsung
            val downloadsDir = Environment.getExternalStoragePublicDirectory(Environment.DIRECTORY_DOWNLOADS)
            if (!downloadsDir.exists()) downloadsDir.mkdirs()

            val file = File(downloadsDir, fileName)
            FileOutputStream(file).use { output ->
                output.write(bytes)
                output.flush()
            }

            // Pindai MediaStore agar langsung muncul di Pengelola File
            MediaScannerConnection.scanFile(this, arrayOf(file.absolutePath), arrayOf("application/pdf"), null)

            val contentUri = try {
                FileProvider.getUriForFile(this, "$packageName.fileprovider", file)
            } catch (e: Exception) {
                Uri.fromFile(file)
            }

            return mapOf("uri" to contentUri.toString(), "path" to file.absolutePath)
        }
    }

    private fun showDownloadSuccessNotification(title: String, message: String, uriString: String?, filePath: String?) {
        val notificationManager = getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val channel = NotificationChannel(
                NOTIF_CHANNEL_ID,
                "Unduhan Rapor MTs Al Fajar",
                NotificationManager.IMPORTANCE_HIGH
            ).apply {
                description = "Notifikasi status unduhan rapor siswa"
                enableVibration(true)
                setShowBadge(true)
            }
            notificationManager.createNotificationChannel(channel)
        }

        val openIntent = createOpenIntent(uriString, filePath)
        val flags = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
            PendingIntent.FLAG_IMMUTABLE or PendingIntent.FLAG_UPDATE_CURRENT
        } else {
            PendingIntent.FLAG_UPDATE_CURRENT
        }
        val pendingIntent = PendingIntent.getActivity(this, NOTIF_ID, openIntent, flags)

        val builder = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            Notification.Builder(this, NOTIF_CHANNEL_ID)
        } else {
            @Suppress("DEPRECATION")
            Notification.Builder(this)
        }

        builder.setContentTitle(title)
            .setContentText(message)
            .setSmallIcon(android.R.drawable.stat_sys_download_done)
            .setContentIntent(pendingIntent)
            .setAutoCancel(true)

        notificationManager.notify(NOTIF_ID, builder.build())
    }

    private fun openPdfFile(uriString: String?, filePath: String?): Boolean {
        val intent = createOpenIntent(uriString, filePath)
        val chooser = Intent.createChooser(intent, "Buka Lembar Rapor Digital")
        chooser.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
        startActivity(chooser)
        return true
    }

    private fun createOpenIntent(uriString: String?, filePath: String?): Intent {
        val uri: Uri = when {
            uriString != null && uriString.startsWith("content://") -> Uri.parse(uriString)
            filePath != null && !filePath.startsWith("Download/") -> {
                val file = File(filePath)
                try {
                    FileProvider.getUriForFile(this, "$packageName.fileprovider", file)
                } catch (e: Exception) {
                    Uri.fromFile(file)
                }
            }
            uriString != null -> Uri.parse(uriString)
            else -> throw IllegalArgumentException("URI atau path berkas tidak valid")
        }

        return Intent(Intent.ACTION_VIEW).apply {
            setDataAndType(uri, "application/pdf")
            addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION)
            addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
        }
    }
}
