package com.example.worklist.data.db

import androidx.room.Dao
import androidx.room.Insert
import androidx.room.OnConflictStrategy
import androidx.room.Query
import androidx.room.Update
import androidx.room.Delete
import androidx.room.Transaction
import com.example.worklist.data.model.Site
import kotlinx.coroutines.flow.Flow

@Dao
interface SiteDao {
    @Insert(onConflict = OnConflictStrategy.REPLACE)
    fun insert(site: Site): Long

    @Insert(onConflict = OnConflictStrategy.REPLACE)
    fun insertAll(sites: List<Site>): List<Long>

    @Update
    fun update(site: Site): Int

    @Update
    fun updateAll(sites: List<Site>): Int

    @Delete
    fun delete(site: Site): Int

    @Query("DELETE FROM sites WHERE company_id = :companyId")
    fun deleteAll(companyId: Int)

    @Query("SELECT * FROM sites WHERE id = :id AND company_id = :companyId")
    fun getById(id: Int, companyId: Int): Flow<Site?>

    @Query("SELECT * FROM sites WHERE id = :id AND company_id = :companyId")
    fun getByIdSync(id: Int, companyId: Int): Site?

    @Query("SELECT * FROM sites WHERE company_id = :companyId ORDER BY name ASC")
    fun getAll(companyId: Int): Flow<List<Site>>

    @Query("SELECT * FROM sites WHERE company_id = :companyId ORDER BY name ASC")
    fun getAllSync(companyId: Int): List<Site>

    @Query("SELECT * FROM sites WHERE status = :status AND company_id = :companyId ORDER BY name ASC")
    fun getByStatus(status: String, companyId: Int): Flow<List<Site>>

    @Query("SELECT * FROM sites WHERE status = 'active' AND company_id = :companyId ORDER BY name ASC")
    fun getActive(companyId: Int): Flow<List<Site>>

    @Query("SELECT * FROM sites WHERE synced = 0 AND company_id = :companyId ORDER BY updated_at ASC")
    fun getUnsynced(companyId: Int): Flow<List<Site>>

    @Query("SELECT COUNT(*) FROM sites WHERE company_id = :companyId")
    fun count(companyId: Int): Int

    @Query("SELECT COUNT(*) FROM sites WHERE status = 'active' AND company_id = :companyId")
    fun countActive(companyId: Int): Int

    @Query("SELECT * FROM sites WHERE company_id = :companyId AND name LIKE :query ORDER BY name ASC")
    fun search(query: String, companyId: Int): Flow<List<Site>>

    @Query("SELECT * FROM sites WHERE company_id = :companyId AND client_name LIKE :query ORDER BY name ASC")
    fun searchByClient(query: String, companyId: Int): Flow<List<Site>>

    @Query("SELECT SUM(CASE WHEN status = 'completed' THEN 1 ELSE 0 END) FROM sites WHERE company_id = :companyId")
    fun countCompleted(companyId: Int): Int

    @Transaction
    fun upsert(site: Site): Long = insert(site)
}