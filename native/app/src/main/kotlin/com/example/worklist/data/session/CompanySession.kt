package com.example.worklist.data.session

import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow

object CompanySession {
    private val _companyId = MutableStateFlow(1)
    val companyId: StateFlow<Int> = _companyId.asStateFlow()

    private val _userId = MutableStateFlow(0)
    val userId: StateFlow<Int> = _userId.asStateFlow()

    fun setContext(companyId: Int, userId: Int) {
        _companyId.value = companyId
        _userId.value = userId
    }

    fun setCurrentCompany(companyId: Int) {
        _companyId.value = companyId
    }

    fun setCurrentUser(userId: Int) {
        _userId.value = userId
    }

    fun clear() {
        _companyId.value = 1
        _userId.value = 0
    }
}