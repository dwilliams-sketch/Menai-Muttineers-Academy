MENAI MUTTINEERS ACADEMY V1.3.2 — ANDROID FIREBASE BRIDGE FIX

WHY
V1.3.1 successfully exposed the real startup error:
PlatformException(channel-error ... FirebaseCoreHostApi.initializeApp)

That means the Flutter UI is running, but Android is not successfully talking to
the native Firebase plugin.

The repository's current GitHub workflow had also reverted to an older builder
and was following "channel: stable". Flutter 3.47 was released in August 2026,
so the same workflow can silently change Flutter versions between builds.

WHAT THIS PATCH DOES
- Pins GitHub builds to Flutter 3.44.8 instead of floating on the newest stable.
- Restores the V1.3 Android settings (minSdk 23 and notification permissions).
- Keeps the successful pinned Firebase package versions.
- Adds a harmless build diagnostic showing whether FlutterFirebaseCorePlugin is
  present in the generated Android plugin registrant.
- Restores 7-day artifact retention.
- Names the APK clearly as V1.3.2.
- Bumps app version to 1.3.2+11.

NO FIREBASE DATABASE/RULE/FUNCTION CHANGES ARE REQUIRED.

BEST WAY TO APPLY
Because .github is a hidden folder on some phones, either:

A) GitHub web
Open .github -> workflows -> build-apps.yml, edit it and replace the whole file
with build-apps.REPLACEMENT.yml from this patch. Then upload pubspec.yaml.

OR

B) Cloud Shell
Copy the two replacement files into the repo and commit/push.

Commit message:
Fix Android Firebase plugin bridge build

TEST
After green tick:
1. Download Menai-Muttineers-Academy-V1-3-2-APK.
2. Extract and install the APK.
3. Open it.
4. If it still reaches the V1.3.1 diagnostic screen, send the new Startup details.
