import java.util.Properties

plugins {
    id("com.android.application")
    id("kotlin-android")
    id("dev.flutter.flutter-gradle-plugin")
    id("com.google.gms.google-services")
    id("com.google.firebase.firebase-perf")
    id("com.google.firebase.crashlytics")
}

/**
 * key.properties sadece RELEASE signing için gereklidir.
 * Debug build için asla zorunlu olmamalı.
 */
val keyPropsFile = file("key.properties")
val keyProps = Properties()
val hasKeyProps = keyPropsFile.exists()

if (hasKeyProps) {
    keyPropsFile.inputStream().use { keyProps.load(it) }
} else {
    println("⚠️ key.properties yok: Debug çalışır. Release signing devre dışı.")
}

val localPropsFile = rootProject.file("local.properties")
val localProps = Properties()
if (localPropsFile.exists()) {
    localPropsFile.inputStream().use { localProps.load(it) }
}
val bundledGoogleMapsApiKey = "AIzaSyCQ6gUYt8TUQ9U4uQo8ZKnTiSp1D3zMEWA"
val googleMapsApiKey: String =
    (project.findProperty("GOOGLE_MAPS_API_KEY") as String?)
        ?: localProps.getProperty("GOOGLE_MAPS_API_KEY", bundledGoogleMapsApiKey)

android {
    namespace = "com.turqapp.app"

    // Flutter plugin bunları yönetir
    compileSdk = flutter.compileSdkVersion
    ndkVersion = "27.0.12077973"

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
        isCoreLibraryDesugaringEnabled = true
    }

    kotlinOptions {
        jvmTarget = "17"
    }

    defaultConfig {
        // BUNLAR ÖNEMLİ: kendi proje değerlerinle aynı olmalı
        applicationId = "com.turqapp.app"

        // flutter.* değerleri genelde doğru
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion

        versionCode = flutter.versionCode
        versionName = flutter.versionName
        manifestPlaceholders["googleMapsApiKey"] = googleMapsApiKey
    }

    /**
     * Release signing sadece key.properties varsa oluşturulur.
     */
    signingConfigs {
        if (hasKeyProps) {
            create("release") {
                // key.properties içeriği:
                // storeFile=../keystore/xxx.jks  (veya app içinde path)
                // storePassword=...
                // keyAlias=...
                // keyPassword=...
                storeFile = file(keyProps["storeFile"] as String)
                storePassword = keyProps["storePassword"] as String
                keyAlias = keyProps["keyAlias"] as String
                keyPassword = keyProps["keyPassword"] as String
            }
        }
    }

    buildTypes {
        getByName("debug") {
            // Debug için ekstra bir şey yapma; default debug keystore kullanılır.
            // (key.properties'e hiç ihtiyaç yok)
            manifestPlaceholders["crashlyticsCollectionEnabled"] = "false"
        }

        getByName("release") {
            // APK boyutunu küçült
            isMinifyEnabled = true
            isShrinkResources = true
            proguardFiles(
                getDefaultProguardFile("proguard-android-optimize.txt"),
                "proguard-rules.pro"
            )
            manifestPlaceholders["crashlyticsCollectionEnabled"] = "true"

            // Release signing sadece key.properties varsa bağlanır.
            if (hasKeyProps) {
                signingConfig = signingConfigs.getByName("release")
            } else {
                // Local release runs need a signed APK even without production keystore.
                signingConfig = signingConfigs.getByName("debug")
                println("⚠️ key.properties yok: release debug keystore ile imzalanıyor (sadece lokal test).")
            }
        }

        // Flutter profile build'i de release benzeri configure edilir; aynı kural burada da geçerli.
        getByName("profile") {
            isMinifyEnabled = false
            isShrinkResources = false
            manifestPlaceholders["crashlyticsCollectionEnabled"] = "false"
        }
    }
}

configurations.all {
    exclude(group = "com.google.android.play", module = "core-common")
}

dependencies {
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.4")
    // Required by Flutter deferred component manager references during R8 minify.
    implementation("com.google.android.play:core:1.10.3")

    // ExoPlayer (Media3) - Native HLS video playback
    implementation("androidx.media3:media3-exoplayer:1.3.1")
    implementation("androidx.media3:media3-exoplayer-hls:1.3.1")
    implementation("androidx.media3:media3-ui:1.3.1")
}
