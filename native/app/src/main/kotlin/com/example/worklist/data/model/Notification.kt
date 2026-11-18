package com.example.worklist.data.model

import androidx.room.Entity
import androidx.room.PrimaryKey
import androidx.room.ColumnInfo
import androidx.room.Index


@Entity(
    tableName = "notifications",
    indices = [Index(value = ["user_id"]), Index(value = ["read"]), Index(value = ["type"])]
)

data class Notification(
    @PrimaryKey(autoGenerate = true)
    @ColumnInfo(name = "id")
    var id: Int = 0,

    @ColumnInfo(name = "user_id")
    var userId: Int = 0,

    @ColumnInfo(name = "title")
    var title: String = "",

    @ColumnInfo(name = "body")
    var body: String = "",

    @ColumnInfo(name = "type")
    var type: String = "info",

    @ColumnInfo(name = "reference_id")
    var referenceId: Int = 0,

    @ColumnInfo(name = "reference_type")
    var referenceType: String = "",

    @ColumnInfo(name = "read")
    var read: Boolean = false,

    @ColumnInfo(name = "action_data")
    var actionData: String = "",

    @ColumnInfo(name = "created_at")
    var createdAt: String = "",

    @ColumnInfo(name = "synced")
    var synced: Boolean = false
) {
    companion object {
        const val TYPE_INFO = "info"
        const val TYPE_WARNING = "warning"
        const val TYPE_ERROR = "error"
        const val TYPE_SUCCESS = "success"
        const val TYPE_PAYMENT = "payment"
        const val TYPE_STOCK = "stock"
        const val TYPE_ATTENDANCE = "attendance"
        const val TYPE_WORKER = "worker"
        const val TYPE_SITE = "site"
    }
}