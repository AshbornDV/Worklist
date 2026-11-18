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

    @Query("DELETE FROM notifications")
    fun deleteAll(): Int

    @Query("SELECT * FROM notifications WHERE id = :id")
    fun getById(id: Int): Flow<Notification?>

    @Query("SELECT * FROM notifications WHERE user_id = :userId ORDER BY created_at DESC")
    fun getByUserId(userId: Int): Flow<List<Notification>>

    @Query("SELECT * FROM notifications WHERE user_id = :userId ORDER BY created_at DESC")
    fun getByUserIdSync(userId: Int): List<Notification>

    @Query("SELECT * FROM notifications WHERE user_id = :userId AND read = 0 ORDER BY created_at DESC")
    fun getUnreadByUserId(userId: Int): Flow<List<Notification>>

    @Query("SELECT * FROM notifications WHERE type = :type ORDER BY created_at DESC")
    fun getByType(type: String): Flow<List<Notification>>

    @Query("SELECT * FROM notifications WHERE synced = 0 ORDER BY created_at ASC")
    fun getUnsynced(): Flow<List<Notification>>

    @Query("SELECT COUNT(*) FROM notifications WHERE user_id = :userId AND read = 0")
    fun countUnread(userId: Int): Int

    @Transaction
    fun upsert(notification: Notification): Long = insert(notification)
}