package com.example.worklist.ui.viewmodel

import androidx.lifecycle.ViewModel
import androidx.lifecycle.ViewModelProvider
import androidx.lifecycle.viewmodel.CreationExtras
import com.example.worklist.WorklistApplication

@Suppress("UNCHECKED_CAST")
private fun applicationFrom(extras: CreationExtras): WorklistApplication =
    extras[ViewModelProvider.AndroidViewModelFactory.APPLICATION_KEY] as WorklistApplication

@Suppress("UNCHECKED_CAST")
fun dashboardViewModelFactory(): ViewModelProvider.Factory = object : ViewModelProvider.Factory {
    override fun <T : ViewModel> create(modelClass: Class<T>, extras: CreationExtras): T {
        val repos = applicationFrom(extras).repositories
        return DashboardViewModel(
            siteRepository = repos.siteRepository,
            workerRepository = repos.workerRepository,
            productRepository = repos.productRepository,
            attendanceRepository = repos.attendanceRepository,
            payrollRepository = repos.payrollRepository,
            collectionRepository = repos.collectionRepository
        ) as T
    }
}

@Suppress("UNCHECKED_CAST")
fun sitesViewModelFactory(): ViewModelProvider.Factory = object : ViewModelProvider.Factory {
    override fun <T : ViewModel> create(modelClass: Class<T>, extras: CreationExtras): T =
        SitesViewModel(applicationFrom(extras).repositories.siteRepository) as T
}

@Suppress("UNCHECKED_CAST")
fun workersViewModelFactory(): ViewModelProvider.Factory = object : ViewModelProvider.Factory {
    override fun <T : ViewModel> create(modelClass: Class<T>, extras: CreationExtras): T =
        WorkersViewModel(applicationFrom(extras).repositories.workerRepository) as T
}

@Suppress("UNCHECKED_CAST")
fun attendanceViewModelFactory(): ViewModelProvider.Factory = object : ViewModelProvider.Factory {
    override fun <T : ViewModel> create(modelClass: Class<T>, extras: CreationExtras): T {
        val repos = applicationFrom(extras).repositories
        return AttendanceViewModel(repos.attendanceRepository, repos.workerRepository) as T
    }
}

@Suppress("UNCHECKED_CAST")
fun payrollViewModelFactory(): ViewModelProvider.Factory = object : ViewModelProvider.Factory {
    override fun <T : ViewModel> create(modelClass: Class<T>, extras: CreationExtras): T {
        val repos = applicationFrom(extras).repositories
        return PayrollViewModel(repos.payrollRepository, repos.workerRepository) as T
    }
}

@Suppress("UNCHECKED_CAST")
fun productsViewModelFactory(): ViewModelProvider.Factory = object : ViewModelProvider.Factory {
    override fun <T : ViewModel> create(modelClass: Class<T>, extras: CreationExtras): T =
        ProductsViewModel(applicationFrom(extras).repositories.productRepository) as T
}

@Suppress("UNCHECKED_CAST")
fun stockViewModelFactory(): ViewModelProvider.Factory = object : ViewModelProvider.Factory {
    override fun <T : ViewModel> create(modelClass: Class<T>, extras: CreationExtras): T =
        StockViewModel(applicationFrom(extras).repositories.productRepository) as T
}

@Suppress("UNCHECKED_CAST")
fun collectionsViewModelFactory(): ViewModelProvider.Factory = object : ViewModelProvider.Factory {
    override fun <T : ViewModel> create(modelClass: Class<T>, extras: CreationExtras): T {
        val repos = applicationFrom(extras).repositories
        return CollectionsViewModel(repos.collectionRepository, repos.siteRepository) as T
    }
}

@Suppress("UNCHECKED_CAST")
fun servicesViewModelFactory(): ViewModelProvider.Factory = object : ViewModelProvider.Factory {
    override fun <T : ViewModel> create(modelClass: Class<T>, extras: CreationExtras): T {
        val repos = applicationFrom(extras).repositories
        return ServicesViewModel(repos.serviceRepository, repos.siteRepository, repos.workerRepository) as T
    }
}

@Suppress("UNCHECKED_CAST")
fun notificationsViewModelFactory(): ViewModelProvider.Factory = object : ViewModelProvider.Factory {
    override fun <T : ViewModel> create(modelClass: Class<T>, extras: CreationExtras): T =
        NotificationsViewModel(applicationFrom(extras).repositories.notificationRepository) as T
}