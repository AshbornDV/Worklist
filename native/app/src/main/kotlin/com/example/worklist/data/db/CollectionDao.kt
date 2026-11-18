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

    @Query("DELETE FROM collections WHERE company_id = :companyId")
    fun deleteAll(companyId: Int)

    @Query("SELECT * FROM collections WHERE id = :id AND company_id = :companyId")
    fun getById(id: Int, companyId: Int): Flow<Collection?>

    @Query("SELECT * FROM collections WHERE id = :id AND company_id = :companyId")
    fun getByIdSync(id: Int, companyId: Int): Collection?

    @Query("SELECT * FROM collections WHERE site_id = :siteId AND company_id = :companyId ORDER BY due_date ASC")
    fun getBySiteId(siteId: Int, companyId: Int): Flow<List<Collection>>

    @Query("SELECT * FROM collections WHERE customer_id = :customerId AND company_id = :companyId ORDER BY due_date ASC")
    fun getByCustomerId(customerId: Int, companyId: Int): Flow<List<Collection>>

    @Query("SELECT * FROM collections WHERE status = :status AND company_id = :companyId ORDER BY due_date ASC")
    fun getByStatus(status: String, companyId: Int): Flow<List<Collection>>

    @Query("SELECT * FROM collections WHERE company_id = :companyId ORDER BY due_date ASC")
    fun getAll(companyId: Int): Flow<List<Collection>>

    @Query("SELECT * FROM collections WHERE company_id = :companyId ORDER BY due_date ASC")
    fun getAllSync(companyId: Int): List<Collection>

    @Query("SELECT * FROM collections WHERE synced = 0 AND company_id = :companyId ORDER BY created_at ASC")
    fun getUnsynced(companyId: Int): Flow<List<Collection>>

    @Query("SELECT COUNT(*) FROM collections WHERE status = 'pending' AND company_id = :companyId")
    fun countPending(companyId: Int): Int

    @Query("SELECT COUNT(*) FROM collections WHERE status = 'overdue' AND company_id = :companyId")
    fun countOverdue(companyId: Int): Int

    @Query("SELECT SUM(amount - paid_amount) FROM collections WHERE status IN ('pending', 'overdue', 'partial') AND company_id = :companyId")
    fun sumOutstanding(companyId: Int): Double

    @Transaction
    fun upsert(collection: Collection): Long = insert(collection)
}