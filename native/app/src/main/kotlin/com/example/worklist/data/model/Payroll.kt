package com.example.worklist.data.model

import androidx.room.Entity
import androidx.room.PrimaryKey
import androidx.room.ColumnInfo
import androidx.room.Index


@Entity(
    tableName = "payroll_records",
    indices = [Index(value = ["worker_id", "period_start", "period_end"]), Index(value = ["site_id"])]
)

data class PayrollRecord(
    @PrimaryKey(autoGenerate = true)
    @ColumnInfo(name = "id")
    var id: Int = 0,

    @ColumnInfo(name = "worker_id")
    var workerId: Int = 0,

    @ColumnInfo(name = "site_id")
    var siteId: Int = 0,

    @ColumnInfo(name = "period_start")
    var periodStart: String = "",

    @ColumnInfo(name = "period_end")
    var periodEnd: String = "",

    @ColumnInfo(name = "days_worked")
    var daysWorked: Double = 0.0,

    @ColumnInfo(name = "daily_wage")
    var dailyWage: Double = 0.0,

    @ColumnInfo(name = "gross_pay")
    var grossPay: Double = 0.0,

    @ColumnInfo(name = "advance_deduction")
    var advanceDeduction: Double = 0.0,

    @ColumnInfo(name = "other_deductions")
    var otherDeductions: Double = 0.0,

    @ColumnInfo(name = "net_pay")
    var netPay: Double = 0.0,

    @ColumnInfo(name = "status")
    var status: String = "pending",

    @ColumnInfo(name = "paid_date")
    var paidDate: String = "",

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
        const val STATUS_CANCELLED = "cancelled"
    }
}