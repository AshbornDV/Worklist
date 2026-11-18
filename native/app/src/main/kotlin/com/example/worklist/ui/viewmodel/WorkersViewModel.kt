package com.example.worklist.ui.viewmodel

import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.example.worklist.data.model.Worker
import com.example.worklist.data.repository.WorkerRepository
import com.example.worklist.data.session.CompanySession
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.launch
import kotlinx.coroutines.withContext

class WorkersViewModel(
    private val workerRepository: WorkerRepository
) : ViewModel() {

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
            _workers.value = withContext(Dispatchers.IO) { workerRepository.getAllSync(CompanySession.companyId.value) }
            _loading.value = false
        }
    }

    fun insert(worker: Worker) {
        viewModelScope.launch {
            withContext(Dispatchers.IO) { workerRepository.insert(worker) }
            load()
        }
    }

    fun update(worker: Worker) {
        viewModelScope.launch {
            withContext(Dispatchers.IO) { workerRepository.update(worker) }
            load()
        }
    }

    fun delete(worker: Worker) {
        viewModelScope.launch {
            withContext(Dispatchers.IO) { workerRepository.delete(worker) }
            load()
        }
    }
}