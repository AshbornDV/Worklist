package com.example.worklist.data.repository

import com.example.worklist.data.db.CompanyDao
import com.example.worklist.data.model.Company
import kotlinx.coroutines.flow.Flow

interface CompanyRepository {
    suspend fun insert(company: Company): Long
    suspend fun update(company: Company): Int
    suspend fun delete(company: Company): Int
    fun getById(id: Int): Flow<Company?>
    suspend fun getByIdSync(id: Int): Company?
    fun getAll(): Flow<List<Company>>
    suspend fun getAllSync(): List<Company>
    fun getActive(): Flow<List<Company>>
    suspend fun upsert(company: Company): Long
}

class CompanyRepositoryImpl(private val dao: CompanyDao) : CompanyRepository {
    override suspend fun insert(company: Company): Long = dao.insert(company)
    override suspend fun update(company: Company): Int = dao.update(company)
    override suspend fun delete(company: Company): Int = dao.delete(company)
    override fun getById(id: Int): Flow<Company?> = dao.getById(id)
    override suspend fun getByIdSync(id: Int): Company? = dao.getByIdSync(id)
    override fun getAll(): Flow<List<Company>> = dao.getAll()
    override suspend fun getAllSync(): List<Company> = dao.getAllSync()
    override fun getActive(): Flow<List<Company>> = dao.getActive()
    override suspend fun upsert(company: Company): Long = dao.upsert(company)
}