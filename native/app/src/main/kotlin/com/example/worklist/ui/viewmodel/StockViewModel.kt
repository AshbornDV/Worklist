package com.example.worklist.ui.viewmodel

import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.example.worklist.data.model.Product
import com.example.worklist.data.repository.ProductRepository
import com.example.worklist.data.session.CompanySession
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.launch
import kotlinx.coroutines.withContext

class StockViewModel(
    private val productRepository: ProductRepository
) : ViewModel() {

    private val _outOfStock = MutableStateFlow<List<Product>>(emptyList())
    val outOfStock: StateFlow<List<Product>> = _outOfStock

    private val _critical = MutableStateFlow<List<Product>>(emptyList())
    val critical: StateFlow<List<Product>> = _critical

    private val _low = MutableStateFlow<List<Product>>(emptyList())
    val low: StateFlow<List<Product>> = _low

    private val _loading = MutableStateFlow(true)
    val loading: StateFlow<Boolean> = _loading

    init {
        load()
    }

    fun load() {
        _loading.value = true
        viewModelScope.launch {
            withContext(Dispatchers.IO) {
                _outOfStock.value = productRepository.getOutOfStockSync(CompanySession.companyId.value)
                _critical.value = productRepository.getCriticalSync(CompanySession.companyId.value)
                _low.value = productRepository.getLowSync(CompanySession.companyId.value)
            }
            _loading.value = false
        }
    }

    fun adjustStock(product: Product, newQuantity: Double) {
        viewModelScope.launch {
            withContext(Dispatchers.IO) {
                product.stockQuantity = newQuantity
                productRepository.update(product)
            }
            load()
        }
    }
}