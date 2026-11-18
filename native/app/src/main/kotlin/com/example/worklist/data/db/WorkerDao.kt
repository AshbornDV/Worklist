package com.example.worklist.data.db

import androidx.room.Dao
import androidx.room.Insert
import androidx.room.OnConflictStrategy
import androidx.room.Query
import androidx.room.Update
import androidx.room.Delete
import androidx.room.Transaction
import com.example.worklist.data.model.Worker
import kotlinx.coroutines.flow.Flow

@Dao
interface WorkerDao {
    @Insert(onConflict = OnConflictStrategy.REPLACE)
    fun insert(worker: Worker): Long

    @Insert(onConflict = OnConflictStrategy.REPLACE)
    fun insertAll(workers: List<Worker>): List<Long>

    @Update
    fun update(worker: Worker): Int

    @Update
    fun updateAll(workers: List<Worker>): Int

    @Delete
    fun delete(worker: Worker): Int

    @Query("DELETE FROM workers")
    fun deleteAll(): Int

    @Query("SELECT * FROM workers WHERE id = :id")
    fun getById(id: Int): Flow<Worker?>

    @Query("SELECT * FROM workers WHERE id = :id")
    fun getByIdSync(id: Int): Worker?

    @Query("SELECT * FROM workers WHERE user_id = :userId")
    fun getByUserId(userId: Int): Flow<Worker?>

    @Query("SELECT * FROM workers WHERE site_id = :siteId ORDER BY full_name ASC")
    fun getBySiteId(siteId: Int): Flow<List<Worker>>

    @Query("SELECT * FROM workers WHERE site_id = :siteId ORDER BY full_name ASC")
    fun getBySiteIdSync(siteId: Int): List<Worker>

    @Query("SELECT * FROM workers ORDER BY full_name ASC")
    fun getAll(): Flow<List<Worker>>

    @Query("SELECT * FROM workers ORDER BY full_name ASC")
    fun getAllSync(): List<Worker>

    @Query("SELECT * FROM workers WHERE status = :status ORDER BY full_name ASC")
    fun getByStatus(status: String): Flow<List<Worker>>

    @Query("SELECT * FROM workers WHERE status = 'active' ORDER BY full_name ASC")
    fun getActive(): Flow<List<Worker>>

    @Query("SELECT * FROM workers WHERE synced = 0 ORDER BY updated_at ASC")
    fun getUnsynced(): Flow<List<Worker>>

    @Query("SELECT COUNT(*) FROM workers")
    fun count(): Int

    @Query("SELECT COUNT(*) FROM workers WHERE status = 'active'")
    fun countActive(): Int

    @Query("SELECT COUNT(*) FROM workers WHERE site_id = :siteId AND status = 'active'")
    fun countActiveBySite(siteId: Int): Int

    @Query("SELECT * FROM workers WHERE full_name LIKE :query ORDER BY full_name ASC")
    fun search(query: String): Flow<List<Worker>>

    @Query("SELECT * FROM workers WHERE phone LIKE :query ORDER BY full_name ASC")
    fun searchByPhone(query: String): Flow<List<Worker>>

    @Transaction
    fun upsert(worker: Worker): Long = insert(worker)
}