package com.example.worklist.ui.viewmodel

import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.example.worklist.data.model.Site
import com.example.worklist.data.model.Worker
import com.example.worklist.data.model.Product
import com.example.worklist.data.model.Attendance
import com.example.worklist.data.model.PayrollRecord
import com.example.worklist.data.model.Collection
import com.example.worklist.data.repository.SiteRepository
import com.example.worklist.data.repository.WorkerRepository
import com.example.worklist.data.repository.ProductRepository
import com.example.worklist.data.repository.AttendanceRepository
import com.example.worklist.data.repository.PayrollRepository
import com.example.worklist.data.repository.CollectionRepository
import com.example.worklist.data.session.CompanySession
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.launch
import kotlinx.coroutines.withContext
import java.time.LocalDate

data class DashboardStats(
    val activeSites: Int = 0,
    val completedSites: Int = 0,
    val activeWorkers: Int = 0,
    val workersPresentToday: Int = 0,
    val workersAbsentToday: Int = 0,
    val totalProducts: Int = 0,
    val materialsIssuedToday: Int = 0,
    val pendingPayments: Double = 0.0,
    val totalProjectCost: Double = 0.0,
    val todayExpenses: Double = 0.0,
    val outOfStock: Int = 0,
    val criticalStock: Int = 0,
    val lowStock: Int = 0,
    val pendingAdvances: Int = 0
)

class DashboardViewModel(
    private val siteRepository: SiteRepository,
    private val workerRepository: WorkerRepository,
    private val productRepository: ProductRepository,
    private val attendanceRepository: AttendanceRepository,
    private val payrollRepository: PayrollRepository,
    private val collectionRepository: CollectionRepository
) : ViewModel() {

    private val _stats = MutableStateFlow<DashboardStats>(DashboardStats())
    val stats: StateFlow<DashboardStats> = _stats

    private val _stockAlerts = MutableStateFlow<List<Product>>(emptyList())
    val stockAlerts: StateFlow<List<Product>> = _stockAlerts

    private val _recentActivity = MutableStateFlow<List<DashboardActivity>>(emptyList())
    val recentActivity: StateFlow<List<DashboardActivity>> = _recentActivity

    private val _attendanceChartData = MutableStateFlow<List<Attendance>>(emptyList())
    val attendanceChartData: StateFlow<List<Attendance>> = _attendanceChartData

    private val _siteProgressChartData = MutableStateFlow<List<Site>>(emptyList())
    val siteProgressChartData: StateFlow<List<Site>> = _siteProgressChartData

    private val _materialUsageChartData = MutableStateFlow<List<Product>>(emptyList())
    val materialUsageChartData: StateFlow<List<Product>> = _materialUsageChartData

    private val _loading = MutableStateFlow(false)
    val loading: StateFlow<Boolean> = _loading

    fun load() {
        _loading.value = true
        viewModelScope.launch {
            withContext(Dispatchers.IO) { loadAll() }
            _loading.value = false
        }
    }

    private suspend fun loadAll() {
        try {
            val today = LocalDate.now().toString()

            val sites = siteRepository.getAllSync(CompanySession.companyId.value)
            val activeSites = sites.count { it.status == "active" }
            val completedSites = sites.count { it.status == "completed" }

            val workers = workerRepository.getAllSync(CompanySession.companyId.value)
            val activeWorkers = workers.size

            val attendanceToday = attendanceRepository.getBySiteAndDateSync(0, today, CompanySession.companyId.value)
            val present = attendanceToday.count { it.type == "full" }
            val half = attendanceToday.count { it.type == "half" }
            val absent = attendanceToday.count { it.type == "absent" }

            val products = productRepository.getAllSync(CompanySession.companyId.value)
            val totalProducts = products.size
            val outOfStock = products.count { it.isOutOfStock() }
            val critical = products.count { it.isCritical() }
            val low = products.count { it.isLow() }

            val collections = collectionRepository.getAllSync(CompanySession.companyId.value)
            val pendingPayments = collections.filter { it.status == "pending" || it.status == "overdue" }
                .sumOf { it.amount - it.paidAmount }
            val totalCost = collections.sumOf { it.amount }

            val companyId = CompanySession.companyId.value
            val stockAlerts = productRepository.getOutOfStockSync(companyId) + productRepository.getCriticalSync(companyId) + productRepository.getLowSync(companyId)

            _stats.value = DashboardStats(
                activeSites = activeSites,
                completedSites = completedSites,
                activeWorkers = activeWorkers,
                workersPresentToday = present,
                workersAbsentToday = absent + half,
                totalProducts = totalProducts,
                materialsIssuedToday = 0,
                pendingPayments = pendingPayments,
                totalProjectCost = totalCost,
                todayExpenses = 0.0,
                outOfStock = outOfStock,
                criticalStock = critical,
                lowStock = low,
                pendingAdvances = 0
            )

            _stockAlerts.value = stockAlerts
            _attendanceChartData.value = attendanceRepository.getByDateRangeSync(
                LocalDate.now().minusDays(30).toString(),
                LocalDate.now().toString(),
                CompanySession.companyId.value
            )
            _siteProgressChartData.value = sites.take(10)
            _materialUsageChartData.value = products.take(10)

        } catch (e: Exception) {
            e.printStackTrace()
        }
    }

    data class DashboardActivity(
        val type: String,
        val title: String,
        val subtitle: String,
        val time: String
    )
}