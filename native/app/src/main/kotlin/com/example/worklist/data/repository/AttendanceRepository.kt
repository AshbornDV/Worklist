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
    suspend fun deleteAll(companyId: Int): Int
    fun getById(id: Int, companyId: Int): Flow<Attendance?>
    suspend fun getByIdSync(id: Int, companyId: Int): Attendance?
    fun getByWorkerAndDate(workerId: Int, date: String, companyId: Int): Flow<Attendance?>
    suspend fun getByWorkerAndDateSync(workerId: Int, date: String, companyId: Int): Attendance?
    fun getByWorkerId(workerId: Int, companyId: Int): Flow<List<Attendance>>
    fun getBySiteAndDate(siteId: Int, date: String, companyId: Int): Flow<List<Attendance>>
    suspend fun getBySiteAndDateSync(siteId: Int, date: String, companyId: Int): List<Attendance>
    fun getByDateRange(startDate: String, endDate: String, companyId: Int): Flow<List<Attendance>>
    suspend fun getByDateRangeSync(startDate: String, endDate: String, companyId: Int): List<Attendance>
    fun getUnsynced(companyId: Int): Flow<List<Attendance>>
    fun countFullByWorkerAndDate(workerId: Int, date: String, companyId: Int): Int
    fun countHalfByWorkerAndDate(workerId: Int, date: String, companyId: Int): Int
    fun countAbsentByWorkerAndDate(workerId: Int, date: String, companyId: Int): Int
    fun countFullBySiteAndDate(siteId: Int, date: String, companyId: Int): Int
    fun countHalfBySiteAndDate(siteId: Int, date: String, companyId: Int): Int
    fun countAbsentBySiteAndDate(siteId: Int, date: String, companyId: Int): Int
    fun getWorkerChartData(workerId: Int, startDate: String, endDate: String, companyId: Int): Flow<List<Attendance>>
    suspend fun upsert(attendance: Attendance): Long
}

class AttendanceRepositoryImpl(private val dao: AttendanceDao) : AttendanceRepository {
    override suspend fun insert(attendance: Attendance): Long = dao.insert(attendance)
    override suspend fun insertAll(attendance: List<Attendance>): List<Long> = dao.insertAll(attendance)
    override suspend fun update(attendance: Attendance): Int = dao.update(attendance)
    override suspend fun updateAll(attendance: List<Attendance>): Int = dao.updateAll(attendance)
    override suspend fun delete(attendance: Attendance): Int = dao.delete(attendance)
    override suspend fun deleteAll(companyId: Int): Int = dao.deleteAll()
    override fun getById(id: Int, companyId: Int): Flow<Attendance?> = dao.getById(id, companyId)
    override suspend fun getByIdSync(id: Int, companyId: Int): Attendance? = dao.getByIdSync(id, companyId)
    override fun getByWorkerAndDate(workerId: Int, date: String, companyId: Int): Flow<Attendance?> = dao.getByWorkerAndDate(workerId, date, companyId)
    override suspend fun getByWorkerAndDateSync(workerId: Int, date: String, companyId: Int): Attendance? = dao.getByWorkerAndDateSync(workerId, date, companyId)
    override fun getByWorkerId(workerId: Int, companyId: Int): Flow<List<Attendance>> = dao.getByWorkerId(workerId, companyId)
    override fun getBySiteAndDate(siteId: Int, date: String, companyId: Int): Flow<List<Attendance>> = dao.getBySiteAndDate(siteId, date, companyId)
    override suspend fun getBySiteAndDateSync(siteId: Int, date: String, companyId: Int): List<Attendance> = dao.getBySiteAndDateSync(siteId, date, companyId)
    override fun getByDateRange(startDate: String, endDate: String, companyId: Int): Flow<List<Attendance>> = dao.getByDateRange(startDate, endDate, companyId)
    override suspend fun getByDateRangeSync(startDate: String, endDate: String, companyId: Int): List<Attendance> = dao.getByDateRangeSync(startDate, endDate, companyId)
    override fun getUnsynced(companyId: Int): Flow<List<Attendance>> = dao.getUnsynced(companyId)
    override fun countFullByWorkerAndDate(workerId: Int, date: String, companyId: Int): Int = dao.countFullByWorkerAndDate(workerId, date, companyId)
    override fun countHalfByWorkerAndDate(workerId: Int, date: String, companyId: Int): Int = dao.countHalfByWorkerAndDate(workerId, date, companyId)
    override fun countAbsentByWorkerAndDate(workerId: Int, date: String, companyId: Int): Int = dao.countAbsentByWorkerAndDate(workerId, date, companyId)
    override fun countFullBySiteAndDate(siteId: Int, date: String, companyId: Int): Int = dao.countFullBySiteAndDate(siteId, date, companyId)
    override fun countHalfBySiteAndDate(siteId: Int, date: String, companyId: Int): Int = dao.countHalfBySiteAndDate(siteId, date, companyId)
    override fun countAbsentBySiteAndDate(siteId: Int, date: String, companyId: Int): Int = dao.countAbsentBySiteAndDate(siteId, date, companyId)
    override fun getWorkerChartData(workerId: Int, startDate: String, endDate: String, companyId: Int): Flow<List<Attendance>> = dao.getWorkerChartData(workerId, startDate, endDate, companyId)
    override suspend fun upsert(attendance: Attendance): Long = dao.upsert(attendance)
}