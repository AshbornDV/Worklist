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

    @Query("DELETE FROM workers WHERE company_id = :companyId")
    fun deleteAll(companyId: Int)

    @Query("SELECT * FROM workers WHERE id = :id AND company_id = :companyId")
    fun getById(id: Int, companyId: Int): Flow<Worker?>

    @Query("SELECT * FROM workers WHERE id = :id AND company_id = :companyId")
    fun getByIdSync(id: Int, companyId: Int): Worker?

    @Query("SELECT * FROM workers WHERE user_id = :userId AND company_id = :companyId")
    fun getByUserId(userId: Int, companyId: Int): Flow<Worker?>

    @Query("SELECT * FROM workers WHERE site_id = :siteId AND company_id = :companyId ORDER BY full_name ASC")
    fun getBySiteId(siteId: Int, companyId: Int): Flow<List<Worker>>

    @Query("SELECT * FROM workers WHERE site_id = :siteId AND company_id = :companyId ORDER BY full_name ASC")
    fun getBySiteIdSync(siteId: Int, companyId: Int): List<Worker>

    @Query("SELECT * FROM workers WHERE company_id = :companyId ORDER BY full_name ASC")
    fun getAll(companyId: Int): Flow<List<Worker>>

    @Query("SELECT * FROM workers WHERE company_id = :companyId ORDER BY full_name ASC")
    fun getAllSync(companyId: Int): List<Worker>

    @Query("SELECT * FROM workers WHERE status = :status AND company_id = :companyId ORDER BY full_name ASC")
    fun getByStatus(status: String, companyId: Int): Flow<List<Worker>>

    @Query("SELECT * FROM workers WHERE status = 'active' AND company_id = :companyId ORDER BY full_name ASC")
    fun getActive(companyId: Int): Flow<List<Worker>>

    @Query("SELECT * FROM workers WHERE synced = 0 AND company_id = :companyId ORDER BY updated_at ASC")
    fun getUnsynced(companyId: Int): Flow<List<Worker>>

    @Query("SELECT COUNT(*) FROM workers WHERE company_id = :companyId")
    fun count(companyId: Int): Int

    @Query("SELECT COUNT(*) FROM workers WHERE status = 'active' AND company_id = :companyId")
    fun countActive(companyId: Int): Int

    @Query("SELECT COUNT(*) FROM workers WHERE site_id = :siteId AND status = 'active' AND company_id = :companyId")
    fun countActiveBySite(siteId: Int, companyId: Int): Int

    @Query("SELECT * FROM workers WHERE company_id = :companyId AND full_name LIKE :query ORDER BY full_name ASC")
    fun search(query: String, companyId: Int): Flow<List<Worker>>

    @Query("SELECT * FROM workers WHERE company_id = :companyId AND phone LIKE :query ORDER BY full_name ASC")
    fun searchByPhone(query: String, companyId: Int): Flow<List<Worker>>

    @Transaction
    fun upsert(worker: Worker): Long = insert(worker)
}