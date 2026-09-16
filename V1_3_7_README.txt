MENAI MUTTINEERS ACADEMY V1.3.7 — SETTINGS & LANGUAGE STATE FIX

GOOD NEWS
=========
V1.3.6 gets into the Academy and signs in successfully when the phone network
allows Firebase traffic.

The next bugs are UI-state bugs, not "too many features".

FAULT 1 — EN/CY FLIPS BACK TO EN
================================
AuthGate was comparing the live language button against the last Firestore user
snapshot on EVERY rebuild. Tapping CY changed the app immediately, but before
Firestore returned the new value, AuthGate saw the old EN snapshot and changed
the app straight back.

V1.3.7 applies the stored account language only once when a user session loads.
After that, EN/CY belongs to the user's button and is persisted to Firestore.

FAULT 2 — SETTINGS CONTROLS LOOK DEAD
=====================================
Profile & Settings was built using the AppUser object that existed when the page
was opened. The switches wrote new values to Firestore, but the controls were
still displaying that old object, so they appeared not to move.

V1.3.7 gives all settings proper local state:
- switches move immediately;
- volume moves smoothly while dragged;
- volume is saved when the drag ends;
- dropdowns change immediately;
- profile/dog photo previews update after upload;
- every change is still saved to the same Firestore user record.

MUSIC
=====
The music switch can now actually turn on and persist. The existing LearnerShell
already listens to the user profile and tells AcademyMusicService to start/stop
or change volume when Firestore updates.

This patch deliberately fixes the controls first. If the switch stays ON but
the music itself is silent, that will be a separate audio-playback fault and can
be diagnosed directly without mixing it up with the settings-state bug.

VERSION
=======
1.3.7+16

UPDATE THESE FIVE FILES
=======================
1. .github/workflows/build-apps.yml
   Replace with build-apps.REPLACEMENT.yml

2. pubspec.yaml
   Replace with the new pubspec.yaml

3. lib/main.dart
   Replace with the new lib/main.dart

4. lib/widgets/language_toggle.dart
   Replace with the new language_toggle.dart

5. lib/screens/learner/more_screens.dart
   Replace with the new more_screens.dart

Commit message:
    Fix settings controls and language persistence

Only the newest GitHub Actions build matters.

AFTER INSTALLING V1.3.7 TEST
============================
1. Tap CY — it should stay in Welsh.
2. Go Profile & Settings.
3. Toggle Pirate backgrounds — switch should move immediately.
4. Toggle Background shanty music — switch should stay ON.
5. Move Music volume — thumb should follow your finger.
6. Leave Settings and open it again — choices should still be saved.
7. Confirm whether Gentle Tide music can be heard.

No Firestore data, Storage data, Cloud Functions, accounts or security rules are
changed by this patch.
