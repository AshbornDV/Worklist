package com.example.worklist.core.designsystem

import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material3.Shapes
import androidx.compose.ui.unit.dp

/**
 * Corner radii ported from Flutter's AppTheme (contracts/theme.json:shape).
 *
 * - extraSmall = 8.dp  -> ChipThemeData
 * - small      = 12.dp -> OutlineInputBorder / FilledButton / ElevatedButton / OutlinedButton
 * - medium     = 14.dp -> CardThemeData
 * - large      = 20.dp -> next step up; not used by the Flutter theme today
 */
val WorklistShapes = Shapes(
    extraSmall = RoundedCornerShape(8.dp),
    small = RoundedCornerShape(12.dp),
    medium = RoundedCornerShape(14.dp),
    large = RoundedCornerShape(20.dp),
)
