package com.example.worklist.data.repository

import com.example.worklist.data.db.ServiceDao
import com.example.worklist.data.model.ServiceRecord
import kotlinx.coroutines.flow.Flow

interface ServiceRepository {
    suspend fun insert(record: ServiceRecord): Long
    suspend fun insertAll(records: List<ServiceRecord>): List<Long>
    suspend fun update(record: ServiceRecord): Int
    suspend fun updateAll(records: List<ServiceRecord>): Int
    suspend fun delete(record: ServiceRecord): Int
    suspend fun deleteAll(): Int
    fun getById(id: Int): Flow<ServiceRecord?>
    suspend fun getByIdSync(id: Int): ServiceRecord?
    fun getBySiteId(siteId: Int): Flow<List<ServiceRecord>>
    fun getByWorkerId(workerId: Int): Flow<List<ServiceRecord>>
    fun getByStatus(status: String): Flow<List<ServiceRecord>>
    fun getAll(): Flow<List<ServiceRecord>>
    suspend fun getAllSync(): List<ServiceRecord>
    fun getUnsynced(): Flow<List<ServiceRecord>>
    suspend fun sumCompleted(): Double
    suspend fun upsert(record: ServiceRecord): Long
}

class ServiceRepositoryImpl(private val dao: ServiceDao) : ServiceRepository {
    override suspend fun insert(record: ServiceRecord): Long = dao.insert(record)
    override suspend fun insertAll(records: List<ServiceRecord>): List<Long> = dao.insertAll(records)
    override suspend fun update(record: ServiceRecord): Int = dao.update(record)
    override suspend fun updateAll(records: List<ServiceRecord>): Int = dao.updateAll(records)
    override suspend fun delete(record: ServiceRecord): Int = dao.delete(record)
    override suspend fun deleteAll(): Int = dao.deleteAll()
    override fun getById(id: Int): Flow<ServiceRecord?> = dao.getById(id)
    override suspend fun getByIdSync(id: Int): ServiceRecord? = dao.getByIdSync(id)
    override fun getBySiteId(siteId: Int): Flow<List<ServiceRecord>> = dao.getBySiteId(siteId)
    override fun getByWorkerId(workerId: Int): Flow<List<ServiceRecord>> = dao.getByWorkerId(workerId)
    override fun getByStatus(status: String): Flow<List<ServiceRecord>> = dao.getByStatus(status)
    override fun getAll(): Flow<List<ServiceRecord>> = dao.getAll()
    override suspend fun getAllSync(): List<ServiceRecord> = dao.getAllSync()
    override fun getUnsynced(): Flow<List<ServiceRecord>> = dao.getUnsynced()
    override suspend fun sumCompleted(): Double = dao.sumCompleted()
    override suspend fun upsert(record: ServiceRecord): Long = dao.upsert(record)
}