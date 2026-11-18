package com.example.worklist.data.repository

import com.example.worklist.data.db.WorkerDao
import com.example.worklist.data.model.Worker
import kotlinx.coroutines.flow.Flow

interface WorkerRepository {
    suspend fun insert(worker: Worker): Long
    suspend fun insertAll(workers: List<Worker>): List<Long>
    suspend fun update(worker: Worker): Int
    suspend fun updateAll(workers: List<Worker>): Int
    suspend fun delete(worker: Worker): Int
    suspend fun deleteAll(companyId: Int)
    fun getById(id: Int, companyId: Int): Flow<Worker?>
    suspend fun getByIdSync(id: Int, companyId: Int): Worker?
    fun getByUserId(userId: Int, companyId: Int): Flow<Worker?>
    fun getBySiteId(siteId: Int, companyId: Int): Flow<List<Worker>>
    suspend fun getBySiteIdSync(siteId: Int, companyId: Int): List<Worker>
    fun getAll(companyId: Int): Flow<List<Worker>>
    suspend fun getAllSync(companyId: Int): List<Worker>
    fun getByStatus(status: String, companyId: Int): Flow<List<Worker>>
    fun getActive(companyId: Int): Flow<List<Worker>>
    fun getUnsynced(companyId: Int): Flow<List<Worker>>
    suspend fun count(companyId: Int): Int
    suspend fun countActive(companyId: Int): Int
    suspend fun countActiveBySite(siteId: Int, companyId: Int): Int
    fun search(query: String, companyId: Int): Flow<List<Worker>>
    fun searchByPhone(query: String, companyId: Int): Flow<List<Worker>>
    suspend fun upsert(worker: Worker): Long
}

class WorkerRepositoryImpl(private val dao: WorkerDao) : WorkerRepository {
    override suspend fun insert(worker: Worker): Long = dao.insert(worker)
    override suspend fun insertAll(workers: List<Worker>): List<Long> = dao.insertAll(workers)
    override suspend fun update(worker: Worker): Int = dao.update(worker)
    override suspend fun updateAll(workers: List<Worker>): Int = dao.updateAll(workers)
    override suspend fun delete(worker: Worker): Int = dao.delete(worker)
    override suspend fun deleteAll(companyId: Int) = dao.deleteAll(companyId)
    override fun getById(id: Int, companyId: Int): Flow<Worker?> = dao.getById(id, companyId)
    override suspend fun getByIdSync(id: Int, companyId: Int): Worker? = dao.getByIdSync(id, companyId)
    override fun getByUserId(userId: Int, companyId: Int): Flow<Worker?> = dao.getByUserId(userId, companyId)
    override fun getBySiteId(siteId: Int, companyId: Int): Flow<List<Worker>> = dao.getBySiteId(siteId, companyId)
    override suspend fun getBySiteIdSync(siteId: Int, companyId: Int): List<Worker> = dao.getBySiteIdSync(siteId, companyId)
    override fun getAll(companyId: Int): Flow<List<Worker>> = dao.getAll(companyId)
    override suspend fun getAllSync(companyId: Int): List<Worker> = dao.getAllSync(companyId)
    override fun getByStatus(status: String, companyId: Int): Flow<List<Worker>> = dao.getByStatus(status, companyId)
    override fun getActive(companyId: Int): Flow<List<Worker>> = dao.getActive(companyId)
    override fun getUnsynced(companyId: Int): Flow<List<Worker>> = dao.getUnsynced(companyId)
    override suspend fun count(companyId: Int): Int = dao.count(companyId)
    override suspend fun countActive(companyId: Int): Int = dao.countActive(companyId)
    override suspend fun countActiveBySite(siteId: Int, companyId: Int): Int = dao.countActiveBySite(siteId, companyId)
    override fun search(query: String, companyId: Int): Flow<List<Worker>> = dao.search(query, companyId)
    override fun searchByPhone(query: String, companyId: Int): Flow<List<Worker>> = dao.searchByPhone(query, companyId)
    override suspend fun upsert(worker: Worker): Long = dao.upsert(worker)
}