# V1.4.0+10 — Engagement & Usability

- Replaced learner-facing £ credit with **Doubloons**: 1 Doubloon = £5 = 30 days for one dog. Existing Firestore balances stay compatible because money is still stored internally in pounds.
- Doubloon balances now update live for learners and staff without a page refresh.
- Upgraded the staff dog directory into a clearer **People Manager**, with live Doubloon controls and role changes.
- Added **Pirate Fun** with a privacy-friendly pirate-name generator and English / Welsh / Pirate translator. Pirate names are fun only and are never saved to the user profile.
- Added a learner callable English↔Welsh translation function; Pirate Talk is generated locally.
- Completed the Welsh fixed-UI/course-content audit and added a build-time Welsh coverage check.
- Fixed longer Welsh timer dialogs and game tabs for smaller phone screens.
- Changed music/effect audio focus so timer and trophy sounds can mix with background music instead of stopping it.
- Updated app/build version to `1.4.0+10`.

# Changelog

## V1.3 build 9 — Firebase dependency stability fix
- Pinned FlutterFire packages to a known-compatible release set.
- Prevents a newly released firebase_auth package from being pulled automatically during GitHub builds.
- Avoids the firebase_auth 6.6.0 Android/Kotlin compilation failure seen during testing.
- GitHub APK and web backup artifacts now retain for 7 days to reduce stored build artifacts.
- No Firebase console or Firestore changes are required for this compile fix.

## V1.3 build 8 — Cupertino import fix
- Added the missing Flutter Cupertino import used by the iOS/macOS page transition builder.
- No Firebase or Firestore changes are required for this patch.

## V1.3 build 7 — compile fix
- Fixed missing closing parentheses in the learner app shell.
- Fixed the Weekly Crew Catch-Up card nesting.
- Fixed the Manage Crew & Staff role selector nesting.
- Updated Flutter page-transition configuration for current Flutter stable.
- No Firebase or Firestore changes are required for this compile fix.


## V1.3.0 — The Super-App Update

### English / Welsh bilingual Academy
- Added a permanent **EN | CY** language control across the main signed-in and sign-in experience.
- Language choice is remembered on the device and saved to the Academy account.
- Core learner, trainer, Admin and Captain interface text now switches between English and Welsh without signing out.
- Captain notices support separate English and Welsh versions.
- Captain/Admin can write a notice in English, press **Translate to Welsh**, review/tweak the translation, preview both languages and then publish.
- Published notices are shown in the learner's selected language.
- Learner/trainer questions and conversation messages are deliberately kept exactly as written and are **not** auto-translated.
- Built-in birthday, bank-holiday and fun-day notifications support English/Welsh delivery.
- Standard weekend substitute days for New Year, Christmas and Boxing Day bank holidays are included.

### Welcome & accounts
- Redesigned opening screen with large **CREATE MY ACCOUNT** and **EXISTING USER — SIGN IN** choices.
- New registration keeps the learner signed in instead of sending them back through login.
- Secure Forgot Password flow retained.
- Added separate `captain` role alongside trainer/admin/learner.
- Added safe **Preview as Learner** Test Deck without changing staff permissions.

### Per-dog Academy access
- Each dog now has its own Academy status and paid voyage.
- Academy price and voyage duration are editable live by Captain/Admin.
- One user wallet/Academy credit can fund several active dogs.
- Each active dog draws the configured amount when its own voyage renews.
- Pause requests take effect after the already-paid voyage finishes.
- Paused dogs keep all history but official course access, progress, assessment and trophies are locked.
- Paused dogs can always request a separately charged 1-to-1.
- **Restart Adventure** allows a paused dog to return using the current configured Academy price.
- Added ledger/history for credit and access deductions.
- Existing V1.2 active dogs can be migrated safely from the staff Dog Snapshot.

### Payments without taking money in the app
- The Academy does not process cards or bank payments.
- Captain/Admin can edit bank/account details, standing-order/direct-debit instructions and payment wording without rebuilding.
- Learner payment reference is generated from dog name + learner initials + an Admin-editable suffix (default `007`).
- Learner can press **I've Made a Payment**; Admin verifies it externally before adding credit.

### Training & support
- Retains eight Key Skills with 5–9 lesson videos each.
- Lesson-specific **Need Help** now opens a comment/video conversation attached to the exact dog, skill and lesson.
- Trainer receives help in the Action Centre and can claim, reply, use saved replies, resolve or set a follow-up.
- Added trainer Recommend Skill action.
- 1-to-1 wording, typical price and typical duration are editable in Academy Settings; the actual quote remains per booking.

### Notifications
- Added in-app notification centre and unread bell.
- Supplied Firebase backend can send background device push notifications after Functions are deployed.
- Notifications cover trainer replies, assessments/trophies, 1-to-1 updates, important notices, account events, birthdays and celebrations.

### Captain's Trophy Cabin
- Trophy Cabinet presented as a wooden Captain's Cabin display.
- Locked awards are shadowed with `???`; earned awards become full colour.
- Trophy reveal/accept celebration with confetti and sound.
- Added birthday, login and course milestone trophies.
- Added Start Lights achievement collection including a hidden **Too Keen, Captain!** award.

### Games & Practice
- Added **Flyball Start Lights** practice game:
  - random short delay before the sequence;
  - top / middle / lower red lights one second apart;
  - green one second later;
  - STOP can be pressed early or after green;
  - timing stored to thousandths and displayed to two decimal places;
  - tiny early attempts can show `-0.00` with an "Aww" sound;
  - rolling-start celebration for +0.000 to +0.004 seconds;
  - attempts, rolling starts, streak, early starts, best and average tracked.
- Start Lights trophies: **Lantern Lubber**, **Rolling Roger**, **Triple Broadside**, **Start Line Scallywag**, **Quickdraw Quartermaster**, **Cannon-Fire Reflexes**, **Master of the Lights**, plus hidden **Too Keen, Captain!**.
- Added short Training Timer with Parrot Squawk, Ship Bell, Tiny Cannon or silent end alarm and optional diary save.

### Crew & Kudos
- Opt-in Crew discovery using learner display name + dog name only.
- Friend requests and Crew links.
- Positive achievement feed and preset Kudos reactions.
- Learners control discoverability and achievement sharing.

### Appearance & music
- Added light pirate background scenes with rotate/favourite/off controls and reduced-motion option.
- Background music is optional and OFF by default.
- Bundled two **The Gentle Tide** starter tracks which alternate.
- Captain/Admin can add/disable public MP3 links from the Music Library without rebuilding.

### Celebrations
- Automatic birthday messages and Birthday Buccaneer trophy.
- Built-in messages for standard England & Wales bank-holiday dates plus St David's Day.
- Fun dates include National Pet Day, National Rum Day, National Dog Day, Talk Like a Pirate Day and World Animal Day.
- Captain/Admin can add additional annual custom celebration dates/messages without rebuilding.

### Links, photos & Treasure Chest
- Follow & Support page: Facebook, Instagram, TikTok, YouTube, website, Easyfundraising and GoFundMe.
- Bank/payment details are editable live.
- Optional compressed member and dog profile photos through Firebase Storage.
- Menai Muttineers Treasure Chest teaser with merchandise-interest capture.

### Staff, reports & management
- Trainer Desk, Action Centre, Dog Directory and Dog Snapshot.
- Account/payment actions separated from ordinary trainer permissions.
- Saved trainer replies, private staff notes, follow-ups, recommendations and claim-work tools.
- Captain/Admin controls roles, course content, settings, links, music, celebrations, notices and feature switches.
- Quarterly reporting includes Academy totals, per-skill assessment performance, help-demand trends, engagement and fun stats.
- Added privacy-safe quarterly social summary.
- Captain's Log, audit trail and System Health.
- Added account-closure request workflow: **Set Sail on a New Adventure**.
- Supplied callable Firebase Function can permanently delete approved learner data and Auth account while anonymising necessary Academy accounting history.

### Backend supplied with V1.3
- Firebase Functions source for:
  - background push from Academy notification records;
  - daily per-dog renewal / pause processing;
  - automatic built-in/custom celebration messages;
  - birthday messages and birthday trophies even if the app is not opened;
  - complete Admin/Captain-approved learner account removal.
- Firebase Storage security rules for compressed profile/dog photos.

## V1.2.2 — Password reset pop-up fix
- Fixed Flutter debug error in the Forgot Password dialog.

## V1.2.1 — Password reset
- Added secure Firebase password reset from the sign-in screen.

## V1.2.0 — Training paths, Trophy Cabinet & Treasure Chest
- Added structured lessons, video assessments, trainer-awarded trophies, automatic milestones, trophy acceptance/celebrations, dog birthdays and Treasure Chest teaser.
