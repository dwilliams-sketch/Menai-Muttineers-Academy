# Menai Muttineers Pre-Flyball Academy — Universal V1

One shared Academy system for:

- Android APK users
- Web browser users
- Trainers
- Captain/Admin

Both the APK and the web app use the same Firebase Authentication and Firestore database. A change made on one device is visible on the other.

## Learner V1

- Self-registration for handler and dog
- Manual payment gate
- Six-character access code after payment
- Eight self-paced Pre-Flyball modules
- YouTube lessons embedded in the course
- Exercise guidance
- Video-link submission for trainer review
- Pass / Keep Practising feedback
- Trainer-approved digital trophies
- Trophy Cabinet
- Ready to Join the Crew completion achievement
- Training diary
- Ask a Trainer
- Weekly Google Meet button
- Captain notices
- Editable dog profile
- 1-to-1 trainer request
- Accept a proposed 1-to-1 time
- Join a booked online 1-to-1 from its Meet link
- See trainer homework after the session

## Trainer V1

- Overview dashboard
- Review submitted videos
- Pass a skill and award a trophy
- Send Keep Practising feedback
- Answer learner questions
- See all learners and dogs
- See inactive learners (14+ days)
- See common question/training topics
- See and manage 1-to-1 requests
- Assign trainer
- Propose date/time
- Add Google Meet link
- Record session notes and homework
- Mark a 1-to-1 completed

## Captain/Admin V1

Everything a trainer can do, plus:

- Mark learner Paid / Unpaid
- Complimentary access
- Generate/regenerate access code
- Lock course access
- Update weekly Google Meet details
- Update each course YouTube URL without rebuilding the app
- Publish/remove Captain notices
- See payment, video, question and 1-to-1 counts

## Build outputs

GitHub Actions creates two outputs from the SAME Flutter code:

1. `Menai-Muttineers-Academy-V1-APK` — installable Android APK
2. `Menai-Muttineers-Academy-V1-Web` — web build backup

It also publishes the web build through GitHub Pages once Pages is enabled for the repository.

Read `SETUP_GUIDE.md` before the first build.
