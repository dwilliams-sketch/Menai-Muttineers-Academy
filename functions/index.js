const admin = require('firebase-admin');
const {setGlobalOptions} = require('firebase-functions/v2');
const {onDocumentCreated} = require('firebase-functions/v2/firestore');
const {onSchedule} = require('firebase-functions/v2/scheduler');
const {onCall, HttpsError} = require('firebase-functions/v2/https');
const {TranslationServiceClient} = require('@google-cloud/translate').v3;

admin.initializeApp();
setGlobalOptions({region: 'europe-west2', maxInstances: 10});

const db = admin.firestore();
const bucket = admin.storage().bucket();
const FieldValue = admin.firestore.FieldValue;
const Timestamp = admin.firestore.Timestamp;
const translationClient = new TranslationServiceClient();

function dayKey(date) {
  const y = date.getUTCFullYear();
  const m = String(date.getUTCMonth() + 1).padStart(2, '0');
  const d = String(date.getUTCDate()).padStart(2, '0');
  return `${y}-${m}-${d}`;
}

function londonParts(date = new Date()) {
  const formatter = new Intl.DateTimeFormat('en-GB', {
    timeZone: 'Europe/London', year: 'numeric', month: '2-digit', day: '2-digit', weekday: 'short',
  });
  const parts = Object.fromEntries(formatter.formatToParts(date).filter(p => p.type !== 'literal').map(p => [p.type, p.value]));
  return {year: Number(parts.year), month: Number(parts.month), day: Number(parts.day), weekday: parts.weekday};
}

function calendarDate(year, month, day) {
  return new Date(Date.UTC(year, month - 1, day, 12, 0, 0));
}

function sameDay(a, b) {
  return a.getUTCFullYear() === b.getUTCFullYear() && a.getUTCMonth() === b.getUTCMonth() && a.getUTCDate() === b.getUTCDate();
}

function easterSunday(year) {
  const a = year % 19;
  const b = Math.floor(year / 100);
  const c = year % 100;
  const d = Math.floor(b / 4);
  const e = b % 4;
  const f = Math.floor((b + 8) / 25);
  const g = Math.floor((b - f + 1) / 3);
  const h = (19 * a + b - d - g + 15) % 30;
  const i = Math.floor(c / 4);
  const k = c % 4;
  const l = (32 + 2 * e + 2 * i - h - k) % 7;
  const m = Math.floor((a + 11 * h + 22 * l) / 451);
  const month = Math.floor((h + l - 7 * m + 114) / 31);
  const day = ((h + l - 7 * m + 114) % 31) + 1;
  return calendarDate(year, month, day);
}

function nthMonday(year, month, n) {
  let d = calendarDate(year, month, 1);
  while (d.getUTCDay() !== 1) d = new Date(d.getTime() + 86400000);
  return new Date(d.getTime() + (n - 1) * 7 * 86400000);
}

function lastMonday(year, month) {
  let d = calendarDate(year, month + 1, 0);
  while (d.getUTCDay() !== 1) d = new Date(d.getTime() - 86400000);
  return d;
}

function nextMonday(date) {
  const d = new Date(date.getTime());
  while (d.getUTCDay() !== 1) d.setUTCDate(d.getUTCDate() + 1);
  return d;
}

function christmasObserved(year) {
  const d = calendarDate(year, 12, 25);
  if (d.getUTCDay() === 6) return calendarDate(year, 12, 27); // Saturday -> Monday
  if (d.getUTCDay() === 0) return calendarDate(year, 12, 27); // Sunday -> Tuesday 27th
  return d;
}

function boxingObserved(year) {
  const d = calendarDate(year, 12, 26);
  if (d.getUTCDay() === 6) return calendarDate(year, 12, 28);
  if (d.getUTCDay() === 0) return calendarDate(year, 12, 28);
  return d;
}

function newYearObserved(year) {
  const d = calendarDate(year, 1, 1);
  if (d.getUTCDay() === 6 || d.getUTCDay() === 0) return nextMonday(d);
  return d;
}

function builtInCelebrations(year, month, day) {
  const today = calendarDate(year, month, day);
  const items = [];
  const add = (id, titleEn, bodyEn, titleCy, bodyCy) => items.push({id, titleEn, bodyEn, titleCy, bodyCy});

  if (month === 1 && day === 1) add('new_year', '🎆 Happy New Year!', 'A fresh year, a fresh voyage and plenty of good training ahead.', '🎆 Blwyddyn Newydd Dda!', 'Blwyddyn newydd, mordaith newydd a digon o hyfforddiant da o’n blaenau.');
  if (month === 3 && day === 1) add('st_davids', '🐉 Happy St David’s Day!', 'Dydd Gŵyl Dewi Hapus from the Menai Muttineers crew.', '🐉 Dydd Gŵyl Dewi Hapus!', 'Dymuniadau gorau ar Ddydd Gŵyl Dewi gan griw Menai Muttineers.');
  if (month === 4 && day === 11) add('pet_day', '🐾 National Pet Day', 'Give your four-legged shipmate an extra bit of fuss today.', '🐾 Diwrnod Cenedlaethol Anifeiliaid Anwes', 'Rhowch ychydig bach o sylw ychwanegol i’ch cyd-longwr pedair coes heddiw.');
  if (month === 8 && day === 16) add('rum_day', '🏴‍☠️ National Rum Day', 'A suitably pirate-themed day. The dogs are on water, mind!', '🏴‍☠️ Diwrnod Cenedlaethol Rym', 'Diwrnod addas iawn i fôr-ladron. Dŵr i’r cŵn, cofiwch!');
  if (month === 8 && day === 26) add('dog_day', '🐕 National Dog Day', 'Today is all about the dogs — as if every Academy day wasn’t already!', '🐕 Diwrnod Cenedlaethol y Ci', 'Mae heddiw i gyd am y cŵn — fel pe na bai pob diwrnod yn yr Academi eisoes!');
  if (month === 9 && day === 19) add('pirate_day', '🏴‍☠️ Talk Like a Pirate Day', 'Arrr! Today the Academy officially permits excessive pirate nonsense.', '🏴‍☠️ Diwrnod Siarad Fel Môr-leidr', 'Arrr! Heddiw mae’r Academi yn caniatáu digonedd o lol môr-ladron.');
  if (month === 10 && day === 4) add('animal_day', '🐾 World Animal Day', 'A good day to celebrate every animal that makes life better.', '🐾 Diwrnod Anifeiliaid y Byd', 'Diwrnod da i ddathlu pob anifail sy’n gwneud bywyd yn well.');
  if (month === 12 && day === 25) add('christmas', '🎄 Merry Christmas!', 'Merry Christmas from the whole Menai Muttineers crew.', '🎄 Nadolig Llawen!', 'Nadolig Llawen gan holl griw Menai Muttineers.');
  if (month === 12 && day === 26) add('boxing_day', '🎁 Boxing Day', 'A day for leftovers, muddy walks and perhaps a very short training game.', '🎁 Gŵyl San Steffan', 'Diwrnod ar gyfer bwyd dros ben, teithiau cerdded mwdlyd ac efallai gêm hyfforddi fer iawn.');

  const easter = easterSunday(year);
  const goodFriday = new Date(easter.getTime() - 2 * 86400000);
  const easterMonday = new Date(easter.getTime() + 86400000);
  if (sameDay(today, goodFriday)) add(`good_friday_${year}`, '⚓ Good Friday', 'Wishing the crew a peaceful bank holiday weekend.', '⚓ Dydd Gwener y Groglith', 'Dymunwn benwythnos gŵyl banc heddychlon i’r criw.');
  if (sameDay(today, easterMonday)) add(`easter_monday_${year}`, '🌷 Easter Monday', 'A bank holiday Monday — a handy day for a little dog training adventure.', '🌷 Dydd Llun y Pasg', 'Dydd Llun gŵyl banc — diwrnod da am antur hyfforddi fach gyda’r ci.');
  if (sameDay(today, nthMonday(year, 5, 1))) add(`early_may_${year}`, '🌿 Early May Bank Holiday', 'A bank holiday voyage — enjoy the extra day with your dog.', '🌿 Gŵyl Banc Gynnar mis Mai', 'Mordaith gŵyl banc — mwynhewch y diwrnod ychwanegol gyda’ch ci.');
  if (sameDay(today, lastMonday(year, 5))) add(`spring_bank_${year}`, '☀️ Spring Bank Holiday', 'Enjoy the bank holiday, crew. Keep any training short and fun.', '☀️ Gŵyl Banc y Gwanwyn', 'Mwynhewch y gŵyl banc, griw. Cadwch unrhyw hyfforddiant yn fyr ac yn hwyl.');
  if (sameDay(today, lastMonday(year, 8))) add(`summer_bank_${year}`, '🏖️ Summer Bank Holiday', 'A summer bank holiday from the Academy crew.', '🏖️ Gŵyl Banc yr Haf', 'Gŵyl banc yr haf gan griw yr Academi.');

  // Substitute bank holidays when fixed dates fall on weekends.
  const nyObs = newYearObserved(year);
  if (sameDay(today, nyObs) && !(month === 1 && day === 1)) add(`new_year_bank_${year}`, '🎆 New Year Bank Holiday', 'Enjoy the New Year bank holiday with your dog.', '🎆 Gŵyl Banc y Flwyddyn Newydd', 'Mwynhewch ŵyl banc y Flwyddyn Newydd gyda’ch ci.');
  const xObs = christmasObserved(year);
  if (sameDay(today, xObs) && !(month === 12 && day === 25)) add(`christmas_bank_${year}`, '🎄 Christmas Bank Holiday', 'An extra Christmas bank holiday day for the crew.', '🎄 Gŵyl Banc y Nadolig', 'Diwrnod gŵyl banc Nadolig ychwanegol i’r criw.');
  const bObs = boxingObserved(year);
  if (sameDay(today, bObs) && !(month === 12 && day === 26)) add(`boxing_bank_${year}`, '🎁 Boxing Day Bank Holiday', 'Enjoy the Boxing Day bank holiday, crew.', '🎁 Gŵyl Banc San Steffan', 'Mwynhewch ŵyl banc San Steffan, griw.');
  return items;
}

async function createNotification(uid, title, body, type, targetId = '', stableId = null) {
  const ref = stableId ? db.collection('notifications').doc(stableId) : db.collection('notifications').doc();
  if (stableId && (await ref.get()).exists) return;
  await ref.set({userId: uid, title, body, type, targetId, read: false, createdAt: FieldValue.serverTimestamp()});
}

exports.pushAcademyNotification = onDocumentCreated('notifications/{notificationId}', async (event) => {
  const data = event.data?.data();
  if (!data || !data.userId) return;
  const user = await db.collection('users').doc(data.userId).get();
  if (!user.exists || user.data()?.pushEnabled === false) return;
  const devices = await user.ref.collection('devices').get();
  const tokens = devices.docs.map(d => d.data().token).filter(Boolean);
  if (!tokens.length) return;

  const result = await admin.messaging().sendEachForMulticast({
    tokens: tokens.slice(0, 500),
    notification: {title: String(data.title || 'Menai Muttineers Academy'), body: String(data.body || '')},
    data: {type: String(data.type || 'general'), targetId: String(data.targetId || '')},
    android: {notification: {sound: 'default'}},
  });

  const cleanup = [];
  result.responses.forEach((r, i) => {
    if (!r.success && ['messaging/registration-token-not-registered', 'messaging/invalid-registration-token'].includes(r.error?.code)) {
      const doc = devices.docs.find(d => d.data().token === tokens[i]);
      if (doc) cleanup.push(doc.ref.delete());
    }
  });
  await Promise.all(cleanup);
});

exports.dailyAcademyMaintenance = onSchedule({schedule: '0 9 * * *', timeZone: 'Europe/London'}, async () => {
  const settings = await db.collection('settings').doc('academy').get();
  const config = settings.data() || {};
  const cost = Number(config.dogPeriodCost ?? 5);
  const days = Math.max(1, Number(config.dogPeriodDays ?? 30));
  const now = new Date();

  // Per-dog pause / renewal processing.
  const activeDogs = await db.collection('dogs').where('academyStatus', '==', 'active').get();
  for (const dogDoc of activeDogs.docs) {
    const dog = dogDoc.data();
    const until = dog.accessUntil?.toDate?.();
    if (!until || until > now) continue;
    if (dog.pauseRequested === true) {
      await dogDoc.ref.update({academyStatus: 'paused', pauseRequested: false, pausedAt: FieldValue.serverTimestamp()});
      await createNotification(dog.ownerId, '⚓ Adventure paused', `${dog.name || 'Your dog'} is now anchored. All progress is safely stored.`, 'account', dogDoc.id, `auto_pause_${dogDoc.id}_${dayKey(now)}`);
      continue;
    }

    const userRef = db.collection('users').doc(dog.ownerId);
    let renewed = false;
    await db.runTransaction(async tx => {
      const user = await tx.get(userRef);
      if (!user.exists) return;
      const balance = Number(user.data().academyCredit || 0);
      if (balance + 0.0001 < cost) {
        tx.update(dogDoc.ref, {academyStatus: 'renewal_due'});
        return;
      }
      tx.update(userRef, {academyCredit: balance - cost});
      tx.update(dogDoc.ref, {
        academyStatus: 'active', pauseRequested: false,
        accessUntil: Timestamp.fromDate(new Date(now.getTime() + days * 86400000)),
      });
      tx.set(userRef.collection('ledger').doc(), {
        type: 'debit', amount: -cost, dogId: dogDoc.id,
        description: `${dog.name || 'Dog'} — ${days} days Academy access`, actor: 'automatic renewal',
        createdAt: FieldValue.serverTimestamp(),
      });
      renewed = true;
    });
    if (renewed) {
      await createNotification(dog.ownerId, '🏴‍☠️ Adventure renewed', `${dog.name || 'Your dog'} has another ${days} days aboard the Academy.`, 'account', dogDoc.id, `auto_renew_${dogDoc.id}_${dayKey(now)}`);
    } else {
      await createNotification(dog.ownerId, '💰 Academy credit needed', `${dog.name || 'Your dog'} needs more Academy credit before the next voyage can begin.`, 'account', dogDoc.id, `auto_low_credit_${dogDoc.id}_${dayKey(now)}`);
    }
  }

  const today = londonParts(now);
  const todayKey = `${today.year}-${String(today.month).padStart(2, '0')}-${String(today.day).padStart(2, '0')}`;
  const celebrations = builtInCelebrations(today.year, today.month, today.day);
  const customSnap = await db.collection('calendarEvents').where('enabled', '==', true).get().catch(() => null);
  const custom = (customSnap?.docs || []).filter(d => Number(d.data().month) === today.month && Number(d.data().day) === today.day)
    .map(d => ({id: `custom_${d.id}`, titleEn: String(d.data().titleEn || d.data().title || 'Academy Day'), bodyEn: String(d.data().messageEn || d.data().message || ''), titleCy: String(d.data().titleCy || d.data().title || 'Academy Day'), bodyCy: String(d.data().messageCy || d.data().message || '')}));

  const learners = await db.collection('users').where('role', '==', 'learner').get();
  const learnerLanguages = new Map(learners.docs.map(d => [d.id, String(d.data().languageCode || 'en')]));
  for (const learner of learners.docs) {
    const cy = learnerLanguages.get(learner.id) === 'cy';
    for (const item of [...celebrations, ...custom]) {
      const title = cy ? String(item.titleCy || item.title || item.titleEn || 'Diwrnod yr Academi') : String(item.titleEn || item.title || 'Academy Day');
      const body = cy ? String(item.bodyCy || item.body || item.bodyEn || '') : String(item.bodyEn || item.body || '');
      await createNotification(learner.id, title, body, 'celebration', '', `auto_${learner.id}_${todayKey}_${item.id}`);
    }
  }

  // Dog birthdays + Birthday Buccaneer trophy, even if the learner does not open the app that day.
  const dogs = await db.collection('dogs').get();
  for (const dogDoc of dogs.docs) {
    const dog = dogDoc.data();
    const dob = String(dog.dateOfBirth || '');
    const match = /^\d{4}-(\d{2})-(\d{2})/.exec(dob);
    if (!match || Number(match[1]) !== today.month || Number(match[2]) !== today.day) continue;
    const eligibleForTrophy = String(dog.academyStatus || '') === 'active';
    const cy = learnerLanguages.get(dog.ownerId) === 'cy';
    const dogName = String(dog.name || (cy ? 'ffrind' : 'matey'));
    await createNotification(
      dog.ownerId,
      cy ? `🎂 Pen-blwydd Hapus, ${dogName}!` : `🎂 Happy Birthday, ${dogName}!`,
      eligibleForTrophy
        ? (cy ? `Mae criw yr Academi yn dymuno pen-blwydd hapus iawn i ${dogName}. Mae tlws Birthday Buccaneer yn aros hefyd!` : `The Academy crew wishes ${dogName} a very happy birthday. A Birthday Buccaneer trophy is waiting too!`)
        : (cy ? `Mae criw yr Academi yn dymuno pen-blwydd hapus iawn i ${dogName}. Mae’r antur wedi’i hangori ar hyn o bryd, felly ni ddyfernir tlws swyddogol tra bo mynediad wedi’i oedi.` : `The Academy crew wishes ${dogName} a very happy birthday. Their Academy adventure is currently anchored, so no official trophy is awarded while access is paused.`),
      'birthday', dogDoc.id, `birthday_${dog.ownerId}_${dogDoc.id}_${today.year}`,
    );
    if (eligibleForTrophy) {
      const trophyRef = dogDoc.ref.collection('trophies').doc(`birthday_${today.year}`);
      if (!(await trophyRef.get()).exists) {
        await trophyRef.set({
          dogId: dogDoc.id, title: 'Birthday Buccaneer', description: `A special Academy birthday trophy for ${dog.name || 'this dog'}.`,
          reviewerName: 'Menai Muttineers Academy', type: 'special', artKey: 'birthday', automatic: true,
          accepted: false, awardedAt: FieldValue.serverTimestamp(), acceptedAt: null,
        });
      }
    }
  }
});

async function deleteQuery(query, recursive = false) {
  const snap = await query.get();
  for (const doc of snap.docs) {
    if (recursive) await db.recursiveDelete(doc.ref);
    else await doc.ref.delete();
  }
}

exports.deleteAcademyAccount = onCall(async (request) => {
  if (!request.auth) throw new HttpsError('unauthenticated', 'Sign in first.');
  const caller = await db.collection('users').doc(request.auth.uid).get();
  const role = String(caller.data()?.role || '');
  if (!['admin', 'captain'].includes(role)) throw new HttpsError('permission-denied', 'Admin/Captain access required.');
  const targetUid = String(request.data?.targetUid || '');
  if (!targetUid) throw new HttpsError('invalid-argument', 'targetUid is required.');
  if (targetUid === request.auth.uid) throw new HttpsError('failed-precondition', 'Use another Captain/Admin to remove a staff account.');

  const targetRef = db.collection('users').doc(targetUid);
  const target = await targetRef.get();
  if (!target.exists) throw new HttpsError('not-found', 'Academy profile not found.');

  // Keep only anonymised money totals where a legitimate accounting record may be needed.
  const ledger = await targetRef.collection('ledger').get();
  if (!ledger.empty) {
    const entries = ledger.docs.map(d => ({
      type: String(d.data().type || ''), amount: Number(d.data().amount || 0),
      createdAt: d.data().createdAt || null,
    }));
    await db.collection('anonymizedAccounting').add({entries, deletedAt: FieldValue.serverTimestamp()});
  }

  const dogDocs = (await db.collection('dogs').where('ownerId', '==', targetUid).get()).docs;
  const dogIds = dogDocs.map(d => d.id);

  const simpleQueries = [
    db.collection('submissions').where('userId', '==', targetUid),
    db.collection('trainingLogs').where('userId', '==', targetUid),
    db.collection('oneToOneRequests').where('userId', '==', targetUid),
    db.collection('notifications').where('userId', '==', targetUid),
    db.collection('paymentRequests').where('userId', '==', targetUid),
    db.collection('restartRequests').where('userId', '==', targetUid),
    db.collection('feedback').where('userId', '==', targetUid),
    db.collection('crewAchievements').where('userId', '==', targetUid),
    db.collection('lightAttempts').where('userId', '==', targetUid),
    db.collection('staffTasks').where('learnerUid', '==', targetUid),
  ];
  for (const q of simpleQueries) await deleteQuery(q);
  await deleteQuery(db.collection('lessonHelp').where('userId', '==', targetUid), true);
  await deleteQuery(db.collection('questions').where('userId', '==', targetUid));
  await deleteQuery(db.collection('crewRequests').where('fromUid', '==', targetUid));
  await deleteQuery(db.collection('crewRequests').where('toUid', '==', targetUid));
  await deleteQuery(db.collection('crewLinks').where('members', 'array-contains', targetUid));
  await deleteQuery(db.collection('kudos').where('fromUid', '==', targetUid));
  await deleteQuery(db.collection('kudos').where('toUid', '==', targetUid));

  await db.collection('merchInterest').doc(targetUid).delete().catch(() => null);
  await db.collection('crewProfiles').doc(targetUid).delete().catch(() => null);
  await db.collection('lightStats').doc(targetUid).delete().catch(() => null);
  await db.collection('accountDeletionRequests').doc(targetUid).delete().catch(() => null);

  for (const dogDoc of dogDocs) {
    await deleteQuery(db.collection('staffNotes').where('dogId', '==', dogDoc.id));
    await db.recursiveDelete(dogDoc.ref);
    await bucket.file(`dogs/${dogDoc.id}.jpg`).delete({ignoreNotFound: true}).catch(() => null);
  }
  await bucket.file(`profiles/${targetUid}.jpg`).delete({ignoreNotFound: true}).catch(() => null);
  await db.recursiveDelete(targetRef);

  await db.collection('auditLog').add({
    action: 'Account deleted', targetId: 'deleted-user', detail: 'Learner requested permanent removal',
    actor: String(caller.data()?.name || role), createdAt: FieldValue.serverTimestamp(),
  });
  await admin.auth().deleteUser(targetUid).catch(err => {
    if (err.code !== 'auth/user-not-found') throw err;
  });
  return {ok: true, removedDogs: dogIds.length};
});


exports.translateAdminText = onCall(async (request) => {
  if (!request.auth) throw new HttpsError('unauthenticated', 'Sign in first.');
  const staff = await db.collection('users').doc(request.auth.uid).get();
  const role = staff.data()?.role;
  if (!['admin', 'captain'].includes(role)) throw new HttpsError('permission-denied', 'Admin/Captain access required.');

  const text = String(request.data?.text || '').trim();
  const source = String(request.data?.sourceLanguage || 'en');
  const target = String(request.data?.targetLanguage || 'cy');
  if (!text) return {text: ''};
  if (!['en', 'cy'].includes(source) || !['en', 'cy'].includes(target) || source === target) {
    throw new HttpsError('invalid-argument', 'Only English and Welsh translation is supported here.');
  }
  if (text.length > 5000) throw new HttpsError('invalid-argument', 'Notice text is too long.');

  const projectId = process.env.GCLOUD_PROJECT || process.env.GCP_PROJECT || admin.app().options.projectId;
  const parent = `projects/${projectId}/locations/global`;
  const [response] = await translationClient.translateText({
    parent,
    contents: [text],
    mimeType: 'text/plain',
    sourceLanguageCode: source,
    targetLanguageCode: target,
  });
  return {text: response.translations?.[0]?.translatedText || ''};
});
