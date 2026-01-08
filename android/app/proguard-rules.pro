# Flutter wrapper - optimisé
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.**  { *; }
-keep class io.flutter.util.**  { *; }
-keep class io.flutter.view.**  { *; }
-keep class io.flutter.**  { *; }
-keep class io.flutter.plugins.**  { *; }

# Isar Database - comme Room
-keep class io.isar.** { *; }
-keep @io.isar.Collection class * { *; }
-keepclassmembers class * {
    @io.isar.* <methods>;
}

# Modèles de données - comme vos API models
-keep class com.ikigabo.ikigabo.data.models.** { *; }
-keepclassmembers class * {
    @io.isar.Id <fields>;
    @io.isar.Index <fields>;
}

# Local Auth
-keep class androidx.biometric.** { *; }

# Riverpod - comme vos ViewModels
-keep class com.riverpod.** { *; }

# Notifications
-keep class com.dexterous.** { *; }

# Préserver les signatures génériques
-keepattributes Signature
-keepattributes *Annotation*
-keepattributes SourceFile,LineNumberTable
-renamesourcefileattribute SourceFile

# Optimisations agressives - comme votre projet
-optimizations !code/synchronized,!field/*,!class/merging/*
-optimizationpasses 5
-allowaccessmodification
-dontpreverify

# Supprimer logs - comme votre projet
-assumenosideeffects class android.util.Log {
    public static *** v(...);
    public static *** i(...);
    public static *** w(...);
    public static *** d(...);
    public static *** e(...);
}

# Supprimer print Flutter
-assumenosideeffects class dart.developer.** {
    public static *** log(...);
}

# Ignorer warnings non critiques
-dontwarn android.content.res.Resources$NotFoundException
-ignorewarnings