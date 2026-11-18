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

@Database(
    entities = [
        Site::class,
        Worker::class,
        Product::class,
        Attendance::class,
        PayrollRecord::class,
        CollectionModel::class,
        ServiceRecord::class,
        User::class,
        Notification::class
    ],
    version = 1,
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
                    .fallbackToDestructiveMigration()
                    .build()
                INSTANCE = instance
                instance
            }
        }
    }
}