package com.example.worklist.ui.screens.stock

import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.PaddingValues
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
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
import com.example.worklist.data.model.Product
import com.example.worklist.ui.viewmodel.StockViewModel
import com.example.worklist.ui.viewmodel.stockViewModelFactory

@androidx.compose.material3.ExperimentalMaterial3Api
@Composable
fun StockScreen(
    viewModel: StockViewModel = viewModel(factory = stockViewModelFactory())
) {
    val outOfStock by viewModel.outOfStock.collectAsState()
    val critical by viewModel.critical.collectAsState()
    val low by viewModel.low.collectAsState()
    val loading by viewModel.loading.collectAsState()

    Scaffold(
        topBar = { TopAppBar(title = { Text("Stock") }) }
    ) { padding ->
        if (loading) {
            Column(
                modifier = Modifier.fillMaxSize(),
                verticalArrangement = Arrangement.Center,
                horizontalAlignment = Alignment.CenterHorizontally
            ) {
                CircularProgressIndicator()
            }
        } else if (outOfStock.isEmpty() && critical.isEmpty() && low.isEmpty()) {
            Column(
                modifier = Modifier.fillMaxSize(),
                verticalArrangement = Arrangement.Center,
                horizontalAlignment = Alignment.CenterHorizontally
            ) {
                Text(
                    text = "All stock healthy.",
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
                if (outOfStock.isNotEmpty()) {
                    item {
                        Text(
                            text = "OUT OF STOCK (${outOfStock.size})",
                            style = MaterialTheme.typography.labelLarge,
                            color = MaterialTheme.colorScheme.error
                        )
                    }
                    items(outOfStock) { StockCard(it, "Out of stock", MaterialTheme.colorScheme.error) }
                }
                if (critical.isNotEmpty()) {
                    item {
                        Text(
                            text = "CRITICAL (${critical.size})",
                            style = MaterialTheme.typography.labelLarge,
                            color = MaterialTheme.colorScheme.tertiary
                        )
                    }
                    items(critical) { StockCard(it, "Critical", MaterialTheme.colorScheme.tertiary) }
                }
                if (low.isNotEmpty()) {
                    item {
                        Text(
                            text = "LOW STOCK (${low.size})",
                            style = MaterialTheme.typography.labelLarge,
                            color = MaterialTheme.colorScheme.primary
                        )
                    }
                    items(low) { StockCard(it, "Low", MaterialTheme.colorScheme.primary) }
                }
            }
        }
    }
}

@Composable
private fun StockCard(product: Product, label: String, color: androidx.compose.ui.graphics.Color) {
    Card(
        modifier = Modifier.fillMaxWidth(),
        colors = CardDefaults.cardColors(containerColor = MaterialTheme.colorScheme.surfaceContainerHighest)
    ) {
        Row(
            modifier = Modifier.padding(16.dp),
            horizontalArrangement = Arrangement.SpaceBetween,
            verticalAlignment = Alignment.CenterVertically
        ) {
            Column(modifier = Modifier.weight(1f)) {
                Text(text = product.name, style = MaterialTheme.typography.titleMedium, fontWeight = FontWeight.Bold)
                Text(
                    text = "${product.stockQuantity} ${product.unit} in stock",
                    style = MaterialTheme.typography.bodySmall,
                    color = MaterialTheme.colorScheme.onSurfaceVariant
                )
            }
            Text(
                text = label.uppercase(),
                style = MaterialTheme.typography.labelSmall,
                color = color
            )
        }
    }
}