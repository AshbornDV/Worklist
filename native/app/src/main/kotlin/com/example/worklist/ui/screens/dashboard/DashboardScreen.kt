package com.example.worklist.ui.screens.dashboard

import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.PaddingValues
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.outlined.LocationCity
import androidx.compose.material.icons.outlined.Person
import androidx.compose.material.icons.outlined.Payments
import androidx.compose.material.icons.outlined.Inventory2
import androidx.compose.material3.Card
import androidx.compose.material3.CardDefaults
import androidx.compose.material3.CircularProgressIndicator
import androidx.compose.material3.Icon
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Scaffold
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.collectAsState
import androidx.compose.runtime.getValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp
import androidx.lifecycle.viewmodel.compose.viewModel
import androidx.navigation.NavHostController
import com.example.worklist.data.model.Product
import com.example.worklist.ui.navigation.WorklistDestination
import com.example.worklist.ui.viewmodel.DashboardStats
import com.example.worklist.ui.viewmodel.DashboardViewModel
import com.example.worklist.ui.viewmodel.dashboardViewModelFactory

@Composable
fun DashboardScreen(
    navController: NavHostController,
    viewModel: DashboardViewModel = viewModel(factory = dashboardViewModelFactory())
) {
    val stats by viewModel.stats.collectAsState()
    val loading by viewModel.loading.collectAsState()

    Scaffold(
        topBar = {
            Column(modifier = Modifier.padding(horizontal = 16.dp, vertical = 8.dp)) {
                Text(
                    text = "Good Morning 👋",
                    style = MaterialTheme.typography.headlineSmall,
                    fontWeight = FontWeight.Bold
                )
                Spacer(modifier = Modifier.height(4.dp))
                Text(
                    text = "Here's what's happening on your projects today.",
                    style = MaterialTheme.typography.bodyMedium,
                    color = MaterialTheme.colorScheme.onSurfaceVariant
                )
            }
        }
    ) { padding ->
        if (loading) {
            Row(
                modifier = Modifier.fillMaxSize(),
                horizontalArrangement = Arrangement.Center,
                verticalAlignment = Alignment.CenterVertically
            ) {
                CircularProgressIndicator()
            }
        } else {
            LazyColumn(
                modifier = Modifier
                    .fillMaxSize()
                    .padding(padding),
                contentPadding = PaddingValues(16.dp),
                verticalArrangement = Arrangement.spacedBy(16.dp)
            ) {
                item { StatsGrid(stats = stats, navController = navController) }
                item { StockAlertsCard(stats = stats, products = emptyList()) }
                item { ActivityFeed(emptyList()) }
            }
        }
    }
}

@Composable
private fun StatsGrid(stats: DashboardStats, navController: NavHostController) {
    Column(verticalArrangement = Arrangement.spacedBy(8.dp)) {
        // Row 1: 2 cards
        Row(horizontalArrangement = Arrangement.spacedBy(8.dp)) {
            StatCard(label = "Active Sites", value = "${stats.activeSites}",
                icon = Icons.Outlined.LocationCity, color = Color(0xFF2563EB),
                onClick = { navController.navigate(WorklistDestination.Sites.route) })
            StatCard(label = "Total Workers", value = "${stats.activeWorkers}",
                icon = Icons.Outlined.Person, color = Color(0xFF16A34A),
                onClick = { navController.navigate(WorklistDestination.Workers.route) })
        }
        // Row 2: 2 cards
        Row(horizontalArrangement = Arrangement.spacedBy(8.dp)) {
            StatCard(label = "Present Today", value = "${stats.workersPresentToday}",
                icon = Icons.Outlined.Person, color = Color(0xFF0D9488),
                onClick = { navController.navigate(WorklistDestination.Attendance.route) })
            StatCard(label = "Absent Today", value = "${stats.workersAbsentToday}",
                icon = Icons.Outlined.Inventory2, color = Color(0xFFDC2626),
                onClick = {})
        }
        // Row 3: 2 cards
        Row(horizontalArrangement = Arrangement.spacedBy(8.dp)) {
            StatCard(label = "Total Products", value = "${stats.totalProducts}",
                icon = Icons.Outlined.Inventory2, color = Color(0xFF7C3AED),
                onClick = { navController.navigate(WorklistDestination.Products.route) })
            StatCard(label = "Pending Payments", value = "Rs. ${"%.0f".format(stats.pendingPayments)}",
                icon = Icons.Outlined.Payments, color = Color(0xFFF59E0B),
                onClick = { navController.navigate(WorklistDestination.Collections.route) })
        }
    }
}

@Composable
private fun StatCard(
    label: String,
    value: String,
    icon: androidx.compose.ui.graphics.vector.ImageVector,
    color: Color,
    onClick: () -> Unit = {}
) {
    Card(
        modifier = Modifier
            .fillMaxWidth()
            .height(80.dp),
        colors = CardDefaults.cardColors(containerColor = MaterialTheme.colorScheme.surfaceContainerHighest),
        onClick = onClick
    ) {
        Row(
            modifier = Modifier.padding(12.dp),
            verticalAlignment = Alignment.CenterVertically
        ) {
            Icon(imageVector = icon, contentDescription = null, tint = color, modifier = Modifier.size(24.dp))
            Spacer(modifier = Modifier.padding(start = 8.dp))
            Column {
                Text(text = label, style = MaterialTheme.typography.labelSmall, color = MaterialTheme.colorScheme.onSurfaceVariant)
                Text(text = value, style = MaterialTheme.typography.titleLarge, fontWeight = FontWeight.Bold)
            }
        }
    }
}

@Composable
private fun StockAlertsCard(stats: DashboardStats, products: List<Product>) {
    val total = stats.outOfStock + stats.criticalStock + stats.lowStock
    val cs = MaterialTheme.colorScheme

    Card(colors = CardDefaults.cardColors(containerColor = cs.surfaceContainerHighest)) {
        Column(modifier = Modifier.padding(16.dp)) {
            if (total > 0) {
                Text(text = "$total product(s) need attention", style = MaterialTheme.typography.titleMedium, fontWeight = FontWeight.Bold, color = cs.error)
                Text(text = "Out of stock: ${stats.outOfStock} • Critical: ${stats.criticalStock} • Low: ${stats.lowStock}", style = MaterialTheme.typography.bodySmall, color = cs.onSurfaceVariant)
            } else {
                Text(text = "All stock healthy", style = MaterialTheme.typography.titleMedium, color = cs.primary)
            }
        }
    }
}

@Composable
private fun ActivityFeed(activity: List<Any>) {
    Text(
        text = "No recent activity",
        style = MaterialTheme.typography.bodyMedium,
        textAlign = TextAlign.Center,
        modifier = Modifier.fillMaxWidth().padding(16.dp),
        color = MaterialTheme.colorScheme.onSurfaceVariant
    )
}