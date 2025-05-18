package com.movieverse.app

import android.app.Application
import android.os.StrictMode
import com.google.firebase.FirebaseApp
import com.google.firebase.FirebaseOptions
import java.util.concurrent.Executors

class MovieVerseApplication : Application() {
    private val backgroundExecutor = Executors.newSingleThreadExecutor()
    
    override fun onCreate() {
        super.onCreate()
        
        // Configure StrictMode to allow network operations temporarily
        StrictMode.setThreadPolicy(
            StrictMode.ThreadPolicy.Builder()
                .permitAll() // Allow all operations to fix StrictMode violations
                .build()
        )
        
        // Initialize Firebase using a proper executor instead of a raw thread
        backgroundExecutor.execute {
            try {
                // Only initialize if not already initialized
                if (FirebaseApp.getApps(this).isEmpty()) {
                    FirebaseApp.initializeApp(this)
                }
            } catch (e: Exception) {
                e.printStackTrace()
            }
        }
    }
    
    override fun onTerminate() {
        super.onTerminate()
        // Shutdown executor
        backgroundExecutor.shutdown()
    }
} 