import java.util.Properties

plugins {
    id("com.android.application")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.example.enterprise_management"
    compileSdk = 37
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    defaultConfig {
        // TODO: Specify your own unique Application ID (https://developer.android.com/studio/build/application-id.html).
        applicationId = "com.example.enterprise_management"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        // Uses the version code from pubspec.yaml. When using split APKs, 1000 * ABI_VERSION
        // is added automatically by Flutter. (https://developer.android.com/studio/build/configure-apk-splits#configure-APK-versions)
        // You can force using the value of versionCode by specifying the `-P force-version-code-ignoring-abi=true`
        // flag during build.
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    buildTypes {
        release {
            // TODO: Add your own signing config for the release build.
            // Signing with the debug keys for now, so `flutter run --release` works.
            signingConfig = signingConfigs.getByName("debug")
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

// Chỉ bật Firebase khi đã đặt google-services.json; thiếu file thì vẫn build được (thông báo đẩy bị tắt).
if (file("google-services.json").exists()) {
    apply(plugin = "com.google.gms.google-services")
}

// Mở cổng backend (5068) cho mọi thiết bị Android đang kết nối: app gọi http://localhost:5068 và adb chuyển về máy tính.
// Chạy mỗi lần build nên chỉ cần `flutter run`, không phải gõ `adb reverse` tay. Không có adb/thiết bị thì bỏ qua, không làm hỏng build.
val adbReverseBackend by tasks.registering {
    outputs.upToDateWhen { false }
    doLast {
        try {
            // Thư mục Android SDK: local.properties (Flutter tự tạo) hoặc biến môi trường.
            val props = Properties()
            val localProps = rootProject.file("local.properties")
            if (localProps.exists()) localProps.inputStream().use { props.load(it) }
            val sdk = props.getProperty("sdk.dir") ?: System.getenv("ANDROID_HOME") ?: System.getenv("ANDROID_SDK_ROOT")
            val exe = if (System.getProperty("os.name").lowercase().contains("windows")) "adb.exe" else "adb"
            val adb = if (sdk != null) File(sdk, "platform-tools/" + exe).absolutePath else exe
            val devices = ProcessBuilder(adb, "devices").redirectErrorStream(true).start()
                .inputStream.bufferedReader().readLines()
                .drop(1)
                .map { it.trim().split(Char(9), Char(32)).filter { part -> part.isNotEmpty() } }
                .filter { it.size >= 2 && it[1] == "device" }
                .map { it[0] }
            for (serial in devices) {
                ProcessBuilder(adb, "-s", serial, "reverse", "tcp:5068", "tcp:5068").redirectErrorStream(true).start().waitFor()
            }
        } catch (e: Exception) {
            logger.warn("Bỏ qua adb reverse: " + e.message)
        }
    }
}

tasks.matching { it.name == "preBuild" }.configureEach { dependsOn(adbReverseBackend) }
