package com.example.worklist.data.db

import android.content.Context
import androidx.room.Database
import androidx.room.Room
import androidx.room.RoomDatabase
import com.example.worklist.data.model.Site
import com.example.worklist.data.model.Worker
import com.example.worklist.data.model.Product
import com.example.worklist.data.model.Attendance
import com.example.worklist.data.model.PayrollRecord
import com.example.worklist.data.model.Collection as CollectionModel
import com.example.worklist.data.model.ServiceRecord
import com.example.worklist.data.model.User
import com.example.worklist.data.model.Notification
import com.example.worklist.data.model.Company
import com.example.worklist.data.model.CompanyMembership
import com.example.worklist.data.model.Payment
import com.example.worklist.data.model.StockMovement

@Database(
    entities = [
        Company::class,
        CompanyMembership::class,
        Site::class,
        Worker::class,
        Product::class,
        Attendance::class,
        PayrollRecord::class,
        Payment::class,
        StockMovement::class,
        CollectionModel::class,
        ServiceRecord::class,
        User::class,
        Notification::class
    ],
    version = 2,
    exportSchema = true,
)
abstract class WorklistDatabase : RoomDatabase() {
    abstract fun siteDao(): SiteDao
    abstract fun workerDao(): WorkerDao
    abstract fun productDao(): ProductDao
    abstract fun attendanceDao(): AttendanceDao
    abstract fun payrollDao(): PayrollDao
    abstract fun collectionDao(): CollectionDao
    abstract fun serviceDao(): ServiceDao
    abstract fun userDao(): UserDao
    abstract fun notificationDao(): NotificationDao
    abstract fun companyDao(): CompanyDao
    abstract fun companyMembershipDao(): CompanyMembershipDao
    abstract fun paymentDao(): PaymentDao
    abstract fun stockMovementDao(): StockMovementDao

    companion object {
        @Volatile
        private var INSTANCE: WorklistDatabase? = null

        fun getDatabase(context: Context): WorklistDatabase {
            return INSTANCE ?: synchronized(this) {
                val instance = Room.databaseBuilder(
                    context.applicationContext,
                    WorklistDatabase::class.java,
                    "worklist_database"
                )
                    .addMigrations(MIGRATION_1_2)
                    .build()
                INSTANCE = instance
                instance
            }
        }
    }
}
