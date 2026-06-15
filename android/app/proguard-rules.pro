# Google Mobile Ads (AdMob)
-keep class com.google.android.gms.ads.** { *; }
-keep class com.google.ads.** { *; }
-dontwarn com.google.android.gms.ads.**

# AndroidX WorkManager / Room
# (versionCode 3 -> 4에서 R8이 WorkDatabase 리플렉션 클래스를 제거해 실행 즉시 크래시난 적 있음)
-keep class androidx.work.** { *; }
-keep class * extends androidx.room.RoomDatabase
-keep class **_Impl { *; }
-dontwarn androidx.work.**

# Keep attributes needed for crash reports / reflection
-keepattributes *Annotation*
-keepattributes Signature
-keepattributes SourceFile,LineNumberTable
