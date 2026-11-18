package com.example.worklist.ui.viewmodel

import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.example.worklist.data.model.ServiceRecord
import com.example.worklist.data.repository.ServiceRepository
import com.example.worklist.data.repository.SiteRepository
import com.example.worklist.data.repository.WorkerRepository
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.launch
import kotlinx.coroutines.withContext

class ServicesViewModel(
    private val serviceRepository: ServiceRepository,
    private val siteRepository: SiteRepository,
    private val workerRepository: WorkerRepository
) : ViewModel() {

    private val _services = MutableStateFlow<List<ServiceRecord>>(emptyList())
    val services: StateFlow<List<ServiceRecord>> = _services

    private val _siteNames = MutableStateFlow<Map<Int, String>>(emptyMap())
    val siteNames: StateFlow<Map<Int, String>> = _siteNames

    private val _workerNames = MutableStateFlow<Map<Int, String>>(emptyMap())
    val workerNames: StateFlow<Map<Int, String>> = _workerNames

    private val _loading = MutableStateFlow(true)
    val loading: StateFlow<Boolean> = _loading

    init {
        load()
    }

    fun load() {
        _loading.value = true
        viewModelScope.launch {
            withContext(Dispatchers.IO) {
                _services.value = serviceRepository.getAllSync()
                _siteNames.value = siteRepository.getAllSync().associate { it.id to it.name }
                _workerNames.value = workerRepository.getAllSync().associate { it.id to it.fullName }
            }
            _loading.value = false
        }
    }

    fun updateStatus(record: ServiceRecord, status: String) {
        viewModelScope.launch {
            withContext(Dispatchers.IO) {
                record.status = status
                serviceRepository.update(record)
            }
            load()
        }
    }
}