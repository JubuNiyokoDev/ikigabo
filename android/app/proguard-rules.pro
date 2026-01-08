# Flutter wrapper
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.**  { *; }
-keep class io.flutter.util.**  { *; }
-keep class io.flutter.view.**  { *; }
-keep class io.flutter.**  { *; }
-keep class io.flutter.plugins.**  { *; }

# Isar Database
-keep class io.isar.** { *; }

# Local Auth
-keep class androidx.biometric.** { *; }

# Riverpod
-keep class com.riverpod.** { *; }

# Notifications
-keep class com.dexterous.** { *; }

# Optimisations agressives
-optimizations !code/simplification/arithmetic,!code/simplification/cast,!field/*,!class/merging/*
-optimizationpasses 5
-allowaccessmodification
-dontpreverify

# Supprimer les logs en production
-assumenosideeffects class android.util.Log {
    public static boolean isLoggable(java.lang.String, int);
    public static int v(...);
    public static int i(...);
    public static int w(...);
    public static int d(...);
    public static int e(...);
}

# Réduire la taille des ressources
-keepattributes *Annotation*
-keepattributes Signature
-keepattributes InnerClasses