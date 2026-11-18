package com.example.worklist.data.model

import androidx.room.Entity
import androidx.room.PrimaryKey
import androidx.room.ColumnInfo
import androidx.room.Index


@Entity(
    tableName = "collections",
    indices = [Index(value = ["site_id"]), Index(value = ["customer_id"]), Index(value = ["status"])]
)

data class Collection(
    @PrimaryKey(autoGenerate = true)
    @ColumnInfo(name = "id")
    var id: Int = 0,

    @ColumnInfo(name = "site_id")
    var siteId: Int = 0,

    @ColumnInfo(name = "customer_id")
    var customerId: Int = 0,

    @ColumnInfo(name = "customer_name")
    var customerName: String = "",

    @ColumnInfo(name = "amount")
    var amount: Double = 0.0,

    @ColumnInfo(name = "paid_amount")
    var paidAmount: Double = 0.0,

    @ColumnInfo(name = "due_date")
    var dueDate: String = "",

    @ColumnInfo(name = "status")
    var status: String = "pending",

    @ColumnInfo(name = "payment_method")
    var paymentMethod: String = "",

    @ColumnInfo(name = "reference_number")
    var referenceNumber: String = "",

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
        const val STATUS_PAID = "paid"
        const val STATUS_PARTIAL = "partial"
        const val STATUS_OVERDUE = "overdue"
    }

    fun remainingAmount(): Double = amount - paidAmount
    fun isOverdue(): Boolean = status == STATUS_OVERDUE || (status == STATUS_PENDING && dueDate != "" && dueDate < java.time.LocalDate.now().toString())
}