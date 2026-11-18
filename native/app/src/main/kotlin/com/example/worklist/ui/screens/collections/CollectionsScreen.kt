package com.example.worklist.ui.screens.collections

import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.PaddingValues
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.material3.Button
import androidx.compose.material3.Card
import androidx.compose.material3.CardDefaults
import androidx.compose.material3.CircularProgressIndicator
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Scaffold
import androidx.compose.material3.Text
import androidx.compose.material3.TopAppBar
import androidx.compose.runtime.Composable
import androidx.compose.runtime.collectAsState
import androidx.compose.runtime.getValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.lifecycle.viewmodel.compose.viewModel
import com.example.worklist.data.model.Collection
import com.example.worklist.ui.viewmodel.CollectionsViewModel
import com.example.worklist.ui.viewmodel.collectionsViewModelFactory

@androidx.compose.material3.ExperimentalMaterial3Api
@Composable
fun CollectionsScreen(
    viewModel: CollectionsViewModel = viewModel(factory = collectionsViewModelFactory())
) {
    val collections by viewModel.collections.collectAsState()
    val siteNames by viewModel.siteNames.collectAsState()
    val loading by viewModel.loading.collectAsState()

    Scaffold(
        topBar = { TopAppBar(title = { Text("Collections") }) }
    ) { padding ->
        if (loading) {
            Column(
                modifier = Modifier.fillMaxSize(),
                verticalArrangement = Arrangement.Center,
                horizontalAlignment = Alignment.CenterHorizontally
            ) {
                CircularProgressIndicator()
            }
        } else if (collections.isEmpty()) {
            Column(
                modifier = Modifier.fillMaxSize(),
                verticalArrangement = Arrangement.Center,
                horizontalAlignment = Alignment.CenterHorizontally
            ) {
                Text(
                    text = "No collections yet.",
                    style = MaterialTheme.typography.bodyLarge,
                    color = MaterialTheme.colorScheme.onSurfaceVariant
                )
            }
        } else {
            LazyColumn(
                modifier = Modifier.padding(padding),
                contentPadding = PaddingValues(16.dp),
                verticalArrangement = Arrangement.spacedBy(8.dp)
            ) {
                items(collections) { collection ->
                    CollectionCard(
                        collection = collection,
                        siteName = siteNames[collection.siteId] ?: "Site ${collection.siteId}",
                        onMarkPaid = { viewModel.markPaid(collection) }
                    )
                }
            }
        }
    }
}

@Composable
private fun CollectionCard(collection: Collection, siteName: String, onMarkPaid: () -> Unit) {
    Card(
        modifier = Modifier.fillMaxWidth(),
        colors = CardDefaults.cardColors(containerColor = MaterialTheme.colorScheme.surfaceContainerHighest)
    ) {
        Column(modifier = Modifier.padding(16.dp)) {
            Text(
                text = "${collection.customerName} — $siteName",
                style = MaterialTheme.typography.titleMedium,
                fontWeight = FontWeight.Bold
            )
            Text(
                text = "Amount: Rs. ${"%.0f".format(collection.amount)} • Paid: Rs. ${"%.0f".format(collection.paidAmount)}",
                style = MaterialTheme.typography.bodyMedium,
                color = MaterialTheme.colorScheme.onSurfaceVariant
            )
            if (collection.status != "paid") {
                Text(
                    text = "Status: ${collection.status.uppercase()}",
                    style = MaterialTheme.typography.labelSmall,
                    color = if (collection.status == "overdue") MaterialTheme.colorScheme.error else MaterialTheme.colorScheme.tertiary
                )
                Button(onClick = onMarkPaid, modifier = Modifier.padding(top = 8.dp)) {
                    Text("Mark as Paid")
                }
            } else {
                Text(
                    text = "PAID",
                    style = MaterialTheme.typography.labelSmall,
                    color = MaterialTheme.colorScheme.primary
                )
            }
        }
    }
}