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
    suspend fun deleteAll(): Int
    fun getById(id: Int): Flow<Product?>
    suspend fun getByIdSync(id: Int): Product?
    fun getBySiteId(siteId: Int): Flow<List<Product>>
    suspend fun getBySiteIdSync(siteId: Int): List<Product>
    fun getAll(): Flow<List<Product>>
    suspend fun getAllSync(): List<Product>
    fun getByCategory(category: String): Flow<List<Product>>
    fun getUnsynced(): Flow<List<Product>>
    suspend fun count(): Int
    suspend fun countOutOfStock(): Int
    suspend fun countCritical(): Int
    suspend fun countLow(): Int
    fun getOutOfStock(): Flow<List<Product>>
    suspend fun getOutOfStockSync(): List<Product>
    fun getCritical(): Flow<List<Product>>
    suspend fun getCriticalSync(): List<Product>
    fun getLow(): Flow<List<Product>>
    suspend fun getLowSync(): List<Product>
    fun search(query: String): Flow<List<Product>>
    suspend fun getTotalInventoryValue(): Double
    suspend fun upsert(product: Product): Long
}

class ProductRepositoryImpl(private val dao: ProductDao) : ProductRepository {
    override suspend fun insert(product: Product): Long = dao.insert(product)
    override suspend fun insertAll(products: List<Product>): List<Long> = dao.insertAll(products)
    override suspend fun update(product: Product): Int = dao.update(product)
    override suspend fun updateAll(products: List<Product>): Int = dao.updateAll(products)
    override suspend fun delete(product: Product): Int = dao.delete(product)
    override suspend fun deleteAll(): Int = dao.deleteAll()
    override fun getById(id: Int): Flow<Product?> = dao.getById(id)
    override suspend fun getByIdSync(id: Int): Product? = dao.getByIdSync(id)
    override fun getBySiteId(siteId: Int): Flow<List<Product>> = dao.getBySiteId(siteId)
    override suspend fun getBySiteIdSync(siteId: Int): List<Product> = dao.getBySiteIdSync(siteId)
    override fun getAll(): Flow<List<Product>> = dao.getAll()
    override suspend fun getAllSync(): List<Product> = dao.getAllSync()
    override fun getByCategory(category: String): Flow<List<Product>> = dao.getByCategory(category)
    override fun getUnsynced(): Flow<List<Product>> = dao.getUnsynced()
    override suspend fun count(): Int = dao.count()
    override suspend fun countOutOfStock(): Int = dao.countOutOfStock()
    override suspend fun countCritical(): Int = dao.countCritical()
    override suspend fun countLow(): Int = dao.countLow()
    override fun getOutOfStock(): Flow<List<Product>> = dao.getOutOfStock()
    override suspend fun getOutOfStockSync(): List<Product> = dao.getOutOfStockSync()
    override fun getCritical(): Flow<List<Product>> = dao.getCritical()
    override suspend fun getCriticalSync(): List<Product> = dao.getCriticalSync()
    override fun getLow(): Flow<List<Product>> = dao.getLow()
    override suspend fun getLowSync(): List<Product> = dao.getLowSync()
    override fun search(query: String): Flow<List<Product>> = dao.search(query)
    override suspend fun getTotalInventoryValue(): Double = dao.getTotalInventoryValue()
    override suspend fun upsert(product: Product): Long = dao.upsert(product)
}