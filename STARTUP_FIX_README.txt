MENAI MUTTINEERS ACADEMY — V1.3.1 STARTUP FIX

WHAT THIS FIXES
The V1.3 Android app can remain on the Menai Muttineers logo indefinitely
because the old startup sequence waits for local language preferences and
Firebase BEFORE Flutter draws its first screen.

V1.3.1 changes startup so:
- Flutter opens immediately.
- A visible "Preparing the Academy..." screen is shown.
- Language preference loading cannot block startup.
- Firebase gets a 20-second startup timeout.
- If Firebase cannot start, the app shows a readable error and a RETRY button
  instead of remaining on the logo forever.
- Missing FIREBASE_* GitHub build settings are reported clearly.
- No Firebase data, Firestore rules, Storage rules or Cloud Functions are changed.

VERSION
1.3.1+10

UPLOAD TO GITHUB
1. Extract this ZIP.
2. In the Menai-Muttineers-Academy GitHub repository choose:
   Add file -> Upload files
3. Upload the CONTENTS of this folder to the repository root:
   - lib
   - pubspec.yaml
   - STARTUP_FIX_README.txt
4. Allow GitHub to replace/update the matching files.
5. Commit message:
   Fix V1.3 Android startup hang
6. Wait for the newest GitHub Actions run to get a green tick.
7. Download the newest APK artifact and install/update the app.

FIRST TEST
The native logo should disappear quickly and be replaced by either:
- the Academy screen, or
- "Preparing the Academy..." for a few seconds.

If Firebase still has an underlying problem, do NOT wait for minutes.
After 20 seconds V1.3.1 should show "Startup details".
Send a screenshot or copy that message so the exact Firebase problem can be fixed.

IMPORTANT
This patch deliberately keeps the Firebase package versions from the successful
V1.3 dependency fix. Do not replace pubspec.yaml with an older V1.3 copy.
