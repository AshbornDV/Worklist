package com.example.worklist.core.designsystem

import androidx.compose.material3.ColorScheme
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.darkColorScheme
import androidx.compose.material3.lightColorScheme
import androidx.compose.runtime.Composable

/** Light scheme assembled from the contract-pinned colour vals. */
val WorklistLightColors: ColorScheme = lightColorScheme(
    primary = lightPrimary,
    onPrimary = lightOnPrimary,
    primaryContainer = lightPrimaryContainer,
    onPrimaryContainer = lightOnPrimaryContainer,
    secondary = lightSecondary,
    onSecondary = lightOnSecondary,
    secondaryContainer = lightSecondaryContainer,
    onSecondaryContainer = lightOnSecondaryContainer,
    tertiary = lightTertiary,
    onTertiary = lightOnTertiary,
    tertiaryContainer = lightTertiaryContainer,
    onTertiaryContainer = lightOnTertiaryContainer,
    error = lightError,
    onError = lightOnError,
    errorContainer = lightErrorContainer,
    onErrorContainer = lightOnErrorContainer,
    surface = lightSurface,
    onSurface = lightOnSurface,
    surfaceDim = lightSurfaceDim,
    surfaceBright = lightSurfaceBright,
    surfaceContainerLowest = lightSurfaceContainerLowest,
    surfaceContainerLow = lightSurfaceContainerLow,
    surfaceContainer = lightSurfaceContainer,
    surfaceContainerHigh = lightSurfaceContainerHigh,
    surfaceContainerHighest = lightSurfaceContainerHighest,
    onSurfaceVariant = lightOnSurfaceVariant,
    outline = lightOutline,
    outlineVariant = lightOutlineVariant,
    // Material3 1.3.1 has no `shadow` ColorScheme member (shadow is internal black).
    // lightShadow is kept as a contract-pinned val and asserted directly in the test.
    scrim = lightScrim,
    inverseSurface = lightInverseSurface,
    // Contract key `onInverseSurface` == Material3 1.3.1 `inverseOnSurface`.
    inverseOnSurface = lightOnInverseSurface,
    inversePrimary = lightInversePrimary,
    surfaceTint = lightSurfaceTint,
)

/** Dark scheme assembled from the contract-pinned colour vals. */
val WorklistDarkColors: ColorScheme = darkColorScheme(
    primary = darkPrimary,
    onPrimary = darkOnPrimary,
    primaryContainer = darkPrimaryContainer,
    onPrimaryContainer = darkOnPrimaryContainer,
    secondary = darkSecondary,
    onSecondary = darkOnSecondary,
    secondaryContainer = darkSecondaryContainer,
    onSecondaryContainer = darkOnSecondaryContainer,
    tertiary = darkTertiary,
    onTertiary = darkOnTertiary,
    tertiaryContainer = darkTertiaryContainer,
    onTertiaryContainer = darkOnTertiaryContainer,
    error = darkError,
    onError = darkOnError,
    errorContainer = darkErrorContainer,
    onErrorContainer = darkOnErrorContainer,
    surface = darkSurface,
    onSurface = darkOnSurface,
    surfaceDim = darkSurfaceDim,
    surfaceBright = darkSurfaceBright,
    surfaceContainerLowest = darkSurfaceContainerLowest,
    surfaceContainerLow = darkSurfaceContainerLow,
    surfaceContainer = darkSurfaceContainer,
    surfaceContainerHigh = darkSurfaceContainerHigh,
    surfaceContainerHighest = darkSurfaceContainerHighest,
    onSurfaceVariant = darkOnSurfaceVariant,
    outline = darkOutline,
    outlineVariant = darkOutlineVariant,
    // See light scheme note: no `shadow` ColorScheme member in Material3 1.3.1.
    scrim = darkScrim,
    inverseSurface = darkInverseSurface,
    inverseOnSurface = darkOnInverseSurface,
    inversePrimary = darkInversePrimary,
    surfaceTint = darkSurfaceTint,
)

/** Root theme: contract colours + Flutter-compatible shapes. */
@Composable
fun WorklistTheme(
    darkTheme: Boolean,
    content: @Composable () -> Unit,
) {
    val colorScheme = if (darkTheme) WorklistDarkColors else WorklistLightColors
    MaterialTheme(
        colorScheme = colorScheme,
        shapes = WorklistShapes,
        content = content,
    )
}
