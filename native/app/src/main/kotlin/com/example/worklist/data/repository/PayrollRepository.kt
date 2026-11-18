package com.example.worklist.data.repository

import com.example.worklist.data.db.PayrollDao
import com.example.worklist.data.model.PayrollRecord
import kotlinx.coroutines.flow.Flow

interface PayrollRepository {
    suspend fun insert(record: PayrollRecord): Long
    suspend fun insertAll(records: List<PayrollRecord>): List<Long>
    suspend fun update(record: PayrollRecord): Int
    suspend fun updateAll(records: List<PayrollRecord>): Int
    suspend fun delete(record: PayrollRecord): Int
    suspend fun deleteAll(): Int
    fun getById(id: Int): Flow<PayrollRecord?>
    suspend fun getByIdSync(id: Int): PayrollRecord?
    fun getByWorkerId(workerId: Int): Flow<List<PayrollRecord>>
    fun getBySiteId(siteId: Int): Flow<List<PayrollRecord>>
    fun getByPeriod(periodStart: String, periodEnd: String): Flow<List<PayrollRecord>>
    suspend fun getByPeriodSync(periodStart: String, periodEnd: String): List<PayrollRecord>
    suspend fun getAllSync(): List<PayrollRecord>
    fun getByStatus(status: String): Flow<List<PayrollRecord>>
    fun getUnsynced(): Flow<List<PayrollRecord>>
    suspend fun countPending(): Int
    suspend fun sumPaid(): Double
    suspend fun sumAdvanceDeductions(): Double
    suspend fun upsert(record: PayrollRecord): Long
}

class PayrollRepositoryImpl(private val dao: PayrollDao) : PayrollRepository {
    override suspend fun insert(record: PayrollRecord): Long = dao.insert(record)
    override suspend fun insertAll(records: List<PayrollRecord>): List<Long> = dao.insertAll(records)
    override suspend fun update(record: PayrollRecord): Int = dao.update(record)
    override suspend fun updateAll(records: List<PayrollRecord>): Int = dao.updateAll(records)
    override suspend fun delete(record: PayrollRecord): Int = dao.delete(record)
    override suspend fun deleteAll(): Int = dao.deleteAll()
    override fun getById(id: Int): Flow<PayrollRecord?> = dao.getById(id)
    override suspend fun getByIdSync(id: Int): PayrollRecord? = dao.getByIdSync(id)
    override fun getByWorkerId(workerId: Int): Flow<List<PayrollRecord>> = dao.getByWorkerId(workerId)
    override fun getBySiteId(siteId: Int): Flow<List<PayrollRecord>> = dao.getBySiteId(siteId)
    override fun getByPeriod(periodStart: String, periodEnd: String): Flow<List<PayrollRecord>> = dao.getByPeriod(periodStart, periodEnd)
    override suspend fun getByPeriodSync(periodStart: String, periodEnd: String): List<PayrollRecord> = dao.getByPeriodSync(periodStart, periodEnd)
    override suspend fun getAllSync(): List<PayrollRecord> = dao.getAllSync()
    override fun getByStatus(status: String): Flow<List<PayrollRecord>> = dao.getByStatus(status)
    override fun getUnsynced(): Flow<List<PayrollRecord>> = dao.getUnsynced()
    override suspend fun countPending(): Int = dao.countPending()
    override suspend fun sumPaid(): Double = dao.sumPaid()
    override suspend fun sumAdvanceDeductions(): Double = dao.sumAdvanceDeductions()
    override suspend fun upsert(record: PayrollRecord): Long = dao.upsert(record)
}