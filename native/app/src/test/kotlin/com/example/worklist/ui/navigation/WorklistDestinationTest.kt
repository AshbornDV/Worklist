package com.example.worklist.ui.navigation

import org.junit.Assert.assertEquals
import org.junit.Test

/**
 * Guards the shell against silently dropping a screen during the Flutter port.
 *
 * The Flutter router in `lib/app.dart` declares exactly 24 GoRoutes. Every one
 * of them must have a destination here, and no two destinations may share a
 * route string (Navigation Compose would otherwise collapse them).
 */
class WorklistDestinationTest {

    @Test
    fun `there are exactly 24 destinations`() {
        assertEquals(
            "shell must mirror the 24 GoRoutes in lib/app.dart",
            24,
            WorklistDestination.entries.size,
        )
    }

    @Test
    fun `every destination has a unique route string`() {
        val routes = WorklistDestination.entries.map { it.route }
        assertEquals(
            "duplicate route strings: ${routes.groupingBy { it }.eachCount().filter { it.value > 1 }}",
            routes.size,
            routes.toSet().size,
        )
    }
}
