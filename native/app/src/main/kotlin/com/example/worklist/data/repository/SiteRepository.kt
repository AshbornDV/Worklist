package com.example.worklist.data.repository

import com.example.worklist.data.db.SiteDao
import com.example.worklist.data.model.Site
import kotlinx.coroutines.flow.Flow

interface SiteRepository {
    suspend fun insert(site: Site): Long
    suspend fun insertAll(sites: List<Site>): List<Long>
    suspend fun update(site: Site): Int
    suspend fun updateAll(sites: List<Site>): Int
    suspend fun delete(site: Site): Int
    suspend fun deleteAll(): Int
    fun getById(id: Int): Flow<Site?>
    suspend fun getByIdSync(id: Int): Site?
    fun getAll(): Flow<List<Site>>
    suspend fun getAllSync(): List<Site>
    fun getByStatus(status: String): Flow<List<Site>>
    fun getActive(): Flow<List<Site>>
    fun getUnsynced(): Flow<List<Site>>
    suspend fun count(): Int
    suspend fun countActive(): Int
    suspend fun countCompleted(): Int
    fun search(query: String): Flow<List<Site>>
    fun searchByClient(query: String): Flow<List<Site>>
    suspend fun upsert(site: Site): Long
}

class SiteRepositoryImpl(private val dao: SiteDao) : SiteRepository {
    override suspend fun insert(site: Site): Long = dao.insert(site)
    override suspend fun insertAll(sites: List<Site>): List<Long> = dao.insertAll(sites)
    override suspend fun update(site: Site): Int = dao.update(site)
    override suspend fun updateAll(sites: List<Site>): Int = dao.updateAll(sites)
    override suspend fun delete(site: Site): Int = dao.delete(site)
    override suspend fun deleteAll(): Int = dao.deleteAll()
    override fun getById(id: Int): Flow<Site?> = dao.getById(id)
    override suspend fun getByIdSync(id: Int): Site? = dao.getByIdSync(id)
    override fun getAll(): Flow<List<Site>> = dao.getAll()
    override suspend fun getAllSync(): List<Site> = dao.getAllSync()
    override fun getByStatus(status: String): Flow<List<Site>> = dao.getByStatus(status)
    override fun getActive(): Flow<List<Site>> = dao.getActive()
    override fun getUnsynced(): Flow<List<Site>> = dao.getUnsynced()
    override suspend fun count(): Int = dao.count()
    override suspend fun countActive(): Int = dao.countActive()
    override suspend fun countCompleted(): Int = dao.countCompleted()
    override fun search(query: String): Flow<List<Site>> = dao.search(query)
    override fun searchByClient(query: String): Flow<List<Site>> = dao.searchByClient(query)
    override suspend fun upsert(site: Site): Long = dao.upsert(site)
}