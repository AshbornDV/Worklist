package com.example.worklist.data.repository

import com.example.worklist.data.db.UserDao
import com.example.worklist.data.model.User
import kotlinx.coroutines.flow.Flow

interface UserRepository {
    suspend fun insert(user: User): Long
    suspend fun insertAll(users: List<User>): List<Long>
    suspend fun update(user: User): Int
    suspend fun updateAll(users: List<User>): Int
    suspend fun delete(user: User): Int
    suspend fun deleteAll(): Int
    fun getById(id: Int): Flow<User?>
    suspend fun getByIdSync(id: Int): User?
    fun getByUsername(username: String): Flow<User?>
    suspend fun getByUsernameSync(username: String): User?
    fun getByEmail(email: String): Flow<User?>
    suspend fun getByEmailSync(email: String): User?
    fun getByRole(role: String): Flow<List<User>>
    fun getActive(): Flow<List<User>>
    fun getAll(): Flow<List<User>>
    fun getUnsynced(): Flow<List<User>>
    suspend fun upsert(user: User): Long
}

class UserRepositoryImpl(private val dao: UserDao) : UserRepository {
    override suspend fun insert(user: User): Long = dao.insert(user)
    override suspend fun insertAll(users: List<User>): List<Long> = dao.insertAll(users)
    override suspend fun update(user: User): Int = dao.update(user)
    override suspend fun updateAll(users: List<User>): Int = dao.updateAll(users)
    override suspend fun delete(user: User): Int = dao.delete(user)
    override suspend fun deleteAll(): Int = dao.deleteAll()
    override fun getById(id: Int): Flow<User?> = dao.getById(id)
    override suspend fun getByIdSync(id: Int): User? = dao.getByIdSync(id)
    override fun getByUsername(username: String): Flow<User?> = dao.getByUsername(username)
    override suspend fun getByUsernameSync(username: String): User? = dao.getByUsernameSync(username)
    override fun getByEmail(email: String): Flow<User?> = dao.getByEmail(email)
    override suspend fun getByEmailSync(email: String): User? = dao.getByEmailSync(email)
    override fun getByRole(role: String): Flow<List<User>> = dao.getByRole(role)
    override fun getActive(): Flow<List<User>> = dao.getActive()
    override fun getAll(): Flow<List<User>> = dao.getAll()
    override fun getUnsynced(): Flow<List<User>> = dao.getUnsynced()
    override suspend fun upsert(user: User): Long = dao.upsert(user)
}