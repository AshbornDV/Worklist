package com.example.worklist.data.model

import androidx.room.Entity
import androidx.room.PrimaryKey
import androidx.room.ColumnInfo
import androidx.room.Index


@Entity(
    tableName = "attendance",
    indices = [Index(value = ["worker_id", "date"]), Index(value = ["site_id", "date"])]
)

data class Attendance(
    @PrimaryKey(autoGenerate = true)
    @ColumnInfo(name = "id")
    var id: Int = 0,

    @ColumnInfo(name = "worker_id")
    var workerId: Int = 0,

    @ColumnInfo(name = "site_id")
    var siteId: Int = 0,

    @ColumnInfo(name = "date")
    var date: String = "",

    @ColumnInfo(name = "check_in_time")
    var checkInTime: String = "",

    @ColumnInfo(name = "check_out_time")
    var checkOutTime: String = "",

    @ColumnInfo(name = "type")
    var type: String = "full",

    @ColumnInfo(name = "hours_worked")
    var hoursWorked: Double = 0.0,

    @ColumnInfo(name = "latitude")
    var latitude: Double = 0.0,

    @ColumnInfo(name = "longitude")
    var longitude: Double = 0.0,

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
        const val TYPE_FULL = "full"
        const val TYPE_HALF = "half"
        const val TYPE_ABSENT = "absent"
        const val TYPE_LEAVE = "leave"
    }
}