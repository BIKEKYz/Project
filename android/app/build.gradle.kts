plugins {
    id("com.android.application")
    id("com.google.gms.google-services")
    // id("org.jetbrains.kotlin.android") // ถ้าโปรเจกต์คุณใช้ Kotlin
}

android {
    namespace = "com.yourcompany.plantify"   // เปลี่ยนเป็นของคุณ
    compileSdk = 34

    defaultConfig {
        applicationId = "com.yourcompany.plantify"  // ให้ตรงกับที่ต้องการ
        minSdk = 23                                  // แนะนำสำหรับ Firebase/Google Sign-In
        targetSdk = 34
        versionCode = 1
        versionName = "1.0"
    }
}

    buildTypes {
        release {
            // TODO: Add your own signing config for the release build.
            // Signing with the debug keys for now, so `flutter run --release` works.
            signingConfig = signingConfigs.getByName("debug")
        }
    }
}

flutter {
    source = "../.."
}
