# Menai Muttineers Academy — Changelog

## V1.2.1 — Password Reset

### Login & account recovery
- Added **Forgot password?** to the sign-in screen.
- User enters their Academy email address and Firebase sends a secure password-reset email.
- Passwords remain private; Captain/Admin cannot see or recover a learner’s password.
- Added clear messages for invalid email, connection problems and too many attempts.
- Reset instructions remind users to check their junk/spam folder.
- No Firestore rules change is required for this patch.

## V1.2.0 — Training Paths, Trophy Cabinet & Treasure Chest

### Training course
- Rebuilt the course around 8 **Key Skills** rather than one video per module.
- Every Key Skill now contains **5–9 short lessons**.
- Learners can mark each lesson as **Watched, Practised, Confident or Need Help**.
- A lesson counts towards assessment readiness once it is **Practised** or **Confident**.
- The assessment button stays locked until every lesson in that Key Skill is complete.
- Captain/Admin can add a separate YouTube URL for every lesson from the Admin screen.
- Existing V1/V1.1 first-module video links are used as a fallback for lesson 1 where possible.

### Trophy Cabinet
- Added a full Trophy Cabinet showing future awards from day one.
- Locked trophies are shown in shadow with **???** until revealed.
- Each trophy has its own visual motif linked to the achievement.
- Trainer-passed Key Skills award a skill trophy.
- New trophies are created as **unopened** until the learner accepts them.

### Trophy celebrations
- New trophy pop-up appears when an unopened trophy is waiting.
- Learner presses **Accept Trophy** to reveal it.
- Acceptance triggers party-popper/confetti animation and a short celebration chime.
- Celebration sound can be switched off in My Dog settings.

### Automatic milestone trophies
- **First Steps Aboard** — first Academy login.
- **Seven Days Aboard** — 7-day consecutive login streak.
- **Sea Legs Streak** — 14-day consecutive login streak.
- **Month on Deck** — 30-day consecutive login streak.
- **First Lesson Logged** — first lesson practised.
- **Brave Enough to Be Judged** — first assessment submitted.
- **First Skill Mastered** — first trainer-verified skill passed.
- **Birthday Buccaneer** — awarded on the dog’s birthday each year.

### Dog profiles
- Added dog date of birth.
- Owners can mark the date as an estimate — a best guess is fine.
- Date of birth is used for birthday celebrations.

### Treasure Chest
- Added **Menai Muttineers Treasure Chest** merch teaser.
- Coming-soon items include mugs, pens, bandanas, real trophies, stickers, magnets, keyrings and clothing.
- Learners can register which products they are interested in.
- Captain/Admin dashboard shows how many learners have registered merch interest.

### Captain/Admin
- Added **Manage Crew & Staff** inside the app.
- Captain/Admin can change a registered account between Learner, Trainer and Admin without using Firebase manually.
- Admin course controls now provide a separate YouTube field for every lesson.
- Learner list now shows login streak and dog date of birth when available.

### Existing V1 features retained
- Shared Android APK and web app.
- Firebase shared data.
- Manual payment approval and access codes.
- Learner, Trainer and Captain/Admin roles.
- Video assessments and trainer feedback.
- Ask a Trainer.
- 1-to-1 requests and bookings.
- Training diary.
- Captain notices.
- Weekly Google Meet link.
- Menai Muttineers branded app/web icons.

### Required Firebase change
V1.2 adds lesson progress, automatic trophies, trophy acceptance, login streaks and merch-interest records. The updated `firestore.rules` file **must be published in Firebase** before learners use V1.2.
