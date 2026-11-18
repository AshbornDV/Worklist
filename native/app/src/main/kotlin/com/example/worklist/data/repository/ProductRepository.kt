package com.example.worklist.data.repository

import com.example.worklist.data.db.ProductDao
import com.example.worklist.data.model.Product
import kotlinx.coroutines.flow.Flow

interface ProductRepository {
    suspend fun insert(product: Product): Long
    suspend fun insertAll(products: List<Product>): List<Long>
    suspend fun update(product: Product): Int
    suspend fun updateAll(products: List<Product>): Int
    suspend fun delete(product: Product): Int
    suspend fun deleteAll(companyId: Int)
    fun getById(id: Int, companyId: Int): Flow<Product?>
    suspend fun getByIdSync(id: Int, companyId: Int): Product?
    fun getBySiteId(siteId: Int, companyId: Int): Flow<List<Product>>
    suspend fun getBySiteIdSync(siteId: Int, companyId: Int): List<Product>
    fun getAll(companyId: Int): Flow<List<Product>>
    suspend fun getAllSync(companyId: Int): List<Product>
    fun getByCategory(category: String, companyId: Int): Flow<List<Product>>
    fun getUnsynced(companyId: Int): Flow<List<Product>>
    suspend fun count(companyId: Int): Int
    suspend fun countOutOfStock(companyId: Int): Int
    suspend fun countCritical(companyId: Int): Int
    suspend fun countLow(companyId: Int): Int
    fun getOutOfStock(companyId: Int): Flow<List<Product>>
    suspend fun getOutOfStockSync(companyId: Int): List<Product>
    fun getCritical(companyId: Int): Flow<List<Product>>
    suspend fun getCriticalSync(companyId: Int): List<Product>
    fun getLow(companyId: Int): Flow<List<Product>>
    suspend fun getLowSync(companyId: Int): List<Product>
    fun search(query: String, companyId: Int): Flow<List<Product>>
    suspend fun getTotalInventoryValue(companyId: Int): Double
    suspend fun upsert(product: Product): Long
}

class ProductRepositoryImpl(private val dao: ProductDao) : ProductRepository {
    override suspend fun insert(product: Product): Long = dao.insert(product)
    override suspend fun insertAll(products: List<Product>): List<Long> = dao.insertAll(products)
    override suspend fun update(product: Product): Int = dao.update(product)
    override suspend fun updateAll(products: List<Product>): Int = dao.updateAll(products)
    override suspend fun delete(product: Product): Int = dao.delete(product)
    override suspend fun deleteAll(companyId: Int) = dao.deleteAll(companyId)
    override fun getById(id: Int, companyId: Int): Flow<Product?> = dao.getById(id, companyId)
    override suspend fun getByIdSync(id: Int, companyId: Int): Product? = dao.getByIdSync(id, companyId)
    override fun getBySiteId(siteId: Int, companyId: Int): Flow<List<Product>> = dao.getBySiteId(siteId, companyId)
    override suspend fun getBySiteIdSync(siteId: Int, companyId: Int): List<Product> = dao.getBySiteIdSync(siteId, companyId)
    override fun getAll(companyId: Int): Flow<List<Product>> = dao.getAll(companyId)
    override suspend fun getAllSync(companyId: Int): List<Product> = dao.getAllSync(companyId)
    override fun getByCategory(category: String, companyId: Int): Flow<List<Product>> = dao.getByCategory(category, companyId)
    override fun getUnsynced(companyId: Int): Flow<List<Product>> = dao.getUnsynced(companyId)
    override suspend fun count(companyId: Int): Int = dao.count(companyId)
    override suspend fun countOutOfStock(companyId: Int): Int = dao.countOutOfStock(companyId)
    override suspend fun countCritical(companyId: Int): Int = dao.countCritical(companyId)
    override suspend fun countLow(companyId: Int): Int = dao.countLow(companyId)
    override fun getOutOfStock(companyId: Int): Flow<List<Product>> = dao.getOutOfStock(companyId)
    override suspend fun getOutOfStockSync(companyId: Int): List<Product> = dao.getOutOfStockSync(companyId)
    override fun getCritical(companyId: Int): Flow<List<Product>> = dao.getCritical(companyId)
    override suspend fun getCriticalSync(companyId: Int): List<Product> = dao.getCriticalSync(companyId)
    override fun getLow(companyId: Int): Flow<List<Product>> = dao.getLow(companyId)
    override suspend fun getLowSync(companyId: Int): List<Product> = dao.getLowSync(companyId)
    override fun search(query: String, companyId: Int): Flow<List<Product>> = dao.search(query, companyId)
    override suspend fun getTotalInventoryValue(companyId: Int): Double = dao.getTotalInventoryValue(companyId)
    override suspend fun upsert(product: Product): Long = dao.upsert(product)
}