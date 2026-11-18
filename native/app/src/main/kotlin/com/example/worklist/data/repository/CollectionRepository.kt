package com.example.worklist.data.repository

import com.example.worklist.data.db.CollectionDao
import com.example.worklist.data.model.Collection
import kotlinx.coroutines.flow.Flow

interface CollectionRepository {
    suspend fun insert(collection: Collection): Long
    suspend fun insertAll(collections: List<Collection>): List<Long>
    suspend fun update(collection: Collection): Int
    suspend fun updateAll(collections: List<Collection>): Int
    suspend fun delete(collection: Collection): Int
    suspend fun deleteAll(companyId: Int)
    fun getById(id: Int, companyId: Int): Flow<Collection?>
    suspend fun getByIdSync(id: Int, companyId: Int): Collection?
    fun getBySiteId(siteId: Int, companyId: Int): Flow<List<Collection>>
    fun getByCustomerId(customerId: Int, companyId: Int): Flow<List<Collection>>
    fun getByStatus(status: String, companyId: Int): Flow<List<Collection>>
    fun getAll(companyId: Int): Flow<List<Collection>>
    suspend fun getAllSync(companyId: Int): List<Collection>
    fun getUnsynced(companyId: Int): Flow<List<Collection>>
    suspend fun countPending(companyId: Int): Int
    suspend fun countOverdue(companyId: Int): Int
    suspend fun sumOutstanding(companyId: Int): Double
    suspend fun upsert(collection: Collection): Long
}

class CollectionRepositoryImpl(private val dao: CollectionDao) : CollectionRepository {
    override suspend fun insert(collection: Collection): Long = dao.insert(collection)
    override suspend fun insertAll(collections: List<Collection>): List<Long> = dao.insertAll(collections)
    override suspend fun update(collection: Collection): Int = dao.update(collection)
    override suspend fun updateAll(collections: List<Collection>): Int = dao.updateAll(collections)
    override suspend fun delete(collection: Collection): Int = dao.delete(collection)
    override suspend fun deleteAll(companyId: Int) = dao.deleteAll(companyId)
    override fun getById(id: Int, companyId: Int): Flow<Collection?> = dao.getById(id, companyId)
    override suspend fun getByIdSync(id: Int, companyId: Int): Collection? = dao.getByIdSync(id, companyId)
    override fun getBySiteId(siteId: Int, companyId: Int): Flow<List<Collection>> = dao.getBySiteId(siteId, companyId)
    override fun getByCustomerId(customerId: Int, companyId: Int): Flow<List<Collection>> = dao.getByCustomerId(customerId, companyId)
    override fun getByStatus(status: String, companyId: Int): Flow<List<Collection>> = dao.getByStatus(status, companyId)
    override fun getAll(companyId: Int): Flow<List<Collection>> = dao.getAll(companyId)
    override suspend fun getAllSync(companyId: Int): List<Collection> = dao.getAllSync(companyId)
    override fun getUnsynced(companyId: Int): Flow<List<Collection>> = dao.getUnsynced(companyId)
    override suspend fun countPending(companyId: Int): Int = dao.countPending(companyId)
    override suspend fun countOverdue(companyId: Int): Int = dao.countOverdue(companyId)
    override suspend fun sumOutstanding(companyId: Int): Double = dao.sumOutstanding(companyId)
    override suspend fun upsert(collection: Collection): Long = dao.upsert(collection)
}