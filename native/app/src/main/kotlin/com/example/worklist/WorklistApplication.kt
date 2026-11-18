package com.example.worklist

import android.app.Application
import com.example.worklist.di.RepositoryModule

/** Application-scoped service locator: holds the Room-backed repository graph. */
class WorklistApplication : Application() {

    lateinit var repositories: RepositoryModule
        private set

    override fun onCreate() {
        super.onCreate()
        repositories = RepositoryModule(this)
    }
}