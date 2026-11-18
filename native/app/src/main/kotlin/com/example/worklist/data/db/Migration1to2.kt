package com.example.worklist.data.db

import android.content.Context
import androidx.room.migration.Migration
import androidx.sqlite.db.SupportSQLiteDatabase

val MIGRATION_1_2 = object : Migration(1, 2) {
    override fun migrate(db: SupportSQLiteDatabase) {
        // Create companies table first (must exist before FK references)
        db.execSQL("""
            CREATE TABLE IF NOT EXISTS "companies" (
                "id" INTEGER PRIMARY KEY AUTOINCREMENT NOT NULL,
                "name" TEXT NOT NULL DEFAULT '',
                "legal_name" TEXT NOT NULL DEFAULT '',
                "tax_id" TEXT NOT NULL DEFAULT '',
                "phone" TEXT NOT NULL DEFAULT '',
                "email" TEXT NOT NULL DEFAULT '',
                "address" TEXT NOT NULL DEFAULT '',
                "city" TEXT NOT NULL DEFAULT '',
                "state" TEXT NOT NULL DEFAULT '',
                "postal_code" TEXT NOT NULL DEFAULT '',
                "country" TEXT NOT NULL DEFAULT '',
                "plan" TEXT NOT NULL DEFAULT 'standard',
                "is_active" INTEGER NOT NULL DEFAULT 1,
                "created_at" TEXT NOT NULL DEFAULT '',
                "updated_at" TEXT NOT NULL DEFAULT '',
                "synced" INTEGER NOT NULL DEFAULT 0
            )
        """)

        // Default company (backward compat for existing single-tenant data)
        db.execSQL("INSERT INTO companies (name, is_active, created_at, synced) VALUES ('Default', 1, datetime('now'), 0)")

        val defaultCompanyId = db.query("SELECT id FROM companies LIMIT 1").use { cursor ->
            if (cursor.moveToFirst()) cursor.getInt(cursor.getColumnIndexOrThrow("id")) else 1
        }

        // Create company_memberships table
        db.execSQL("""
            CREATE TABLE IF NOT EXISTS "company_memberships" (
                "id" INTEGER PRIMARY KEY AUTOINCREMENT NOT NULL,
                "company_id" INTEGER NOT NULL DEFAULT 0,
                "user_id" INTEGER NOT NULL DEFAULT 0,
                "role" TEXT NOT NULL DEFAULT 'member',
                "is_admin" INTEGER NOT NULL DEFAULT 0,
                "joined_at" TEXT NOT NULL DEFAULT '',
                "status" TEXT NOT NULL DEFAULT 'active',
                "created_at" TEXT NOT NULL DEFAULT '',
                "updated_at" TEXT NOT NULL DEFAULT '',
                FOREIGN KEY(company_id) REFERENCES companies(id),
                FOREIGN KEY(user_id) REFERENCES users(id)
            )
        """)
        db.execSQL("CREATE INDEX IF NOT EXISTS 'index_company_memberships_company_id' ON company_memberships('company_id')")
        db.execSQL("CREATE INDEX IF NOT EXISTS 'index_company_memberships_user_id' ON company_memberships('user_id')")
        db.execSQL("CREATE INDEX IF NOT EXISTS 'index_company_memberships_company_user' ON company_memberships('company_id', 'user_id')")

        // Migrate existing User records to default company membership
        db.execSQL("INSERT INTO company_memberships (company_id, user_id, role, is_admin, joined_at, status, created_at, updated_at) SELECT $defaultCompanyId, id, role, 1, COALESCE(last_login, ''), 'active', createdAt, updatedAt FROM users WHERE id > 0")

        // Create payments table
        db.execSQL("""
            CREATE TABLE IF NOT EXISTS "payments" (
                "id" INTEGER PRIMARY KEY AUTOINCREMENT NOT NULL,
                "company_id" INTEGER NOT NULL DEFAULT 0,
                "worker_id" INTEGER NOT NULL DEFAULT 0,
                "site_id" INTEGER NOT NULL DEFAULT 0,
                "payroll_record_id" INTEGER NOT NULL DEFAULT 0,
                "amount" REAL NOT NULL DEFAULT 0,
                "rate_basis" TEXT NOT NULL DEFAULT 'daily',
                "daily_rate" REAL NOT NULL DEFAULT 0,
                "job_rate" REAL NOT NULL DEFAULT 0,
                "days_or_jobs" REAL NOT NULL DEFAULT 0,
                "paid_date" TEXT NOT NULL DEFAULT '',
                "payment_method" TEXT NOT NULL DEFAULT '',
                "reference_number" TEXT NOT NULL DEFAULT '',
                "notes" TEXT NOT NULL DEFAULT '',
                "created_at" TEXT NOT NULL DEFAULT '',
                FOREIGN KEY(company_id) REFERENCES companies(id),
                FOREIGN KEY(worker_id) REFERENCES workers(id),
                FOREIGN KEY(site_id) REFERENCES sites(id),
                FOREIGN KEY(payroll_record_id) REFERENCES payroll_records(id)
            )
        """)
        db.execSQL("CREATE INDEX IF NOT EXISTS 'index_payments_company_id' ON payments('company_id')")
        db.execSQL("CREATE INDEX IF NOT EXISTS 'index_payments_worker_id' ON payments('worker_id')")
        db.execSQL("CREATE INDEX IF NOT EXISTS 'index_payments_site_id' ON payments('site_id')")
        db.execSQL("CREATE INDEX IF NOT EXISTS 'index_payments_payroll_id' ON payments('payroll_record_id')")

        // Create stock_movements table
        db.execSQL("""
            CREATE TABLE IF NOT EXISTS "stock_movements" (
                "id" INTEGER PRIMARY KEY AUTOINCREMENT NOT NULL,
                "company_id" INTEGER NOT NULL DEFAULT 0,
                "product_id" INTEGER NOT NULL DEFAULT 0,
                "site_id" INTEGER NOT NULL DEFAULT 0,
                "type" TEXT NOT NULL DEFAULT 'ship',
                "quantity" REAL NOT NULL DEFAULT 0,
                "unit_cost" REAL NOT NULL DEFAULT 0,
                "total_cost" REAL NOT NULL DEFAULT 0,
                "reference_number" TEXT NOT NULL DEFAULT '',
                "notes" TEXT NOT NULL DEFAULT '',
                "movement_date" TEXT NOT NULL DEFAULT '',
                "created_at" TEXT NOT NULL DEFAULT '',
                FOREIGN KEY(company_id) REFERENCES companies(id),
                FOREIGN KEY(product_id) REFERENCES products(id),
                FOREIGN KEY(site_id) REFERENCES sites(id)
            )
        """)
        db.execSQL("CREATE INDEX IF NOT EXISTS 'index_stock_movements_company_id' ON stock_movements('company_id')")
        db.execSQL("CREATE INDEX IF NOT EXISTS 'index_stock_movements_product_id' ON stock_movements('product_id')")
        db.execSQL("CREATE INDEX IF NOT EXISTS 'index_stock_movements_site_id' ON stock_movements('site_id')")
        db.execSQL("CREATE INDEX IF NOT EXISTS 'index_stock_movements_type' ON stock_movements('type')")

        // Add companyId column to existing tables
        db.execSQL("ALTER TABLE sites ADD COLUMN company_id INTEGER NOT NULL DEFAULT $defaultCompanyId")
        db.execSQL("ALTER TABLE sites ADD COLUMN area_estimate REAL NOT NULL DEFAULT 0")
        db.execSQL("ALTER TABLE sites ADD COLUMN area_final REAL NOT NULL DEFAULT 0")
        db.execSQL("ALTER TABLE sites ADD COLUMN budget_estimate REAL NOT NULL DEFAULT 0")
        db.execSQL("ALTER TABLE sites ADD COLUMN budget_actual REAL NOT NULL DEFAULT 0")
        db.execSQL("ALTER TABLE sites ADD COLUMN satisfaction_score REAL NOT NULL DEFAULT 0")
        db.execSQL("ALTER TABLE sites ADD COLUMN final_work_days INTEGER NOT NULL DEFAULT 0")
        db.execSQL("CREATE INDEX IF NOT EXISTS 'index_sites_company_id' ON sites('company_id')")

        db.execSQL("ALTER TABLE workers ADD COLUMN company_id INTEGER NOT NULL DEFAULT $defaultCompanyId")
        db.execSQL("ALTER TABLE workers ADD COLUMN current_site_id INTEGER NOT NULL DEFAULT 0")
        db.execSQL("ALTER TABLE workers ADD COLUMN paid_total REAL NOT NULL DEFAULT 0")
        db.execSQL("ALTER TABLE workers ADD COLUMN absent_days INTEGER NOT NULL DEFAULT 0")
        db.execSQL("CREATE INDEX IF NOT EXISTS 'index_workers_company_id' ON workers('company_id')")
        db.execSQL("CREATE INDEX IF NOT EXISTS 'index_workers_current_site_id' ON workers('current_site_id')")

        db.execSQL("ALTER TABLE products ADD COLUMN company_id INTEGER NOT NULL DEFAULT $defaultCompanyId")
        db.execSQL("CREATE INDEX IF NOT EXISTS 'index_products_company_id' ON products('company_id')")

        db.execSQL("ALTER TABLE attendance ADD COLUMN company_id INTEGER NOT NULL DEFAULT $defaultCompanyId")

        db.execSQL("ALTER TABLE payroll_records ADD COLUMN company_id INTEGER NOT NULL DEFAULT $defaultCompanyId")

        // Update users with company membership reference
        db.execSQL("ALTER TABLE users ADD COLUMN company_id INTEGER DEFAULT NULL")
    }
}