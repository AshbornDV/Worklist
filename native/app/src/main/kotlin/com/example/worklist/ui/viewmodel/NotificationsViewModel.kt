package com.example.worklist.ui.viewmodel

import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.example.worklist.data.model.Notification
import com.example.worklist.data.repository.NotificationRepository
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.launch
import kotlinx.coroutines.withContext

class NotificationsViewModel(
    private val notificationRepository: NotificationRepository
) : ViewModel() {

    private val _notifications = MutableStateFlow<List<Notification>>(emptyList())
    val notifications: StateFlow<List<Notification>> = _notifications

    private val _loading = MutableStateFlow(true)
    val loading: StateFlow<Boolean> = _loading

    init {
        load()
    }

    fun load() {
        _loading.value = true
        viewModelScope.launch {
            // userId 1 default for local-only port; auth will populate this later.
            _notifications.value = withContext(Dispatchers.IO) { notificationRepository.getByUserIdSync(1) }
            _loading.value = false
        }
    }

    fun markRead(notification: Notification) {
        viewModelScope.launch {
            withContext(Dispatchers.IO) {
                notification.read = true
                notificationRepository.update(notification)
            }
            load()
        }
    }

    fun add(title: String, body: String, type: String = "info") {
        viewModelScope.launch {
            withContext(Dispatchers.IO) {
                notificationRepository.insert(
                    Notification(
                        userId = 1,
                        title = title,
                        body = body,
                        type = type,
                        createdAt = java.time.LocalDate.now().toString()
                    )
                )
            }
            load()
        }
    }
}