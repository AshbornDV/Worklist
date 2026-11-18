package com.example.worklist.ui.viewmodel

import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.example.worklist.data.model.Notification
import com.example.worklist.data.repository.NotificationRepository
import com.example.worklist.data.session.CompanySession
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
            val companyId = CompanySession.companyId.value
            val userId = CompanySession.userId.value
            _notifications.value = withContext(Dispatchers.IO) { notificationRepository.getByUserIdSync(userId, companyId) }
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
                        companyId = CompanySession.companyId.value,
                        userId = CompanySession.userId.value,
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