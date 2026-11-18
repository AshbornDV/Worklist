package com.example.worklist.data.model

import androidx.room.Entity
import androidx.room.PrimaryKey
import androidx.room.ColumnInfo
import androidx.room.Index


@Entity(
    tableName = "service_records",
    indices = [
        Index(value = ["company_id"]),
        Index(value = ["site_id"]),
        Index(value = ["worker_id"]),
        Index(value = ["status"])
    ]
)

data class ServiceRecord(
    @PrimaryKey(autoGenerate = true)
    @ColumnInfo(name = "id")
    var id: Int = 0,

    @ColumnInfo(name = "company_id")
    var companyId: Int = 0,

    @ColumnInfo(name = "site_id")
    var siteId: Int = 0,

    @ColumnInfo(name = "worker_id")
    var workerId: Int = 0,

    @ColumnInfo(name = "service_name")
    var serviceName: String = "",

    @ColumnInfo(name = "description")
    var description: String = "",

    @ColumnInfo(name = "quantity")
    var quantity: Double = 0.0,

    @ColumnInfo(name = "unit_price")
    var unitPrice: Double = 0.0,

    @ColumnInfo(name = "total_price")
    var totalPrice: Double = 0.0,

    @ColumnInfo(name = "date")
    var date: String = "",

    @ColumnInfo(name = "status")
    var status: String = "pending",

    @ColumnInfo(name = "notes")
    var notes: String = "",

    @ColumnInfo(name = "created_at")
    var createdAt: String = "",

    @ColumnInfo(name = "updated_at")
    var updatedAt: String = "",

    @ColumnInfo(name = "synced")
    var synced: Boolean = false
) {
    companion object {
        const val STATUS_PENDING = "pending"
        const val STATUS_IN_PROGRESS = "in_progress"
        const val STATUS_COMPLETED = "completed"
        const val STATUS_CANCELLED = "cancelled"
    }
}