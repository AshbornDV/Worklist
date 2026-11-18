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
    suspend fun deleteAll(): Int
    fun getById(id: Int): Flow<Worker?>
    suspend fun getByIdSync(id: Int): Worker?
    fun getByUserId(userId: Int): Flow<Worker?>
    fun getBySiteId(siteId: Int): Flow<List<Worker>>
    suspend fun getBySiteIdSync(siteId: Int): List<Worker>
    fun getAll(): Flow<List<Worker>>
    suspend fun getAllSync(): List<Worker>
    fun getByStatus(status: String): Flow<List<Worker>>
    fun getActive(): Flow<List<Worker>>
    fun getUnsynced(): Flow<List<Worker>>
    suspend fun count(): Int
    suspend fun countActive(): Int
    suspend fun countActiveBySite(siteId: Int): Int
    fun search(query: String): Flow<List<Worker>>
    fun searchByPhone(query: String): Flow<List<Worker>>
    suspend fun upsert(worker: Worker): Long
}

class WorkerRepositoryImpl(private val dao: WorkerDao) : WorkerRepository {
    override suspend fun insert(worker: Worker): Long = dao.insert(worker)
    override suspend fun insertAll(workers: List<Worker>): List<Long> = dao.insertAll(workers)
    override suspend fun update(worker: Worker): Int = dao.update(worker)
    override suspend fun updateAll(workers: List<Worker>): Int = dao.updateAll(workers)
    override suspend fun delete(worker: Worker): Int = dao.delete(worker)
    override suspend fun deleteAll(): Int = dao.deleteAll()
    override fun getById(id: Int): Flow<Worker?> = dao.getById(id)
    override suspend fun getByIdSync(id: Int): Worker? = dao.getByIdSync(id)
    override fun getByUserId(userId: Int): Flow<Worker?> = dao.getByUserId(userId)
    override fun getBySiteId(siteId: Int): Flow<List<Worker>> = dao.getBySiteId(siteId)
    override suspend fun getBySiteIdSync(siteId: Int): List<Worker> = dao.getBySiteIdSync(siteId)
    override fun getAll(): Flow<List<Worker>> = dao.getAll()
    override suspend fun getAllSync(): List<Worker> = dao.getAllSync()
    override fun getByStatus(status: String): Flow<List<Worker>> = dao.getByStatus(status)
    override fun getActive(): Flow<List<Worker>> = dao.getActive()
    override fun getUnsynced(): Flow<List<Worker>> = dao.getUnsynced()
    override suspend fun count(): Int = dao.count()
    override suspend fun countActive(): Int = dao.countActive()
    override suspend fun countActiveBySite(siteId: Int): Int = dao.countActiveBySite(siteId)
    override fun search(query: String): Flow<List<Worker>> = dao.search(query)
    override fun searchByPhone(query: String): Flow<List<Worker>> = dao.searchByPhone(query)
    override suspend fun upsert(worker: Worker): Long = dao.upsert(worker)
}