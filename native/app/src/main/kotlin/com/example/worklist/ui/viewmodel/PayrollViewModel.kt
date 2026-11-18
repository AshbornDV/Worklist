package com.example.worklist.ui.viewmodel

import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.example.worklist.data.model.PayrollRecord
import com.example.worklist.data.model.Worker
import com.example.worklist.data.repository.PayrollRepository
import com.example.worklist.data.repository.WorkerRepository
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.launch
import kotlinx.coroutines.withContext

class PayrollViewModel(
    private val payrollRepository: PayrollRepository,
    private val workerRepository: WorkerRepository
) : ViewModel() {

    private val _records = MutableStateFlow<List<PayrollRecord>>(emptyList())
    val records: StateFlow<List<PayrollRecord>> = _records

    private val _workers = MutableStateFlow<List<Worker>>(emptyList())
    val workers: StateFlow<List<Worker>> = _workers

    private val _loading = MutableStateFlow(true)
    val loading: StateFlow<Boolean> = _loading

    init {
        load()
    }

    fun load() {
        _loading.value = true
        viewModelScope.launch {
            withContext(Dispatchers.IO) {
                _workers.value = workerRepository.getAllSync()
                _records.value = payrollRepository.getAllSync()
            }
            _loading.value = false
        }
    }
}