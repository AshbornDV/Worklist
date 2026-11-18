package com.example.worklist.ui.viewmodel

import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.example.worklist.data.model.Collection
import com.example.worklist.data.repository.CollectionRepository
import com.example.worklist.data.repository.SiteRepository
import com.example.worklist.data.session.CompanySession
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.launch
import kotlinx.coroutines.withContext

class CollectionsViewModel(
    private val collectionRepository: CollectionRepository,
    private val siteRepository: SiteRepository
) : ViewModel() {

    private val _collections = MutableStateFlow<List<Collection>>(emptyList())
    val collections: StateFlow<List<Collection>> = _collections

    private val _siteNames = MutableStateFlow<Map<Int, String>>(emptyMap())
    val siteNames: StateFlow<Map<Int, String>> = _siteNames

    private val _loading = MutableStateFlow(true)
    val loading: StateFlow<Boolean> = _loading

    init {
        load()
    }

    fun load() {
        _loading.value = true
        viewModelScope.launch {
            withContext(Dispatchers.IO) {
                val cid = CompanySession.companyId.value
                _collections.value = collectionRepository.getAllSync(cid)
                _siteNames.value = siteRepository.getAllSync(cid).associate { it.id to it.name }
            }
            _loading.value = false
        }
    }

    fun markPaid(collection: Collection) {
        viewModelScope.launch {
            withContext(Dispatchers.IO) {
                collection.status = "paid"
                collection.paidAmount = collection.amount
                collectionRepository.update(collection)
            }
            load()
        }
    }
}