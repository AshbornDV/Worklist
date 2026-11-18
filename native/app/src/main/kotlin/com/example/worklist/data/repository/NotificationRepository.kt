package com.example.worklist.data.repository

import com.example.worklist.data.db.NotificationDao
import com.example.worklist.data.model.Notification
import kotlinx.coroutines.flow.Flow

interface NotificationRepository {
    suspend fun insert(notification: Notification): Long
    suspend fun insertAll(notifications: List<Notification>): List<Long>
    suspend fun update(notification: Notification): Int
    suspend fun updateAll(notifications: List<Notification>): Int
    suspend fun delete(notification: Notification): Int
    suspend fun deleteAll(): Int
    fun getById(id: Int): Flow<Notification?>
    fun getByUserId(userId: Int): Flow<List<Notification>>
    suspend fun getByUserIdSync(userId: Int): List<Notification>
    fun getUnreadByUserId(userId: Int): Flow<List<Notification>>
    fun getByType(type: String): Flow<List<Notification>>
    fun getUnsynced(): Flow<List<Notification>>
    suspend fun countUnread(userId: Int): Int
    suspend fun upsert(notification: Notification): Long
}

class NotificationRepositoryImpl(private val dao: NotificationDao) : NotificationRepository {
    override suspend fun insert(notification: Notification): Long = dao.insert(notification)
    override suspend fun insertAll(notifications: List<Notification>): List<Long> = dao.insertAll(notifications)
    override suspend fun update(notification: Notification): Int = dao.update(notification)
    override suspend fun updateAll(notifications: List<Notification>): Int = dao.updateAll(notifications)
    override suspend fun delete(notification: Notification): Int = dao.delete(notification)
    override suspend fun deleteAll(): Int = dao.deleteAll()
    override fun getById(id: Int): Flow<Notification?> = dao.getById(id)
    override fun getByUserId(userId: Int): Flow<List<Notification>> = dao.getByUserId(userId)
    override suspend fun getByUserIdSync(userId: Int): List<Notification> = dao.getByUserIdSync(userId)
    override fun getUnreadByUserId(userId: Int): Flow<List<Notification>> = dao.getUnreadByUserId(userId)
    override fun getByType(type: String): Flow<List<Notification>> = dao.getByType(type)
    override fun getUnsynced(): Flow<List<Notification>> = dao.getUnsynced()
    override suspend fun countUnread(userId: Int): Int = dao.countUnread(userId)
    override suspend fun upsert(notification: Notification): Long = dao.upsert(notification)
}