package com.example.worklist.data.db

import androidx.room.Dao
import androidx.room.Insert
import androidx.room.OnConflictStrategy
import androidx.room.Query
import androidx.room.Update
import androidx.room.Delete
import androidx.room.Transaction
import com.example.worklist.data.model.User
import kotlinx.coroutines.flow.Flow

@Dao
interface UserDao {
    @Insert(onConflict = OnConflictStrategy.REPLACE)
    fun insert(user: User): Long

    @Insert(onConflict = OnConflictStrategy.REPLACE)
    fun insertAll(users: List<User>): List<Long>

    @Update
    fun update(user: User): Int

    @Update
    fun updateAll(users: List<User>): Int

    @Delete
    fun delete(user: User): Int

    @Query("DELETE FROM users WHERE company_id = :companyId")
    fun deleteAll(companyId: Int)

    @Query("SELECT * FROM users WHERE id = :id AND company_id = :companyId")
    fun getById(id: Int, companyId: Int): Flow<User?>

    @Query("SELECT * FROM users WHERE id = :id AND company_id = :companyId")
    fun getByIdSync(id: Int, companyId: Int): User?

    @Query("SELECT * FROM users WHERE username = :username AND company_id = :companyId")
    fun getByUsername(username: String, companyId: Int): Flow<User?>

    @Query("SELECT * FROM users WHERE username = :username AND company_id = :companyId")
    fun getByUsernameSync(username: String, companyId: Int): User?

    @Query("SELECT * FROM users WHERE email = :email AND company_id = :companyId")
    fun getByEmail(email: String, companyId: Int): Flow<User?>

    @Query("SELECT * FROM users WHERE email = :email AND company_id = :companyId")
    fun getByEmailSync(email: String, companyId: Int): User?

    @Query("SELECT * FROM users WHERE role = :role AND company_id = :companyId ORDER BY username ASC")
    fun getByRole(role: String, companyId: Int): Flow<List<User>>

    @Query("SELECT * FROM users WHERE is_active = 1 AND company_id = :companyId ORDER BY username ASC")
    fun getActive(companyId: Int): Flow<List<User>>

    @Query("SELECT * FROM users WHERE company_id = :companyId ORDER BY username ASC")
    fun getAll(companyId: Int): Flow<List<User>>

    @Query("SELECT * FROM users WHERE synced = 0 AND company_id = :companyId ORDER BY updated_at ASC")
    fun getUnsynced(companyId: Int): Flow<List<User>>

    @Query("SELECT * FROM users WHERE company_id = :companyId ORDER BY username ASC")
    fun getAllSync(companyId: Int): List<User>

    @Transaction
    fun upsert(user: User): Long = insert(user)
}