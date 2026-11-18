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
    suspend fun deleteAll(): Int
    fun getById(id: Int): Flow<Collection?>
    suspend fun getByIdSync(id: Int): Collection?
    fun getBySiteId(siteId: Int): Flow<List<Collection>>
    fun getByCustomerId(customerId: Int): Flow<List<Collection>>
    fun getByStatus(status: String): Flow<List<Collection>>
    fun getAll(): Flow<List<Collection>>
    suspend fun getAllSync(): List<Collection>
    fun getUnsynced(): Flow<List<Collection>>
    suspend fun countPending(): Int
    suspend fun countOverdue(): Int
    suspend fun sumOutstanding(): Double
    suspend fun upsert(collection: Collection): Long
}

class CollectionRepositoryImpl(private val dao: CollectionDao) : CollectionRepository {
    override suspend fun insert(collection: Collection): Long = dao.insert(collection)
    override suspend fun insertAll(collections: List<Collection>): List<Long> = dao.insertAll(collections)
    override suspend fun update(collection: Collection): Int = dao.update(collection)
    override suspend fun updateAll(collections: List<Collection>): Int = dao.updateAll(collections)
    override suspend fun delete(collection: Collection): Int = dao.delete(collection)
    override suspend fun deleteAll(): Int = dao.deleteAll()
    override fun getById(id: Int): Flow<Collection?> = dao.getById(id)
    override suspend fun getByIdSync(id: Int): Collection? = dao.getByIdSync(id)
    override fun getBySiteId(siteId: Int): Flow<List<Collection>> = dao.getBySiteId(siteId)
    override fun getByCustomerId(customerId: Int): Flow<List<Collection>> = dao.getByCustomerId(customerId)
    override fun getByStatus(status: String): Flow<List<Collection>> = dao.getByStatus(status)
    override fun getAll(): Flow<List<Collection>> = dao.getAll()
    override suspend fun getAllSync(): List<Collection> = dao.getAllSync()
    override fun getUnsynced(): Flow<List<Collection>> = dao.getUnsynced()
    override suspend fun countPending(): Int = dao.countPending()
    override suspend fun countOverdue(): Int = dao.countOverdue()
    override suspend fun sumOutstanding(): Double = dao.sumOutstanding()
    override suspend fun upsert(collection: Collection): Long = dao.upsert(collection)
}