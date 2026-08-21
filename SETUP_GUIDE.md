# First Setup Guide

## A. Create the Firebase project

Create one Firebase project called **Menai Muttineers Academy**.

This one project is the shared database for the APK and the web app.

### 1. Authentication

Firebase Console → Authentication → Sign-in method → enable **Email/Password**.

### 2. Firestore

Firebase Console → Firestore Database → Create database → Production mode.

Open Firestore Rules and replace them with the contents of `firestore.rules`, then Publish.

### 3. Android app in Firebase

Firebase Project Settings → Your apps → Add app → Android.

Use this exact package name:

`com.menaimuttineers.academy`

You do not need to put `google-services.json` in this repository. This V1.2 build passes Firebase configuration safely into both builds through GitHub Actions.

### 4. Web app in Firebase

Firebase Project Settings → Your apps → Add app → Web.

Give it a name such as:

`Menai Muttineers Academy Web`

Firebase will show a configuration containing values such as apiKey, authDomain, projectId, storageBucket, messagingSenderId and appId.

## B. Add GitHub repository secrets

GitHub repository → Settings → Secrets and variables → Actions → New repository secret.

Add these exact names:

- `FIREBASE_API_KEY`
- `FIREBASE_PROJECT_ID`
- `FIREBASE_MESSAGING_SENDER_ID`
- `FIREBASE_AUTH_DOMAIN`
- `FIREBASE_STORAGE_BUCKET`
- `FIREBASE_WEB_APP_ID`
- `FIREBASE_ANDROID_APP_ID`

`FIREBASE_WEB_APP_ID` is the `appId` from the Firebase WEB app.

`FIREBASE_ANDROID_APP_ID` is the App ID shown for the Firebase ANDROID app in Project Settings.

The Android and Web builds use the same project ID and Firestore data, but each has its own Firebase App ID.

## C. Enable the online web link

GitHub repository → Settings → Pages.

Under Build and deployment, choose **GitHub Actions** as the source.

After the workflow publishes successfully, GitHub will give the repository a web address similar to:

`https://YOUR-GITHUB-NAME.github.io/YOUR-REPOSITORY-NAME/`

In Firebase Authentication settings, add your GitHub Pages host to **Authorized domains** if Firebase asks for it. The host is normally:

`YOUR-GITHUB-NAME.github.io`

The web app and APK then use the same accounts, dogs, payments, course progress, submissions, trophies, questions, bookings and trainer notes.

## D. Run the build

GitHub → Actions → **Build Academy APK and Web** → Run workflow.

A successful run gives you:

- Android APK artifact
- Web build artifact
- GitHub Pages deployment link

## E. Make the first account Captain/Admin

1. Open the web app or APK.
2. Register yourself once as a normal learner.
3. Firebase Console → Firestore → `users`.
4. Find your user record.
5. Change `role` from `learner` to `admin`.
6. Change `paymentStatus` to `paid`.
7. Change `activated` to `true`.
8. Sign out and back in.

You will now see the Captain/Admin screens.

## F. Add trainers / admins

A trainer or additional admin registers once in the normal way.

In V1.2 the Captain can then use **Admin → Manage Crew & Staff** and change their role to **Trainer** or **Admin** directly in the app.

The original Captain account still needs the one-time Firebase role change described above. After that, normal staff-role changes can be managed in the Academy.

Trainers can review skills, award trophies, reply to questions and manage 1-to-1 requests. Admins also get payment, lesson, notice and staff-role controls.

## G. Payment and access in V1.2

Payment is deliberately manual in V1.2.

Captain/Admin opens Learners and presses **Mark paid + issue code**.

The app creates a six-character activation code. Send that code to the learner.

The readable code is shown to the Admin when it is generated. Only a one-way hash is stored in Firestore.

If the learner loses it, use **New access code**.

## H. Course videos and live sessions

Captain/Admin → Admin:

- Set the next live-session date/time
- Set the topic
- Paste the shared Google Meet URL
- Expand each Key Skill and paste a YouTube URL for each individual lesson

These are database changes. You do not rebuild the APK when a lesson or Meet link changes.

## I. 1-to-1 flow

Learner:

Request 1-to-1 → choose topic/type/availability → submit.

Trainer/Admin:

1-to-1 → Manage → assign trainer → enter proposed date/time → add Meet link if online → set status to PROPOSED.

Learner:

Press **Accept time** → status becomes BOOKED.

Trainer:

After the session, add trainer notes/homework and mark COMPLETED.

Everything remains in that dog/learner's shared Academy record.
