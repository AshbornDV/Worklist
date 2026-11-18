package com.example.worklist.data.model

import androidx.room.Entity
import androidx.room.PrimaryKey
import androidx.room.ColumnInfo


@Entity(tableName = "users")

data class User(
    @PrimaryKey(autoGenerate = true)
    @ColumnInfo(name = "id")
    var id: Int = 0,

    @ColumnInfo(name = "username")
    var username: String = "",

    @ColumnInfo(name = "email")
    var email: String = "",

    @ColumnInfo(name = "password_hash")
    var passwordHash: String = "",

    @ColumnInfo(name = "role")
    var role: String = "worker",

    @ColumnInfo(name = "full_name")
    var fullName: String = "",

    @ColumnInfo(name = "phone")
    var phone: String = "",

    @ColumnInfo(name = "is_active")
    var isActive: Boolean = true,

    @ColumnInfo(name = "last_login")
    var lastLogin: String = "",

    @ColumnInfo(name = "created_at")
    var createdAt: String = "",

    @ColumnInfo(name = "updated_at")
    var updatedAt: String = "",

    @ColumnInfo(name = "synced")
    var synced: Boolean = false
) {
    companion object {
        const val ROLE_ADMIN = "admin"
        const val ROLE_MANAGER = "manager"
        const val ROLE_SUPERVISOR = "supervisor"
        const val ROLE_WORKER = "worker"
    }
}