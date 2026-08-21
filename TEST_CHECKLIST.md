# Menai Muttineers Academy V1.2.1 — Test Checklist

Use one pretend learner and dog before inviting the real course.

## Build / update
- [ ] Upload V1.2 files to GitHub.
- [ ] Publish the V1.2 `firestore.rules` in Firebase.
- [ ] GitHub Actions build ends with a green tick.
- [ ] New V1.2 APK installs/updates on Android.
- [ ] GitHub Pages web app opens.
- [ ] APK and web app show the same account data.

## Captain/Admin
- [ ] Captain account still opens Captain/Admin view.
- [ ] Admin → Manage Crew & Staff can change another account to Trainer.
- [ ] Admin can change it back to Learner.
- [ ] Captain can paste/save lesson YouTube URLs for several Key Skills.
- [ ] Captain can update the weekly Google Meet information.
- [ ] Captain can publish a notice.


## Password reset
- [ ] Sign-out screen shows **Forgot password?**.
- [ ] Reset dialog accepts the learner’s email address.
- [ ] Firebase password-reset email arrives.
- [ ] Reset link allows a new password to be chosen.
- [ ] New password signs into both APK and web app.
- [ ] Existing trophies, lesson progress and account role remain unchanged after resetting the password.

## Learner registration / access
- [ ] Create a new learner and dog.
- [ ] Add a dog date of birth or estimated date.
- [ ] New account shows Awaiting Payment.
- [ ] Captain marks learner paid and receives a 6-character code.
- [ ] Learner enters code and course unlocks.

## Training structure
- [ ] Key Skills list opens.
- [ ] A Key Skill shows all its 5–9 lessons.
- [ ] YouTube lesson plays on Android.
- [ ] YouTube lesson plays on web.
- [ ] Learner can select Watched.
- [ ] Learner can select Practised.
- [ ] Learner can select Confident.
- [ ] Learner can select Need Help.
- [ ] Assessment remains locked until every lesson is Practised/Confident.
- [ ] Assessment unlocks when all required lessons are complete.

## Assessment / trophies
- [ ] Learner submits an assessment video link.
- [ ] Trainer sees assessment in Reviews.
- [ ] Trainer can choose Keep Practising and send feedback.
- [ ] Learner can resubmit after practising.
- [ ] Trainer can choose Pass + Trophy.
- [ ] Learner sees a Trophy Unlocked pop-up.
- [ ] Pressing Accept Trophy plays celebration sound.
- [ ] Confetti/party poppers display.
- [ ] Trophy becomes full colour in Trophy Cabinet.
- [ ] Locked trophies remain shadowed with ???.
- [ ] Celebration sound can be switched off in My Dog.

## Automatic trophies
- [ ] First learner login awards First Steps Aboard.
- [ ] First lesson practised awards First Lesson Logged.
- [ ] First assessment awards Brave Enough to Be Judged.
- [ ] First trainer-passed skill awards First Skill Mastered.
- [ ] Login streak is visible to learner/admin.
- [ ] Birthday field can be edited later.

Note: 7, 14 and 30-day streak trophies are best checked over real days rather than manually changing Firebase data.

## Treasure Chest
- [ ] Treasure Chest opens.
- [ ] Coming-soon merch cards are visible.
- [ ] Learner can select products and Register My Interest.
- [ ] Captain dashboard Merch interest count increases.

## Existing features
- [ ] Ask a Trainer works.
- [ ] Trainer reply appears to learner.
- [ ] 1-to-1 request works.
- [ ] Trainer proposes time / Meet link.
- [ ] Learner accepts booking.
- [ ] Training diary saves entries.
- [ ] Captain notice appears to learner.

## V1.2.2 password reset regression test
- [ ] Tap Forgot password? and confirm the dialog opens without a red Flutter error screen.
- [ ] Enter an account email and tap Send reset link.
- [ ] Confirm the dialog closes cleanly.
- [ ] Confirm a reset email is received (also check junk/spam).
- [ ] Reset the password and sign in with the new password.
