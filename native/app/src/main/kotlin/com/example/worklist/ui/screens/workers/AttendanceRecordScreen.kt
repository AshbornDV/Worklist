package com.example.worklist.ui.screens.workers

import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.PaddingValues
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.width
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.outlined.Close
import androidx.compose.material.icons.outlined.Check
import androidx.compose.material.icons.outlined.Person
import androidx.compose.material3.Button
import androidx.compose.material3.Card
import androidx.compose.material3.CardDefaults
import androidx.compose.material3.ExperimentalMaterial3Api
import androidx.compose.material3.Icon
import androidx.compose.material3.IconButton
import androidx.compose.material3.MaterialTheme
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
import androidx.compose.ui.unit.dp
import androidx.lifecycle.viewmodel.compose.viewModel
import com.example.worklist.data.model.Attendance
import com.example.worklist.data.model.Worker
import com.example.worklist.ui.viewmodel.AttendanceViewModel
import com.example.worklist.ui.viewmodel.attendanceViewModelFactory
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
fun AttendanceRecordScreen(
    navController: NavHostController,
    workerId: Int? = null,
    viewModel: AttendanceViewModel = viewModel(factory = attendanceViewModelFactory())
) {
    val snackbarHostState = remember { SnackbarHostState() }
    val scope = rememberCoroutineScope()
    val loading by viewModel.loading.collectAsState()
    val workers by viewModel.workers.collectAsState()
    val selectedDate = remember { SimpleDateFormat("yyyy-MM-dd").format(Date()) }

    var selectedWorkerId by remember { mutableStateOf(workerId ?: 0) }
    var attendanceType by remember { mutableStateOf("full") }

    val isPreSelected = workerId != null

    Scaffold(
        topBar = {
            TopAppBar(
                title = { Text("Record Attendance — $selectedDate") },
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
                                val attendance = Attendance(
                                    id = 0,
                                    companyId = CompanySession.companyId.value,
                                    workerId = selectedWorkerId,
                                    siteId = 0, // TODO: add site picker
                                    date = selectedDate,
                                    type = attendanceType,
                                    checkInTime = "",
                                    checkOutTime = "",
                                    notes = "",
                                    synced = false,
                                    createdAt = "",
                                )
                                viewModel.markAttendance(selectedWorkerId, attendanceType)
                                scope.launch { snackbarHostState.showSnackbar("Attendance recorded") }
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

                SectionCard(title = "Attendance Type") {
                    AttendanceTypeChips(
                        selectedType = attendanceType,
                        onTypeChange = { attendanceType = it }
                    )
                }

                SectionCard(title = "Date") {
                    Text(
                        text = selectedDate,
                        style = MaterialTheme.typography.titleMedium,
                        modifier = Modifier.fillMaxWidth().padding(vertical = 8.dp)
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
private fun AttendanceTypeChips(
    selectedType: String,
    onTypeChange: (String) -> Unit
) {
    val types = listOf(
        Pair("full", "Full Day"),
        Pair("half", "Half Day"),
        Pair("absent", "Absent")
    )
    Row(
        modifier = Modifier.fillMaxWidth(),
        horizontalArrangement = Arrangement.spacedBy(8.dp)
    ) {
        types.forEach { (type, label) ->
            val color = when (type) {
                "full" -> Color(0xFF16A34A)
                "half" -> Color(0xFFF59E0B)
                "absent" -> Color(0xFFDC2626)
                else -> MaterialTheme.colorScheme.primary
            }
            androidx.compose.material3.FilterChip(
                selected = selectedType == type,
                onClick = { onTypeChange(type) },
                label = { Text(label, color = if (selectedType == type) color else MaterialTheme.colorScheme.onSurface) },
                modifier = Modifier.weight(1f),
            )
        }
    }
}