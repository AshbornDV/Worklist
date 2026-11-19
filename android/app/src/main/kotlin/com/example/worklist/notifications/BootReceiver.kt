package com.example.worklist.notifications

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.util.Log
import androidx.work.WorkManager

/**
 * Fires on BOOT_COMPLETED (and QUICKBOOT_POWERON for some OEMs). WorkManager
 * already persists periodic work across reboots, so this receiver is only a
 * belt-and-braces nudge that touches the WorkManager singleton so the OS
 * re-evaluates its pending work after a restart.
 *
 * It deliberately does NOT enqueue its own worker — the Flutter `workmanager`
 * plugin owns scheduling (using a unique work name with UPDATE policy), so
 * adding another enqueue here would risk a duplicate job.
 */
class BootReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context?, intent: Intent?) {
        if (context == null) return
        val action = intent?.action
        if (action == Intent.ACTION_BOOT_COMPLETED ||
            action == "android.intent.action.QUICKBOOT_POWERON"
        ) {
            try {
                WorkManager.getInstance(context)
                Log.i(TAG, "WorkManager primed after boot")
            } catch (e: Exception) {
                Log.e(TAG, "Failed to prime WorkManager after boot", e)
            }
        }
    }

    companion object {
        private const val TAG = "BootReceiver"
    }
}
