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

    @Query("SELECT * FROM payroll_records WHERE worker_id = :workerId AND company_id = :companyId ORDER BY period_start DESC")
    fun getByWorkerId(workerId: Int, companyId: Int): Flow<List<PayrollRecord>>

    @Query("SELECT * FROM payroll_records WHERE site_id = :siteId AND company_id = :companyId ORDER BY period_start DESC")
    fun getBySiteId(siteId: Int, companyId: Int): Flow<List<PayrollRecord>>

    @Query("SELECT * FROM payroll_records WHERE period_start = :periodStart AND period_end = :periodEnd AND company_id = :companyId ORDER BY worker_id ASC")
    fun getByPeriod(periodStart: String, periodEnd: String, companyId: Int): Flow<List<PayrollRecord>>

    @Query("SELECT * FROM payroll_records WHERE period_start = :periodStart AND period_end = :periodEnd AND company_id = :companyId ORDER BY worker_id ASC")
    fun getByPeriodSync(periodStart: String, periodEnd: String, companyId: Int): List<PayrollRecord>

    @Query("SELECT * FROM payroll_records WHERE company_id = :companyId ORDER BY period_start DESC")
    fun getAllSync(companyId: Int): List<PayrollRecord>

    @Query("SELECT * FROM payroll_records WHERE status = :status AND company_id = :companyId ORDER BY period_start DESC")
    fun getByStatus(status: String, companyId: Int): Flow<List<PayrollRecord>>

    @Query("SELECT * FROM payroll_records WHERE synced = 0 AND company_id = :companyId ORDER BY created_at ASC")
    fun getUnsynced(companyId: Int): Flow<List<PayrollRecord>>

    @Query("SELECT COUNT(*) FROM payroll_records WHERE status = 'pending' AND company_id = :companyId")
    fun countPending(companyId: Int): Int

    @Query("SELECT SUM(net_pay) FROM payroll_records WHERE status = 'paid' AND company_id = :companyId")
    fun sumPaid(companyId: Int): Double

    @Query("SELECT SUM(advance_deduction) FROM payroll_records WHERE status = 'paid' AND company_id = :companyId")
    fun sumAdvanceDeductions(companyId: Int): Double

    @Transaction
    fun upsert(record: PayrollRecord): Long = insert(record)
}