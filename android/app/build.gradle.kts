plugins {
    id("com.android.application")
    id("kotlin-android")
    // Add the Google services Gradle plugin
    id("com.google.gms.google-services")
    id("com.google.firebase.crashlytics")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.movieverse.app"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = "27.0.12077973"

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_11.toString()
    }

    defaultConfig {
        // TODO: Specify your own unique Application ID (https://developer.android.com/studio/build/application-id.html).
        applicationId = "com.movieverse.app"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = 23
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
        multiDexEnabled = true
    }

    buildTypes {
        release {
            // TODO: Add your own signing config for the release build.
            // Signing with the debug keys for now, so `flutter run --release` works.
            signingConfig = signingConfigs.getByName("debug")
            
            // Disable Crashlytics for now to simplify initialization
            manifestPlaceholders["crashlyticsCollectionEnabled"] = false
            isMinifyEnabled = true
            proguardFiles(getDefaultProguardFile("proguard-android-optimize.txt"), "proguard-rules.pro")
        }
        
        debug {
            // Disable Crashlytics completely
            manifestPlaceholders["crashlyticsCollectionEnabled"] = false
            manifestPlaceholders["firebaseCrashlyticsAutoInit"] = false
            isMinifyEnabled = false
        }
    }

    // Optimize packaging process
    packagingOptions {
        resources {
            excludes += listOf("META-INF/DEPENDENCIES", "META-INF/LICENSE", "META-INF/LICENSE.txt", 
                              "META-INF/license.txt", "META-INF/NOTICE", "META-INF/NOTICE.txt", 
                              "META-INF/notice.txt", "META-INF/ASL2.0", "META-INF/*.kotlin_module")
        }
    }

    // Configure only for apps with targetSdkVersion 32+
    if (flutter.targetSdkVersion >= 32) {
        buildFeatures {
            viewBinding = true
        }
    }
}

flutter {
    source = "../.."
}

dependencies {
    // Import the Firebase BoM with a specific version
    implementation(platform("com.google.firebase:firebase-bom:33.13.0"))

    // Only include the Firebase products we're actually using
    implementation("com.google.firebase:firebase-analytics")
    implementation("com.google.firebase:firebase-auth")
    
    // Add Google Sign-In dependency
    implementation("com.google.android.gms:play-services-auth:20.7.0")
    
    // Add multidex support
    implementation("androidx.multidex:multidex:2.0.1")

    // Add the dependencies for any other desired Firebase products
    // https://firebase.google.com/docs/android/setup#available-libraries
}
