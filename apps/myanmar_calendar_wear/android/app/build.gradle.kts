import java.io.FileInputStream
import java.util.Properties

plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

val keystoreProperties = Properties()
// Play needs the phone's upload key (same listing), so without a key.properties
// of its own the watch build uses the phone app's.
val keystorePropertiesFile = rootProject.file("key.properties").takeIf { it.exists() }
    ?: rootProject.file("../../myanmar_calendar/android/key.properties")
if (keystorePropertiesFile.exists()) {
    keystoreProperties.load(FileInputStream(keystorePropertiesFile))
}
val hasReleaseKey =
    System.getenv("ANDROID_KEYSTORE_PATH") != null || keystorePropertiesFile.exists()

android {
    // The phone's package id: Play serves the watch build from the same listing.
    namespace = "dev.mixin27.mmcalendar"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        // flutter_local_notifications (through the holidays package) needs desugaring.
        isCoreLibraryDesugaringEnabled = true
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_11.toString()
    }

    defaultConfig {
        applicationId = "dev.mixin27.mmcalendar"
        // Wear OS 3.
        minSdk = 30
        targetSdk = flutter.targetSdkVersion
        // pubspec.yaml: 1_000_000 + the phone's build number, so the watch
        // build always sorts above the phone build it ships with.
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    signingConfigs {
        create("release") {
            if (System.getenv("ANDROID_KEYSTORE_PATH") != null) {
                storeFile = file(System.getenv("ANDROID_KEYSTORE_PATH"))
                keyAlias = System.getenv("ANDROID_KEYSTORE_ALIAS")
                keyPassword = System.getenv("ANDROID_KEYSTORE_PRIVATE_KEY_PASSWORD")
                storePassword = System.getenv("ANDROID_KEYSTORE_PASSWORD")
            } else {
                keyAlias = keystoreProperties["keyAlias"] as String?
                keyPassword = keystoreProperties["keyPassword"] as String?
                // Relative to that project's app module, as its own build reads it.
                storeFile = keystoreProperties["storeFile"]?.let {
                    keystorePropertiesFile.parentFile.resolve("app").resolve(it as String)
                }
                storePassword = keystoreProperties["storePassword"] as String?
            }
        }
    }

    buildTypes {
        release {
            // Without the upload key (a fresh checkout, CI without secrets)
            // release builds are debug-signed so `flutter build apk` still works.
            signingConfig =
                signingConfigs.getByName(if (hasReleaseKey) "release" else "debug")
        }
    }
}

dependencies {
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.4")

    implementation("androidx.wear:wear:1.3.0")

    // Tile: the day, the moon and what's next.
    implementation("androidx.wear.tiles:tiles:1.5.0")
    implementation("androidx.wear.protolayout:protolayout:1.3.0")
    implementation("androidx.wear.protolayout:protolayout-expression:1.3.0")
    implementation("com.google.guava:guava:33.4.8-android")

    // Complications: moon and day, Myanmar date, moon illumination.
    implementation("androidx.wear.watchface:watchface-complications-data-source-ktx:1.2.1")
    implementation("org.jetbrains.kotlinx:kotlinx-coroutines-android:1.10.2")
}

flutter {
    source = "../.."
}
