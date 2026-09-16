# Menai Muttineers Academy V1.4

One shared Menai Muttineers Pre-Flyball Academy for Android and the web. The APK and web app use the same Firebase accounts and data.


## English / Welsh

V1.4 is bilingual. Learners and staff can switch between **EN | CY** from the app header. The choice is remembered and follows the Academy account. Fixed Academy interface text is translated in the app. Captain notices can be auto-translated from English to Welsh using the supplied Firebase callable function, then manually checked before publishing. Learner/trainer conversation text is never silently translated.

## V1.4 at a glance

### Learners
- Clear new-user / existing-user landing screen and secure Forgot Password flow.
- One learner account can manage several dogs; each dog has its own paid Academy voyage.
- Academy access uses Doubloons: 1 Doubloon = £5 = 30 days for one dog.
- Live Doubloon balance and history, external bank-payment instructions, payment reference and payment confirmation request.
- Pause a dog at the end of its current paid voyage; a paused dog keeps its history but course access is locked until Restart Adventure.
- 1-to-1 requests remain available for paused dogs and are charged separately; the guidance text/price is Admin-editable.
- Eight structured Key Skills with 5–9 lessons each, YouTube lessons, lesson progress and assessments.
- Need Help on an individual lesson opens a two-way trainer conversation with optional video link.
- Notification bell plus optional background push notifications after Firebase Functions are deployed.
- Captain's Trophy Cabin with shadowed `???` awards, trophy reveals, confetti and sounds.
- Automatic milestone, birthday and Start Lights trophies.
- Crew/friend requests, privacy controls, positive achievement feed and preset Kudos.
- Games & Practice: Flyball Start Lights, responsive training timer and a Pirate Fun area with a pirate-name generator and English/Welsh/Pirate translator.
- Follow & Support page for social media, Easyfundraising, GoFundMe, website and bank-payment information.
- Treasure Chest merchandise teaser and interest capture.
- Optional compressed member/dog profile photos through Firebase Storage.
- Optional rotating pirate backgrounds, reduced-motion setting, background music, volume and track skip.
- Two built-in Gentle Tide tracks; Captain/Admin can add enabled public MP3 links without rebuilding the app.
- Set Sail on a New Adventure account-closure request.

### Trainers
- Trainer Desk and Action Centre for assessments, lesson-help threads, 1-to-1s and follow-ups.
- Claim work so two trainers do not unknowingly answer the same item.
- Private staff notes, saved replies, follow-up reminders and Recommend Skill actions.
- One-page Dog Snapshot showing progress and current Academy status.

### Admin
- Academy access fixed at 1 Doubloon (£5) for 30 days per dog, with editable 1-to-1 wording/price/duration, payment-reference suffix and account-closure wording.
- Bank details, standing-order/direct-debit instructions and social/fundraising links can all be edited live.
- Manage Learner / Trainer / Admin / Captain roles from inside the app.
- Doubloon controls, payment confirmation, pause/restart requests and legacy dog migration.
- Course/YouTube editor, music library, celebration calendar, notices, feature switches, saved replies and account-deletion requests.

### Captain
- Captain's Bridge dashboard and Action Centre.
- Quarterly Academy reporting with learner/dog totals, assessment/pass rate, per-skill performance, help trends, training logs, trophies, graduates, 1-to-1s, Kudos and Start Lights statistics.
- Privacy-safe social summary for sharing public Academy achievements.
- Captain's Log, audit trail, System Health and safe Preview as Learner / Test Deck.

## Important V1.4 setup

1. Upload V1.4 to the existing GitHub repository.
2. V1.4 does not need new Firestore permissions if V1.3 rules are already live; the supplied rules remain the reference copy.
3. Update `.github/workflows/build-apps.yml` if the hidden `.github` folder did not upload.
4. Let GitHub build the Android APK and web app.
5. Test the core app first.
6. Optional/full features:
   - Enable Firebase Storage and publish `storage.rules` for profile photos.
   - Deploy the supplied Firebase Functions for the learner English/Welsh translator, background push, daily renewals/pauses, automatic celebration messages and complete Admin-approved account deletion.

The app can build and the main Academy can be tested before Storage/Functions are enabled. See `V1_4_SETUP_GUIDE.md`.
