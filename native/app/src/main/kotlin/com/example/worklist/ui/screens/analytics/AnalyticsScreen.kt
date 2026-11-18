package com.example.worklist.ui.screens.analytics

import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.padding
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Scaffold
import androidx.compose.material3.Text
import androidx.compose.material3.TopAppBar
import androidx.compose.runtime.Composable
import androidx.compose.runtime.collectAsState
import androidx.compose.runtime.getValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp
import androidx.lifecycle.viewmodel.compose.viewModel
import com.example.worklist.ui.viewmodel.DashboardViewModel
import com.example.worklist.ui.viewmodel.dashboardViewModelFactory

@androidx.compose.material3.ExperimentalMaterial3Api
@Composable
fun AnalyticsScreen(
    viewModel: DashboardViewModel = viewModel(factory = dashboardViewModelFactory())
) {
    val stats by viewModel.stats.collectAsState()

    Scaffold(
        topBar = { TopAppBar(title = { Text("Analytics") }) }
    ) { padding ->
        Column(
            modifier = Modifier
                .fillMaxSize()
                .padding(padding)
                .padding(24.dp),
            horizontalAlignment = Alignment.CenterHorizontally,
            verticalArrangement = Arrangement.spacedBy(16.dp)
        ) {
            MetricRow(label = "Active Sites", value = "${stats.activeSites}")
            MetricRow(label = "Completed Sites", value = "${stats.completedSites}")
            MetricRow(label = "Active Workers", value = "${stats.activeWorkers}")
            MetricRow(label = "Workers Present Today", value = "${stats.workersPresentToday}")
            MetricRow(label = "Total Products", value = "${stats.totalProducts}")
            MetricRow(label = "Pending Payments", value = "Rs. ${"%.0f".format(stats.pendingPayments)}")
        }
    }
}

@Composable
private fun MetricRow(label: String, value: String) {
    Column {
        Text(
            text = label,
            style = MaterialTheme.typography.bodyMedium,
            color = MaterialTheme.colorScheme.onSurfaceVariant
        )
        Text(
            text = value,
            style = MaterialTheme.typography.titleLarge,
            fontWeight = androidx.compose.ui.text.font.FontWeight.Bold
        )
    }
}