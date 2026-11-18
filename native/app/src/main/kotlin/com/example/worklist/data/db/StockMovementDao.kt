package com.example.worklist.data.db

import androidx.room.Dao
import androidx.room.Insert
import androidx.room.OnConflictStrategy
import androidx.room.Query
import androidx.room.Update
import androidx.room.Delete
import androidx.room.Transaction
import com.example.worklist.data.model.StockMovement
import kotlinx.coroutines.flow.Flow

@Dao
interface StockMovementDao {
    @Insert(onConflict = OnConflictStrategy.REPLACE)
    fun insert(movement: StockMovement): Long

    @Update
    fun update(movement: StockMovement): Int

    @Delete
    fun delete(movement: StockMovement): Int

    @Query("SELECT * FROM stock_movements WHERE id = :id")
    fun getById(id: Int): Flow<StockMovement?>

    @Query("SELECT * FROM stock_movements WHERE product_id = :productId AND company_id = :companyId ORDER BY movement_date DESC")
    fun getByProduct(productId: Int, companyId: Int): Flow<List<StockMovement>>

    @Query("SELECT * FROM stock_movements WHERE site_id = :siteId AND company_id = :companyId ORDER BY movement_date DESC")
    fun getBySite(siteId: Int, companyId: Int): Flow<List<StockMovement>>

    @Query("SELECT * FROM stock_movements WHERE company_id = :companyId AND type = :type ORDER BY movement_date DESC")
    fun getByType(type: String, companyId: Int): Flow<List<StockMovement>>

    @Query("SELECT COALESCE(SUM(CASE WHEN type = 'ship' THEN quantity ELSE -quantity END), 0) FROM stock_movements WHERE product_id = :productId AND company_id = :companyId")
    fun netQuantity(productId: Int, companyId: Int): Double

    @Query("SELECT COALESCE(SUM(total_cost), 0) FROM stock_movements WHERE company_id = :companyId AND type != 'return'")
    fun totalCostByCompany(companyId: Int): Double

    @Transaction
    fun upsert(movement: StockMovement): Long = insert(movement)
}