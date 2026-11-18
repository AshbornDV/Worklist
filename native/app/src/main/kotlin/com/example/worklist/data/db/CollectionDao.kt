package com.example.worklist.data.db

import androidx.room.Dao
import androidx.room.Insert
import androidx.room.OnConflictStrategy
import androidx.room.Query
import androidx.room.Update
import androidx.room.Delete
import androidx.room.Transaction
import com.example.worklist.data.model.Collection
import kotlinx.coroutines.flow.Flow

@Dao
interface CollectionDao {
    @Insert(onConflict = OnConflictStrategy.REPLACE)
    fun insert(collection: Collection): Long

    @Insert(onConflict = OnConflictStrategy.REPLACE)
    fun insertAll(collections: List<Collection>): List<Long>

    @Update
    fun update(collection: Collection): Int

    @Update
    fun updateAll(collections: List<Collection>): Int

    @Delete
    fun delete(collection: Collection): Int

    @Query("DELETE FROM collections")
    fun deleteAll(): Int

    @Query("SELECT * FROM collections WHERE id = :id")
    fun getById(id: Int): Flow<Collection?>

    @Query("SELECT * FROM collections WHERE id = :id")
    fun getByIdSync(id: Int): Collection?

    @Query("SELECT * FROM collections WHERE site_id = :siteId ORDER BY due_date ASC")
    fun getBySiteId(siteId: Int): Flow<List<Collection>>

    @Query("SELECT * FROM collections WHERE customer_id = :customerId ORDER BY due_date ASC")
    fun getByCustomerId(customerId: Int): Flow<List<Collection>>

    @Query("SELECT * FROM collections WHERE status = :status ORDER BY due_date ASC")
    fun getByStatus(status: String): Flow<List<Collection>>

    @Query("SELECT * FROM collections ORDER BY due_date ASC")
    fun getAll(): Flow<List<Collection>>

    @Query("SELECT * FROM collections ORDER BY due_date ASC")
    fun getAllSync(): List<Collection>

    @Query("SELECT * FROM collections WHERE synced = 0 ORDER BY created_at ASC")
    fun getUnsynced(): Flow<List<Collection>>

    @Query("SELECT COUNT(*) FROM collections WHERE status = 'pending'")
    fun countPending(): Int

    @Query("SELECT COUNT(*) FROM collections WHERE status = 'overdue'")
    fun countOverdue(): Int

    @Query("SELECT SUM(amount - paid_amount) FROM collections WHERE status IN ('pending', 'overdue', 'partial')")
    fun sumOutstanding(): Double

    @Transaction
    fun upsert(collection: Collection): Long = insert(collection)
}