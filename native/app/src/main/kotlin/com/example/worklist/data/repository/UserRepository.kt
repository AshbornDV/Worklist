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
    suspend fun deleteAll(companyId: Int)
    fun getById(id: Int, companyId: Int): Flow<User?>
    suspend fun getByIdSync(id: Int, companyId: Int): User?
    fun getByUsername(username: String, companyId: Int): Flow<User?>
    suspend fun getByUsernameSync(username: String, companyId: Int): User?
    fun getByEmail(email: String, companyId: Int): Flow<User?>
    suspend fun getByEmailSync(email: String, companyId: Int): User?
    fun getByRole(role: String, companyId: Int): Flow<List<User>>
    fun getActive(companyId: Int): Flow<List<User>>
    fun getAll(companyId: Int): Flow<List<User>>
    fun getUnsynced(companyId: Int): Flow<List<User>>
    suspend fun upsert(user: User): Long
}

class UserRepositoryImpl(private val dao: UserDao) : UserRepository {
    override suspend fun insert(user: User): Long = dao.insert(user)
    override suspend fun insertAll(users: List<User>): List<Long> = dao.insertAll(users)
    override suspend fun update(user: User): Int = dao.update(user)
    override suspend fun updateAll(users: List<User>): Int = dao.updateAll(users)
    override suspend fun delete(user: User): Int = dao.delete(user)
    override suspend fun deleteAll(companyId: Int) = dao.deleteAll(companyId)
    override fun getById(id: Int, companyId: Int): Flow<User?> = dao.getById(id, companyId)
    override suspend fun getByIdSync(id: Int, companyId: Int): User? = dao.getByIdSync(id, companyId)
    override fun getByUsername(username: String, companyId: Int): Flow<User?> = dao.getByUsername(username, companyId)
    override suspend fun getByUsernameSync(username: String, companyId: Int): User? = dao.getByUsernameSync(username, companyId)
    override fun getByEmail(email: String, companyId: Int): Flow<User?> = dao.getByEmail(email, companyId)
    override suspend fun getByEmailSync(email: String, companyId: Int): User? = dao.getByEmailSync(email, companyId)
    override fun getByRole(role: String, companyId: Int): Flow<List<User>> = dao.getByRole(role, companyId)
    override fun getActive(companyId: Int): Flow<List<User>> = dao.getActive(companyId)
    override fun getAll(companyId: Int): Flow<List<User>> = dao.getAll(companyId)
    override fun getUnsynced(companyId: Int): Flow<List<User>> = dao.getUnsynced(companyId)
    override suspend fun upsert(user: User): Long = dao.upsert(user)
}