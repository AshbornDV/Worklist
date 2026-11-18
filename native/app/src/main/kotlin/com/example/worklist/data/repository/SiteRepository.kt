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
    suspend fun deleteAll(companyId: Int)
    fun getById(id: Int, companyId: Int): Flow<Site?>
    suspend fun getByIdSync(id: Int, companyId: Int): Site?
    fun getAll(companyId: Int): Flow<List<Site>>
    suspend fun getAllSync(companyId: Int): List<Site>
    fun getByStatus(status: String, companyId: Int): Flow<List<Site>>
    fun getActive(companyId: Int): Flow<List<Site>>
    fun getUnsynced(companyId: Int): Flow<List<Site>>
    suspend fun count(companyId: Int): Int
    suspend fun countActive(companyId: Int): Int
    suspend fun countCompleted(companyId: Int): Int
    fun search(query: String, companyId: Int): Flow<List<Site>>
    fun searchByClient(query: String, companyId: Int): Flow<List<Site>>
    suspend fun upsert(site: Site): Long
}

class SiteRepositoryImpl(private val dao: SiteDao) : SiteRepository {
    override suspend fun insert(site: Site): Long = dao.insert(site)
    override suspend fun insertAll(sites: List<Site>): List<Long> = dao.insertAll(sites)
    override suspend fun update(site: Site): Int = dao.update(site)
    override suspend fun updateAll(sites: List<Site>): Int = dao.updateAll(sites)
    override suspend fun delete(site: Site): Int = dao.delete(site)
    override suspend fun deleteAll(companyId: Int) = dao.deleteAll(companyId)
    override fun getById(id: Int, companyId: Int): Flow<Site?> = dao.getById(id, companyId)
    override suspend fun getByIdSync(id: Int, companyId: Int): Site? = dao.getByIdSync(id, companyId)
    override fun getAll(companyId: Int): Flow<List<Site>> = dao.getAll(companyId)
    override suspend fun getAllSync(companyId: Int): List<Site> = dao.getAllSync(companyId)
    override fun getByStatus(status: String, companyId: Int): Flow<List<Site>> = dao.getByStatus(status, companyId)
    override fun getActive(companyId: Int): Flow<List<Site>> = dao.getActive(companyId)
    override fun getUnsynced(companyId: Int): Flow<List<Site>> = dao.getUnsynced(companyId)
    override suspend fun count(companyId: Int): Int = dao.count(companyId)
    override suspend fun countActive(companyId: Int): Int = dao.countActive(companyId)
    override suspend fun countCompleted(companyId: Int): Int = dao.countCompleted(companyId)
    override fun search(query: String, companyId: Int): Flow<List<Site>> = dao.search(query, companyId)
    override fun searchByClient(query: String, companyId: Int): Flow<List<Site>> = dao.searchByClient(query, companyId)
    override suspend fun upsert(site: Site): Long = dao.upsert(site)
}