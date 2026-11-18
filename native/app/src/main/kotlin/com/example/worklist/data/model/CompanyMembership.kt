package com.example.worklist.data.model

import androidx.room.Entity
import androidx.room.PrimaryKey
import androidx.room.ColumnInfo
import androidx.room.Index

@Entity(
    tableName = "company_memberships",
    indices = [Index(value = ["company_id"]), Index(value = ["user_id"]), Index(value = ["company_id", "user_id"])]
)
data class CompanyMembership(
    @PrimaryKey(autoGenerate = true)
    @ColumnInfo(name = "id")
    var id: Int = 0,

    @ColumnInfo(name = "company_id")
    var companyId: Int = 0,

    @ColumnInfo(name = "user_id")
    var userId: Int = 0,

    @ColumnInfo(name = "role")
    var role: String = ROLE_MEMBER,

    @ColumnInfo(name = "is_admin")
    var isAdmin: Boolean = false,

    @ColumnInfo(name = "joined_at")
    var joinedAt: String = "",

    @ColumnInfo(name = "status")
    var status: String = STATUS_ACTIVE,

    @ColumnInfo(name = "created_at")
    var createdAt: String = "",

    @ColumnInfo(name = "updated_at")
    var updatedAt: String = ""
) {
    companion object {
        const val ROLE_ADMIN = "admin"
        const val ROLE_MANAGER = "manager"
        const val ROLE_SUPERVISOR = "supervisor"
        const val ROLE_MEMBER = "member"
        const val STATUS_ACTIVE = "active"
        const val STATUS_SUSPENDED = "suspended"
    }
}