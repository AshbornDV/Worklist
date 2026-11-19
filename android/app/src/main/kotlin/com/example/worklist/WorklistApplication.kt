package com.example.worklist

import android.app.Application
import android.util.Log
import androidx.work.WorkManager
import io.flutter.app.FlutterApplication

/**
 * Application subclass required by the `workmanager` plugin on Android. The
 * plugin initializes its Dart callback dispatcher from this process; extending
 * [FlutterApplication] (rather than a bare [Application]) is the recommended
 * setup so WorkManager can launch the background Dart isolate.
 *
 * The actual periodic scheduling is owned entirely by the Flutter `workmanager`
 * plugin (initialized from Dart). This class just ensures WorkManager is primed
 * on every cold start; WorkManager persists its periodic work across reboots,
 * so no manual re-enqueue is needed here. [BootReceiver] is a belt-and-braces
 * safeguard that touches the WorkManager singleton on BOOT_COMPLETED.
 */
class WorklistApplication : FlutterApplication() {
    override fun onCreate() {
        super.onCreate()
        try {
            WorkManager.getInstance(this)
        } catch (e: Exception) {
            Log.e("WorklistApp", "WorkManager init failed", e)
        }
    }
}
