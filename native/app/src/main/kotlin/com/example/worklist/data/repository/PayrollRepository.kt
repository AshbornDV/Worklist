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
    fun getByWorkerId(workerId: Int, companyId: Int): Flow<List<PayrollRecord>>
    fun getBySiteId(siteId: Int, companyId: Int): Flow<List<PayrollRecord>>
    fun getByPeriod(periodStart: String, periodEnd: String, companyId: Int): Flow<List<PayrollRecord>>
    suspend fun getByPeriodSync(periodStart: String, periodEnd: String, companyId: Int): List<PayrollRecord>
    suspend fun getAllSync(companyId: Int): List<PayrollRecord>
    fun getByStatus(status: String, companyId: Int): Flow<List<PayrollRecord>>
    fun getUnsynced(companyId: Int): Flow<List<PayrollRecord>>
    suspend fun countPending(companyId: Int): Int
    suspend fun sumPaid(companyId: Int): Double
    suspend fun sumAdvanceDeductions(companyId: Int): Double
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
    override fun getByWorkerId(workerId: Int, companyId: Int): Flow<List<PayrollRecord>> = dao.getByWorkerId(workerId,companyId)
    override fun getBySiteId(siteId: Int, companyId: Int): Flow<List<PayrollRecord>> = dao.getBySiteId(siteId,companyId)
    override fun getByPeriod(periodStart: String, periodEnd: String, companyId: Int): Flow<List<PayrollRecord>> = dao.getByPeriod(periodStart, periodEnd,companyId)
    override suspend fun getByPeriodSync(periodStart: String, periodEnd: String, companyId: Int): List<PayrollRecord> = dao.getByPeriodSync(periodStart, periodEnd,companyId)
    override suspend fun getAllSync(companyId: Int): List<PayrollRecord> = dao.getAllSync(companyId)
    override fun getByStatus(status: String, companyId: Int): Flow<List<PayrollRecord>> = dao.getByStatus(status,companyId)
    override fun getUnsynced(companyId: Int): Flow<List<PayrollRecord>> = dao.getUnsynced(companyId)
    override suspend fun countPending(companyId: Int): Int = dao.countPending(companyId)
    override suspend fun sumPaid(companyId: Int): Double = dao.sumPaid(companyId)
    override suspend fun sumAdvanceDeductions(companyId: Int): Double = dao.sumAdvanceDeductions(companyId)
    override suspend fun upsert(record: PayrollRecord): Long = dao.upsert(record)
}