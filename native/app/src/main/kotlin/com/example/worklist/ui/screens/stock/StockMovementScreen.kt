package com.example.worklist.ui.screens.stock

import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.PaddingValues
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.text.KeyboardOptions
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.outlined.Close
import androidx.compose.material.icons.outlined.Check
import androidx.compose.material.icons.outlined.Inventory2
import androidx.compose.material3.Button
import androidx.compose.material3.Card
import androidx.compose.material3.CardDefaults
import androidx.compose.material3.ExperimentalMaterial3Api
import androidx.compose.material3.Icon
import androidx.compose.material3.IconButton
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.OutlinedTextField
import androidx.compose.material3.Scaffold
import androidx.compose.material3.Snackbar
import androidx.compose.material3.SnackbarHost
import androidx.compose.material3.SnackbarHostState
import androidx.compose.material3.Text
import androidx.compose.material3.TopAppBar
import androidx.compose.material3.TopAppBarDefaults
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.input.KeyboardType
import androidx.compose.ui.unit.dp
import androidx.lifecycle.viewmodel.compose.viewModel
import com.example.worklist.data.model.StockMovement
import com.example.worklist.data.model.Product
import com.example.worklist.ui.viewmodel.StockViewModel
import com.example.worklist.ui.viewmodel.stockViewModelFactory
import androidx.navigation.NavHostController
import androidx.compose.runtime.collectAsState
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.verticalScroll
import com.example.worklist.data.session.CompanySession
import com.example.worklist.ui.screens.shared.EmptyState
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import kotlinx.coroutines.launch
import androidx.compose.runtime.rememberCoroutineScope

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun StockMovementScreen(
    navController: NavHostController,
    productId: Int? = null,
    viewModel: StockViewModel = viewModel(factory = stockViewModelFactory())
) {
    val snackbarHostState = remember { SnackbarHostState() }
    val scope = rememberCoroutineScope()
    val loading by viewModel.loading.collectAsState()
    val products by viewModel.allProducts.collectAsState()

    var selectedProductId by remember { mutableStateOf(productId ?: 0) }
    var quantity by remember { mutableStateOf("") }
    var unitCost by remember { mutableStateOf("") }
    var referenceNumber by remember { mutableStateOf("") }
    var notes by remember { mutableStateOf("") }
    var movementType by remember { mutableStateOf(StockMovement.TYPE_SHIP) }
    var movementDate by remember { mutableStateOf(java.text.SimpleDateFormat("yyyy-MM-dd").format(java.util.Date())) }

    val isEditing = productId != null

    Scaffold(
        topBar = {
            TopAppBar(
                title = { Text("Record Stock Movement") },
                navigationIcon = {
                    IconButton(onClick = { navController.popBackStack() }) {
                        Icon(imageVector = Icons.Outlined.Close, contentDescription = "Close")
                    }
                },
                actions = {
                    if (!loading) {
                        Button(
                            onClick = {
                                if (selectedProductId == 0) {
                                    scope.launch { snackbarHostState.showSnackbar("Select a product") }
                                    return@Button
                                }
                                val qty = quantity.toDoubleOrNull() ?: 0.0
                                if (qty <= 0) {
                                    scope.launch { snackbarHostState.showSnackbar("Enter valid quantity") }
                                    return@Button
                                }
                                val cost = unitCost.toDoubleOrNull() ?: 0.0
                                val movement = StockMovement(
                                    id = 0,
                                    companyId = CompanySession.companyId.value,
                                    productId = selectedProductId,
                                    siteId = 0,
                                    type = movementType,
                                    quantity = if (movementType == StockMovement.TYPE_USAGE || movementType == StockMovement.TYPE_RETURN) -qty else qty,
                                    unitCost = cost,
                                    totalCost = qty * cost,
                                    referenceNumber = referenceNumber,
                                    notes = notes,
                                    movementDate = movementDate,
                                    createdAt = "",
                                )
                                scope.launch { viewModel.insertStockMovement(movement) }
                                scope.launch { snackbarHostState.showSnackbar("Stock movement recorded") }
                                navController.popBackStack()
                            },
                            modifier = Modifier.padding(end = 16.dp)
                        ) {
                            Icon(imageVector = Icons.Outlined.Check, contentDescription = "Save")
                            Text("Record")
                        }
                    }
                },
                colors = TopAppBarDefaults.topAppBarColors(
                    containerColor = MaterialTheme.colorScheme.primaryContainer
                )
            )
        },
        snackbarHost = { SnackbarHost(snackbarHostState) }
    ) { padding ->
        if (products.isEmpty()) {
            EmptyState(
                message = "No products available. Add products first."
            )
        } else {
            androidx.compose.foundation.layout.Column(
                modifier = Modifier
                    .fillMaxSize()
                    .padding(padding)
                    .verticalScroll(rememberScrollState())
                    .padding(16.dp),
                verticalArrangement = Arrangement.spacedBy(16.dp)
            ) {
                SectionCard(title = "Product") {
                    ProductDropdown(
                        products = products,
                        selectedId = selectedProductId,
                        onSelect = { selectedProductId = it }
                    )
                }

                SectionCard(title = "Movement Type") {
                    MovementTypeChips(
                        selectedType = movementType,
                        onTypeChange = { movementType = it }
                    )
                }

                SectionCard(title = "Quantity & Cost") {
                    Row(horizontalArrangement = Arrangement.spacedBy(8.dp)) {
                        FormField(
                            label = "Quantity",
                            value = quantity,
                            onValueChange = { quantity = it },
                            placeholder = "0",
                            keyboardType = KeyboardType.Number,
                            modifier = Modifier.weight(1f)
                        )
                        FormField(
                            label = "Unit Cost (Rs)",
                            value = unitCost,
                            onValueChange = { unitCost = it },
                            placeholder = "0.00",
                            keyboardType = KeyboardType.Number,
                            modifier = Modifier.weight(1f)
                        )
                    }
                }

                SectionCard(title = "Details") {
                    FormField(
                        label = "Reference Number",
                        value = referenceNumber,
                        onValueChange = { referenceNumber = it },
                        placeholder = "PO/Invoice #",
                        keyboardType = KeyboardType.Text
                    )
                    FormField(
                        label = "Date",
                        value = movementDate,
                        onValueChange = { movementDate = it },
                        placeholder = "YYYY-MM-DD",
                        keyboardType = KeyboardType.Text
                    )
                    FormField(
                        label = "Notes",
                        value = notes,
                        onValueChange = { notes = it },
                        placeholder = "Notes",
                        keyboardType = KeyboardType.Text,
                        modifier = Modifier.height(80.dp)
                    )
                }
            }
        }
    }
}

@Composable
private fun SectionCard(title: String, content: @Composable () -> Unit) {
    Card(
        modifier = Modifier.fillMaxWidth(),
        colors = CardDefaults.cardColors(containerColor = MaterialTheme.colorScheme.surfaceContainerHigh)
    ) {
        Column(modifier = Modifier.padding(16.dp), verticalArrangement = Arrangement.spacedBy(12.dp)) {
            Text(text = title, style = MaterialTheme.typography.titleMedium, fontWeight = FontWeight.Bold)
            content()
        }
    }
}

@Composable
private fun FormField(
    label: String,
    value: String,
    onValueChange: (String) -> Unit,
    placeholder: String = "",
    modifier: Modifier = Modifier,
    keyboardType: KeyboardType = KeyboardType.Text,
    keyboardOptions: KeyboardOptions = KeyboardOptions(keyboardType = keyboardType)
) {
    Column(modifier = modifier.fillMaxWidth(), verticalArrangement = Arrangement.spacedBy(4.dp)) {
        Text(text = label, style = MaterialTheme.typography.labelMedium, color = MaterialTheme.colorScheme.onSurfaceVariant)
        OutlinedTextField(
            value = value,
            onValueChange = onValueChange,
            label = { Text(placeholder) },
            keyboardOptions = keyboardOptions,
            modifier = Modifier.fillMaxWidth(),
            singleLine = true,
        )
    }
}

@Composable
private fun ProductDropdown(
    products: List<Product>,
    selectedId: Int,
    onSelect: (Int) -> Unit
) {
    val selectedProduct = products.find { it.id == selectedId }
    androidx.compose.material3.OutlinedTextField(
        value = selectedProduct?.name ?: "Select product",
        onValueChange = {},
        readOnly = true,
        label = { Text("Select product") },
        modifier = Modifier.fillMaxWidth(),
        trailingIcon = {
            androidx.compose.material3.DropdownMenu(
                expanded = true,
                onDismissRequest = {},
            ) {
                products.forEach { product ->
                    androidx.compose.material3.DropdownMenuItem(
                        onClick = { onSelect(product.id) },
                        text = { Text(text = product.name) }
                    )
                }
            }
        }
    )
}

@Composable
private fun MovementTypeChips(
    selectedType: String,
    onTypeChange: (String) -> Unit
) {
    val types = listOf(
        Pair(StockMovement.TYPE_SHIP, "Shipment In"),
        Pair(StockMovement.TYPE_USAGE, "Usage Out"),
        Pair(StockMovement.TYPE_ADJUST, "Adjustment"),
        Pair(StockMovement.TYPE_RETURN, "Return")
    )
    Row(
        modifier = Modifier.fillMaxWidth(),
        horizontalArrangement = Arrangement.spacedBy(8.dp)
    ) {
        types.forEach { (type, label) ->
            androidx.compose.material3.FilterChip(
                selected = selectedType == type,
                onClick = { onTypeChange(type) },
                label = { Text(label) },
                modifier = Modifier.weight(1f)
            )
        }
    }
}