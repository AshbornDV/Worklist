package com.example.worklist.data.repository

import com.example.worklist.data.db.PaymentDao
import com.example.worklist.data.model.Payment
import kotlinx.coroutines.flow.Flow

interface PaymentRepository {
    suspend fun insert(payment: Payment): Long
    suspend fun update(payment: Payment): Int
    suspend fun delete(payment: Payment): Int
    fun getById(id: Int, companyId: Int): Flow<Payment?>
    suspend fun getByIdSync(id: Int, companyId: Int): Payment?
    fun getByWorkerId(workerId: Int, companyId: Int): Flow<List<Payment>>
    fun getBySiteId(siteId: Int, companyId: Int): Flow<List<Payment>>
    suspend fun getAllSync(companyId: Int): List<Payment>
    suspend fun sumPaidTotal(companyId: Int): Double
    suspend fun sumByWorker(workerId: Int, companyId: Int): Double
    suspend fun upsert(payment: Payment): Long
}

class PaymentRepositoryImpl(private val dao: PaymentDao) : PaymentRepository {
    override suspend fun insert(payment: Payment): Long = dao.insert(payment)
    override suspend fun update(payment: Payment): Int = dao.update(payment)
    override suspend fun delete(payment: Payment): Int = dao.delete(payment)
    override fun getById(id: Int, companyId: Int): Flow<Payment?> = dao.getById(id, companyId)
    override suspend fun getByIdSync(id: Int, companyId: Int): Payment? = dao.getByIdSync(id, companyId)
    override fun getByWorkerId(workerId: Int, companyId: Int): Flow<List<Payment>> = dao.getByWorkerId(workerId, companyId)
    override fun getBySiteId(siteId: Int, companyId: Int): Flow<List<Payment>> = dao.getBySiteId(siteId, companyId)
    override suspend fun getAllSync(companyId: Int): List<Payment> = dao.getAllSync(companyId)
    override suspend fun sumPaidTotal(companyId: Int): Double = dao.sumPaidTotal(companyId)
    override suspend fun sumByWorker(workerId: Int, companyId: Int): Double = dao.sumByWorker(workerId, companyId)
    override suspend fun upsert(payment: Payment): Long = dao.upsert(payment)
}