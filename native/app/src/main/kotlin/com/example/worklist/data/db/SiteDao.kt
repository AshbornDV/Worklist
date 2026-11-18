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

    @Query("DELETE FROM sites")
    fun deleteAll(): Int

    @Query("SELECT * FROM sites WHERE id = :id")
    fun getById(id: Int): Flow<Site?>

    @Query("SELECT * FROM sites WHERE id = :id")
    fun getByIdSync(id: Int): Site?

    @Query("SELECT * FROM sites ORDER BY name ASC")
    fun getAll(): Flow<List<Site>>

    @Query("SELECT * FROM sites ORDER BY name ASC")
    fun getAllSync(): List<Site>

    @Query("SELECT * FROM sites WHERE status = :status ORDER BY name ASC")
    fun getByStatus(status: String): Flow<List<Site>>

    @Query("SELECT * FROM sites WHERE status = 'active' ORDER BY name ASC")
    fun getActive(): Flow<List<Site>>

    @Query("SELECT * FROM sites WHERE synced = 0 ORDER BY updated_at ASC")
    fun getUnsynced(): Flow<List<Site>>

    @Query("SELECT COUNT(*) FROM sites")
    fun count(): Int

    @Query("SELECT COUNT(*) FROM sites WHERE status = 'active'")
    fun countActive(): Int

    @Query("SELECT * FROM sites WHERE name LIKE :query ORDER BY name ASC")
    fun search(query: String): Flow<List<Site>>

    @Query("SELECT * FROM sites WHERE client_name LIKE :query ORDER BY name ASC")
    fun searchByClient(query: String): Flow<List<Site>>

    @Query("SELECT SUM(CASE WHEN status = 'completed' THEN 1 ELSE 0 END) FROM sites")
    fun countCompleted(): Int

    @Transaction
    fun upsert(site: Site): Long = insert(site)
}