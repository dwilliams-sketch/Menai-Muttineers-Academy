# Upgrade the existing GitHub project to V1.2

This pack is designed to replace/update the files in the existing `menai-muttineers-academy` GitHub repository. Keep the Firebase secrets already saved in GitHub — you do not need to enter them again.

## 1. Upload V1.2 to GitHub
1. Open the existing GitHub repository.
2. Go to **Code → Add file → Upload files**.
3. Upload the **contents** of this V1.2 folder to the repository root.
4. Allow GitHub to replace files with the same names.
5. Commit with a message such as `Upgrade Academy to V1.2`.
6. If Windows hides `.github`, update `.github/workflows/build-apps.yml` manually in GitHub as before.

A push to `main` should automatically start **Build Academy APK and Web**. You can also run it manually from **Actions**.

## 2. IMPORTANT — publish the new Firestore rules
The V1.2 app needs new database permissions.

1. Open Firebase Console → Menai Muttineers Academy.
2. Open **Firestore Database → Rules**.
3. Replace the existing rules with the complete contents of `firestore.rules` from this V1.2 pack.
4. Click **Publish**.

Do this before testing lesson progress, trophy acceptance, streak trophies or Treasure Chest interest.

## 3. Build outputs
A successful GitHub run creates:
- `Menai-Muttineers-Academy-V1-2-APK` — Android installer ZIP containing `app-debug.apk`.
- `Menai-Muttineers-Academy-V1-2-Web` — web build backup.
- GitHub Pages deployment — updated online Academy.

## 4. Add lesson videos
Sign in as Captain/Admin and open **Admin**.
Under **Key Skill video lessons**, expand each Key Skill and paste the YouTube URL for each lesson.

Unlisted YouTube videos are ideal for the course.

## 5. Existing accounts
Existing Firebase learner/admin/trainer accounts continue to work. New V1.2 fields use safe defaults until they are populated.

Existing learners can add or estimate their dog’s date of birth from **My Dog**.
