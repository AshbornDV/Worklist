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

    @Query("DELETE FROM users")
    fun deleteAll(): Int

    @Query("SELECT * FROM users WHERE id = :id")
    fun getById(id: Int): Flow<User?>

    @Query("SELECT * FROM users WHERE id = :id")
    fun getByIdSync(id: Int): User?

    @Query("SELECT * FROM users WHERE username = :username")
    fun getByUsername(username: String): Flow<User?>

    @Query("SELECT * FROM users WHERE username = :username")
    fun getByUsernameSync(username: String): User?

    @Query("SELECT * FROM users WHERE email = :email")
    fun getByEmail(email: String): Flow<User?>

    @Query("SELECT * FROM users WHERE email = :email")
    fun getByEmailSync(email: String): User?

    @Query("SELECT * FROM users WHERE role = :role ORDER BY username ASC")
    fun getByRole(role: String): Flow<List<User>>

    @Query("SELECT * FROM users WHERE is_active = 1 ORDER BY username ASC")
    fun getActive(): Flow<List<User>>

    @Query("SELECT * FROM users ORDER BY username ASC")
    fun getAll(): Flow<List<User>>

    @Query("SELECT * FROM users WHERE synced = 0 ORDER BY updated_at ASC")
    fun getUnsynced(): Flow<List<User>>

    @Transaction
    fun upsert(user: User): Long = insert(user)
}