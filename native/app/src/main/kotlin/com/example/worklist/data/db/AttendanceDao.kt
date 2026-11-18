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

    @Query("SELECT * FROM attendance WHERE id = :id")
    fun getById(id: Int): Flow<Attendance?>

    @Query("SELECT * FROM attendance WHERE id = :id")
    fun getByIdSync(id: Int): Attendance?

    @Query("SELECT * FROM attendance WHERE worker_id = :workerId AND date = :date")
    fun getByWorkerAndDate(workerId: Int, date: String): Flow<Attendance?>

    @Query("SELECT * FROM attendance WHERE worker_id = :workerId AND date = :date")
    fun getByWorkerAndDateSync(workerId: Int, date: String): Attendance?

    @Query("SELECT * FROM attendance WHERE worker_id = :workerId ORDER BY date DESC")
    fun getByWorkerId(workerId: Int): Flow<List<Attendance>>

    @Query("SELECT * FROM attendance WHERE site_id = :siteId AND date = :date ORDER BY check_in_time ASC")
    fun getBySiteAndDate(siteId: Int, date: String): Flow<List<Attendance>>

    @Query("SELECT * FROM attendance WHERE site_id = :siteId AND date = :date ORDER BY check_in_time ASC")
    fun getBySiteAndDateSync(siteId: Int, date: String): List<Attendance>

    @Query("SELECT * FROM attendance WHERE date BETWEEN :startDate AND :endDate ORDER BY date DESC, worker_id ASC")
    fun getByDateRange(startDate: String, endDate: String): Flow<List<Attendance>>

    @Query("SELECT * FROM attendance WHERE date BETWEEN :startDate AND :endDate ORDER BY date DESC, worker_id ASC")
    fun getByDateRangeSync(startDate: String, endDate: String): List<Attendance>

    @Query("SELECT * FROM attendance WHERE synced = 0 ORDER BY date ASC")
    fun getUnsynced(): Flow<List<Attendance>>

    @Query("SELECT COUNT(*) FROM attendance WHERE worker_id = :workerId AND date = :date AND type = 'full'")
    fun countFullByWorkerAndDate(workerId: Int, date: String): Int

    @Query("SELECT COUNT(*) FROM attendance WHERE worker_id = :workerId AND date = :date AND type = 'half'")
    fun countHalfByWorkerAndDate(workerId: Int, date: String): Int

    @Query("SELECT COUNT(*) FROM attendance WHERE worker_id = :workerId AND date = :date AND type = 'absent'")
    fun countAbsentByWorkerAndDate(workerId: Int, date: String): Int

    @Query("SELECT COUNT(*) FROM attendance WHERE site_id = :siteId AND date = :date AND type = 'full'")
    fun countFullBySiteAndDate(siteId: Int, date: String): Int

    @Query("SELECT COUNT(*) FROM attendance WHERE site_id = :siteId AND date = :date AND type = 'half'")
    fun countHalfBySiteAndDate(siteId: Int, date: String): Int

    @Query("SELECT COUNT(*) FROM attendance WHERE site_id = :siteId AND date = :date AND type = 'absent'")
    fun countAbsentBySiteAndDate(siteId: Int, date: String): Int

    @Query("SELECT * FROM attendance WHERE worker_id = :workerId AND date BETWEEN :startDate AND :endDate ORDER BY date ASC")
    fun getWorkerChartData(workerId: Int, startDate: String, endDate: String): Flow<List<Attendance>>

    @Transaction
    fun upsert(attendance: Attendance): Long = insert(attendance)
}