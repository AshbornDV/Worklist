package com.example.worklist.data.repository

import com.example.worklist.data.db.StockMovementDao
import com.example.worklist.data.model.StockMovement
import kotlinx.coroutines.flow.Flow

interface StockMovementRepository {
    suspend fun insert(movement: StockMovement): Long
    suspend fun update(movement: StockMovement): Int
    suspend fun delete(movement: StockMovement): Int
    fun getById(id: Int): Flow<StockMovement?>
    fun getByProduct(productId: Int, companyId: Int): Flow<List<StockMovement>>
    fun getBySite(siteId: Int, companyId: Int): Flow<List<StockMovement>>
    fun getByType(type: String, companyId: Int): Flow<List<StockMovement>>
    suspend fun netQuantity(productId: Int, companyId: Int): Double
    suspend fun totalCostByCompany(companyId: Int): Double
    suspend fun upsert(movement: StockMovement): Long
}

class StockMovementRepositoryImpl(private val dao: StockMovementDao) : StockMovementRepository {
    override suspend fun insert(movement: StockMovement): Long = dao.insert(movement)
    override suspend fun update(movement: StockMovement): Int = dao.update(movement)
    override suspend fun delete(movement: StockMovement): Int = dao.delete(movement)
    override fun getById(id: Int): Flow<StockMovement?> = dao.getById(id)
    override fun getByProduct(productId: Int, companyId: Int): Flow<List<StockMovement>> = dao.getByProduct(productId, companyId)
    override fun getBySite(siteId: Int, companyId: Int): Flow<List<StockMovement>> = dao.getBySite(siteId, companyId)
    override fun getByType(type: String, companyId: Int): Flow<List<StockMovement>> = dao.getByType(type, companyId)
    override suspend fun netQuantity(productId: Int, companyId: Int): Double = dao.netQuantity(productId, companyId)
    override suspend fun totalCostByCompany(companyId: Int): Double = dao.totalCostByCompany(companyId)
    override suspend fun upsert(movement: StockMovement): Long = dao.upsert(movement)
}