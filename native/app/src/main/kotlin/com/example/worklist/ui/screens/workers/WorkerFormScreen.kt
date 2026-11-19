package com.example.worklist.ui.screens.workers

import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.PaddingValues
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.text.KeyboardOptions
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.outlined.Close
import androidx.compose.material.icons.outlined.Check
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
import com.example.worklist.data.model.Worker
import com.example.worklist.ui.viewmodel.WorkersViewModel
import com.example.worklist.ui.viewmodel.workersViewModelFactory
import androidx.navigation.NavHostController
import androidx.compose.runtime.collectAsState
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.verticalScroll
import kotlinx.coroutines.launch
import androidx.compose.runtime.rememberCoroutineScope

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun WorkerFormScreen(
    navController: NavHostController,
    workerId: Int? = null,
    viewModel: WorkersViewModel = viewModel(factory = workersViewModelFactory())
) {
    val snackbarHostState = remember { SnackbarHostState() }
    val scope = rememberCoroutineScope()
    val loading by viewModel.loading.collectAsState()

    var fullName by remember { mutableStateOf("") }
    var phone by remember { mutableStateOf("") }
    var email by remember { mutableStateOf("") }
    var address by remember { mutableStateOf("") }
    var role by remember { mutableStateOf("worker") }
    var skillLevel by remember { mutableStateOf("skilled") }
    var dailyWage by remember { mutableStateOf("") }
    var joinDate by remember { mutableStateOf("") }
    var status by remember { mutableStateOf("active") }

    val isEditing = workerId != null

    Scaffold(
        topBar = {
            TopAppBar(
                title = { Text(if (isEditing) "Edit Worker" else "New Worker") },
                navigationIcon = {
                    IconButton(onClick = { navController.popBackStack() }) {
                        Icon(imageVector = Icons.Outlined.Close, contentDescription = "Close")
                    }
                },
                actions = {
                    if (!loading) {
                        Button(
                            onClick = {
                                val worker = Worker(
                                    id = workerId ?: 0,
                                    fullName = fullName,
                                    phone = phone,
                                    email = email,
                                    address = address,
                                    role = role,
                                    skillLevel = skillLevel,
                                    dailyWage = dailyWage.toDoubleOrNull() ?: 0.0,
                                    joinDate = joinDate,
                                    status = status,
                                )
                                if (isEditing) {
                                    viewModel.update(worker)
                                } else {
                                    viewModel.insert(worker)
                                }
                                scope.launch { snackbarHostState.showSnackbar("Worker saved") }
                                navController.popBackStack()
                            },
                            modifier = Modifier.padding(end = 16.dp)
                        ) {
                            Icon(imageVector = Icons.Outlined.Check, contentDescription = "Save")
                            Text("Save")
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
        androidx.compose.foundation.layout.Column(
            modifier = Modifier
                .fillMaxSize()
                .padding(padding)
                .verticalScroll(rememberScrollState())
                .padding(16.dp),
            verticalArrangement = Arrangement.spacedBy(16.dp)
        ) {
            SectionCard(title = "Personal Information") {
                FormField(label = "Full Name *", value = fullName, onValueChange = { fullName = it }, placeholder = "Enter full name", keyboardType = KeyboardType.Text)
                FormField(label = "Phone", value = phone, onValueChange = { phone = it }, placeholder = "Phone number", keyboardType = KeyboardType.Phone)
                FormField(label = "Email", value = email, onValueChange = { email = it }, placeholder = "Email address", keyboardType = KeyboardType.Text)
                FormField(label = "Address", value = address, onValueChange = { address = it }, placeholder = "Address", keyboardType = KeyboardType.Text)
            }

            SectionCard(title = "Role & Skills") {
                FormField(
                    label = "Role",
                    value = role,
                    onValueChange = { role = it },
                    placeholder = "Role",
                    keyboardType = KeyboardType.Text
                )
                FormField(
                    label = "Skill Level",
                    value = skillLevel,
                    onValueChange = { skillLevel = it },
                    placeholder = "Skill Level",
                    keyboardType = KeyboardType.Text
                )
            }

            SectionCard(title = "Employment Details") {
                Row(horizontalArrangement = Arrangement.spacedBy(8.dp)) {
                    FormField(label = "Daily Wage (Rs)", value = dailyWage, onValueChange = { dailyWage = it }, placeholder = "0.00", keyboardType = KeyboardType.Number, modifier = Modifier.weight(1f))
                    FormField(label = "Join Date", value = joinDate, onValueChange = { joinDate = it }, placeholder = "YYYY-MM-DD", keyboardType = KeyboardType.Text, modifier = Modifier.weight(1f))
                }
                FormField(
                    label = "Status",
                    value = status,
                    onValueChange = { status = it },
                    placeholder = "Status",
                    keyboardType = KeyboardType.Text
                )
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