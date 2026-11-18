package com.example.worklist.data.db

import androidx.room.Dao
import androidx.room.Insert
import androidx.room.OnConflictStrategy
import androidx.room.Query
import androidx.room.Update
import androidx.room.Delete
import androidx.room.Transaction
import com.example.worklist.data.model.CompanyMembership
import kotlinx.coroutines.flow.Flow

@Dao
interface CompanyMembershipDao {
    @Insert(onConflict = OnConflictStrategy.REPLACE)
    fun insert(membership: CompanyMembership): Long

    @Update
    fun update(membership: CompanyMembership): Int

    @Delete
    fun delete(membership: CompanyMembership): Int

    @Query("SELECT * FROM company_memberships WHERE id = :id")
    fun getById(id: Int): Flow<CompanyMembership?>

    @Query("SELECT * FROM company_memberships WHERE company_id = :companyId AND user_id = :userId")
    fun getByCompanyAndUser(companyId: Int, userId: Int): Flow<CompanyMembership?>

    @Query("SELECT * FROM company_memberships WHERE company_id = :companyId")
    fun getByCompanyId(companyId: Int): Flow<List<CompanyMembership>>

    @Query("SELECT * FROM company_memberships WHERE user_id = :userId")
    fun getByUserId(userId: Int): Flow<List<CompanyMembership>>

    @Transaction
    fun upsert(membership: CompanyMembership): Long = insert(membership)
}