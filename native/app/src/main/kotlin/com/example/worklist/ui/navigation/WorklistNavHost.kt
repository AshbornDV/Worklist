package com.example.worklist.ui.navigation

import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.navigation.NavHostController
import androidx.navigation.compose.NavHost
import androidx.navigation.compose.composable
import androidx.navigation.compose.rememberNavController

/**
 * Placeholder nav graph: every [WorklistDestination] is registered and renders
 * a [PlaceholderScreen]. Real screens replace these one by one in later
 * milestones; the route set stays frozen.
 */
@Composable
fun WorklistNavHost(
    startDestination: WorklistDestination,
    modifier: Modifier = Modifier,
    navController: NavHostController = rememberNavController(),
) {
    NavHost(
        navController = navController,
        startDestination = startDestination.route,
        modifier = modifier,
    ) {
        WorklistDestination.entries.forEach { destination ->
            composable(route = destination.route) {
                PlaceholderScreen(title = destination.title)
            }
        }
    }
}

@Composable
private fun PlaceholderScreen(title: String) {
    Box(
        modifier = Modifier.fillMaxSize(),
        contentAlignment = Alignment.Center,
    ) {
        Text(text = title, style = MaterialTheme.typography.headlineMedium)
    }
}
