# Menai Muttineers Academy V1.3 — Test Checklist

## A. Upgrade / build
- [ ] V1.3 files uploaded to existing GitHub repository root.
- [ ] `.github/workflows/build-apps.yml` updated to the V1.3 version.
- [ ] V1.3 `firestore.rules` published in Firebase.
- [ ] Latest GitHub Action gets a green tick.
- [ ] V1.3 APK installs/updates on Android.
- [ ] Existing GitHub Pages web link opens V1.3.
- [ ] Existing Captain account still signs in with Captain role.

## B. New-account journey
- [ ] Landing page clearly shows large CREATE MY ACCOUNT button.
- [ ] Landing page clearly shows separate EXISTING USER — SIGN IN button.
- [ ] Registration uses three clear steps.
- [ ] Learner remains signed in after creating account.
- [ ] Forgot Password opens and sends reset email without Flutter red screen.
- [ ] New learner sees waiting/payment information without needing to log in again.

## C. Dynamic Academy settings
- [ ] Captain changes per-dog price and learner screens update without rebuild.
- [ ] Captain changes voyage days and learner screens update without rebuild.
- [ ] Captain changes 1-to-1 wording/guide price/duration and learner screen updates.
- [ ] Captain changes payment suffix from 007 for testing and reference updates.
- [ ] Captain can change account-closure wording.

## D. Bank/payment/credit
- [ ] Admin enters bank details and payment instructions in Control Room.
- [ ] Learner sees current bank details.
- [ ] Learner sees generated DOGNAME-INITIALS-SUFFIX reference.
- [ ] Learner presses I'VE MADE A PAYMENT and Admin sees it.
- [ ] Admin confirms payment; first dog gets access and remaining amount becomes credit.
- [ ] Ledger shows credit/debit history.
- [ ] App does not ask for card/bank login details or process payment itself.

## E. Multiple dogs / access
- [ ] Learner adds a second dog.
- [ ] Dog switcher changes the whole training/trophy context.
- [ ] Both dogs can be independently active.
- [ ] Each dog has its own access date.
- [ ] Pause one dog; other dog remains active.
- [ ] Paused dog cannot use lessons/assessments/trophies.
- [ ] Paused dog can press RESTART ADVENTURE.
- [ ] Paused dog can press REQUEST A 1-to-1.
- [ ] History/trophies remain stored while paused.
- [ ] Restart does not affect the other dog.

## F. Course / lesson help
- [ ] Each Key Skill opens its own 5–9 lessons.
- [ ] YouTube lesson links open/play where configured.
- [ ] Learner can mark lesson Watched / Practised / Confident / Need Help.
- [ ] Need Help asks for a comment and optional video link.
- [ ] Trainer Action Centre receives exact dog/skill/lesson context.
- [ ] Trainer can claim thread.
- [ ] Trainer can use a saved reply.
- [ ] Trainer reply creates learner notification.
- [ ] Learner can reply again.
- [ ] Trainer can set a 7-day follow-up and later resolve the thread.
- [ ] Trainer can Recommend Skill from Dog Snapshot.

## G. Assessment / Trophy Cabin
- [ ] Assessment is locked until required lesson progress is complete.
- [ ] Learner submits assessment video link.
- [ ] Trainer can claim it.
- [ ] PASS awards correct trophy; Keep Practising sends feedback without trophy.
- [ ] New trophy remains unopened until learner accepts.
- [ ] Trophy reveal shows confetti/sound when enabled.
- [ ] Captain's Trophy Cabin shows locked `???` trophies and full-colour earned trophies.
- [ ] Birthday trophy works with dog DOB.

## H. Flyball Start Lights game
- [ ] Open More/Games & Practice → Start Lights.
- [ ] GO starts after a small random delay.
- [ ] Top red lights first.
- [ ] Middle red lights 1 second later.
- [ ] Lower red lights 1 second later.
- [ ] Green lights 1 second later.
- [ ] STOP before green produces a negative time.
- [ ] STOP after green produces a positive time.
- [ ] Result is stored to thousandths internally and displayed to two decimal places.
- [ ] Tiny early result can display `-0.00` and plays Aww sound.
- [ ] +0.000 to +0.004 gives rolling-start celebration.
- [ ] Attempts/rolling/early/best/average update.
- [ ] First practice awards Lantern Lubber.
- [ ] First rolling start awards Rolling Roger.
- [ ] 3 rolling starts in a row awards Triple Broadside.
- [ ] 10 / 25 / 50 / 100 rolling totals award their trophies.
- [ ] Hidden Too Keen, Captain! can trigger after repeated tiny early starts.

## I. Training timer
- [ ] Timer offers short preset sessions.
- [ ] Parrot Squawk works.
- [ ] Ship Bell works.
- [ ] Tiny Cannon works.
- [ ] Silent option works.
- [ ] End of timer offers training-diary save.

## J. Crew / Kudos
- [ ] Learner can opt in/out of Crew discoverability.
- [ ] Other learner sees only intended public Crew details.
- [ ] Friend request can be sent/accepted/declined.
- [ ] Shared positive achievement appears in Crew feed when permitted.
- [ ] Preset Kudos can be sent.
- [ ] Receiving Kudos creates notification.
- [ ] Training struggles/Need Help are NOT shown in public Crew feed.

## K. Links / Treasure Chest / appearance
- [ ] Social links work where configured.
- [ ] Easyfundraising / GoFundMe links work.
- [ ] Bank-payment page uses live Admin details.
- [ ] Treasure Chest records merchandise interest.
- [ ] Pirate backgrounds can be ON/OFF.
- [ ] Rotate background changes between app sessions; fixed favourite stays fixed.
- [ ] Reduced motion works.
- [ ] Background music defaults OFF.
- [ ] Music can be enabled, volume changed and track skipped.
- [ ] Gentle Tide I/II alternate.
- [ ] Admin-added public MP3 track appears without APK rebuild.

## L. 1-to-1
- [ ] Active dog can request 1-to-1.
- [ ] Paused dog can request 1-to-1.
- [ ] Trainer sees request and learner notes/video.
- [ ] Trainer can quote price/duration independently of Academy price.
- [ ] Learner is notified of proposal/update.
- [ ] Trainer can add follow-up/homework and mark completed.

## M. Staff / Captain tools
- [ ] Trainer cannot change account credit/bank settings.
- [ ] Admin/Captain can manage roles and account settings.
- [ ] Preview as Learner does not alter staff role or real learner data.
- [ ] Action Centre shows assessments/help/1-to-1/accounts/follow-ups.
- [ ] Dog Snapshot gives useful current context.
- [ ] Private staff notes are hidden from learner.
- [ ] Captain Log works.
- [ ] Audit Log records important staff actions.
- [ ] System Health displays V1.3.

## N. Quarterly report
- [ ] Select quarter/year.
- [ ] Active/paused dog totals make sense.
- [ ] Assessment/pass rate makes sense.
- [ ] Per-skill assessment performance appears.
- [ ] Help-demand topics appear.
- [ ] Training logs/trophies/graduates/1-to-1/Kudos/Start Lights totals appear.
- [ ] Privacy-safe social summary contains aggregate data, not learner private information.

## O. Account closure
- [ ] Learner sees Set Sail on a New Adventure.
- [ ] Confirmation encourages Pause instead if they only need a break.
- [ ] Request reaches Admin/Captain.
- [ ] Admin gets a second permanent-delete warning.
- [ ] Until Functions are deployed, full deletion is treated as backend-not-ready rather than pretending it succeeded.
- [ ] After Functions deploy, approved deletion removes Auth/profile/dogs/training/support/social/photo data.
- [ ] Necessary Academy accounting history is anonymised.

## P. Optional Firebase backend
- [ ] Storage rules published and photo feature switch enabled only after Storage exists.
- [ ] Member image uploads compressed photo.
- [ ] Dog image uploads compressed photo.
- [ ] Firebase Functions deploy successfully.
- [ ] Android accepts notification permission.
- [ ] Trainer reply produces push while app is closed.
- [ ] Daily backend processes expired active dog correctly.
- [ ] Pause request completes at voyage end.
- [ ] Birthday/celebration can be created by backend without opening app.

## Q. English / Welsh
- [ ] EN | CY toggle is easy to find on sign-in and the main learner/staff header.
- [ ] Switching to CY changes the interface immediately without sign-out/restart.
- [ ] Language choice remains after closing/reopening the app.
- [ ] Signed-in language choice is saved to the user profile and follows the account.
- [ ] Registration, payments/access, dog switching, Training, Trophy Cabin, Crew, Games, Settings and staff controls have usable Welsh labels.
- [ ] Welsh date picker / standard Material controls use Welsh localisation where supported.
- [ ] Captain writes an English notice and presses Translate to Welsh.
- [ ] Auto-translated Welsh can be edited before publishing.
- [ ] Notice editor warns that auto-translated wording should be reviewed.
- [ ] English and Welsh previews show the exact authored wording.
- [ ] English learner receives/sees English notice; Welsh learner receives/sees Welsh notice.
- [ ] Learner question text remains exactly as typed when the language toggle changes.
- [ ] Trainer reply text remains exactly as typed when the language toggle changes.
- [ ] Birthday and built-in celebration notices respect the saved language.

## R. Final smoke test
- [ ] Two built-in Gentle Tide tracks are present and alternate when music is enabled.
- [ ] Admin can add/disable/remove a public MP3 URL without rebuilding.
- [ ] Start Lights still works after language switching.
- [ ] Paused dog still has Request a 1-to-1 and Restart Adventure only for protected Academy features.
- [ ] Account price, period, 1-to-1 wording and bank details can all be changed by Admin without a code rebuild.
- [ ] Set Sail on a New Adventure request reaches Admin/Captain.

