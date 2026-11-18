package com.example.worklist.data.model

import androidx.room.Entity
import androidx.room.PrimaryKey
import androidx.room.ColumnInfo
import androidx.room.Index


@Entity(
    tableName = "products",
    indices = [Index(value = ["category"]), Index(value = ["site_id"])]
)

data class Product(
    @PrimaryKey(autoGenerate = true)
    @ColumnInfo(name = "id")
    var id: Int = 0,

    @ColumnInfo(name = "name")
    var name: String = "",

    @ColumnInfo(name = "category")
    var category: String = "",

    @ColumnInfo(name = "unit")
    var unit: String = "",

    @ColumnInfo(name = "unit_price")
    var unitPrice: Double = 0.0,

    @ColumnInfo(name = "stock_quantity")
    var stockQuantity: Double = 0.0,

    @ColumnInfo(name = "minimum_stock")
    var minimumStock: Double = 0.0,

    @ColumnInfo(name = "critical_stock")
    var criticalStock: Double = 0.0,

    @ColumnInfo(name = "site_id")
    var siteId: Int = 0,

    @ColumnInfo(name = "supplier")
    var supplier: String = "",

    @ColumnInfo(name = "supplier_contact")
    var supplierContact: String = "",

    @ColumnInfo(name = "description")
    var description: String = "",

    @ColumnInfo(name = "created_at")
    var createdAt: String = "",

    @ColumnInfo(name = "updated_at")
    var updatedAt: String = "",

    @ColumnInfo(name = "synced")
    var synced: Boolean = false
) {
    fun isOutOfStock(): Boolean = stockQuantity <= 0
    fun isCritical(): Boolean = stockQuantity <= criticalStock && stockQuantity > 0
    fun isLow(): Boolean = stockQuantity <= minimumStock && stockQuantity > criticalStock
}