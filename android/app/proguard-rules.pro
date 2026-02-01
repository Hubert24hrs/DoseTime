# Flutter/Dart ProGuard Rules for DoseTime
# Keep Flutter and Dart classes
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }
-keep class io.flutter.util.** { *; }
-keep class io.flutter.view.** { *; }
-keep class io.flutter.embedding.** { *; }

# RevenueCat
-keep class com.revenuecat.purchases.** { *; }
-keep class com.android.vending.billing.** { *; }

# Firebase
-keep class com.google.firebase.** { *; }
-keep class com.google.android.gms.** { *; }

# GSON (if used)
-keepattributes Signature
-keepattributes *Annotation*

# SQLite
-keep class org.sqlite.** { *; }
-keep class org.sqlite.database.** { *; }

# Kotlin
-keep class kotlin.** { *; }
-dontwarn kotlin.**

# Keep model classes (if any use reflection)
-keepclassmembers class * {
    @com.google.gson.annotations.SerializedName <fields>;
}

# Keep enums
-keepclassmembers enum * { *; }

# Don't warn about missing classes
-dontwarn org.conscrypt.**
-dontwarn org.bouncycastle.**
-dontwarn org.openjsse.**
