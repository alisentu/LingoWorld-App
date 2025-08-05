plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.example.lingoworld"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = "27.0.12077973" // NDK sürümü

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
        isCoreLibraryDesugaringEnabled = true // Desugaring aktif edildi
        tasks.withType<JavaCompile> {
    options.compilerArgs.add("-Xlint:-options")
}

    }

    kotlinOptions {
        jvmTarget = "11"
    }

    defaultConfig {
        applicationId = "com.example.lingoworld"
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    buildTypes {
        release {
            signingConfig = signingConfigs.getByName("debug")
        }
    }
}

flutter {
    source = "../.."
}

dependencies {
    // Desugaring için gerekli kütüphane (mutlaka eklenmeli)
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.4")
}
