package com.example.worklist.ui.navigation

import org.junit.Assert.assertEquals
import org.junit.Test

/**
 * Guards the shell against silently dropping a screen during the Flutter port.
 *
 * The Flutter router in `lib/app.dart` declares exactly 26 GoRoutes (24 original +
 * 2 new form routes: products/new, services/new). Every one of them must have a
 * destination here, and no two destinations may share a route string (Navigation
 * Compose would otherwise collapse them).
 */
class WorklistDestinationTest {

    @Test
    fun `there are exactly 26 destinations`() {
        assertEquals(
            "shell must mirror the 26 GoRoutes in lib/app.dart",
            26,
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
