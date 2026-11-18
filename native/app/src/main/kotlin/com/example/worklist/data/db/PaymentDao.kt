package com.example.worklist.data.db

import androidx.room.Dao
import androidx.room.Insert
import androidx.room.OnConflictStrategy
import androidx.room.Query
import androidx.room.Update
import androidx.room.Delete
import androidx.room.Transaction
import com.example.worklist.data.model.Payment
import kotlinx.coroutines.flow.Flow

@Dao
interface PaymentDao {
    @Insert(onConflict = OnConflictStrategy.REPLACE)
    fun insert(payment: Payment): Long

    @Update
    fun update(payment: Payment): Int

    @Delete
    fun delete(payment: Payment): Int

    @Query("SELECT * FROM payments WHERE id = :id AND company_id = :companyId")
    fun getById(id: Int, companyId: Int): Flow<Payment?>

    @Query("SELECT * FROM payments WHERE id = :id AND company_id = :companyId")
    fun getByIdSync(id: Int, companyId: Int): Payment?

    @Query("SELECT * FROM payments WHERE worker_id = :workerId AND company_id = :companyId ORDER BY paid_date DESC")
    fun getByWorkerId(workerId: Int, companyId: Int): Flow<List<Payment>>

    @Query("SELECT * FROM payments WHERE site_id = :siteId AND company_id = :companyId ORDER BY paid_date DESC")
    fun getBySiteId(siteId: Int, companyId: Int): Flow<List<Payment>>

    @Query("SELECT * FROM payments WHERE company_id = :companyId ORDER BY paid_date DESC")
    fun getAllSync(companyId: Int): List<Payment>

    @Query("SELECT SUM(amount) FROM payments WHERE company_id = :companyId")
    fun sumPaidTotal(companyId: Int): Double

    @Query("SELECT SUM(amount) FROM payments WHERE worker_id = :workerId AND company_id = :companyId")
    fun sumByWorker(workerId: Int, companyId: Int): Double

    @Transaction
    fun upsert(payment: Payment): Long = insert(payment)
}