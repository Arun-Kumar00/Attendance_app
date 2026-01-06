import java.util.Properties
import java.io.FileInputStream

plugins {
    id("com.android.application")
    id("com.google.gms.google-services")
    id("kotlin-android")
    id("dev.flutter.flutter-gradle-plugin")
}

// Safely load the keystore properties using Kotlin syntax
val keystorePropertiesFile = rootProject.file("android/key.properties")
val keystoreProperties = Properties()
if (keystorePropertiesFile.exists()) {
    keystoreProperties.load(FileInputStream(keystorePropertiesFile))
}

android {
    namespace = "com.arunnitd.vidhar"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = "27.0.12077973"

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_11.toString()
    }

    // Correct Kotlin syntax for signingConfigs
    signingConfigs {
        create("release") {
            keyAlias = "my-key-alias"
            keyPassword = "Arun@345"
            storeFile = file("my-upload-key.keystore")
            storePassword = "Arun@345"
        }
    }
    defaultConfig {
        applicationId = "com.arunnitd.vidhar"
        minSdk = 24
        targetSdk = 35
        versionCode = 4
        versionName = "1.0.6"
    }

    // Correct Kotlin syntax for build types
    buildTypes {
        getByName("release") {
            isMinifyEnabled = true
            proguardFiles(getDefaultProguardFile("proguard-android-optimize.txt"), "proguard-rules.pro")
            signingConfig = signingConfigs.getByName("release")
        }
    }
}

flutter {
    source = "../.."
}