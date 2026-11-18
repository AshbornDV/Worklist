package com.example.worklist.data.model

import androidx.room.Entity
import androidx.room.PrimaryKey
import androidx.room.ColumnInfo
import androidx.room.Index

@Entity(
    tableName = "stock_movements",
    indices = [
        Index(value = ["company_id"]),
        Index(value = ["product_id"]),
        Index(value = ["site_id"]),
        Index(value = ["type"])
    ]
)
data class StockMovement(
    @PrimaryKey(autoGenerate = true)
    @ColumnInfo(name = "id")
    var id: Int = 0,

    @ColumnInfo(name = "company_id")
    var companyId: Int = 0,

    @ColumnInfo(name = "product_id")
    var productId: Int = 0,

    @ColumnInfo(name = "site_id")
    var siteId: Int = 0,

    @ColumnInfo(name = "type")
    var type: String = TYPE_SHIP,

    @ColumnInfo(name = "quantity")
    var quantity: Double = 0.0,

    @ColumnInfo(name = "unit_cost")
    var unitCost: Double = 0.0,

    @ColumnInfo(name = "total_cost")
    var totalCost: Double = 0.0,

    @ColumnInfo(name = "reference_number")
    var referenceNumber: String = "",

    @ColumnInfo(name = "notes")
    var notes: String = "",

    @ColumnInfo(name = "movement_date")
    var movementDate: String = "",

    @ColumnInfo(name = "created_at")
    var createdAt: String = "",
) {
    companion object {
        const val TYPE_SHIP = "ship"
        const val TYPE_USAGE = "usage"
        const val TYPE_ADJUST = "adjust"
        const val TYPE_RETURN = "return"
    }
}