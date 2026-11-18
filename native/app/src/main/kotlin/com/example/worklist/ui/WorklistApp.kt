package com.example.worklist.ui

import androidx.compose.foundation.isSystemInDarkTheme
import androidx.compose.foundation.layout.BoxWithConstraints
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.padding
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.NavigationBar
import androidx.compose.material3.NavigationBarItem
import androidx.compose.material3.NavigationRail
import androidx.compose.material3.NavigationRailItem
import androidx.compose.material3.Scaffold
import androidx.compose.material3.Surface
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.saveable.rememberSaveable
import androidx.compose.runtime.setValue
import androidx.compose.ui.Modifier
import androidx.compose.ui.unit.dp
import com.example.worklist.core.designsystem.WorklistTheme
import com.example.worklist.ui.navigation.WorklistDestination
import com.example.worklist.ui.navigation.WorklistNavHost

/** Five top-level entries of the shell; each tab hosts its own nav graph. */
private enum class WorklistTab(
    val label: String,
    val startDestination: WorklistDestination,
) {
    Home("Home", WorklistDestination.Home),
    Sites("Sites", WorklistDestination.Sites),
    Workers("Workers", WorklistDestination.Workers),
    Payroll("Payroll", WorklistDestination.Payroll),
    More("More", WorklistDestination.Notifications),
}

/** Root composable: contract theme + responsive 5-tab shell. */
@androidx.compose.material3.ExperimentalMaterial3Api
@Composable
fun WorklistApp() {
    WorklistTheme(darkTheme = isSystemInDarkTheme()) {
        var selectedTab by rememberSaveable { mutableStateOf(WorklistTab.Home) }
        Surface(
            modifier = Modifier.fillMaxSize(),
            color = MaterialTheme.colorScheme.background,
        ) {
            ResponsiveShell(
                selectedTab = selectedTab,
                onTabSelected = { selectedTab = it },
            )
        }
    }
}

@androidx.compose.material3.ExperimentalMaterial3Api
@Composable
private fun ResponsiveShell(
    selectedTab: WorklistTab,
    onTabSelected: (WorklistTab) -> Unit,
) {
    BoxWithConstraints(modifier = Modifier.fillMaxSize()) {
        if (maxWidth < 600.dp) {
            Scaffold(
                bottomBar = { BottomTabs(selectedTab, onTabSelected) },
            ) { padding ->
                WorklistNavHost(
                    startDestination = selectedTab.startDestination,
                    modifier = Modifier.padding(padding),
                )
            }
        } else {
            Row(modifier = Modifier.fillMaxSize()) {
                NavRail(selectedTab, onTabSelected)
                WorklistNavHost(
                    startDestination = selectedTab.startDestination,
                    modifier = Modifier.weight(1f),
                )
            }
        }
    }
}

@androidx.compose.material3.ExperimentalMaterial3Api
@Composable
private fun BottomTabs(
    selectedTab: WorklistTab,
    onTabSelected: (WorklistTab) -> Unit,
) {
    NavigationBar {
        WorklistTab.entries.forEach { tab ->
            NavigationBarItem(
                selected = tab == selectedTab,
                onClick = { onTabSelected(tab) },
                icon = { TabIcon(tab) },
                label = { Text(tab.label) },
            )
        }
    }
}

@androidx.compose.material3.ExperimentalMaterial3Api
@Composable
private fun NavRail(
    selectedTab: WorklistTab,
    onTabSelected: (WorklistTab) -> Unit,
) {
    NavigationRail {
        WorklistTab.entries.forEach { tab ->
            NavigationRailItem(
                selected = tab == selectedTab,
                onClick = { onTabSelected(tab) },
                icon = { TabIcon(tab) },
                label = { Text(tab.label) },
            )
        }
    }
}

// Icons are deliberately omitted: material-icons-* is not a dependency at this
// milestone. The first letter keeps each tab visually distinguishable without
// pulling in a new library (brief: add ONLY navigation-compose).
@Composable
private fun TabIcon(tab: WorklistTab) {
    Text(tab.label.first().toString())
}
