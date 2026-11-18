package com.example.worklist.data.db

import androidx.room.Dao
import androidx.room.Insert
import androidx.room.OnConflictStrategy
import androidx.room.Query
import androidx.room.Update
import androidx.room.Delete
import androidx.room.Transaction
import com.example.worklist.data.model.PayrollRecord
import kotlinx.coroutines.flow.Flow

@Dao
interface PayrollDao {
    @Insert(onConflict = OnConflictStrategy.REPLACE)
    fun insert(record: PayrollRecord): Long

    @Insert(onConflict = OnConflictStrategy.REPLACE)
    fun insertAll(records: List<PayrollRecord>): List<Long>

    @Update
    fun update(record: PayrollRecord): Int

    @Update
    fun updateAll(records: List<PayrollRecord>): Int

    @Delete
    fun delete(record: PayrollRecord): Int

    @Query("DELETE FROM payroll_records")
    fun deleteAll(): Int

    @Query("SELECT * FROM payroll_records WHERE id = :id")
    fun getById(id: Int): Flow<PayrollRecord?>

    @Query("SELECT * FROM payroll_records WHERE id = :id")
    fun getByIdSync(id: Int): PayrollRecord?

    @Query("SELECT * FROM payroll_records WHERE worker_id = :workerId ORDER BY period_start DESC")
    fun getByWorkerId(workerId: Int): Flow<List<PayrollRecord>>

    @Query("SELECT * FROM payroll_records WHERE site_id = :siteId ORDER BY period_start DESC")
    fun getBySiteId(siteId: Int): Flow<List<PayrollRecord>>

    @Query("SELECT * FROM payroll_records WHERE period_start = :periodStart AND period_end = :periodEnd ORDER BY worker_id ASC")
    fun getByPeriod(periodStart: String, periodEnd: String): Flow<List<PayrollRecord>>

    @Query("SELECT * FROM payroll_records WHERE period_start = :periodStart AND period_end = :periodEnd ORDER BY worker_id ASC")
    fun getByPeriodSync(periodStart: String, periodEnd: String): List<PayrollRecord>

    @Query("SELECT * FROM payroll_records ORDER BY period_start DESC")
    fun getAllSync(): List<PayrollRecord>

    @Query("SELECT * FROM payroll_records WHERE status = :status ORDER BY period_start DESC")
    fun getByStatus(status: String): Flow<List<PayrollRecord>>

    @Query("SELECT * FROM payroll_records WHERE synced = 0 ORDER BY created_at ASC")
    fun getUnsynced(): Flow<List<PayrollRecord>>

    @Query("SELECT COUNT(*) FROM payroll_records WHERE status = 'pending'")
    fun countPending(): Int

    @Query("SELECT SUM(net_pay) FROM payroll_records WHERE status = 'paid'")
    fun sumPaid(): Double

    @Query("SELECT SUM(advance_deduction) FROM payroll_records WHERE status = 'paid'")
    fun sumAdvanceDeductions(): Double

    @Transaction
    fun upsert(record: PayrollRecord): Long = insert(record)
}