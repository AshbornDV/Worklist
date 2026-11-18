package com.example.worklist.data.repository

import com.example.worklist.data.db.AttendanceDao
import com.example.worklist.data.model.Attendance
import kotlinx.coroutines.flow.Flow

interface AttendanceRepository {
    suspend fun insert(attendance: Attendance): Long
    suspend fun insertAll(attendance: List<Attendance>): List<Long>
    suspend fun update(attendance: Attendance): Int
    suspend fun updateAll(attendance: List<Attendance>): Int
    suspend fun delete(attendance: Attendance): Int
    suspend fun deleteAll(): Int
    fun getById(id: Int): Flow<Attendance?>
    suspend fun getByIdSync(id: Int): Attendance?
    fun getByWorkerAndDate(workerId: Int, date: String): Flow<Attendance?>
    suspend fun getByWorkerAndDateSync(workerId: Int, date: String): Attendance?
    fun getByWorkerId(workerId: Int): Flow<List<Attendance>>
    fun getBySiteAndDate(siteId: Int, date: String): Flow<List<Attendance>>
    suspend fun getBySiteAndDateSync(siteId: Int, date: String): List<Attendance>
    fun getByDateRange(startDate: String, endDate: String): Flow<List<Attendance>>
    suspend fun getByDateRangeSync(startDate: String, endDate: String): List<Attendance>
    fun getUnsynced(): Flow<List<Attendance>>
    fun countFullByWorkerAndDate(workerId: Int, date: String): Int
    fun countHalfByWorkerAndDate(workerId: Int, date: String): Int
    fun countAbsentByWorkerAndDate(workerId: Int, date: String): Int
    fun countFullBySiteAndDate(siteId: Int, date: String): Int
    fun countHalfBySiteAndDate(siteId: Int, date: String): Int
    fun countAbsentBySiteAndDate(siteId: Int, date: String): Int
    fun getWorkerChartData(workerId: Int, startDate: String, endDate: String): Flow<List<Attendance>>
    suspend fun upsert(attendance: Attendance): Long
}

class AttendanceRepositoryImpl(private val dao: AttendanceDao) : AttendanceRepository {
    override suspend fun insert(attendance: Attendance): Long = dao.insert(attendance)
    override suspend fun insertAll(attendance: List<Attendance>): List<Long> = dao.insertAll(attendance)
    override suspend fun update(attendance: Attendance): Int = dao.update(attendance)
    override suspend fun updateAll(attendance: List<Attendance>): Int = dao.updateAll(attendance)
    override suspend fun delete(attendance: Attendance): Int = dao.delete(attendance)
    override suspend fun deleteAll(): Int = dao.deleteAll()
    override fun getById(id: Int): Flow<Attendance?> = dao.getById(id)
    override suspend fun getByIdSync(id: Int): Attendance? = dao.getByIdSync(id)
    override fun getByWorkerAndDate(workerId: Int, date: String): Flow<Attendance?> = dao.getByWorkerAndDate(workerId, date)
    override suspend fun getByWorkerAndDateSync(workerId: Int, date: String): Attendance? = dao.getByWorkerAndDateSync(workerId, date)
    override fun getByWorkerId(workerId: Int): Flow<List<Attendance>> = dao.getByWorkerId(workerId)
    override fun getBySiteAndDate(siteId: Int, date: String): Flow<List<Attendance>> = dao.getBySiteAndDate(siteId, date)
    override suspend fun getBySiteAndDateSync(siteId: Int, date: String): List<Attendance> = dao.getBySiteAndDateSync(siteId, date)
    override fun getByDateRange(startDate: String, endDate: String): Flow<List<Attendance>> = dao.getByDateRange(startDate, endDate)
    override suspend fun getByDateRangeSync(startDate: String, endDate: String): List<Attendance> = dao.getByDateRangeSync(startDate, endDate)
    override fun getUnsynced(): Flow<List<Attendance>> = dao.getUnsynced()
    override fun countFullByWorkerAndDate(workerId: Int, date: String): Int = dao.countFullByWorkerAndDate(workerId, date)
    override fun countHalfByWorkerAndDate(workerId: Int, date: String): Int = dao.countHalfByWorkerAndDate(workerId, date)
    override fun countAbsentByWorkerAndDate(workerId: Int, date: String): Int = dao.countAbsentByWorkerAndDate(workerId, date)
    override fun countFullBySiteAndDate(siteId: Int, date: String): Int = dao.countFullBySiteAndDate(siteId, date)
    override fun countHalfBySiteAndDate(siteId: Int, date: String): Int = dao.countHalfBySiteAndDate(siteId, date)
    override fun countAbsentBySiteAndDate(siteId: Int, date: String): Int = dao.countAbsentBySiteAndDate(siteId, date)
    override fun getWorkerChartData(workerId: Int, startDate: String, endDate: String): Flow<List<Attendance>> = dao.getWorkerChartData(workerId, startDate, endDate)
    override suspend fun upsert(attendance: Attendance): Long = dao.upsert(attendance)
}