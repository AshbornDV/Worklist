package com.example.worklist.data.model

import androidx.room.Entity
import androidx.room.PrimaryKey
import androidx.room.ColumnInfo
import androidx.room.Index

@Entity(
    tableName = "payments",
    indices = [
        Index(value = ["company_id"]),
        Index(value = ["worker_id"]),
        Index(value = ["site_id"]),
        Index(value = ["payroll_record_id"])
    ]
)
data class Payment(
    @PrimaryKey(autoGenerate = true)
    @ColumnInfo(name = "id")
    var id: Int = 0,

    @ColumnInfo(name = "company_id")
    var companyId: Int = 0,

    @ColumnInfo(name = "worker_id")
    var workerId: Int = 0,

    @ColumnInfo(name = "site_id")
    var siteId: Int = 0,

    @ColumnInfo(name = "payroll_record_id")
    var payrollRecordId: Int = 0,

    @ColumnInfo(name = "amount")
    var amount: Double = 0.0,

    @ColumnInfo(name = "rate_basis")
    var rateBasis: String = RATE_BASIS_DAILY,

    @ColumnInfo(name = "daily_rate")
    var dailyRate: Double = 0.0,

    @ColumnInfo(name = "job_rate")
    var jobRate: Double = 0.0,

    @ColumnInfo(name = "days_or_jobs")
    var daysOrJobs: Double = 0.0,

    @ColumnInfo(name = "paid_date")
    var paidDate: String = "",

    @ColumnInfo(name = "payment_method")
    var paymentMethod: String = "",

    @ColumnInfo(name = "reference_number")
    var referenceNumber: String = "",

    @ColumnInfo(name = "notes")
    var notes: String = "",

    @ColumnInfo(name = "created_at")
    var createdAt: String = "",
) {
    companion object {
        const val RATE_BASIS_DAILY = "daily"
        const val RATE_BASIS_JOB = "job"
    }
}