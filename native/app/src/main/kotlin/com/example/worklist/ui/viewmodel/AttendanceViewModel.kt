package com.example.worklist.ui.viewmodel

import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.example.worklist.data.model.Attendance
import com.example.worklist.data.model.Worker
import com.example.worklist.data.repository.AttendanceRepository
import com.example.worklist.data.repository.WorkerRepository
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.launch
import kotlinx.coroutines.withContext
import java.time.LocalDate

class AttendanceViewModel(
    private val attendanceRepository: AttendanceRepository,
    private val workerRepository: WorkerRepository
) : ViewModel() {

    private val _workers = MutableStateFlow<List<Worker>>(emptyList())
    val workers: StateFlow<List<Worker>> = _workers

    private val _attendance = MutableStateFlow<List<Attendance>>(emptyList())
    val attendance: StateFlow<List<Attendance>> = _attendance

    private val _selectedDate = MutableStateFlow(LocalDate.now().toString())
    val selectedDate: StateFlow<String> = _selectedDate

    private val _loading = MutableStateFlow(true)
    val loading: StateFlow<Boolean> = _loading

    init {
        load()
    }

    fun setDate(date: String) {
        _selectedDate.value = date
        load()
    }

    fun load() {
        _loading.value = true
        viewModelScope.launch {
            withContext(Dispatchers.IO) {
                _workers.value = workerRepository.getAllSync()
                _attendance.value = attendanceRepository.getBySiteAndDateSync(0, _selectedDate.value)
            }
            _loading.value = false
        }
    }

    fun markAttendance(workerId: Int, type: String) {
        viewModelScope.launch {
            withContext(Dispatchers.IO) {
                val existing = attendanceRepository.getByWorkerAndDateSync(workerId, _selectedDate.value)
                if (existing != null) {
                    existing.type = type
                    attendanceRepository.update(existing)
                } else {
                    attendanceRepository.insert(
                        Attendance(
                            workerId = workerId,
                            siteId = 0,
                            date = _selectedDate.value,
                            type = type,
                            createdAt = LocalDate.now().toString()
                        )
                    )
                }
            }
            load()
        }
    }

    /** Returns a worker's attendance type for the selected date, or null if unrecorded. */
    fun typeForWorker(workerId: Int): String? =
        _attendance.value.firstOrNull { it.workerId == workerId }?.type
}