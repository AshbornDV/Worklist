package com.example.worklist.ui.screens.payroll

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
import androidx.compose.material.icons.outlined.Payments
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
import com.example.worklist.data.model.Payment
import com.example.worklist.data.model.Worker
import com.example.worklist.data.model.Site
import com.example.worklist.ui.viewmodel.PayrollViewModel
import com.example.worklist.ui.viewmodel.payrollViewModelFactory
import androidx.navigation.NavHostController
import androidx.compose.runtime.collectAsState
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.verticalScroll
import com.example.worklist.data.session.CompanySession
import com.example.worklist.ui.screens.shared.EmptyState
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import java.text.SimpleDateFormat
import java.util.Date
import kotlinx.coroutines.launch
import androidx.compose.runtime.rememberCoroutineScope

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun PaymentRecordScreen(
    navController: NavHostController,
    workerId: Int? = null,
    viewModel: PayrollViewModel = viewModel(factory = payrollViewModelFactory())
) {
    val snackbarHostState = remember { SnackbarHostState() }
    val scope = rememberCoroutineScope()
    val loading by viewModel.loading.collectAsState()
    val workers by viewModel.workers.collectAsState()
    val sites by viewModel.sites.collectAsState()
    val selectedDate = remember { SimpleDateFormat("yyyy-MM-dd").format(Date()) }

    var selectedWorkerId by remember { mutableStateOf(workerId ?: 0) }
    var selectedSiteId by remember { mutableStateOf(0) }
    var amount by remember { mutableStateOf("") }
    var rateBasis by remember { mutableStateOf(Payment.RATE_BASIS_DAILY) }
    var dailyRate by remember { mutableStateOf("") }
    var jobRate by remember { mutableStateOf("") }
    var daysOrJobs by remember { mutableStateOf("") }
    var paymentMethod by remember { mutableStateOf("cash") }
    var referenceNumber by remember { mutableStateOf("") }
    var notes by remember { mutableStateOf("") }

    val isPreSelected = workerId != null

    Scaffold(
        topBar = {
            TopAppBar(
                title = { Text("Record Payment — $selectedDate") },
                navigationIcon = {
                    IconButton(onClick = { navController.popBackStack() }) {
                        Icon(imageVector = Icons.Outlined.Close, contentDescription = "Close")
                    }
                },
                actions = {
                    if (!loading) {
                        Button(
                            onClick = {
                                if (selectedWorkerId == 0) {
                                    scope.launch { snackbarHostState.showSnackbar("Select a worker") }
                                    return@Button
                                }
                                val amt = amount.toDoubleOrNull() ?: 0.0
                                if (amt <= 0) {
                                    scope.launch { snackbarHostState.showSnackbar("Enter valid amount") }
                                    return@Button
                                }
                                val payment = Payment(
                                    id = 0,
                                    companyId = CompanySession.companyId.value,
                                    workerId = selectedWorkerId,
                                    siteId = selectedSiteId,
                                    payrollRecordId = 0,
                                    amount = amt,
                                    rateBasis = rateBasis,
                                    dailyRate = dailyRate.toDoubleOrNull() ?: 0.0,
                                    jobRate = jobRate.toDoubleOrNull() ?: 0.0,
                                    daysOrJobs = daysOrJobs.toDoubleOrNull() ?: 0.0,
                                    paidDate = selectedDate,
                                    paymentMethod = paymentMethod,
                                    referenceNumber = referenceNumber,
                                    notes = notes,
                                    createdAt = "",
                                )
                                scope.launch { viewModel.insertPayment(payment) }
                                scope.launch { snackbarHostState.showSnackbar("Payment recorded") }
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
        if (workers.isEmpty()) {
            EmptyState(
                message = "No workers available. Add workers first."
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
                SectionCard(title = "Worker") {
                    if (!isPreSelected) {
                        WorkerDropdown(
                            workers = workers,
                            selectedId = selectedWorkerId,
                            onSelect = { selectedWorkerId = it }
                        )
                    } else {
                        val worker = workers.find { it.id == selectedWorkerId }
                        Text(
                            text = worker?.fullName ?: "Unknown Worker",
                            style = MaterialTheme.typography.titleMedium,
                            modifier = Modifier.fillMaxWidth().padding(vertical = 8.dp)
                        )
                    }
                }

                SectionCard(title = "Site (Optional)") {
                    SiteDropdown(
                        sites = sites,
                        selectedId = selectedSiteId,
                        onSelect = { selectedSiteId = it }
                    )
                }

                SectionCard(title = "Rate Basis") {
                    RateBasisChips(
                        selectedBasis = rateBasis,
                        onBasisChange = { rateBasis = it }
                    )
                }

                SectionCard(title = "Amount Details") {
                    FormField(
                        label = "Amount (Rs)",
                        value = amount,
                        onValueChange = { amount = it },
                        placeholder = "0.00",
                        keyboardType = KeyboardType.Number
                    )
                    if (rateBasis == Payment.RATE_BASIS_DAILY) {
                        Row(horizontalArrangement = Arrangement.spacedBy(8.dp)) {
                            FormField(
                                label = "Daily Rate (Rs)",
                                value = dailyRate,
                                onValueChange = { dailyRate = it },
                                placeholder = "0.00",
                                keyboardType = KeyboardType.Number,
                                modifier = Modifier.weight(1f)
                            )
                            FormField(
                                label = "Days",
                                value = daysOrJobs,
                                onValueChange = { daysOrJobs = it },
                                placeholder = "0",
                                keyboardType = KeyboardType.Number,
                                modifier = Modifier.weight(1f)
                            )
                        }
                    } else {
                        Row(horizontalArrangement = Arrangement.spacedBy(8.dp)) {
                            FormField(
                                label = "Job Rate (Rs)",
                                value = jobRate,
                                onValueChange = { jobRate = it },
                                placeholder = "0.00",
                                keyboardType = KeyboardType.Number,
                                modifier = Modifier.weight(1f)
                            )
                            FormField(
                                label = "Jobs",
                                value = daysOrJobs,
                                onValueChange = { daysOrJobs = it },
                                placeholder = "0",
                                keyboardType = KeyboardType.Number,
                                modifier = Modifier.weight(1f)
                            )
                        }
                    }
                }

                SectionCard(title = "Payment Details") {
                    FormField(
                        label = "Payment Method",
                        value = paymentMethod,
                        onValueChange = { paymentMethod = it },
                        placeholder = "cash / bank / upi",
                        keyboardType = KeyboardType.Text
                    )
                    FormField(
                        label = "Reference Number",
                        value = referenceNumber,
                        onValueChange = { referenceNumber = it },
                        placeholder = "Transaction ID / Cheque #",
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
private fun WorkerDropdown(
    workers: List<Worker>,
    selectedId: Int,
    onSelect: (Int) -> Unit
) {
    val selectedWorker = workers.find { it.id == selectedId }
    androidx.compose.material3.OutlinedTextField(
        value = selectedWorker?.fullName ?: "Select worker",
        onValueChange = {},
        readOnly = true,
        label = { Text("Select worker") },
        modifier = Modifier.fillMaxWidth(),
        trailingIcon = {
            androidx.compose.material3.DropdownMenu(
                expanded = true,
                onDismissRequest = {},
            ) {
                workers.forEach { worker ->
                    androidx.compose.material3.DropdownMenuItem(
                        onClick = { onSelect(worker.id) },
                        text = { Text(text = worker.fullName) }
                    )
                }
            }
        }
    )
}

@Composable
private fun SiteDropdown(
    sites: List<Site>,
    selectedId: Int,
    onSelect: (Int) -> Unit
) {
    val selectedSite = sites.find { it.id == selectedId }
    androidx.compose.material3.OutlinedTextField(
        value = selectedSite?.name ?: "Select site (optional)",
        onValueChange = {},
        readOnly = true,
        label = { Text("Select site (optional)") },
        modifier = Modifier.fillMaxWidth(),
        trailingIcon = {
            androidx.compose.material3.DropdownMenu(
                expanded = true,
                onDismissRequest = {},
            ) {
                androidx.compose.material3.DropdownMenuItem(
                    onClick = { onSelect(0) },
                    text = { Text("None") }
                )
                sites.forEach { site ->
                    androidx.compose.material3.DropdownMenuItem(
                        onClick = { onSelect(site.id) },
                        text = { Text(text = site.name) }
                    )
                }
            }
        }
    )
}

@Composable
private fun RateBasisChips(
    selectedBasis: String,
    onBasisChange: (String) -> Unit
) {
    val types = listOf(
        Pair(Payment.RATE_BASIS_DAILY, "Daily Rate"),
        Pair(Payment.RATE_BASIS_JOB, "Job Rate")
    )
    Row(
        modifier = Modifier.fillMaxWidth(),
        horizontalArrangement = Arrangement.spacedBy(8.dp)
    ) {
        types.forEach { (basis, label) ->
            androidx.compose.material3.FilterChip(
                selected = selectedBasis == basis,
                onClick = { onBasisChange(basis) },
                label = { Text(label) },
                modifier = Modifier.weight(1f),
            )
        }
    }
}