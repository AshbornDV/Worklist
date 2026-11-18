package com.example.worklist.ui.viewmodel

import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.example.worklist.data.model.Site
import com.example.worklist.data.repository.SiteRepository
import com.example.worklist.data.session.CompanySession
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.launch
import kotlinx.coroutines.withContext

class SitesViewModel(
    private val siteRepository: SiteRepository
) : ViewModel() {

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
            val data = withContext(Dispatchers.IO) { siteRepository.getAllSync(CompanySession.companyId.value) }
            _sites.value = data
            _loading.value = false
        }
    }

    fun insert(site: Site) {
        viewModelScope.launch {
            withContext(Dispatchers.IO) { siteRepository.insert(site) }
            load()
        }
    }

    fun update(site: Site) {
        viewModelScope.launch {
            withContext(Dispatchers.IO) { siteRepository.update(site) }
            load()
        }
    }

    fun delete(site: Site) {
        viewModelScope.launch {
            withContext(Dispatchers.IO) { siteRepository.delete(site) }
            load()
        }
    }

    companion object {
        @Suppress("UNUSED_PARAMETER")
        fun Factory(context: android.content.Context): SitesViewModel {
            val database = com.example.worklist.data.db.WorklistDatabase.getDatabase(context)
            return SitesViewModel(com.example.worklist.data.repository.SiteRepositoryImpl(database.siteDao()))
        }
    }
}