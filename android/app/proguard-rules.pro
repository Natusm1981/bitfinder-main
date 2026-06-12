# Keep native methods
-keepclasseswithmembernames,includedescriptorclasses class * {
    native <methods>;
}

# Keep all public classes in our package
-keep public class br.net.mantovani.bitfinder.** { *; }

# Keep NativeCrypto class and all methods
-keep class br.net.mantovani.bitfinder.NativeCrypto {
    *;
}

# Keep MainActivity and method channel handlers
-keep class br.net.mantovani.bitfinder.MainActivity {
    *;
}

# Keep all Flutter plugin classes
-keep class io.flutter.plugins.** { *; }
-keep class io.flutter.plugin.common.** { *; }
-keep class io.flutter.embedding.** { *; }

# Keep method channel related
-keepclassmembers class * {
    @io.flutter.embedding.engine.dart.DartExecutor$DartEntrypoint *;
}

# Flutter
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.**  { *; }
-keep class io.flutter.util.**  { *; }
-keep class io.flutter.view.**  { *; }
-keep class io.flutter.**  { *; }
-keep class io.flutter.plugins.**  { *; }

# Preserve annotations
-keepattributes *Annotation*
-keepattributes Signature
-keepattributes Exceptions

# Keep BuildConfig
-keep class **.BuildConfig { *; }

# Keep Kotlin metadata
-keep class kotlin.Metadata { *; }

# Shared Preferences
-keep class androidx.preference.** { *; }

# Don't warn about missing classes
-dontwarn android.support.**
-dontwarn com.google.android.material.**
-dontwarn androidx.**

# Play Store deferred components (Flutter uses but we don't need)
-dontwarn com.google.android.play.core.**
-keep class com.google.android.play.core.** { *; }

# Optimize but don't over-optimize
-optimizationpasses 5
-dontusemixedcaseclassnames
-dontskipnonpubliclibraryclasses
-verbose

# Keep line numbers for debugging
-keepattributes SourceFile,LineNumberTable
-renamesourcefileattribute SourceFile
