# Menai Muttineers Academy V1.3 — Upgrade & Build Guide

This upgrades the existing working V1.2 GitHub/Firebase project. Existing Firebase accounts and Academy records are kept.

## Part 1 — Upload V1.3 to GitHub

1. Download and extract the V1.3 ZIP.
2. Open the existing `menai-muttineers-academy` repository in GitHub.
3. Open the **<> Code** tab.
4. Choose **Add file → Upload files**.
5. Drag the CONTENTS of the extracted V1.3 folder into the repository root.
6. Allow existing files to be replaced/updated.
7. Suggested commit message: `Upgrade Menai Muttineers Academy to V1.3`.
8. Commit the changes.

### Hidden `.github` folder
Windows may hide `.github`, so it may not upload.

After the normal upload:
1. In GitHub open `.github → workflows → build-apps.yml`.
2. Click the pencil/edit icon.
3. Open the V1.3 `.github/workflows/build-apps.yml` on your computer in Notepad.
4. Copy all of it and replace the GitHub version.
5. Commit with `Update V1.3 build workflow`.

The final workflow produces:
- `Menai-Muttineers-Academy-V1-3-APK`
- `Menai-Muttineers-Academy-V1-3-Web`
- the GitHub Pages deployment package.

## Part 2 — Publish the V1.3 Firestore rules

Do this before asking real learners to use V1.3.

1. Open Firebase Console → your **Menai Muttineers Academy** project.
2. Open **Firestore Database → Rules**.
3. Open `firestore.rules` from the V1.3 folder in Notepad.
4. Replace all existing Firebase Rules text with the V1.3 rules.
5. Click **Publish**.

The new rules support per-dog access, Crew/Kudos, lesson-help threads, staff tools, dynamic settings, Start Lights, reports and account-closure requests.

## Part 3 — Build the APK and web app

Uploading/committing to `main` normally starts the GitHub Action automatically.

1. Open GitHub → **Actions**.
2. Open **Build Academy APK and Web**.
3. Wait for the latest V1.3 run.
4. Green tick = successful compile/build.
5. Under **Summary → Artifacts**, download `Menai-Muttineers-Academy-V1-3-APK`.
6. Extract it and install `Menai-Muttineers-Academy-V1.3.apk` on Android.
7. The same successful action also updates the existing GitHub Pages web link.

If the build is red, open the failing step and copy/screenshot the error for fixing. The first GitHub V1.3 build is the full Flutter compiler test because Flutter is not available in the packaging environment.

## Part 4 — First V1.3 Captain setup

Log in with the existing Captain/Admin account.

Open **Control Room → Academy Price, Access & Wording** and set:
- Academy price per dog;
- voyage/access days;
- typical 1-to-1 price;
- typical 1-to-1 minutes;
- 1-to-1 learner wording;
- payment-reference suffix (default `007`);
- account-closure wording.

Open **Links, Bank & Support** and enter/edit:
- Facebook / Instagram / TikTok / YouTube / website;
- Easyfundraising / GoFundMe;
- bank/account name;
- sort code / account number;
- standing-order/direct-debit instructions;
- payment note.

These values are live Firestore settings — changing them does NOT require a new APK.

## Part 5 — Existing V1.2 dogs

V1.3 keeps legacy V1.2 activated learners usable. In the staff **Dogs** view, a legacy dog can be migrated onto the new per-dog voyage model. The migration uses the CURRENT configured Academy price/days rather than a hard-coded value.

## Part 6 — Optional profile photos / Firebase Storage

Profile photos are kept behind an Admin feature switch until Storage is configured.

Cloud Storage for Firebase currently requires the Firebase project to use the Blaze billing plan. The Academy compresses/crops profile and dog photos before upload; training videos remain external YouTube/Drive links.

To enable it:
1. In Firebase open **Storage** and create/confirm the default bucket.
2. Open **Storage → Rules**.
3. Replace the rules with the complete V1.3 `storage.rules` file.
4. Publish.
5. In Academy **Control Room → Feature Switches**, turn profile-photo uploads ON.
6. Set a Google Cloud budget alert before wider use.

## Part 7 — Background push, automatic renewals/celebrations & complete deletion

The normal app and in-app notification bell work without Functions. V1.3 also supplies backend Functions for the jobs that must happen while nobody has the app open.

These backend features require Firebase Functions / a billing-enabled project:
- push notification appears while Android app is closed;
- daily automatic per-dog renewal/pause processing;
- automatic bank-holiday/fun-day/custom celebration messages even if the learner does not open the app;
- birthday messages/trophies even if the app is not opened;
- full Admin-approved Auth/data deletion for `Set Sail on a New Adventure`.

The backend source is in the `functions` folder.

### Deploy with Firebase CLI
On a computer with Node installed:

```text
npm install -g firebase-tools
firebase login
firebase use menai-muttineers-academy
firebase deploy --only functions
```

If the project alias has not been set locally, run `firebase use --add` first and choose the Menai Muttineers Academy Firebase project.

You can also deploy the rules through CLI if wanted:

```text
firebase deploy --only firestore:rules,storage
```

After Functions deploy, allow notifications when Android asks. Device tokens are stored against the signed-in Academy account.

## Part 8 — Music

V1.3 contains two built-in Gentle Tide tracks and alternates them.

For future tracks, Captain/Admin can open **Control Room → Academy Music Library** and enter:
- track title;
- a public direct MP3 URL;
- enabled/disabled state.

No APK rebuild is needed for remote music additions. Learners control Music On/Off and volume themselves; music defaults OFF.

## Part 9 — Celebration calendar

The app/back-end contains standard Academy celebration dates. Captain/Admin can add more in **Celebration Calendar** using month/day/title/message. These are data records, so adding a new day does not require another APK.

## Part 10 — Test before wider rollout

Use `TEST_CHECKLIST.md` and Captain **Preview as Learner**. Test at least one new learner with two dogs, a pause/restart, lesson help, assessment/trophy, Crew/Kudos, Start Lights and the quarterly report before wider rollout.

## Part 8 — English / Welsh and Captain notice translation

The **EN | CY** interface toggle works in the APK/web build itself. No extra Firebase setup is needed for the fixed bilingual interface.

Captain/Admin **Translate to Welsh** for newly written notices uses the supplied callable Firebase Function `translateAdminText` and Google Cloud Translation.

To enable that live translation feature:
1. The Firebase project must use the **Blaze** billing plan because Cloud Functions require billing-enabled Google Cloud resources.
2. In the Google Cloud Console for the same `menai-muttineers-academy` project, enable **Cloud Translation API**.
3. Deploy the supplied `functions` folder using Firebase CLI. A browser-based Google Cloud Shell can be used if you do not want to install developer tools on the computer.
4. If Google reports an IAM permission error for translation, grant the Functions runtime service account the **Cloud Translation API User** role, then deploy again.
5. Test from **Captain → Control Room → Captain Notices**: write English, press **Translate to Welsh**, tweak the Welsh, mark it checked and preview before publishing.

If Functions/Translation are not enabled yet, the notice editor still allows both English and Welsh to be typed manually. It will not pretend a translation succeeded.

**Privacy rule:** learner/trainer help conversations, feedback, notes and free-text questions are stored and displayed as originally written. They are not sent to automatic translation by the app.

## Part 9 — Automatic celebration messages

V1.3 includes automatic messages for birthdays, St David's Day, common England & Wales bank holidays and fun dates such as National Pet Day, National Rum Day, National Dog Day, Talk Like a Pirate Day and World Animal Day. Weekend substitute days for New Year/Christmas/Boxing Day are included.

- When the app is opened, the client creates the day's missing celebration notification safely using a stable ID.
- After `dailyAcademyMaintenance` is deployed, the backend can create those messages even when the learner does not open the app that day.
- Built-in messages are delivered in the learner's saved English/Welsh language.
- Captain/Admin can add extra annual dates in the Celebration Calendar without rebuilding the APK.

## Part 10 — Music library

The two supplied **The Gentle Tide** tracks are bundled inside the APK/web build and alternate automatically when background music is enabled. Music is OFF by default for learners.

Captain/Admin can add more music without rebuilding by adding a **public direct HTTPS MP3 URL** in **Control Room → Academy Music Library**. For the web version, the file host must allow normal browser playback/CORS. If an added remote track cannot play, the built-in tracks remain available.

## Part 11 — Before real rollout

Run `TEST_CHECKLIST.md` using at least:
- one Captain account;
- one Trainer account;
- one new learner with two dogs;
- one active and one paused dog;
- one English account and one Welsh account.

The first GitHub Actions run is the full Flutter compile test for this V1.3 package. If it is red, open the first failed build step and use that exact message for the next fix rather than changing Firebase data at random.

