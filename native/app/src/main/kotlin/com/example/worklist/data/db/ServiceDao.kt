package com.example.worklist.data.db

import androidx.room.Dao
import androidx.room.Insert
import androidx.room.OnConflictStrategy
import androidx.room.Query
import androidx.room.Update
import androidx.room.Delete
import androidx.room.Transaction
import com.example.worklist.data.model.ServiceRecord
import kotlinx.coroutines.flow.Flow

@Dao
interface ServiceDao {
    @Insert(onConflict = OnConflictStrategy.REPLACE)
    fun insert(record: ServiceRecord): Long

    @Insert(onConflict = OnConflictStrategy.REPLACE)
    fun insertAll(records: List<ServiceRecord>): List<Long>

    @Update
    fun update(record: ServiceRecord): Int

    @Update
    fun updateAll(records: List<ServiceRecord>): Int

    @Delete
    fun delete(record: ServiceRecord): Int

    @Query("DELETE FROM service_records WHERE company_id = :companyId")
    fun deleteAll(companyId: Int)

    @Query("SELECT * FROM service_records WHERE id = :id AND company_id = :companyId")
    fun getById(id: Int, companyId: Int): Flow<ServiceRecord?>

    @Query("SELECT * FROM service_records WHERE id = :id AND company_id = :companyId")
    fun getByIdSync(id: Int, companyId: Int): ServiceRecord?

    @Query("SELECT * FROM service_records WHERE site_id = :siteId AND company_id = :companyId ORDER BY date DESC")
    fun getBySiteId(siteId: Int, companyId: Int): Flow<List<ServiceRecord>>

    @Query("SELECT * FROM service_records WHERE worker_id = :workerId AND company_id = :companyId ORDER BY date DESC")
    fun getByWorkerId(workerId: Int, companyId: Int): Flow<List<ServiceRecord>>

    @Query("SELECT * FROM service_records WHERE status = :status AND company_id = :companyId ORDER BY date DESC")
    fun getByStatus(status: String, companyId: Int): Flow<List<ServiceRecord>>

    @Query("SELECT * FROM service_records WHERE company_id = :companyId ORDER BY date DESC")
    fun getAll(companyId: Int): Flow<List<ServiceRecord>>

    @Query("SELECT * FROM service_records WHERE company_id = :companyId ORDER BY date DESC")
    fun getAllSync(companyId: Int): List<ServiceRecord>

    @Query("SELECT * FROM service_records WHERE synced = 0 AND company_id = :companyId ORDER BY created_at ASC")
    fun getUnsynced(companyId: Int): Flow<List<ServiceRecord>>

    @Query("SELECT SUM(total_price) FROM service_records WHERE status = 'completed' AND company_id = :companyId")
    fun sumCompleted(companyId: Int): Double

    @Transaction
    fun upsert(record: ServiceRecord): Long = insert(record)
}