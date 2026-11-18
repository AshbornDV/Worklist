package com.example.worklist.data.db

import androidx.room.Dao
import androidx.room.Insert
import androidx.room.OnConflictStrategy
import androidx.room.Query
import androidx.room.Update
import androidx.room.Delete
import androidx.room.Transaction
import com.example.worklist.data.model.Product
import kotlinx.coroutines.flow.Flow

@Dao
interface ProductDao {
    @Insert(onConflict = OnConflictStrategy.REPLACE)
    fun insert(product: Product): Long

    @Insert(onConflict = OnConflictStrategy.REPLACE)
    fun insertAll(products: List<Product>): List<Long>

    @Update
    fun update(product: Product): Int

    @Update
    fun updateAll(products: List<Product>): Int

    @Delete
    fun delete(product: Product): Int

    @Query("DELETE FROM products WHERE company_id = :companyId")
    fun deleteAll(companyId: Int)

    @Query("SELECT * FROM products WHERE id = :id AND company_id = :companyId")
    fun getById(id: Int, companyId: Int): Flow<Product?>

    @Query("SELECT * FROM products WHERE id = :id AND company_id = :companyId")
    fun getByIdSync(id: Int, companyId: Int): Product?

    @Query("SELECT * FROM products WHERE site_id = :siteId AND company_id = :companyId ORDER BY name ASC")
    fun getBySiteId(siteId: Int, companyId: Int): Flow<List<Product>>

    @Query("SELECT * FROM products WHERE site_id = :siteId AND company_id = :companyId ORDER BY name ASC")
    fun getBySiteIdSync(siteId: Int, companyId: Int): List<Product>

    @Query("SELECT * FROM products WHERE company_id = :companyId ORDER BY name ASC")
    fun getAll(companyId: Int): Flow<List<Product>>

    @Query("SELECT * FROM products WHERE company_id = :companyId ORDER BY name ASC")
    fun getAllSync(companyId: Int): List<Product>

    @Query("SELECT * FROM products WHERE category = :category AND company_id = :companyId ORDER BY name ASC")
    fun getByCategory(category: String, companyId: Int): Flow<List<Product>>

    @Query("SELECT * FROM products WHERE synced = 0 AND company_id = :companyId ORDER BY updated_at ASC")
    fun getUnsynced(companyId: Int): Flow<List<Product>>

    @Query("SELECT COUNT(*) FROM products WHERE company_id = :companyId")
    fun count(companyId: Int): Int

    @Query("SELECT COUNT(*) FROM products WHERE stock_quantity <= 0 AND company_id = :companyId")
    fun countOutOfStock(companyId: Int): Int

    @Query("SELECT COUNT(*) FROM products WHERE stock_quantity > 0 AND stock_quantity <= critical_stock AND company_id = :companyId")
    fun countCritical(companyId: Int): Int

    @Query("SELECT COUNT(*) FROM products WHERE stock_quantity > critical_stock AND stock_quantity <= minimum_stock AND company_id = :companyId")
    fun countLow(companyId: Int): Int

    @Query("SELECT * FROM products WHERE stock_quantity <= 0 AND company_id = :companyId ORDER BY name ASC")
    fun getOutOfStock(companyId: Int): Flow<List<Product>>

    @Query("SELECT * FROM products WHERE stock_quantity <= 0 AND company_id = :companyId ORDER BY name ASC")
    fun getOutOfStockSync(companyId: Int): List<Product>

    @Query("SELECT * FROM products WHERE stock_quantity > 0 AND stock_quantity <= critical_stock AND company_id = :companyId ORDER BY name ASC")
    fun getCritical(companyId: Int): Flow<List<Product>>

    @Query("SELECT * FROM products WHERE stock_quantity > 0 AND stock_quantity <= critical_stock AND company_id = :companyId ORDER BY name ASC")
    fun getCriticalSync(companyId: Int): List<Product>

    @Query("SELECT * FROM products WHERE stock_quantity > critical_stock AND stock_quantity <= minimum_stock AND company_id = :companyId ORDER BY name ASC")
    fun getLow(companyId: Int): Flow<List<Product>>

    @Query("SELECT * FROM products WHERE stock_quantity > critical_stock AND stock_quantity <= minimum_stock AND company_id = :companyId ORDER BY name ASC")
    fun getLowSync(companyId: Int): List<Product>

    @Query("SELECT * FROM products WHERE company_id = :companyId AND name LIKE :query ORDER BY name ASC")
    fun search(query: String, companyId: Int): Flow<List<Product>>

    @Query("SELECT SUM(stock_quantity * unit_price) FROM products WHERE company_id = :companyId")
    fun getTotalInventoryValue(companyId: Int): Double

    @Transaction
    fun upsert(product: Product): Long = insert(product)
}