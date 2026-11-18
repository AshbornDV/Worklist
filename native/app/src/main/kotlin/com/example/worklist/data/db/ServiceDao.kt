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

    @Query("DELETE FROM service_records")
    fun deleteAll(): Int

    @Query("SELECT * FROM service_records WHERE id = :id")
    fun getById(id: Int): Flow<ServiceRecord?>

    @Query("SELECT * FROM service_records WHERE id = :id")
    fun getByIdSync(id: Int): ServiceRecord?

    @Query("SELECT * FROM service_records WHERE site_id = :siteId ORDER BY date DESC")
    fun getBySiteId(siteId: Int): Flow<List<ServiceRecord>>

    @Query("SELECT * FROM service_records WHERE worker_id = :workerId ORDER BY date DESC")
    fun getByWorkerId(workerId: Int): Flow<List<ServiceRecord>>

    @Query("SELECT * FROM service_records WHERE status = :status ORDER BY date DESC")
    fun getByStatus(status: String): Flow<List<ServiceRecord>>

    @Query("SELECT * FROM service_records ORDER BY date DESC")
    fun getAll(): Flow<List<ServiceRecord>>

    @Query("SELECT * FROM service_records ORDER BY date DESC")
    fun getAllSync(): List<ServiceRecord>

    @Query("SELECT * FROM service_records WHERE synced = 0 ORDER BY created_at ASC")
    fun getUnsynced(): Flow<List<ServiceRecord>>

    @Query("SELECT SUM(total_price) FROM service_records WHERE status = 'completed'")
    fun sumCompleted(): Double

    @Transaction
    fun upsert(record: ServiceRecord): Long = insert(record)
}