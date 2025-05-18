package com.movieverse.app

import io.flutter.embedding.android.FlutterActivity
import android.os.Bundle
import android.os.StrictMode

class MainActivity : FlutterActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        // Configure StrictMode for development
        val policy = StrictMode.ThreadPolicy.Builder()
            .permitAll() // Temporarily permit all operations for troubleshooting
            .build()
        StrictMode.setThreadPolicy(policy)
        
        super.onCreate(savedInstanceState)
    }
} 