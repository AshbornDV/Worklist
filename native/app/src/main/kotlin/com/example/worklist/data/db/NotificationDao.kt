package com.example.worklist.data.db

import androidx.room.Dao
import androidx.room.Insert
import androidx.room.OnConflictStrategy
import androidx.room.Query
import androidx.room.Update
import androidx.room.Delete
import androidx.room.Transaction
import com.example.worklist.data.model.Notification
import kotlinx.coroutines.flow.Flow

@Dao
interface NotificationDao {
    @Insert(onConflict = OnConflictStrategy.REPLACE)
    fun insert(notification: Notification): Long

    @Insert(onConflict = OnConflictStrategy.REPLACE)
    fun insertAll(notifications: List<Notification>): List<Long>

    @Update
    fun update(notification: Notification): Int

    @Update
    fun updateAll(notifications: List<Notification>): Int

    @Delete
    fun delete(notification: Notification): Int

    @Query("DELETE FROM notifications WHERE company_id = :companyId")
    fun deleteAll(companyId: Int)

    @Query("SELECT * FROM notifications WHERE id = :id AND company_id = :companyId")
    fun getById(id: Int, companyId: Int): Flow<Notification?>

    @Query("SELECT * FROM notifications WHERE user_id = :userId AND company_id = :companyId ORDER BY created_at DESC")
    fun getByUserId(userId: Int, companyId: Int): Flow<List<Notification>>

    @Query("SELECT * FROM notifications WHERE user_id = :userId AND company_id = :companyId ORDER BY created_at DESC")
    fun getByUserIdSync(userId: Int, companyId: Int): List<Notification>

    @Query("SELECT * FROM notifications WHERE user_id = :userId AND read = 0 AND company_id = :companyId ORDER BY created_at DESC")
    fun getUnreadByUserId(userId: Int, companyId: Int): Flow<List<Notification>>

    @Query("SELECT * FROM notifications WHERE type = :type AND company_id = :companyId ORDER BY created_at DESC")
    fun getByType(type: String, companyId: Int): Flow<List<Notification>>

    @Query("SELECT * FROM notifications WHERE synced = 0 AND company_id = :companyId ORDER BY created_at ASC")
    fun getUnsynced(companyId: Int): Flow<List<Notification>>

    @Query("SELECT COUNT(*) FROM notifications WHERE user_id = :userId AND read = 0 AND company_id = :companyId")
    fun countUnread(userId: Int, companyId: Int): Int

    @Transaction
    fun upsert(notification: Notification): Long = insert(notification)
}