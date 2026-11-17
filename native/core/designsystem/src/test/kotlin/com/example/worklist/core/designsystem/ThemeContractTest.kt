package com.example.worklist.core.designsystem

import androidx.compose.ui.geometry.Size
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.toArgb
import androidx.compose.ui.unit.Density
import kotlinx.serialization.Serializable
import kotlinx.serialization.json.Json
import org.junit.Assert.assertEquals
import org.junit.Assert.assertNotNull
import org.junit.Assert.assertTrue
import org.junit.Test
import java.io.File

@Serializable
data class ThemeContract(
    val light: Map<String, String>,
    val dark: Map<String, String>,
    val status: Map<String, String>,
    val attendance: Map<String, String>,
    val shape: Map<String, Int>,
)

/** Pins the native Compose theme byte-for-byte to contracts/theme.json. */
class ThemeContractTest {
    private val contract: ThemeContract by lazy {
        val dir = System.getProperty("worklist.contracts")
            ?: error("Missing required system property 'worklist.contracts'")
        val file = File(dir, "theme.json")
        assertTrue("Contract file missing: ${file.absolutePath}", file.isFile)
        Json.decodeFromString<ThemeContract>(file.readText())
    }

    private fun String.toArgbInt(): Int = removePrefix("#").toLong(16).toInt()

    private fun assertRole(label: String, name: String, hex: String?, actual: Color) {
        assertNotNull("$label missing contract role '$name'", hex)
        assertEquals(
            "$label.$name mismatch: contract=$hex actual=#${Integer.toHexString(actual.toArgb())}",
            hex!!.toArgbInt(),
            actual.toArgb(),
        )
    }

    @Test
    fun lightSchemeMatchesContract() {
        val c = contract.light
        assertRole("light", "primary", c["primary"], WorklistLightColors.primary)
        assertRole("light", "onPrimary", c["onPrimary"], WorklistLightColors.onPrimary)
        assertRole("light", "primaryContainer", c["primaryContainer"], WorklistLightColors.primaryContainer)
        assertRole("light", "onPrimaryContainer", c["onPrimaryContainer"], WorklistLightColors.onPrimaryContainer)
        assertRole("light", "secondary", c["secondary"], WorklistLightColors.secondary)
        assertRole("light", "onSecondary", c["onSecondary"], WorklistLightColors.onSecondary)
        assertRole("light", "secondaryContainer", c["secondaryContainer"], WorklistLightColors.secondaryContainer)
        assertRole("light", "onSecondaryContainer", c["onSecondaryContainer"], WorklistLightColors.onSecondaryContainer)
        assertRole("light", "tertiary", c["tertiary"], WorklistLightColors.tertiary)
        assertRole("light", "onTertiary", c["onTertiary"], WorklistLightColors.onTertiary)
        assertRole("light", "tertiaryContainer", c["tertiaryContainer"], WorklistLightColors.tertiaryContainer)
        assertRole("light", "onTertiaryContainer", c["onTertiaryContainer"], WorklistLightColors.onTertiaryContainer)
        assertRole("light", "error", c["error"], WorklistLightColors.error)
        assertRole("light", "onError", c["onError"], WorklistLightColors.onError)
        assertRole("light", "errorContainer", c["errorContainer"], WorklistLightColors.errorContainer)
        assertRole("light", "onErrorContainer", c["onErrorContainer"], WorklistLightColors.onErrorContainer)
        assertRole("light", "surface", c["surface"], WorklistLightColors.surface)
        assertRole("light", "onSurface", c["onSurface"], WorklistLightColors.onSurface)
        assertRole("light", "surfaceDim", c["surfaceDim"], WorklistLightColors.surfaceDim)
        assertRole("light", "surfaceBright", c["surfaceBright"], WorklistLightColors.surfaceBright)
        assertRole("light", "surfaceContainerLowest", c["surfaceContainerLowest"], WorklistLightColors.surfaceContainerLowest)
        assertRole("light", "surfaceContainerLow", c["surfaceContainerLow"], WorklistLightColors.surfaceContainerLow)
        assertRole("light", "surfaceContainer", c["surfaceContainer"], WorklistLightColors.surfaceContainer)
        assertRole("light", "surfaceContainerHigh", c["surfaceContainerHigh"], WorklistLightColors.surfaceContainerHigh)
        assertRole("light", "surfaceContainerHighest", c["surfaceContainerHighest"], WorklistLightColors.surfaceContainerHighest)
        assertRole("light", "onSurfaceVariant", c["onSurfaceVariant"], WorklistLightColors.onSurfaceVariant)
        assertRole("light", "outline", c["outline"], WorklistLightColors.outline)
        assertRole("light", "outlineVariant", c["outlineVariant"], WorklistLightColors.outlineVariant)
        // Material3 1.3.1 ColorScheme has no `shadow` member; pin the contract val directly.
        assertRole("light", "shadow", c["shadow"], lightShadow)
        assertRole("light", "scrim", c["scrim"], WorklistLightColors.scrim)
        assertRole("light", "inverseSurface", c["inverseSurface"], WorklistLightColors.inverseSurface)
        // Contract `onInverseSurface` is named `inverseOnSurface` in Material3.
        assertRole("light", "onInverseSurface", c["onInverseSurface"], WorklistLightColors.inverseOnSurface)
        assertRole("light", "inversePrimary", c["inversePrimary"], WorklistLightColors.inversePrimary)
        assertRole("light", "surfaceTint", c["surfaceTint"], WorklistLightColors.surfaceTint)
    }

    @Test
    fun darkSchemeMatchesContract() {
        val c = contract.dark
        assertRole("dark", "primary", c["primary"], WorklistDarkColors.primary)
        assertRole("dark", "onPrimary", c["onPrimary"], WorklistDarkColors.onPrimary)
        assertRole("dark", "primaryContainer", c["primaryContainer"], WorklistDarkColors.primaryContainer)
        assertRole("dark", "onPrimaryContainer", c["onPrimaryContainer"], WorklistDarkColors.onPrimaryContainer)
        assertRole("dark", "secondary", c["secondary"], WorklistDarkColors.secondary)
        assertRole("dark", "onSecondary", c["onSecondary"], WorklistDarkColors.onSecondary)
        assertRole("dark", "secondaryContainer", c["secondaryContainer"], WorklistDarkColors.secondaryContainer)
        assertRole("dark", "onSecondaryContainer", c["onSecondaryContainer"], WorklistDarkColors.onSecondaryContainer)
        assertRole("dark", "tertiary", c["tertiary"], WorklistDarkColors.tertiary)
        assertRole("dark", "onTertiary", c["onTertiary"], WorklistDarkColors.onTertiary)
        assertRole("dark", "tertiaryContainer", c["tertiaryContainer"], WorklistDarkColors.tertiaryContainer)
        assertRole("dark", "onTertiaryContainer", c["onTertiaryContainer"], WorklistDarkColors.onTertiaryContainer)
        assertRole("dark", "error", c["error"], WorklistDarkColors.error)
        assertRole("dark", "onError", c["onError"], WorklistDarkColors.onError)
        assertRole("dark", "errorContainer", c["errorContainer"], WorklistDarkColors.errorContainer)
        assertRole("dark", "onErrorContainer", c["onErrorContainer"], WorklistDarkColors.onErrorContainer)
        assertRole("dark", "surface", c["surface"], WorklistDarkColors.surface)
        assertRole("dark", "onSurface", c["onSurface"], WorklistDarkColors.onSurface)
        assertRole("dark", "surfaceDim", c["surfaceDim"], WorklistDarkColors.surfaceDim)
        assertRole("dark", "surfaceBright", c["surfaceBright"], WorklistDarkColors.surfaceBright)
        assertRole("dark", "surfaceContainerLowest", c["surfaceContainerLowest"], WorklistDarkColors.surfaceContainerLowest)
        assertRole("dark", "surfaceContainerLow", c["surfaceContainerLow"], WorklistDarkColors.surfaceContainerLow)
        assertRole("dark", "surfaceContainer", c["surfaceContainer"], WorklistDarkColors.surfaceContainer)
        assertRole("dark", "surfaceContainerHigh", c["surfaceContainerHigh"], WorklistDarkColors.surfaceContainerHigh)
        assertRole("dark", "surfaceContainerHighest", c["surfaceContainerHighest"], WorklistDarkColors.surfaceContainerHighest)
        assertRole("dark", "onSurfaceVariant", c["onSurfaceVariant"], WorklistDarkColors.onSurfaceVariant)
        assertRole("dark", "outline", c["outline"], WorklistDarkColors.outline)
        assertRole("dark", "outlineVariant", c["outlineVariant"], WorklistDarkColors.outlineVariant)
        assertRole("dark", "shadow", c["shadow"], darkShadow)
        assertRole("dark", "scrim", c["scrim"], WorklistDarkColors.scrim)
        assertRole("dark", "inverseSurface", c["inverseSurface"], WorklistDarkColors.inverseSurface)
        assertRole("dark", "onInverseSurface", c["onInverseSurface"], WorklistDarkColors.inverseOnSurface)
        assertRole("dark", "inversePrimary", c["inversePrimary"], WorklistDarkColors.inversePrimary)
        assertRole("dark", "surfaceTint", c["surfaceTint"], WorklistDarkColors.surfaceTint)
    }

    @Test
    fun shapesMatchContract() {
        // Density 1f => px value equals dp value, so a 14.dp corner reads back as 14f.
        val density = Density(1f, 1f)
        val extraSmallPx = WorklistShapes.extraSmall.topStart.toPx(Size.Unspecified, density)
        val smallPx = WorklistShapes.small.topStart.toPx(Size.Unspecified, density)
        val mediumPx = WorklistShapes.medium.topStart.toPx(Size.Unspecified, density)
        val largePx = WorklistShapes.large.topStart.toPx(Size.Unspecified, density)

        assertEquals("chip radius", 8f, extraSmallPx, 0f)
        assertEquals("small radius", 12f, smallPx, 0f)
        assertEquals("medium radius", 14f, mediumPx, 0f)
        assertEquals("large radius", 20f, largePx, 0f)

        assertEquals(
            "chip radius matches contract",
            contract.shape["chipRadius"]?.toFloat(),
            extraSmallPx,
        )
        assertEquals(
            "input radius matches contract",
            contract.shape["inputRadius"]?.toFloat(),
            smallPx,
        )
        assertEquals(
            "card radius matches contract",
            contract.shape["cardRadius"]?.toFloat(),
            mediumPx,
        )
    }

    @Test
    fun statusColorsMatchContract() {
        val c = contract.status
        val light = WorklistLightColors
        assertRole("status", "active", c["active"], statusColor("active", light))
        assertRole("status", "completed", c["completed"], statusColor("completed", light))
        assertRole("status", "pending", c["pending"], statusColor("pending", light))
        assertRole("status", "on_hold", c["on_hold"], statusColor("on_hold", light))
        assertRole("status", "approved", c["approved"], statusColor("approved", light))
        assertRole("status", "rejected", c["rejected"], statusColor("rejected", light))
        assertRole("status", "inactive", c["inactive"], statusColor("inactive", light))
        assertRole("status", "default", c["default"], statusColor("anything-else", light))
        // Flutter lowercases the status before the switch.
        assertRole("status", "active (uppercase input)", c["active"], statusColor("ACTIVE", light))
    }

    @Test
    fun attendanceColorsMatchContract() {
        val c = contract.attendance
        val light = WorklistLightColors
        assertRole("attendance", "full", c["full"], attendanceColor("full", light))
        assertRole("attendance", "half", c["half"], attendanceColor("half", light))
        assertRole("attendance", "absent", c["absent"], attendanceColor("absent", light))
        assertRole("attendance", "default", c["default"], attendanceColor("unknown", light))
    }
}
