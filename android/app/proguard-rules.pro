# Android framework XML parsers implement org.xmlpull.v1.XmlPullParser by name.
# If R8 renames this interface, AppCompat menu inflation can crash in release
# builds when UCropActivity creates its toolbar menu.
-keep class org.xmlpull.v1.** { *; }
-keep interface org.xmlpull.v1.** { *; }
