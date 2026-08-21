# Menai Muttineers Academy V1.2.1

A shared Flutter Android + web training platform for the Menai Muttineers remote Pre-Flyball Academy.

## V1.2.1 highlights
- Added **Forgot password?** on the sign-in screen using secure Firebase password-reset emails.
- Learners, trainers and admins can reset their own password without Captain/Admin access to the password.
- Existing V1.2 features remain unchanged.

## V1.2 highlights
- 8 structured Key Skills with 5–9 video lessons each.
- Learner lesson progress: Watched / Practised / Confident / Need Help.
- Assessments unlock after every lesson in the Key Skill is practised.
- Trainer review with Pass + Trophy or Keep Practising.
- Shadowed Trophy Cabinet with hidden `???` awards.
- Trophy reveal pop-ups, confetti/party-popper animation and celebration sound.
- Automatic first-login, 7-day, 14-day, 30-day, first-lesson, first-assessment, first-skill and birthday trophies.
- Dog date of birth with estimated-date option.
- Menai Muttineers Treasure Chest merch teaser + interest collection.
- Captain/Admin can manage learner/trainer/admin roles inside the app.
- Existing payment/access-code, 1-to-1, Ask a Trainer, diary, notices and Google Meet features retained.

## Platforms
The same Flutter codebase builds:
- Android APK.
- Web app deployed through GitHub Pages.

Both use the same Firebase Authentication and Cloud Firestore data.

## Important before V1.2 testing
Publish the updated `firestore.rules` in Firebase. See `V1_2_UPGRADE_GUIDE.md`.

## Build
The GitHub Actions workflow at `.github/workflows/build-apps.yml` builds both platforms using the Firebase repository secrets already configured for this project.
