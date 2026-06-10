# flutter_local_notifications: scheduled notifications are deserialized via
# Gson reflection at boot/fire time; R8 must not strip or rename these.
-keep class com.dexterous.** { *; }

# Flutter references Play Core for deferred components even when unused.
-dontwarn com.google.android.play.core.**
