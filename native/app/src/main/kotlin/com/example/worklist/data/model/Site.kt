package com.example.worklist.data.model

import androidx.room.Entity
import androidx.room.PrimaryKey
import androidx.room.ColumnInfo


@Entity(tableName = "sites")

data class Site(
    @PrimaryKey(autoGenerate = true)
    @ColumnInfo(name = "id")
    var id: Int = 0,

    @ColumnInfo(name = "name")
    var name: String = "",

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

    @ColumnInfo(name = "client_name")
    var clientName: String = "",

    @ColumnInfo(name = "client_contact")
    var clientContact: String = "",

    @ColumnInfo(name = "client_phone")
    var clientPhone: String = "",

    @ColumnInfo(name = "start_date")
    var startDate: String = "",

    @ColumnInfo(name = "end_date")
    var endDate: String = "",

    @ColumnInfo(name = "status")
    var status: String = "active",

    @ColumnInfo(name = "progress")
    var progress: Int = 0,

    @ColumnInfo(name = "description")
    var description: String = "",

    @ColumnInfo(name = "notes")
    var notes: String = "",

    @ColumnInfo(name = "latitude")
    var latitude: Double = 0.0,

    @ColumnInfo(name = "longitude")
    var longitude: Double = 0.0,

    @ColumnInfo(name = "created_at")
    var createdAt: String = "",

    @ColumnInfo(name = "updated_at")
    var updatedAt: String = "",

    @ColumnInfo(name = "synced")
    var synced: Boolean = false,

    @ColumnInfo(name = "company_id")
    var companyId: Int = 0,

    @ColumnInfo(name = "area_estimate")
    var areaEstimate: Double = 0.0,

    @ColumnInfo(name = "area_final")
    var areaFinal: Double = 0.0,

    @ColumnInfo(name = "budget_estimate")
    var budgetEstimate: Double = 0.0,

    @ColumnInfo(name = "budget_actual")
    var budgetActual: Double = 0.0,

    @ColumnInfo(name = "satisfaction_score")
    var satisfactionScore: Double = 0.0,

    @ColumnInfo(name = "final_work_days")
    var finalWorkDays: Int = 0
) {
    companion object {
        const val STATUS_ACTIVE = "active"
        const val STATUS_COMPLETED = "completed"
        const val STATUS_PENDING = "pending"
        const val STATUS_ON_HOLD = "on_hold"
    }
}