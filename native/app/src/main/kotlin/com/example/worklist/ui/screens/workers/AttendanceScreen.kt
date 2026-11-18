package com.example.worklist.ui.screens.workers

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
import androidx.compose.material3.FilterChip
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
import com.example.worklist.data.model.Worker
import com.example.worklist.ui.viewmodel.AttendanceViewModel
import com.example.worklist.ui.viewmodel.attendanceViewModelFactory

@androidx.compose.material3.ExperimentalMaterial3Api
@Composable
fun AttendanceScreen(
    viewModel: AttendanceViewModel = viewModel(factory = attendanceViewModelFactory())
) {
    val workers by viewModel.workers.collectAsState()
    val attendance by viewModel.attendance.collectAsState()
    val selectedDate by viewModel.selectedDate.collectAsState()
    val loading by viewModel.loading.collectAsState()

    Scaffold(
        topBar = {
            TopAppBar(title = { Text("Attendance — $selectedDate") })
        }
    ) { padding ->
        if (loading) {
            Column(
                modifier = Modifier.fillMaxSize(),
                verticalArrangement = Arrangement.Center,
                horizontalAlignment = Alignment.CenterHorizontally
            ) {
                CircularProgressIndicator()
            }
        } else if (workers.isEmpty()) {
            Column(
                modifier = Modifier.fillMaxSize(),
                verticalArrangement = Arrangement.Center,
                horizontalAlignment = Alignment.CenterHorizontally
            ) {
                Text(
                    text = "No workers to mark attendance for.",
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
                items(workers) { worker ->
                    WorkerAttendanceRow(
                        worker = worker,
                        currentType = viewModel.typeForWorker(worker.id),
                        onSelect = { type -> viewModel.markAttendance(worker.id, type) }
                    )
                }
            }
        }
    }
}

@Composable
private fun WorkerAttendanceRow(
    worker: Worker,
    currentType: String?,
    onSelect: (String) -> Unit
) {
    Card(
        modifier = Modifier.fillMaxWidth(),
        colors = CardDefaults.cardColors(containerColor = MaterialTheme.colorScheme.surfaceContainerHighest)
    ) {
        Column(modifier = Modifier.padding(16.dp)) {
            Text(
                text = worker.fullName,
                style = MaterialTheme.typography.titleMedium,
                fontWeight = FontWeight.Bold
            )
            Row(
                modifier = Modifier.padding(top = 8.dp),
                horizontalArrangement = Arrangement.spacedBy(8.dp)
            ) {
                StatusFilterChip(label = "Full", type = "full", selected = currentType == "full", onSelect = onSelect)
                StatusFilterChip(label = "Half", type = "half", selected = currentType == "half", onSelect = onSelect)
                StatusFilterChip(label = "Absent", type = "absent", selected = currentType == "absent", onSelect = onSelect)
            }
        }
    }
}

@Composable
private fun StatusFilterChip(
    label: String,
    type: String,
    selected: Boolean,
    onSelect: (String) -> Unit
) {
    FilterChip(
        selected = selected,
        onClick = { onSelect(type) },
        label = { Text(label) }
    )
}