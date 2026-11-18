package com.example.worklist.data.db

import androidx.room.Dao
import androidx.room.Insert
import androidx.room.OnConflictStrategy
import androidx.room.Query
import androidx.room.Update
import androidx.room.Delete
import androidx.room.Transaction
import com.example.worklist.data.model.Company
import kotlinx.coroutines.flow.Flow

@Dao
interface CompanyDao {
    @Insert(onConflict = OnConflictStrategy.REPLACE)
    fun insert(company: Company): Long

    @Update
    fun update(company: Company): Int

    @Delete
    fun delete(company: Company): Int

    @Query("SELECT * FROM companies WHERE id = :id")
    fun getById(id: Int): Flow<Company?>

    @Query("SELECT * FROM companies WHERE id = :id")
    fun getByIdSync(id: Int): Company?

    @Query("SELECT * FROM companies ORDER BY name ASC")
    fun getAll(): Flow<List<Company>>

    @Query("SELECT * FROM companies ORDER BY name ASC")
    fun getAllSync(): List<Company>

    @Query("SELECT * FROM companies WHERE is_active = 1 ORDER BY name ASC")
    fun getActive(): Flow<List<Company>>

    @Transaction
    fun upsert(company: Company): Long = insert(company)
}