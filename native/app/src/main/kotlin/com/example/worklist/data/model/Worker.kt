package com.example.worklist.data.model

import androidx.room.Entity
import androidx.room.PrimaryKey
import androidx.room.ColumnInfo
import androidx.room.Index


@Entity(
    tableName = "workers",
    indices = [
        Index(value = ["company_id"]),
        Index(value = ["site_id"]),
        Index(value = ["user_id"]),
        Index(value = ["current_site_id"])
    ]
)

data class Worker(
    @PrimaryKey(autoGenerate = true)
    @ColumnInfo(name = "id")
    var id: Int = 0,

    @ColumnInfo(name = "user_id")
    var userId: Int = 0,

    @ColumnInfo(name = "site_id")
    var siteId: Int = 0,

    @ColumnInfo(name = "full_name")
    var fullName: String = "",

    @ColumnInfo(name = "phone")
    var phone: String = "",

    @ColumnInfo(name = "email")
    var email: String = "",

    @ColumnInfo(name = "role")
    var role: String = "worker",

    @ColumnInfo(name = "skill_level")
    var skillLevel: String = "unskilled",

    @ColumnInfo(name = "daily_wage")
    var dailyWage: Double = 0.0,

    @ColumnInfo(name = "advance_balance")
    var advanceBalance: Double = 0.0,

    @ColumnInfo(name = "join_date")
    var joinDate: String = "",

    @ColumnInfo(name = "status")
    var status: String = "active",

    @ColumnInfo(name = "emergency_contact_name")
    var emergencyContactName: String = "",

    @ColumnInfo(name = "emergency_contact_phone")
    var emergencyContactPhone: String = "",

    @ColumnInfo(name = "address")
    var address: String = "",

    @ColumnInfo(name = "id_document_type")
    var idDocumentType: String = "",

    @ColumnInfo(name = "id_document_number")
    var idDocumentNumber: String = "",

    @ColumnInfo(name = "created_at")
    var createdAt: String = "",

    @ColumnInfo(name = "updated_at")
    var updatedAt: String = "",

    @ColumnInfo(name = "synced")
    var synced: Boolean = false,

    @ColumnInfo(name = "company_id")
    var companyId: Int = 0,

    @ColumnInfo(name = "current_site_id")
    var currentSiteId: Int = 0,

    @ColumnInfo(name = "paid_total")
    var paidTotal: Double = 0.0,

    @ColumnInfo(name = "absent_days")
    var absentDays: Int = 0
) {
    companion object {
        const val STATUS_ACTIVE = "active"
        const val STATUS_INACTIVE = "inactive"
        const val ROLE_WORKER = "worker"
        const val ROLE_SUPERVISOR = "supervisor"
        const val ROLE_FOREMAN = "foreman"
        const val SKILL_UNSKILLED = "unskilled"
        const val SKILL_SEMI_SKILLED = "semi_skilled"
        const val SKILL_SKILLED = "skilled"
    }
}