package com.example.worklist.di

import android.content.Context
import com.example.worklist.data.db.WorklistDatabase
import com.example.worklist.data.repository.AttendanceRepository
import com.example.worklist.data.repository.AttendanceRepositoryImpl
import com.example.worklist.data.repository.CollectionRepository
import com.example.worklist.data.repository.CollectionRepositoryImpl
import com.example.worklist.data.repository.CompanyRepository
import com.example.worklist.data.repository.CompanyRepositoryImpl
import com.example.worklist.data.repository.NotificationRepository
import com.example.worklist.data.repository.NotificationRepositoryImpl
import com.example.worklist.data.repository.PaymentRepository
import com.example.worklist.data.repository.PaymentRepositoryImpl
import com.example.worklist.data.repository.PayrollRepository
import com.example.worklist.data.repository.PayrollRepositoryImpl
import com.example.worklist.data.repository.ProductRepository
import com.example.worklist.data.repository.ProductRepositoryImpl
import com.example.worklist.data.repository.ServiceRepository
import com.example.worklist.data.repository.ServiceRepositoryImpl
import com.example.worklist.data.repository.SiteRepository
import com.example.worklist.data.repository.SiteRepositoryImpl
import com.example.worklist.data.repository.StockMovementRepository
import com.example.worklist.data.repository.StockMovementRepositoryImpl
import com.example.worklist.data.repository.UserRepository
import com.example.worklist.data.repository.UserRepositoryImpl
import com.example.worklist.data.repository.WorkerRepository
import com.example.worklist.data.repository.WorkerRepositoryImpl

class RepositoryModule(private val context: Context) {
    private val database = WorklistDatabase.getDatabase(context)

    val siteRepository: SiteRepository = SiteRepositoryImpl(database.siteDao())
    val workerRepository: WorkerRepository = WorkerRepositoryImpl(database.workerDao())
    val productRepository: ProductRepository = ProductRepositoryImpl(database.productDao())
    val attendanceRepository: AttendanceRepository = AttendanceRepositoryImpl(database.attendanceDao())
    val payrollRepository: PayrollRepository = PayrollRepositoryImpl(database.payrollDao())
    val collectionRepository: CollectionRepository = CollectionRepositoryImpl(database.collectionDao())
    val serviceRepository: ServiceRepository = ServiceRepositoryImpl(database.serviceDao())
    val userRepository: UserRepository = UserRepositoryImpl(database.userDao())
    val notificationRepository: NotificationRepository = NotificationRepositoryImpl(database.notificationDao())
    val companyRepository: CompanyRepository = CompanyRepositoryImpl(database.companyDao())
    val paymentRepository: PaymentRepository = PaymentRepositoryImpl(database.paymentDao())
    val stockMovementRepository: StockMovementRepository = StockMovementRepositoryImpl(database.stockMovementDao())
}