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
import com.example.worklist.ui.screens.account.AccountScreen
import com.example.worklist.ui.screens.analytics.AnalyticsScreen
import com.example.worklist.ui.screens.calendar.CalendarScreen
import com.example.worklist.ui.screens.collections.CollectionsScreen
import com.example.worklist.ui.screens.dashboard.DashboardScreen
import com.example.worklist.ui.screens.notifications.NotificationsScreen
import com.example.worklist.ui.screens.payroll.PayrollScreen
import com.example.worklist.ui.screens.products.ProductsScreen
import com.example.worklist.ui.screens.services.ServicesScreen
import com.example.worklist.ui.screens.sites.SitesScreen
import com.example.worklist.ui.screens.stock.StockScreen
import com.example.worklist.ui.screens.workers.AttendanceScreen
import com.example.worklist.ui.screens.workers.WorkersScreen

/**
 * Placeholder nav graph: every [WorklistDestination] is registered and renders
 * a [PlaceholderScreen]. Real screens replace these one by one in later
 * milestones; the route set stays frozen.
 */
@androidx.compose.material3.ExperimentalMaterial3Api
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
                when (destination) {
                    is WorklistDestination.Home -> DashboardScreen()
                    is WorklistDestination.Sites -> SitesScreen()
                    is WorklistDestination.Workers -> WorkersScreen()
                    is WorklistDestination.Attendance -> AttendanceScreen()
                    is WorklistDestination.Payroll -> PayrollScreen()
                    is WorklistDestination.Products -> ProductsScreen()
                    is WorklistDestination.Stock -> StockScreen()
                    is WorklistDestination.Services -> ServicesScreen()
                    is WorklistDestination.Collections -> CollectionsScreen()
                    is WorklistDestination.Calendar -> CalendarScreen()
                    is WorklistDestination.Analytics -> AnalyticsScreen()
                    is WorklistDestination.Notifications -> NotificationsScreen()
                    is WorklistDestination.Account -> AccountScreen()
                    else -> PlaceholderScreen(title = destination.title)
                }
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