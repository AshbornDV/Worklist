package com.example.worklist.core.designsystem

import androidx.compose.material3.ColorScheme
import androidx.compose.ui.graphics.Color

/**
 * Ports AppTheme.statusColor / attendanceColor from
 * lib/core/theme/app_theme.dart:114-146 exactly.
 *
 * Status is matched case-insensitively (Flutter calls toLowerCase());
 * attendance is case-sensitive. Both fall back to outline on an unknown key.
 */

fun statusColor(status: String, scheme: ColorScheme): Color = when (status.lowercase()) {
    "active" -> Color(0xFF2E7D32)
    "completed" -> scheme.primary
    "pending" -> Color(0xFFF57C00)
    "on_hold" -> Color(0xFF6D4C41)
    "approved" -> Color(0xFF2E7D32)
    "rejected" -> scheme.error
    "inactive" -> scheme.outline
    else -> scheme.outline
}

fun attendanceColor(type: String, scheme: ColorScheme): Color = when (type) {
    "full" -> Color(0xFF2E7D32)
    "half" -> Color(0xFFF57C00)
    "absent" -> scheme.error
    else -> scheme.outline
}
