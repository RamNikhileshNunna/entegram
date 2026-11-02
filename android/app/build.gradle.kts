plugins {
    id("com.android.application")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

// Release identity must be explicitly supplied. Never create a random debug
// key for a published update: Android would reject it over existing installs.
val releaseStorePath = System.getenv("ENTEGRAM_KEYSTORE_PATH")
val releaseStorePassword = System.getenv("ENTEGRAM_KEYSTORE_PASSWORD")
val releaseKeyAlias = System.getenv("ENTEGRAM_KEY_ALIAS") ?: "androiddebugkey"
val releaseKeyPassword = System.getenv("ENTEGRAM_KEY_PASSWORD") ?: releaseStorePassword
val hasReleaseSigning = !releaseStorePath.isNullOrBlank() && !releaseStorePassword.isNullOrBlank()
val requestsRelease = gradle.startParameter.taskNames.any { it.contains("release", ignoreCase = true) }
if (requestsRelease && !hasReleaseSigning) {
    throw GradleException("Release signing requires ENTEGRAM_KEYSTORE_PATH and ENTEGRAM_KEYSTORE_PASSWORD. See docs/SIGNING.md.")
}

android {
    namespace = "com.entegram.entegram"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    defaultConfig {
        // TODO: Specify your own unique Application ID (https://developer.android.com/studio/build/application-id.html).
        applicationId = "com.entegram.entegram"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    signingConfigs {
        if (hasReleaseSigning) {
            create("persistentRelease") {
                storeFile = file(releaseStorePath!!)
                storePassword = releaseStorePassword
                keyAlias = releaseKeyAlias
                keyPassword = releaseKeyPassword
            }
        }
    }

    buildTypes {
        release {
            signingConfig = if (hasReleaseSigning) signingConfigs.getByName("persistentRelease") else null
        }
    }
}

kotlin {
    compilerOptions {
        jvmTarget = org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_17
    }
}

flutter {
    source = "../.."
}
