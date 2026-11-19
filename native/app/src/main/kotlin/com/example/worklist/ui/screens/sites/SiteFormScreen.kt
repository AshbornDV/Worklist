package com.example.worklist.ui.screens.sites

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
import com.example.worklist.data.model.Site
import com.example.worklist.ui.viewmodel.SitesViewModel
import com.example.worklist.ui.viewmodel.sitesViewModelFactory
import androidx.navigation.NavHostController
import androidx.compose.runtime.collectAsState
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.verticalScroll
import kotlinx.coroutines.launch
import androidx.compose.runtime.rememberCoroutineScope

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun SiteFormScreen(
    navController: NavHostController,
    siteId: Int? = null,
    viewModel: SitesViewModel = viewModel(factory = sitesViewModelFactory())
) {
    val snackbarHostState = remember { SnackbarHostState() }
    val scope = rememberCoroutineScope()
    val loading by viewModel.loading.collectAsState()

    var name by remember { mutableStateOf("") }
    var address by remember { mutableStateOf("") }
    var city by remember { mutableStateOf("") }
    var state by remember { mutableStateOf("") }
    var postalCode by remember { mutableStateOf("") }
    var country by remember { mutableStateOf("India") }
    var clientName by remember { mutableStateOf("") }
    var clientContact by remember { mutableStateOf("") }
    var clientPhone by remember { mutableStateOf("") }
    var startDate by remember { mutableStateOf("") }
    var endDate by remember { mutableStateOf("") }
    var areaEstimate by remember { mutableStateOf("") }
    var budgetEstimate by remember { mutableStateOf("") }
    var description by remember { mutableStateOf("") }
    var notes by remember { mutableStateOf("") }
    var status by remember { mutableStateOf(Site.STATUS_ACTIVE) }

    val isEditing = siteId != null

    Scaffold(
        topBar = {
            TopAppBar(
                title = { Text(if (isEditing) "Edit Site" else "New Site") },
                navigationIcon = {
                    IconButton(onClick = { navController.popBackStack() }) {
                        Icon(imageVector = Icons.Outlined.Close, contentDescription = "Close")
                    }
                },
                actions = {
                    if (!loading) {
                        Button(
                            onClick = {
                                val site = Site(
                                    id = siteId ?: 0,
                                    name = name,
                                    address = address,
                                    city = city,
                                    state = state,
                                    postalCode = postalCode,
                                    country = country,
                                    clientName = clientName,
                                    clientContact = clientContact,
                                    clientPhone = clientPhone,
                                    startDate = startDate,
                                    endDate = endDate,
                                    status = status,
                                    areaEstimate = areaEstimate.toDoubleOrNull() ?: 0.0,
                                    budgetEstimate = budgetEstimate.toDoubleOrNull() ?: 0.0,
                                    description = description,
                                    notes = notes,
                                )
                                if (isEditing) {
                                    viewModel.update(site)
                                } else {
                                    viewModel.insert(site)
                                }
                                scope.launch { snackbarHostState.showSnackbar("Site saved") }
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
            SectionCard(title = "Basic Information") {
                FormField(label = "Site Name *", value = name, onValueChange = { name = it }, placeholder = "Enter site name", keyboardType = KeyboardType.Text)
                FormField(label = "Address", value = address, onValueChange = { address = it }, placeholder = "Street address", keyboardType = KeyboardType.Text)
                Row(horizontalArrangement = Arrangement.spacedBy(8.dp)) {
                    FormField(label = "City", value = city, onValueChange = { city = it }, placeholder = "City", modifier = Modifier.weight(1f))
                    FormField(label = "State", value = state, onValueChange = { state = it }, placeholder = "State", modifier = Modifier.weight(1f))
                }
                Row(horizontalArrangement = Arrangement.spacedBy(8.dp)) {
                    FormField(label = "Postal Code", value = postalCode, onValueChange = { postalCode = it }, placeholder = "PIN", keyboardType = KeyboardType.Number, modifier = Modifier.weight(1f))
                    FormField(label = "Country", value = country, onValueChange = { country = it }, placeholder = "Country", modifier = Modifier.weight(1f))
                }
            }

            SectionCard(title = "Client Information") {
                FormField(label = "Client Name", value = clientName, onValueChange = { clientName = it }, placeholder = "Client name", keyboardType = KeyboardType.Text)
                FormField(label = "Contact Person", value = clientContact, onValueChange = { clientContact = it }, placeholder = "Contact person", keyboardType = KeyboardType.Text)
                FormField(label = "Client Phone", value = clientPhone, onValueChange = { clientPhone = it }, placeholder = "Phone number", keyboardType = KeyboardType.Phone)
            }

            SectionCard(title = "Dates & Progress") {
                Row(horizontalArrangement = Arrangement.spacedBy(8.dp)) {
                    FormField(label = "Start Date", value = startDate, onValueChange = { startDate = it }, placeholder = "YYYY-MM-DD", keyboardType = KeyboardType.Text, modifier = Modifier.weight(1f))
                    FormField(label = "End Date", value = endDate, onValueChange = { endDate = it }, placeholder = "YYYY-MM-DD", keyboardType = KeyboardType.Text, modifier = Modifier.weight(1f))
                }
                FormField(
                    label = "Status",
                    value = status,
                    onValueChange = { status = it },
                    placeholder = "Status",
                    keyboardType = KeyboardType.Text
                )
            }

            SectionCard(title = "Estimates") {
                Row(horizontalArrangement = Arrangement.spacedBy(8.dp)) {
                    FormField(label = "Area Estimate (sq ft)", value = areaEstimate, onValueChange = { areaEstimate = it }, placeholder = "0.0", keyboardType = KeyboardType.Number, modifier = Modifier.weight(1f))
                    FormField(label = "Budget Estimate (Rs)", value = budgetEstimate, onValueChange = { budgetEstimate = it }, placeholder = "0.00", keyboardType = KeyboardType.Number, modifier = Modifier.weight(1f))
                }
            }

            SectionCard(title = "Description & Notes") {
                FormField(label = "Description", value = description, onValueChange = { description = it }, placeholder = "Project description", modifier = Modifier.height(80.dp))
                FormField(label = "Notes", value = notes, onValueChange = { notes = it }, placeholder = "Additional notes", modifier = Modifier.height(80.dp))
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