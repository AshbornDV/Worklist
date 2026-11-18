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
    suspend fun deleteAll(companyId: Int)
    fun getById(id: Int, companyId: Int): Flow<ServiceRecord?>
    suspend fun getByIdSync(id: Int, companyId: Int): ServiceRecord?
    fun getBySiteId(siteId: Int, companyId: Int): Flow<List<ServiceRecord>>
    fun getByWorkerId(workerId: Int, companyId: Int): Flow<List<ServiceRecord>>
    fun getByStatus(status: String, companyId: Int): Flow<List<ServiceRecord>>
    fun getAll(companyId: Int): Flow<List<ServiceRecord>>
    suspend fun getAllSync(companyId: Int): List<ServiceRecord>
    fun getUnsynced(companyId: Int): Flow<List<ServiceRecord>>
    suspend fun sumCompleted(companyId: Int): Double
    suspend fun upsert(record: ServiceRecord): Long
}

class ServiceRepositoryImpl(private val dao: ServiceDao) : ServiceRepository {
    override suspend fun insert(record: ServiceRecord): Long = dao.insert(record)
    override suspend fun insertAll(records: List<ServiceRecord>): List<Long> = dao.insertAll(records)
    override suspend fun update(record: ServiceRecord): Int = dao.update(record)
    override suspend fun updateAll(records: List<ServiceRecord>): Int = dao.updateAll(records)
    override suspend fun delete(record: ServiceRecord): Int = dao.delete(record)
    override suspend fun deleteAll(companyId: Int) = dao.deleteAll(companyId)
    override fun getById(id: Int, companyId: Int): Flow<ServiceRecord?> = dao.getById(id, companyId)
    override suspend fun getByIdSync(id: Int, companyId: Int): ServiceRecord? = dao.getByIdSync(id, companyId)
    override fun getBySiteId(siteId: Int, companyId: Int): Flow<List<ServiceRecord>> = dao.getBySiteId(siteId, companyId)
    override fun getByWorkerId(workerId: Int, companyId: Int): Flow<List<ServiceRecord>> = dao.getByWorkerId(workerId, companyId)
    override fun getByStatus(status: String, companyId: Int): Flow<List<ServiceRecord>> = dao.getByStatus(status, companyId)
    override fun getAll(companyId: Int): Flow<List<ServiceRecord>> = dao.getAll(companyId)
    override suspend fun getAllSync(companyId: Int): List<ServiceRecord> = dao.getAllSync(companyId)
    override fun getUnsynced(companyId: Int): Flow<List<ServiceRecord>> = dao.getUnsynced(companyId)
    override suspend fun sumCompleted(companyId: Int): Double = dao.sumCompleted(companyId)
    override suspend fun upsert(record: ServiceRecord): Long = dao.upsert(record)
}