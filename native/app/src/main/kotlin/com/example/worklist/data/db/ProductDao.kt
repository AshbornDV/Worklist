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

    @Query("DELETE FROM products")
    fun deleteAll(): Int

    @Query("SELECT * FROM products WHERE id = :id")
    fun getById(id: Int): Flow<Product?>

    @Query("SELECT * FROM products WHERE id = :id")
    fun getByIdSync(id: Int): Product?

    @Query("SELECT * FROM products WHERE site_id = :siteId ORDER BY name ASC")
    fun getBySiteId(siteId: Int): Flow<List<Product>>

    @Query("SELECT * FROM products WHERE site_id = :siteId ORDER BY name ASC")
    fun getBySiteIdSync(siteId: Int): List<Product>

    @Query("SELECT * FROM products ORDER BY name ASC")
    fun getAll(): Flow<List<Product>>

    @Query("SELECT * FROM products ORDER BY name ASC")
    fun getAllSync(): List<Product>

    @Query("SELECT * FROM products WHERE category = :category ORDER BY name ASC")
    fun getByCategory(category: String): Flow<List<Product>>

    @Query("SELECT * FROM products WHERE synced = 0 ORDER BY updated_at ASC")
    fun getUnsynced(): Flow<List<Product>>

    @Query("SELECT COUNT(*) FROM products")
    fun count(): Int

    @Query("SELECT COUNT(*) FROM products WHERE stock_quantity <= 0")
    fun countOutOfStock(): Int

    @Query("SELECT COUNT(*) FROM products WHERE stock_quantity > 0 AND stock_quantity <= critical_stock")
    fun countCritical(): Int

    @Query("SELECT COUNT(*) FROM products WHERE stock_quantity > critical_stock AND stock_quantity <= minimum_stock")
    fun countLow(): Int

    @Query("SELECT * FROM products WHERE stock_quantity <= 0 ORDER BY name ASC")
    fun getOutOfStock(): Flow<List<Product>>

    @Query("SELECT * FROM products WHERE stock_quantity <= 0 ORDER BY name ASC")
    fun getOutOfStockSync(): List<Product>

    @Query("SELECT * FROM products WHERE stock_quantity > 0 AND stock_quantity <= critical_stock ORDER BY name ASC")
    fun getCritical(): Flow<List<Product>>

    @Query("SELECT * FROM products WHERE stock_quantity > 0 AND stock_quantity <= critical_stock ORDER BY name ASC")
    fun getCriticalSync(): List<Product>

    @Query("SELECT * FROM products WHERE stock_quantity > critical_stock AND stock_quantity <= minimum_stock ORDER BY name ASC")
    fun getLow(): Flow<List<Product>>

    @Query("SELECT * FROM products WHERE stock_quantity > critical_stock AND stock_quantity <= minimum_stock ORDER BY name ASC")
    fun getLowSync(): List<Product>

    @Query("SELECT * FROM products WHERE name LIKE :query ORDER BY name ASC")
    fun search(query: String): Flow<List<Product>>

    @Query("SELECT SUM(stock_quantity * unit_price) FROM products")
    fun getTotalInventoryValue(): Double

    @Transaction
    fun upsert(product: Product): Long = insert(product)
}