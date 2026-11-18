package com.example.worklist.data.db

import androidx.room.Dao
import androidx.room.Insert
import androidx.room.OnConflictStrategy
import androidx.room.Query
import androidx.room.Update
import androidx.room.Delete
import androidx.room.Transaction
import com.example.worklist.data.model.Attendance
import kotlinx.coroutines.flow.Flow

@Dao
interface AttendanceDao {
    @Insert(onConflict = OnConflictStrategy.REPLACE)
    fun insert(attendance: Attendance): Long

    @Insert(onConflict = OnConflictStrategy.REPLACE)
    fun insertAll(attendance: List<Attendance>): List<Long>

    @Update
    fun update(attendance: Attendance): Int

    @Update
    fun updateAll(attendance: List<Attendance>): Int

    @Delete
    fun delete(attendance: Attendance): Int

    @Query("DELETE FROM attendance")
    fun deleteAll(): Int

    @Query("SELECT * FROM attendance WHERE id = :id AND company_id = :companyId")
    fun getById(id: Int, companyId: Int): Flow<Attendance?>

    @Query("SELECT * FROM attendance WHERE id = :id AND company_id = :companyId")
    fun getByIdSync(id: Int, companyId: Int): Attendance?

    @Query("SELECT * FROM attendance WHERE worker_id = :workerId AND date = :date AND company_id = :companyId")
    fun getByWorkerAndDate(workerId: Int, date: String, companyId: Int): Flow<Attendance?>

    @Query("SELECT * FROM attendance WHERE worker_id = :workerId AND date = :date AND company_id = :companyId")
    fun getByWorkerAndDateSync(workerId: Int, date: String, companyId: Int): Attendance?

    @Query("SELECT * FROM attendance WHERE worker_id = :workerId AND company_id = :companyId ORDER BY date DESC")
    fun getByWorkerId(workerId: Int, companyId: Int): Flow<List<Attendance>>

    @Query("SELECT * FROM attendance WHERE worker_id = :workerId AND company_id = :companyId ORDER BY date DESC")
    fun getByWorkerIdSync(workerId: Int, companyId: Int): List<Attendance>

    @Query("SELECT * FROM attendance WHERE site_id = :siteId AND date = :date AND company_id = :companyId ORDER BY check_in_time ASC")
    fun getBySiteAndDate(siteId: Int, date: String, companyId: Int): Flow<List<Attendance>>

    @Query("SELECT * FROM attendance WHERE site_id = :siteId AND date = :date AND company_id = :companyId ORDER BY check_in_time ASC")
    fun getBySiteAndDateSync(siteId: Int, date: String, companyId: Int): List<Attendance>

    @Query("SELECT * FROM attendance WHERE date BETWEEN :startDate AND :endDate AND company_id = :companyId ORDER BY date DESC, worker_id ASC")
    fun getByDateRange(startDate: String, endDate: String, companyId: Int): Flow<List<Attendance>>

    @Query("SELECT * FROM attendance WHERE date BETWEEN :startDate AND :endDate AND company_id = :companyId ORDER BY date DESC, worker_id ASC")
    fun getByDateRangeSync(startDate: String, endDate: String, companyId: Int): List<Attendance>

    @Query("SELECT * FROM attendance WHERE synced = 0 AND company_id = :companyId ORDER BY date ASC")
    fun getUnsynced(companyId: Int): Flow<List<Attendance>>

    @Query("SELECT * FROM attendance WHERE company_id = :companyId ORDER BY date DESC")
    fun getAllSync(companyId: Int): List<Attendance>

    @Query("SELECT COUNT(*) FROM attendance WHERE worker_id = :workerId AND date = :date AND type = 'full' AND company_id = :companyId")
    fun countFullByWorkerAndDate(workerId: Int, date: String, companyId: Int): Int

    @Query("SELECT COUNT(*) FROM attendance WHERE worker_id = :workerId AND date = :date AND type = 'half' AND company_id = :companyId")
    fun countHalfByWorkerAndDate(workerId: Int, date: String, companyId: Int): Int

    @Query("SELECT COUNT(*) FROM attendance WHERE worker_id = :workerId AND date = :date AND type = 'absent' AND company_id = :companyId")
    fun countAbsentByWorkerAndDate(workerId: Int, date: String, companyId: Int): Int

    @Query("SELECT COUNT(*) FROM attendance WHERE site_id = :siteId AND date = :date AND type = 'full' AND company_id = :companyId")
    fun countFullBySiteAndDate(siteId: Int, date: String, companyId: Int): Int

    @Query("SELECT COUNT(*) FROM attendance WHERE site_id = :siteId AND date = :date AND type = 'half' AND company_id = :companyId")
    fun countHalfBySiteAndDate(siteId: Int, date: String, companyId: Int): Int

    @Query("SELECT COUNT(*) FROM attendance WHERE site_id = :siteId AND date = :date AND type = 'absent' AND company_id = :companyId")
    fun countAbsentBySiteAndDate(siteId: Int, date: String, companyId: Int): Int

    @Query("SELECT * FROM attendance WHERE worker_id = :workerId AND date BETWEEN :startDate AND :endDate AND company_id = :companyId ORDER BY date ASC")
    fun getWorkerChartData(workerId: Int, startDate: String, endDate: String, companyId: Int): Flow<List<Attendance>>

    @Transaction
    fun upsert(attendance: Attendance): Long = insert(attendance)
}