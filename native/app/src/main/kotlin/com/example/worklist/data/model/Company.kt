package com.example.worklist.data.model

import androidx.room.Entity
import androidx.room.PrimaryKey
import androidx.room.ColumnInfo

@Entity(tableName = "companies")
data class Company(
    @PrimaryKey(autoGenerate = true)
    @ColumnInfo(name = "id")
    var id: Int = 0,

    @ColumnInfo(name = "name")
    var name: String = "",

    @ColumnInfo(name = "legal_name")
    var legalName: String = "",

    @ColumnInfo(name = "tax_id")
    var taxId: String = "",

    @ColumnInfo(name = "phone")
    var phone: String = "",

    @ColumnInfo(name = "email")
    var email: String = "",

    @ColumnInfo(name = "address")
    var address: String = "",

    @ColumnInfo(name = "city")
    var city: String = "",

    @ColumnInfo(name = "state")
    var state: String = "",

    @ColumnInfo(name = "postal_code")
    var postalCode: String = "",

    @ColumnInfo(name = "country")
    var country: String = "",

    @ColumnInfo(name = "plan")
    var plan: String = PLAN_STANDARD,

    @ColumnInfo(name = "is_active")
    var isActive: Boolean = true,

    @ColumnInfo(name = "created_at")
    var createdAt: String = "",

    @ColumnInfo(name = "updated_at")
    var updatedAt: String = "",

    @ColumnInfo(name = "synced")
    var synced: Boolean = false
) {
    companion object {
        const val PLAN_STANDARD = "standard"
        const val PLAN_PREMIUM = "premium"
        const val PLAN_ENTERPRISE = "enterprise"
    }
}