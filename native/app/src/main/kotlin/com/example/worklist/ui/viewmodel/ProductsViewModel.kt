package com.example.worklist.ui.viewmodel

import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.example.worklist.data.model.Product
import com.example.worklist.data.repository.ProductRepository
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.launch
import kotlinx.coroutines.withContext

class ProductsViewModel(
    private val productRepository: ProductRepository
) : ViewModel() {

    private val _products = MutableStateFlow<List<Product>>(emptyList())
    val products: StateFlow<List<Product>> = _products

    private val _loading = MutableStateFlow(true)
    val loading: StateFlow<Boolean> = _loading

    init {
        load()
    }

    fun load() {
        _loading.value = true
        viewModelScope.launch {
            _products.value = withContext(Dispatchers.IO) { productRepository.getAllSync() }
            _loading.value = false
        }
    }

    fun insert(product: Product) {
        viewModelScope.launch {
            withContext(Dispatchers.IO) { productRepository.insert(product) }
            load()
        }
    }

    fun update(product: Product) {
        viewModelScope.launch {
            withContext(Dispatchers.IO) { productRepository.update(product) }
            load()
        }
    }

    fun delete(product: Product) {
        viewModelScope.launch {
            withContext(Dispatchers.IO) { productRepository.delete(product) }
            load()
        }
    }
}