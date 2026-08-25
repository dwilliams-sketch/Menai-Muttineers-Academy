# V1.3 — Simple GitHub Build Steps

This package is an upgrade for the existing `menai-muttineers-academy` GitHub/Firebase project.

## 1. Upload V1.3
1. Extract the V1.3 ZIP.
2. GitHub → existing Academy repository → **<> Code**.
3. **Add file → Upload files**.
4. Drag the CONTENTS of the extracted V1.3 folder into the repository root.
5. Commit as: `Upgrade Menai Muttineers Academy to V1.3`.

## 2. Check the hidden workflow
Windows may hide `.github`.

GitHub → `.github` → `workflows` → `build-apps.yml`.
If it did not update, edit it and replace its contents with the V1.3 version from the ZIP.

## 3. Publish Firestore rules
Firebase → **Firestore Database → Rules**.
Replace the existing rules with the ZIP's `firestore.rules`, then **Publish**.

## 4. Build APK + web
The GitHub build should start after the commit.

GitHub → **Actions → Build Academy APK and Web**.
Wait for the latest run.
- Green tick: open **Summary → Artifacts** and download `Menai-Muttineers-Academy-V1-3-APK`.
- The same build deploys the web version to the existing GitHub Pages link.
- Red cross: open the first failed step and copy/screenshot the exact error.

## 5. Captain first checks
Before inviting learners, set live values in **Control Room**:
- price per dog / access days;
- 1-to-1 wording / guide price / guide duration;
- bank details/payment wording/reference suffix;
- social/fundraising links;
- feature switches.

## 6. Optional/full cloud features
The app and web build can be tested before these are enabled, but these features need extra Firebase setup:
- **Firebase Storage**: profile/dog photo uploads.
- **Firebase Functions**: background push, daily renewal/pause processing, automatic celebrations when the app is closed, complete approved account deletion.
- **Cloud Translation API + Functions**: Captain notice English→Welsh auto-translation.

See `V1_3_SETUP_GUIDE.md` for those steps.
