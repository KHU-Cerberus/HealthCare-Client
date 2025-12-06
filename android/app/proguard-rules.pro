# Gson specific classes
-keepattributes Signature
-keepattributes *Annotation*
-dontwarn sun.misc.**

# Gson uses generic type information stored in a class file when working with fields
-keepattributes Signature

# Keep generic signature of TypeToken
-keep class com.google.gson.reflect.TypeToken { *; }
-keep class * extends com.google.gson.reflect.TypeToken

# Keep all model classes
-keep class com.example.health_care.SleepSegmentData { *; }

# Keep Gson annotations
-keep class com.google.gson.annotations.** { *; }

# Prevent R8 from leaving Data object members always null
-keepclassmembers,allowobfuscation class * {
  @com.google.gson.annotations.SerializedName <fields>;
}

# Retain generic signatures of TypeToken and its subclasses
-keep,allowobfuscation,allowshrinking class com.google.gson.reflect.TypeToken
-keep,allowobfuscation,allowshrinking class * extends com.google.gson.reflect.TypeToken

# Sleep API classes
-keep class com.google.android.gms.location.** { *; }
-keep interface com.google.android.gms.location.** { *; }