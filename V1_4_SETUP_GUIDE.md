# Menai Muttineers Academy V1.4 — Upgrade Guide

V1.4 upgrades the existing Academy without replacing learner accounts or Firestore history.

## What changes

- **Doubloons:** 1 Doubloon = £5 = 30 days of Academy access for one dog.
- Existing `academyCredit` values stay stored as pounds behind the scenes, so there is **no balance migration**.
- Learner and staff Doubloon balances listen to Firestore live and update without refreshing.
- **People Manager:** easier role and Doubloon controls.
- **Welsh:** fixed Academy UI and the built-in course/trophy text have been audited; GitHub now checks that new fixed English UI text has a Welsh entry.
- **Audio:** timer/trophy effects use a mixing audio context so background music should keep playing.
- **Pirate Fun:** pirate-name generator plus English / Welsh / Pirate translator. Generated pirate names are never saved to profiles.

## Firestore rules

V1.4 does **not** introduce a new client collection or permission requirement. If the supplied V1.3 rules are already live, no Firestore rules change is required for this upgrade.

The `firestore.rules` file remains in the package as the reference/current rule set.

## Firebase Functions — required for the fun English/Welsh translator

V1.4 adds the callable function `translateAcademyText`. The rest of Pirate Talk works on the device, but English↔Welsh translation needs this function deployed.

From the Academy project in Cloud Shell:

```bash
cd ~/Menai-Muttineers-Academy/functions
npm install
cd ..
firebase deploy --only functions
```

The project already uses Cloud Translation for Captain/Admin notice translation. If that older translation feature already works, the Google Cloud Translation setup should already be in place.

## Build test

Committing V1.4 to `main` starts **Build Academy APK and Web**.

The workflow now runs the Welsh UI audit first, then Flutter compiles the APK and web app.

Successful artifacts are:

- `Menai-Muttineers-Academy-V1-4-APK`
- `Menai-Muttineers-Academy-V1-4-Web`

The first green GitHub Action is the real Flutter compile test for this package.

## First checks after installation

1. Open the Academy in English and Welsh and move through Home, Training, Games, Support, Account and Settings.
2. From Admin/Captain, add **1 Doubloon** to a learner and check that the learner balance changes without refresh.
3. Confirm 1 Doubloon opens **30 days** for one dog.
4. Open **Games & Practice → Pirate Fun** and test the name generator.
5. After Functions are deployed, test English→Welsh and Welsh→English in the translator.
6. Start background music, then test the timer alarm and a trophy sound. Music should continue/mix rather than be stopped.
7. Switch the timer to Welsh on a small phone and make sure the finish dialog wraps instead of overflowing.

## Important

Do not delete or recreate Firestore data for this upgrade. Existing users, dogs, progress, trophies, payments and balances are designed to carry forward.
