package com.example.worklist.ui.viewmodel

import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.example.worklist.data.model.PayrollRecord
import com.example.worklist.data.model.Payment
import com.example.worklist.data.model.Site
import com.example.worklist.data.model.Worker
import com.example.worklist.data.repository.PayrollRepository
import com.example.worklist.data.repository.PaymentRepository
import com.example.worklist.data.repository.SiteRepository
import com.example.worklist.data.repository.WorkerRepository
import com.example.worklist.data.session.CompanySession
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.launch
import kotlinx.coroutines.withContext

class PayrollViewModel(
    private val payrollRepository: PayrollRepository,
    private val workerRepository: WorkerRepository,
    private val siteRepository: SiteRepository,
    private val paymentRepository: PaymentRepository
) : ViewModel() {

    private val _records = MutableStateFlow<List<PayrollRecord>>(emptyList())
    val records: StateFlow<List<PayrollRecord>> = _records

    private val _workers = MutableStateFlow<List<Worker>>(emptyList())
    val workers: StateFlow<List<Worker>> = _workers

    private val _sites = MutableStateFlow<List<Site>>(emptyList())
    val sites: StateFlow<List<Site>> = _sites

    private val _loading = MutableStateFlow(true)
    val loading: StateFlow<Boolean> = _loading

    init {
        load()
    }

    fun load() {
        _loading.value = true
        viewModelScope.launch {
            withContext(Dispatchers.IO) {
                _workers.value = workerRepository.getAllSync(CompanySession.companyId.value)
                _records.value = payrollRepository.getAllSync(CompanySession.companyId.value)
                _sites.value = siteRepository.getAllSync(CompanySession.companyId.value)
            }
            _loading.value = false
        }
    }

    suspend fun insertPayment(payment: Payment) {
        withContext(Dispatchers.IO) {
            paymentRepository.insert(payment)
        }
    }
}