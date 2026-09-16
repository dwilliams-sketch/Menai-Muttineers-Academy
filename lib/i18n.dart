import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LanguageController {
  static final ValueNotifier<String> language = ValueNotifier<String>('en');
  static SharedPreferences? _prefs;

  static Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
    final saved = _prefs?.getString('academy_language');
    if (saved == 'cy' || saved == 'en' || saved == 'pirate') {
      language.value = saved!;
    }
  }

  static String get current => language.value;

  static Future<void> set(String code) async {
    if (code != 'en' && code != 'cy' && code != 'pirate') return;
    language.value = code;
    await _prefs?.setString('academy_language', code);
  }
}

String tr(String input, {String? languageCode}) {
  final lang = languageCode ?? LanguageController.current;

  if (input.trim().isEmpty) return input;

  if (lang == 'pirate') {
    return _pirateTr(input);
  }

  if (lang != 'cy') return input;

  final direct = _cy[input];
  if (direct != null) return direct;

  // Common dynamic patterns used throughout the Academy.
  final patterns = <MapEntry<RegExp, String Function(Match)>>[
    MapEntry(
      RegExp(r'^Welcome aboard, (.+)$'),
      (m) => 'Croeso ar fwrdd, ${m.group(1)}',
    ),
    MapEntry(
      RegExp(r'^(.+)’s adventure is currently anchored$'),
      (m) => 'Mae antur ${m.group(1)} wedi’i hangori ar hyn o bryd',
    ),
    MapEntry(
      RegExp(r'^(.+) is waiting to set sail$'),
      (m) => 'Mae ${m.group(1)} yn aros i hwylio',
    ),
    MapEntry(
      RegExp(r'^(.+)’s Adventure Map$'),
      (m) => 'Map Antur ${m.group(1)}',
    ),
    MapEntry(
      RegExp(r'^(.+)’s cabinet$'),
      (m) => 'Cwpwrdd tlysau ${m.group(1)}',
    ),
    MapEntry(RegExp(r'^(.+)’s Photo$'), (m) => 'Llun ${m.group(1)}'),
    MapEntry(
      RegExp(r'^This week: (.+)$'),
      (m) => 'Yr wythnos hon: ${m.group(1)}',
    ),
    MapEntry(RegExp(r'^(\d+) days$'), (m) => '${m.group(1)} diwrnod'),
    MapEntry(RegExp(r'^(\d+) min$'), (m) => '${m.group(1)} munud'),
    MapEntry(
      RegExp(r'^(\d+) of (\d+) lessons practised$'),
      (m) => '${m.group(1)} o ${m.group(2)} gwers wedi’u hymarfer',
    ),
    MapEntry(
      RegExp(r'^(\d+) of (\d+) Key Skills trainer verified$'),
      (m) =>
          '${m.group(1)} o ${m.group(2)} Sgil Allweddol wedi’u gwirio gan hyfforddwr',
    ),
    MapEntry(RegExp(r'^(\d+) Kudos$'), (m) => '${m.group(1)} Kudos'),
    MapEntry(RegExp(r'^Payment: (.+)$'), (m) => 'Taliad: ${m.group(1)}'),
    MapEntry(RegExp(r'^Role: (.+)$'), (m) => 'Rôl: ${m.group(1)}'),
    MapEntry(
      RegExp(r'^Academy status: (.+)$'),
      (m) => 'Statws yr Academi: ${m.group(1)}',
    ),
    MapEntry(
      RegExp(r'^Account credit: (.+)$'),
      (m) => 'Credyd cyfrif: ${m.group(1)}',
    ),
    MapEntry(
      RegExp(r'^Current balance: (.+)$'),
      (m) => 'Balans presennol: ${m.group(1)}',
    ),
    MapEntry(
      RegExp(r'^Next renewal: (.+)$'),
      (m) => 'Adnewyddu nesaf: ${m.group(1)}',
    ),
    MapEntry(
      RegExp(r'^Assigned: (.+)$'),
      (m) => 'Wedi’i neilltuo: ${m.group(1)}',
    ),
    MapEntry(RegExp(r'^Trainer: (.+)$'), (m) => 'Hyfforddwr: ${m.group(1)}'),
    MapEntry(RegExp(r'^Dog: (.+)$'), (m) => 'Ci: ${m.group(1)}'),
    MapEntry(RegExp(r'^Breed: (.+)$'), (m) => 'Brîd: ${m.group(1)}'),
    MapEntry(RegExp(r'^Attempts: (.+)$'), (m) => 'Ymdrechion: ${m.group(1)}'),
    MapEntry(
      RegExp(r'^Step (\d+) of (\d+)$'),
      (m) => 'Cam ${m.group(1)} o ${m.group(2)}',
    ),
    MapEntry(
      RegExp(r'^Doubloon balance: (.+)$'),
      (m) => 'Balans Doubloons: ${m.group(1)}',
    ),
    MapEntry(
      RegExp(r'^Registered dogs: (\\d+)$'),
      (m) => 'Cŵn cofrestredig: ${m.group(1)}',
    ),
    MapEntry(
      RegExp(r'^Active dogs now: (\\d+)$'),
      (m) => 'Cŵn gweithredol nawr: ${m.group(1)}',
    ),
    MapEntry(
      RegExp(r'^Next 30-day renewal: (\\d+) Doubloons / £(.+)$'),
      (m) =>
          'Adnewyddiad nesaf 30 diwrnod: ${m.group(1)} Doubloons / £${m.group(2)}',
    ),
    MapEntry(
      RegExp(r'^Access until: (.+)$'),
      (m) => 'Mynediad tan: ${m.group(1)}',
    ),
    MapEntry(
      RegExp(r'^Current paid access ends: (.+)$'),
      (m) => 'Mae’r mynediad taledig presennol yn dod i ben: ${m.group(1)}',
    ),
    MapEntry(RegExp(r'^End sound: (.+)$'), (m) {
      final sound = switch (m.group(1)) {
        'PARROT' => 'PAROT',
        'BELL' => 'CLOCH',
        'CANNON' => 'CANON',
        'NONE' => 'DIM',
        final value => value ?? '',
      };
      return 'Sain ar y diwedd: $sound';
    }),
    MapEntry(
      RegExp(r'^(\d+(?:\.\d+)?) Doubloon$'),
      (m) => '${m.group(1)} Doubloon',
    ),
    MapEntry(
      RegExp(r'^(\d+(?:\.\d+)?) Doubloons$'),
      (m) => '${m.group(1)} Doubloons',
    ),
    MapEntry(
      RegExp(r'^([+-]\d+(?:\.\d+)?) Doubloon$'),
      (m) => '${m.group(1)} Doubloon',
    ),
    MapEntry(
      RegExp(r'^([+-]\d+(?:\.\d+)?) Doubloons$'),
      (m) => '${m.group(1)} Doubloons',
    ),
    MapEntry(
      RegExp(r'^(\d+) trophies earned$'),
      (m) => '${m.group(1)} tlws wedi’u hennill',
    ),
    MapEntry(
      RegExp(r'^(\d+) training diary entries$'),
      (m) => '${m.group(1)} cofnod dyddiadur hyfforddi',
    ),
    MapEntry(
      RegExp(r'^Recommend a skill for (.+)$'),
      (m) => 'Argymell sgil i ${m.group(1)}',
    ),
    MapEntry(
      RegExp(r'^Adjust Doubloons — (.+)$'),
      (m) => 'Addasu Doubloons — ${m.group(1)}',
    ),
    MapEntry(RegExp(r'^Dogs: (.+)$'), (m) => 'Cŵn: ${m.group(1)}'),
    MapEntry(
      RegExp(r'^(.+) — Dog Snapshot$'),
      (m) => '${m.group(1)} — Crynodeb y Ci',
    ),
    MapEntry(
      RegExp(r'^(.+) — Academy V1\.4$'),
      (m) => '${m.group(1)} — Academi V1.4',
    ),
    MapEntry(
      RegExp(
        r'^Your account and (.+)’s profile are safely created\. We just need to confirm the first Academy payment before the course unlocks\.$',
      ),
      (m) =>
          'Mae eich cyfrif a phroffil ${m.group(1)} wedi’u creu’n ddiogel. Dim ond cadarnhau taliad cyntaf yr Academi sydd ei angen cyn datgloi’r cwrs.',
    ),
    MapEntry(
      RegExp(
        r'^Dog name \+ your initials \+ (.+) helps us match the payment quickly\.$',
      ),
      (m) =>
          'Mae enw’r ci + eich llythrennau cyntaf + ${m.group(1)} yn ein helpu i baru’r taliad yn gyflym.',
    ),
    MapEntry(
      RegExp(
        r'^Please use this exact reference so we know who and which dog the payment relates to\. Reference suffix: (.+)\.$',
      ),
      (m) =>
          'Defnyddiwch yr union gyfeirnod hwn fel ein bod yn gwybod pwy a pha gi mae’r taliad ar ei gyfer. Ôl-ddodiad y cyfeirnod: ${m.group(1)}.',
    ),
    MapEntry(
      RegExp(
        r'^Typical guide: £(.+) for (\d+) minutes\. Your trainer will confirm the actual price and length before you accept\.$',
      ),
      (m) =>
          'Canllaw arferol: £${m.group(1)} am ${m.group(2)} munud. Bydd eich hyfforddwr yn cadarnhau’r pris a’r hyd gwirioneddol cyn i chi dderbyn.',
    ),
    MapEntry(
      RegExp(r'^(\d+) new message(s)? aboard$'),
      (m) =>
          '${m.group(1)} new message${m.group(1) == '1' ? '' : 's'} in the bottle',
    ),
    MapEntry(
      RegExp(r'^(.+) • Academy$'),
      (m) => '${m.group(1)} • Academy Ship',
    ),
    MapEntry(
      RegExp(r'^Last/current paid voyage: (.+)$'),
      (m) => 'Last/current passage: ${m.group(1)}',
    ),
    MapEntry(
      RegExp(r'^(.+)’s training tools are anchored$'),
      (m) => '${m.group(1)}’s training gear is below deck',
    ),
    MapEntry(RegExp(r'^(.+)’s Photo$'), (m) => '${m.group(1)}’s Portrait'),
  ];
  for (final entry in patterns) {
    final match = entry.key.firstMatch(input);
    if (match != null) return entry.value(match);
  }

  // Short labels can safely be translated when embedded in dynamic UI strings.
  var out = input;
  const replacements = <String, String>{
    // Upper-case values are often produced from Firestore status fields.
    'NEW / AWAITING PAYMENT': 'NEWYDD / YN AROS AM DALIAD',
    'RENEWAL_DUE': 'ADNEWYDDU’N DDYLEDUS',
    'RENEWAL DUE': 'ADNEWYDDU’N DDYLEDUS',
    'LEGACY ACTIVE': 'HEN FYNEDIAD GWEITHREDOL',
    'IN PROGRESS': 'AR WAITH',
    'GETTING THERE': 'YN GWELLA',
    'COMPLIMENTARY': 'AM DDIM',
    'UNPAID': 'HEB EI DALU',
    'REQUESTED': 'WEDI GOFYN',
    'PROPOSED': 'ARFAETHEDIG',
    'BOOKED': 'WEDI ARCHEBU',
    'COMPLETED': 'WEDI CWBLHAU',
    'DECLINED': 'WEDI GWRTHOD',
    'CANCELLED': 'WEDI CANSLO',
    'RESOLVED': 'WEDI DATRYS',
    'ACTIVE': 'GWEITHREDOL',
    'PAUSED': 'WEDI’I OEDI',
    'AWAITING': 'YN AROS',
    'GRADUATED': 'WEDI GRADDIO',
    'LEARNER': 'DYSGWR',
    'TRAINER': 'HYFFORDDWR',
    'ADMIN': 'GWEINYDDWR',
    'CAPTAIN': 'CAPTEN',
    'NORMAL': 'ARFEROL',
    'IMPORTANT': 'PWYSIG',
    'WATCH LIST': 'RHESTR WYLIO',
    'COVE': 'CILFACH',
    'DECK': 'DEC',
    'ISLAND': 'YNYS',
    'PARROT': 'PAROT',
    'CANNON': 'CANON',
    'HARBOUR': 'HARBWR',
    'NONE': 'DIM',
    'PAID': 'WEDI TALU',
    'NEW': 'NEWYDD',
    'Active': 'Gweithredol',
    'Paused': 'Wedi’i oedi',
    'Awaiting': 'Yn aros',
    'Completed': 'Wedi cwblhau',
    'Passed': 'Wedi pasio',
    'Waiting': 'Yn aros',
    'Trainer': 'Hyfforddwr',
    'Captain': 'Capten',
    'Admin': 'Gweinyddwr',
    'Learner': 'Dysgwr',
    ' dogs': ' cŵn',
    ' dog': ' ci',
    'Dog': 'Ci',
    'days': 'diwrnod',
    'minutes': 'munud',
  };
  replacements.forEach((a, b) {
    out = out.replaceAll(a, b);
  });
  return out;
}

String _pirateTr(String input) {
  final direct = _pirate[input];
  if (direct != null) return direct;

  final patterns = <MapEntry<RegExp, String Function(Match)>>[
    MapEntry(RegExp(r'^Welcome aboard, (.+)$'), (m) => 'Ahoy, ${m.group(1)}!'),
    MapEntry(
      RegExp(r'^(.+)’s Adventure Map$'),
      (m) => '${m.group(1)}’s Treasure Map',
    ),
    MapEntry(
      RegExp(r'^(.+)’s cabinet$'),
      (m) => '${m.group(1)}’s Treasure Cabinet',
    ),
    MapEntry(RegExp(r'^This week: (.+)$'), (m) => 'This voyage: ${m.group(1)}'),
    MapEntry(RegExp(r'^Role: (.+)$'), (m) => 'Crew role: ${m.group(1)}'),
    MapEntry(
      RegExp(r'^Current balance: (.+)$'),
      (m) => 'Doubloon chest: ${m.group(1)}',
    ),
    MapEntry(
      RegExp(r'^Next renewal: (.+)$'),
      (m) => 'Next voyage renewal: ${m.group(1)}',
    ),
    MapEntry(RegExp(r'^Assigned: (.+)$'), (m) => 'Claimed by: ${m.group(1)}'),
    MapEntry(
      RegExp(r'^Registered dogs: (\d+)$'),
      (m) => 'Dogs on the books: ${m.group(1)}',
    ),
    MapEntry(
      RegExp(r'^Active dogs now: (\d+)$'),
      (m) => 'Dogs sailing now: ${m.group(1)}',
    ),
    MapEntry(
      RegExp(r'^Access until: (.+)$'),
      (m) => 'Passage until: ${m.group(1)}',
    ),
    MapEntry(
      RegExp(r'^Current paid access ends: (.+)$'),
      (m) => 'Current passage ends: ${m.group(1)}',
    ),
    MapEntry(
      RegExp(r'^(\d+) trophies earned$'),
      (m) => '${m.group(1)} treasures earned',
    ),
    MapEntry(RegExp(r'^Dogs: (.+)$'), (m) => 'Shipmates: ${m.group(1)}'),
  ];

  for (final entry in patterns) {
    final match = entry.key.firstMatch(input);
    if (match != null) return entry.value(match);
  }

  return input;
}

const Map<String, String> _pirate = {
  // V1.4.2 video storage dashboard
  'Academy Video Storage': 'Captain’s Video Hold',
  'Temporary learner assessment and Help Me footage.':
      'Temporary moving pictures stored below deck.',
  'Videos stored': 'Videos aboard',
  'Storage used': 'Cargo space used',
  'Temporary videos': 'Temporary cargo',
  'Awaiting deletion': 'Ready to go overboard',
  'Marked to keep': 'Marked for the Captain',
  'Waiting assessments': 'Waiting Captain’s checks',
  'Archived to Drive': 'Stowed in the archive',
  'Deleted last cleanup': 'Thrown overboard last cleanup',
  'Last storage check': 'Last hold inspection',
  'No storage check has run yet.':
      'The Captain has not inspected the video hold yet.',
  'REFRESH STORAGE': 'INSPECT VIDEO HOLD',
  'Checking storage...': 'Inspecting the hold...',
  'Storage refreshed.': 'Video hold inspected.',
  'Could not refresh storage right now.':
      'Could not inspect the video hold right now.',
  'Not checked yet': 'Not inspected yet',
  'Temporary Academy videos are removed 30 days after an assessment is reviewed or a Help Me conversation is resolved, unless you mark them to keep.': 'Temporary videos go overboard 30 days after review or resolution unless the Captain marks them to keep.',
  // V1.4.2 learner video uploads
  'That video is too large. Please choose a shorter clip under 100 MB.': 'That moving picture is too heavy for the ship! Choose a shorter clip under 100 MB.',
  'We could not upload that video. Please try again or use a video link instead.': 'We could not haul that video aboard. Try again or use a video link instead.',
  'We could not remove that video. Please try again.':
      'We could not throw that video overboard. Try again.',
  'Please record a video, choose one from your phone, or add a video link.':
      'Record a video, choose one from your phone, or send us a video link.',
  'Send us a short video showing the skill. The easiest option is to record one now or choose one already on your phone.': 'Send the crew a short video showing the skill. Record one now or choose one already on your phone.',
  'RECORD VIDEO NOW': 'RECORD VIDEO NOW',
  'CHOOSE FROM PHONE': 'CHOOSE FROM PHONE',
  'Uploading your video...': 'Hauling your video aboard...',
  'Video ready': 'Video aboard and ready',
  'OR USE A LINK': 'OR SEND A LINK',
  'Video link': 'Video link',
  'Keep clips short and clear. Recordings are limited to 90 seconds and Academy uploads have a 100 MB maximum.': 'Keep clips short and clear, matey — 90 seconds maximum and no more than 100 MB.',
  'Tell the trainers what is happening. You can also send us a short video so we can see exactly what you mean.': 'Tell the trainers what is going wrong, and send a short video if it helps us see the trouble.',
  'Show us the problem': 'Show the crew the problem',
  'RECORD VIDEO': 'RECORD VIDEO',
  'A short clip is normally plenty. Recordings are limited to 90 seconds.':
      'A short clip is normally plenty — keep it under 90 seconds.',
  // Core Academy
  'Menai Muttineers Academy': 'Menai Muttineers Academy',
  'Academy V1.4': 'Academy V1.4 — Pirate Mode',
  'Preparing the Academy…': 'Preparing the ship…',
  'This should only take a few seconds.': 'We’ll be underway in a few seconds.',
  'RETRY': 'TRY AGAIN, MATEY',
  'Your pre-flyball adventure starts here.':
      'Your pre-flyball voyage starts here.',

  // Sign-in / account
  'New to the Academy?': 'New aboard?',
  'CREATE MY ACCOUNT': 'JOIN THE CREW',
  'Already aboard?': 'Already aboard?',
  'EXISTING USER — SIGN IN': 'CREWMATE — SIGN IN',
  'Welcome back aboard.': 'Welcome back aboard, matey.',
  'SIGN IN': 'SIGN IN ABOARD',
  'Signing in...': 'Coming aboard...',
  'Account setup': 'Crew Setup',
  'Sign out': 'ABANDON SHIP',
  'Sign out and register again': 'ABANDON SHIP & REGISTER AGAIN',
  'CREATE ACCOUNT': 'JOIN THE CREW',
  'NEXT': 'ONWARD',
  'BACK': 'BACK A DECK',

  // Learner navigation
  'Home': 'Home Deck',
  'Training': 'Training Quarters',
  'Support': 'Shipmate Support',
  'Trophies': 'Treasure Cabinet',
  'More': 'More Booty',

  // Home
  'Welcome to your Home Deck.': 'Welcome to your Home Deck, matey.',
  'Your Academy Voyage': 'Your Academy Voyage',
  'CONTINUE ADVENTURE': 'SET SAIL!',
  'Captain’s Message': 'Captain’s Orders',
  'Weekly Crew Catch-Up': 'Weekly Crew Muster',
  'JOIN GOOGLE MEET': 'JOIN THE CREW CALL',
  'Notices': 'Ship’s Notices',
  'Notifications': 'Messages in a Bottle',
  'Mark all as read': 'Mark all opened',
  'No notifications yet.': 'No messages in the bottle yet.',

  // Training
  'Training Adventure': 'Training Voyage',
  'Key Skills': 'Key Skills',
  'Why this matters': 'Why this matters aboard ship',
  'Lessons': 'Training Drills',
  'Watched': 'Seen It',
  'Practised': 'Practised',
  'Confident': 'Shipshape',
  'Need Help': 'Need a Hand?',
  'NEED HELP': 'CALL FOR HELP',
  'Assessment': 'Assessment',
  'Assessment locked': 'Assessment below deck',
  'READY FOR ASSESSMENT': 'READY FOR CAPTAIN’S CHECK',
  'REQUEST ASSESSMENT': 'REQUEST CAPTAIN’S CHECK',
  'SUBMIT ASSESSMENT': 'SEND FOR REVIEW',
  'Keep practising': 'Keep training, matey',
  'Passed': 'Shipshape!',
  'Awaiting review': 'Awaiting Captain’s review',

  // Trophy cabin
  'DOG ACHIEVEMENTS': 'DOG TREASURES',
  'Trophy Cabin': 'Treasure Cabin',
  'Keep sailing to discover this trophy':
      'Keep sailing to uncover this treasure',
  'Trainer verified': 'Crew trainer verified',

  // Payments / access
  'Payments & Access': 'Doubloons & Passage',
  'Academy Credit': 'Doubloon Chest',
  'Account History': 'Ship’s Ledger',
  'Pay outside the app': 'Pay at the harbour',
  'I’VE MADE A PAYMENT': 'DOUBLOONS SENT',
  'Use this payment reference:': 'Use this treasure reference:',
  'Academy access': 'Academy Passage',
  'Active': 'Sailing',
  'Paused': 'Anchored',
  'Renewal due': 'Passage Due',
  'Awaiting': 'Awaiting Orders',
  'PAUSE AT END OF CURRENT VOYAGE': 'DROP ANCHOR AFTER THIS VOYAGE',
  'CANCEL PAUSE': 'RAISE ANCHOR',
  'RESTART ADVENTURE': 'SET SAIL AGAIN',

  // More page
  'Questions, 1-to-1 sessions and diary':
      'Questions, private training and Captain’s log',
  'Start Lights and short training timer':
      'Start lights and quick training timer',
  'Doubloons, dog access, pause and payment details':
      'Doubloons, passage and payment details',
  'Socials, Easyfundraising, GoFundMe and club links':
      'Crew socials, fundraising and club links',
  'Merchandise coming soon': 'Crew supplies coming soon',
  'Photos, backgrounds, music and privacy':
      'Ship portraits, scenery, shanties and privacy',
  'Send feedback or report a problem':
      'Send word to the Captain or report a problem',

  // Staff area
  'Bridge': 'Captain’s Bridge',
  'Tasks': 'Orders',
  'Dogs': 'Crew Dogs',
  'Reports': 'Captain’s Charts',
  'Control': 'Ship’s Controls',
  'Action Centre': 'Action Deck',
  'People Manager': 'Crew Manager',
  'CLAIM THIS': 'CLAIM THIS JOB',
  'Resolve': 'CLOSE CASE',
  'Reply to learner': 'Reply to shipmate',
  'SEND REPLY': 'SEND MESSAGE',
  'ADD VIDEO LINK': 'ADD VIDEO LINK',
  'HIDE VIDEO LINK': 'HIDE VIDEO LINK',
  'DICTATE REPLY': 'SPEAK REPLY',
  'STOP LISTENING': 'STOP LISTENING',
  'Listening… speak your reply.': 'Listening… speak, matey.',

  // Common actions
  'Watch in app': 'WATCH ABOARD',
  'Open original': 'OPEN ORIGINAL',
  'Keep for records': 'STOW IN THE CAPTAIN’S ARCHIVE',
  'Kept for records': 'STOWED FOR THE CAPTAIN',
  'Video could not be played here.':
      'This moving picture could not be played aboard.',

  'Cancel': 'BELAY THAT',
  'Other': 'Something Else',
  'Open video': 'WATCH VIDEO',
  'RESTART 30 DAYS': 'SET SAIL FOR 30 DAYS',
  'AUTHORISE 30 DAYS': 'GRANT 30 DAYS PASSAGE',
  'PAUSE ALL DOGS': 'DROP ANCHOR FOR ALL DOGS',
  'CANCEL ALL PAUSES': 'RAISE ALL ANCHORS',

  // Statuses
  'ACTIVE': 'SAILING',
  'PAUSED': 'ANCHORED',
  'AWAITING': 'AWAITING ORDERS',
  'COMPLETED': 'VOYAGE COMPLETE',
  'RESOLVED': 'SORTED',
  'TRAINER': 'TRAINER',
  'CAPTAIN': 'CAPTAIN',
  'ADMIN': 'QUARTERMASTER',
  'LEARNER': 'CREWMATE',
  'The Crew': 'The Crew',
  'No dog profile found. Please contact the Captain.':
      'No dog profile found aboard. Send word to the Captain.',
  'Tap the bell at the top to open your postbox.':
      'Tap the bell above to open your message bottle.',
  'Login streak': 'Days Aboard',
  'Doubloons': 'Doubloons',
  'More From the Academy': 'More Booty From the Academy',
  'Training Support': 'Training Help Deck',
  'Games & Practice': 'Games & Deck Drills',
  'Follow & Support the Crew': 'Follow & Back the Crew',
  'Muttineers Treasure Chest': 'Muttineers Treasure Chest',
  'Profile & Settings': 'Captain’s Log & Settings',
  'Suggest an Improvement': 'Send Word to the Captain',
  'Official training tools stay locked while this dog is paused. Restart the adventure or use the 1-to-1 button on the anchored screen.': 'Training gear stays below deck while this dog is anchored. Set sail again or use the 1-to-1 button on the anchored screen.',
  'Follow the Crew': 'Follow the Crew',
  'Keep up with the Muttineers and help support the Academy.':
      'Keep up with the Muttineers and help keep the Academy ship sailing.',
  'Support the Crew': 'Back the Crew',
  'Bank Transfer / Standing Order':
      'Doubloons by Bank Transfer / Standing Order',
  'Payments happen outside the app. The Academy does not collect your bank or card details.': 'Payments happen ashore. The Academy never stores your bank or card details.',
  '1 Doubloon (£5) gives one dog 30 days of Academy access.':
      '1 Doubloon (£5) buys one dog 30 days of Academy passage.',
  'Your reference:': 'Your treasure reference:',
  'Reference copied.': 'Treasure reference copied.',
  'Link coming soon': 'Coming over the horizon',
  'Profile Photos': 'Crew Portraits',
  'My Photo': 'My Portrait',
  'Appearance & Sound': 'Ship Appearance & Sound',
  'Pirate backgrounds': 'Pirate Scenery',
  'Light pirate scenes behind the app. Turn off for a plain view.':
      'Pirate scenery behind the Academy. Turn it off for calmer waters.',
  'Background style': 'Scenery Style',
  'Change each visit': 'New Scene Each Voyage',
  'My favourite': 'My Favourite Port',
  'Favourite scene': 'Favourite Scene',
  'Background shanty music': 'Background Sea Shanties',
  'Loops between Academy tracks. Off by default.':
      'Plays Academy shanties in the background. Off by default.',
  'Music volume': 'Shanty Volume',
  'Trophy celebration sounds': 'Treasure Celebration Sounds',
  'Reduced animation': 'Calmer Sailing',
  'Use gentler movement and transitions.':
      'Use gentler movement and calmer page changes.',
  'Training timer sound': 'Training Timer Signal',
  'Crew Privacy': 'Crew Privacy',
  'Request a 1-to-1': 'Request Private Training',
  'REQUEST A 1-to-1': 'REQUEST PRIVATE TRAINING',
  'REQUEST A 1-to-1 SESSION': 'REQUEST PRIVATE TRAINING',
  'Restart request sent to Admin.':
      'Restart request sent to the quartermaster.',
  'Photo upload is currently disabled by Admin. This keeps the Academy on the low-cost setup until cloud photo storage is enabled.': 'Portrait uploads are currently below deck. This keeps the Academy running on the low-cost setup until cloud storage is enabled.',
  'Photo upload is not available yet. Admin may need to enable Firebase Storage.': 'Portrait upload is not ready yet. The quartermaster may need to enable cloud storage.',
  'Could not save that setting. Please try again.':
      'Could not update the ship’s log. Please try again.',
  '♪ Skip music track': '♪ Skip this shanty',
};

class I18nText extends StatelessWidget {
  final String data;
  final TextStyle? style;
  final TextAlign? textAlign;
  final int? maxLines;
  final TextOverflow? overflow;
  final bool? softWrap;

  const I18nText(
    this.data, {
    super.key,
    this.style,
    this.textAlign,
    this.maxLines,
    this.overflow,
    this.softWrap,
  });

  @override
  Widget build(BuildContext context) => Text(
    tr(data),
    style: style,
    textAlign: textAlign,
    maxLines: maxLines,
    overflow: overflow,
    softWrap: softWrap,
  );
}

const Map<String, String> _cy = {
  // V1.4.2 video storage dashboard
  'Academy Video Storage': 'Storfa Fideos yr Academi',
  'Temporary learner assessment and Help Me footage.':
      'Fideos dros dro o asesiadau dysgwyr a cheisiadau Help Me.',
  'Videos stored': 'Fideos wedi’u storio',
  'Storage used': 'Storfa a ddefnyddiwyd',
  'Temporary videos': 'Fideos dros dro',
  'Awaiting deletion': 'Yn aros i gael eu dileu',
  'Marked to keep': 'Wedi’u marcio i’w cadw',
  'Waiting assessments': 'Asesiadau sy’n aros',
  'Archived to Drive': 'Wedi’u harchifo i Drive',
  'Deleted last cleanup': 'Wedi’u dileu yn y glanhau diwethaf',
  'Last storage check': 'Gwiriad storfa diwethaf',
  'No storage check has run yet.': 'Nid oes gwiriad storfa wedi rhedeg eto.',
  'REFRESH STORAGE': 'ADNEWYDDU’R STORFA',
  'Checking storage...': 'Yn gwirio’r storfa...',
  'Storage refreshed.': 'Storfa wedi’i hadnewyddu.',
  'Could not refresh storage right now.':
      'Ni ellid adnewyddu’r storfa ar hyn o bryd.',
  'Not checked yet': 'Heb ei wirio eto',
  'Temporary Academy videos are removed 30 days after an assessment is reviewed or a Help Me conversation is resolved, unless you mark them to keep.': 'Caiff fideos dros dro yr Academi eu dileu 30 diwrnod ar ôl i asesiad gael ei adolygu neu sgwrs Help Me gael ei datrys, oni bai eich bod yn eu marcio i’w cadw.',
  // V1.4.2 learner video uploads
  'That video is too large. Please choose a shorter clip under 100 MB.':
      'Mae’r fideo hwnnw’n rhy fawr. Dewiswch glip byrrach o dan 100 MB.',
  'We could not upload that video. Please try again or use a video link instead.': 'Ni allem uwchlwytho’r fideo hwnnw. Rhowch gynnig arall arni neu defnyddiwch ddolen fideo yn lle.',
  'We could not remove that video. Please try again.':
      'Ni allem dynnu’r fideo hwnnw. Rhowch gynnig arall arni.',
  'Please record a video, choose one from your phone, or add a video link.':
      'Recordiwch fideo, dewiswch un o’ch ffôn, neu ychwanegwch ddolen fideo.',
  'Send us a short video showing the skill. The easiest option is to record one now or choose one already on your phone.': 'Anfonwch fideo byr atom yn dangos y sgil. Y ffordd hawsaf yw recordio un nawr neu ddewis un sydd eisoes ar eich ffôn.',
  'RECORD VIDEO NOW': 'RECORDIO FIDEO NAWR',
  'CHOOSE FROM PHONE': 'DEWIS O’R FFÔN',
  'Uploading your video...': 'Yn uwchlwytho eich fideo...',
  'Video ready': 'Fideo yn barod',
  'OR USE A LINK': 'NEU DEFNYDDIO DOLEN',
  'Video link': 'Dolen fideo',
  'YouTube / Google Drive / iCloud / other share link':
      'YouTube / Google Drive / iCloud / dolen rannu arall',
  'Keep clips short and clear. Recordings are limited to 90 seconds and Academy uploads have a 100 MB maximum.': 'Cadwch y clipiau’n fyr ac yn glir. Mae recordiadau wedi’u cyfyngu i 90 eiliad ac mae uchafswm o 100 MB ar uwchlwythiadau’r Academi.',
  'Tell the trainers what is happening. You can also send us a short video so we can see exactly what you mean.': 'Dywedwch wrth yr hyfforddwyr beth sy’n digwydd. Gallwch hefyd anfon fideo byr atom fel y gallwn weld yn union beth rydych yn ei olygu.',
  'Show us the problem': 'Dangoswch y broblem i ni',
  'RECORD VIDEO': 'RECORDIO FIDEO',
  'A short clip is normally plenty. Recordings are limited to 90 seconds.': 'Mae clip byr fel arfer yn ddigon. Mae recordiadau wedi’u cyfyngu i 90 eiliad.',
  // Core navigation and account flow
  'Menai Muttineers Academy': 'Academi Menai Muttineers',
  'Academy V1.4': 'Academi V1.4',
  'Preparing the Academy…': 'Yn paratoi’r Academi…',
  'This should only take a few seconds.':
      'Dylai hyn gymryd ychydig eiliadau yn unig.',
  'The Academy could not finish starting.':
      'Ni allai’r Academi orffen cychwyn.',
  'Nothing has been deleted. Check your internet connection, then tap Retry.': 'Nid oes dim wedi’i ddileu. Gwiriwch eich cysylltiad rhyngrwyd, yna tapiwch Ailgeisio.',
  'Startup details': 'Manylion cychwyn',
  'RETRY': 'AILGEISIO',
  'Unknown startup error.': 'Gwall cychwyn anhysbys.',
  'Your pre-flyball adventure starts here.':
      'Mae eich antur cyn-flyball yn dechrau yma.',
  'New to the Academy?': 'Yn newydd i’r Academi?',
  'CREATE MY ACCOUNT': 'CREU FY NGHYFRIF',
  'Already aboard?': 'Eisoes ar fwrdd?',
  'EXISTING USER — SIGN IN': 'DEFNYDDIWR PRESENNOL — MEWNGOFNODI',
  'Create an account once, then use the same login on the Android app or the web Academy.': 'Crëwch gyfrif unwaith, yna defnyddiwch yr un manylion mewngofnodi ar yr ap Android neu’r Academi ar y we.',
  'Welcome back aboard.': 'Croeso yn ôl ar fwrdd.',
  'Email': 'E-bost',
  'Email address': 'Cyfeiriad e-bost',
  'Password': 'Cyfrinair',
  'SIGN IN': 'MEWNGOFNODI',
  'Signing in...': 'Yn mewngofnodi...',
  'Forgot password?': 'Wedi anghofio’r cyfrinair?',
  'Reset your password': 'Ailosod eich cyfrinair',
  'Enter the email address you used for the Academy. We’ll send a secure reset link.': 'Rhowch y cyfeiriad e-bost a ddefnyddiwyd gennych ar gyfer yr Academi. Byddwn yn anfon dolen ailosod ddiogel.',
  'Send reset link': 'Anfon dolen ailosod',
  'Cancel': 'Canslo',
  'Watch in app': 'Gwylio yn yr ap',
  'Open original': 'Agor y gwreiddiol',
  'Keep for records': 'Cadw ar gyfer cofnodion',
  'Kept for records': 'Wedi’i gadw ar gyfer cofnodion',
  'Video could not be played here.': 'Ni ellid chwarae’r fideo yma.',
  'Back to account choices': 'Yn ôl i’r dewisiadau cyfrif',
  'Welcome aboard — we’ll set you up in three simple steps.':
      'Croeso ar fwrdd — byddwn yn eich sefydlu mewn tri cham syml.',
  'Your name': 'Eich enw',
  'Telephone number': 'Rhif ffôn',
  'Dog name': 'Enw’r ci',
  'Dog’s name': 'Enw’r ci',
  'Breed': 'Brîd',
  'Dog’s age (optional)': 'Oedran y ci (dewisol)',
  'Date of birth (optional)': 'Dyddiad geni (dewisol)',
  'Date of birth YYYY-MM-DD (optional)': 'Dyddiad geni BBBB-MM-DD (dewisol)',
  'This date is an estimate': 'Amcangyfrif yw’r dyddiad hwn',
  'Previous training experience (optional)':
      'Profiad hyfforddi blaenorol (dewisol)',
  'Anything the trainers should know (optional)':
      'Unrhyw beth y dylai’r hyfforddwyr ei wybod (dewisol)',
  'NEXT': 'NESAF',
  'BACK': 'YN ÔL',
  'CREATE ACCOUNT': 'CREU CYFRIF',
  'You will stay signed in after registration — there is no need to sign in again.': 'Byddwch yn aros wedi mewngofnodi ar ôl cofrestru — nid oes angen mewngofnodi eto.',
  'Please enter your email and password.': 'Rhowch eich e-bost a’ch cyfrinair.',
  'Please enter a valid email address.': 'Rhowch gyfeiriad e-bost dilys.',
  'Password reset email sent. Check your inbox and junk/spam folder.': 'Mae e-bost ailosod cyfrinair wedi’i anfon. Gwiriwch eich mewnflwch a’ch ffolder sbam.',
  'Account setup': 'Sefydlu cyfrif',
  'Sign out and register again': 'Allgofnodi a chofrestru eto',
  'Sign out': 'Allgofnodi',
  'Your login exists, but the Academy profile was not found.': 'Mae eich manylion mewngofnodi yn bodoli, ond ni chanfuwyd proffil yr Academi.',

  // Main learner navigation
  'Home': 'Hafan',
  'Training': 'Hyfforddiant',
  'Support': 'Cymorth',
  'Trophies': 'Tlysau',
  'More': 'Mwy',
  'Welcome to your Home Deck.': 'Croeso i’ch Dec Cartref.',
  'Your Academy Voyage': 'Eich Mordaith Academi',
  'CONTINUE ADVENTURE': 'PARHAU Â’R ANTUR',
  'Captain’s Message': 'Neges y Capten',
  'Weekly Crew Catch-Up': 'Sgwrs Wythnosol y Criw',
  'JOIN GOOGLE MEET': 'Ymuno â GOOGLE MEET',
  'Notices': 'Hysbysiadau',
  'Notifications': 'Hysbysiadau',
  'Mark all as read': 'Marcio pob un fel wedi’i ddarllen',
  'No notifications yet.': 'Dim hysbysiadau eto.',
  'That help conversation could not be found.':
      'Ni ellid dod o hyd i’r sgwrs gymorth honno.',
  'Your adventure is ready!': 'Mae eich antur yn barod!',
  'Access code': 'Cod mynediad',
  'ACTIVATE ACADEMY': 'GWEITHREDU’R ACADEMI',
  'Pay outside the app': 'Talu y tu allan i’r ap',
  'The Academy never takes card or bank details inside the app. Use your normal banking app / standing order.': 'Nid yw’r Academi byth yn cymryd manylion cerdyn neu fanc yn yr ap. Defnyddiwch eich ap bancio arferol / archeb sefydlog.',
  'I’VE MADE A PAYMENT': 'Rwyf WEDI GWNEUD TALIAD',
  'Amount sent (£)': 'Swm a anfonwyd (£)',
  'Method': 'Dull',
  'Bank transfer': 'Trosglwyddiad banc',
  'Standing order': 'Archeb sefydlog',
  'Other': 'Arall',
  'Send to Admin': 'Anfon at y Gweinyddwr',
  'Use this payment reference:': 'Defnyddiwch y cyfeirnod talu hwn:',
  'Reference copied.': 'Cyfeirnod wedi’i gopïo.',

  // Dog access / payments
  'Payments & Access': 'Taliadau a Mynediad',
  'Academy Credit': 'Credyd yr Academi',
  'Account History': 'Hanes y Cyfrif',
  'PAUSE AT END OF CURRENT VOYAGE': 'OEDI AR DDIWEDD Y FORDAITH BRESENNOL',
  'CANCEL PAUSE': 'CANSLO’R OEDI',
  'RESTART ADVENTURE': 'AILDDECHRAU’R ANTUR',
  'REQUEST A 1-to-1': 'GOFYN AM 1-i-1',
  'REQUEST A 1-to-1 SESSION': 'GOFYN AM SESIWN 1-i-1',
  '1-to-1 sessions are separate paid training sessions and remain available whether Academy access is active or paused.': 'Mae sesiynau 1-i-1 yn sesiynau hyfforddi â thâl ar wahân ac maent ar gael p’un a yw mynediad yr Academi yn weithredol neu wedi’i oedi.',
  'All progress, trophies and training history are safely stored. Course lessons and official achievements stay locked while this dog is paused.': 'Mae’r holl gynnydd, tlysau a hanes hyfforddi wedi’u cadw’n ddiogel. Mae gwersi’r cwrs a chyflawniadau swyddogol wedi’u cloi tra bo’r ci hwn wedi’i oedi.',
  'This dog needs Academy access before training progress, assessments, trophies and certificates unlock.': 'Mae angen mynediad i’r Academi ar y ci hwn cyn datgloi cynnydd hyfforddi, asesiadau, tlysau a thystysgrifau.',
  'Restart request sent to Admin.':
      'Cais ailgychwyn wedi’i anfon at y Gweinyddwr.',
  'Academy access': 'Mynediad yr Academi',
  'Active': 'Gweithredol',
  'Paused': 'Wedi’i oedi',
  'Renewal due': 'Adnewyddu’n ddyledus',
  'Awaiting': 'Yn aros',

  // Training
  'Training Adventure': 'Antur Hyfforddi',
  'Key Skills': 'Sgiliau Allweddol',
  'Why this matters': 'Pam mae hyn yn bwysig',
  'Lessons': 'Gwersi',
  'Watched': 'Wedi gwylio',
  'Practised': 'Wedi ymarfer',
  'Confident': 'Hyderus',
  'Need Help': 'Angen Cymorth',
  'NEED HELP': 'ANGEN CYMORTH',
  'Assessment': 'Asesiad',
  'Assessment locked': 'Asesiad wedi’i gloi',
  'READY FOR ASSESSMENT': 'BAROD AM ASESIAD',
  'REQUEST ASSESSMENT': 'GOFYN AM ASESIAD',
  'Assessment video link': 'Dolen fideo asesu',
  'YouTube / Google Drive / other share link':
      'Dolen YouTube / Google Drive / rhannu arall',
  'Optional note': 'Nodyn dewisol',
  'SUBMIT ASSESSMENT': 'CYFLWYNO ASESIAD',
  'Video coming soon — the Captain can add the link from Course Editor.': 'Fideo yn dod yn fuan — gall y Capten ychwanegu’r ddolen o Olygydd y Cwrs.',
  'Trainer verified • Trophy earned':
      'Wedi’i wirio gan hyfforddwr • Tlws wedi’i ennill',
  'Keep practising': 'Parhewch i ymarfer',
  'Passed': 'Wedi pasio',
  'Awaiting review': 'Yn aros am adolygiad',

  // Course titles
  'Key Skill 1': 'Sgil Allweddol 1',
  'Key Skill 2': 'Sgil Allweddol 2',
  'Key Skill 3': 'Sgil Allweddol 3',
  'Key Skill 4': 'Sgil Allweddol 4',
  'Key Skill 5': 'Sgil Allweddol 5',
  'Key Skill 6': 'Sgil Allweddol 6',
  'Key Skill 7': 'Sgil Allweddol 7',
  'Key Skill 8': 'Sgil Allweddol 8',
  'Focus & Engagement': 'Ffocws ac Ymgysylltu',
  'Rapid Recall': 'Galw’n Ôl Cyflym',
  'Toy & Tug Drive': 'Brwdfrydedd Tegan a Thynnu',
  'Dead Ball Retrieve': 'Nôl Pêl Llonydd',
  'Target Foundations': 'Sylfeini Targedu',
  'Movement & Body Awareness': 'Symudiad ac Ymwybyddiaeth o’r Corff',
  'Working Around Distractions': 'Gweithio o Amgylch Pethau sy’n Tynnu Sylw',
  'Pre-Flyball Ready': 'Barod ar gyfer Cyn-Flyball',
  'What Engagement Looks Like': 'Sut Mae Ymgysylltu’n Edrych',
  'Reward Markers & Timing': 'Marcwyr Gwobrwyo ac Amseru',
  'Voluntary Check-Ins': 'Cysylltu’n Wirfoddol',
  'Follow Me': 'Dilyn Fi',
  'Switching Rewards': 'Newid Gwobrau',
  'Focus Around Distractions': 'Ffocws o Amgylch Pethau sy’n Tynnu Sylw',
  'Recall Foundations': 'Sylfeini Galw’n Ôl',
  'Name Response': 'Ymateb i’r Enw',
  'Reward Placement': 'Lleoli’r Wobr',
  'Restrained Recall': 'Galw’n Ôl gyda Dal',
  'Adding Distance': 'Ychwanegu Pellter',
  'Adding Distractions': 'Ychwanegu Pethau sy’n Tynnu Sylw',
  'Speed & Clean Finish': 'Cyflymder a Gorffeniad Glân',
  'Find the Best Reward': 'Dod o Hyd i’r Wobr Orau',
  'Invitation to Play': 'Gwahoddiad i Chwarae',
  'Safe Tug Mechanics': 'Techneg Tynnu Ddiogel',
  'Release & Re-Engage': 'Rhyddhau ac Ail-Ymgysylltu',
  'Food to Toy Switching': 'Newid o Fwyd i Degan',
  'Bring the Toy Back': 'Dod â’r Tegan yn Ôl',
  'Build Value in the Ball': 'Adeiladu Gwerth yn y Bêl',
  'Stationary Pickup': 'Codi Pêl Llonydd',
  'Turn Back to the Handler': 'Troi’n Ôl at y Triniwr',
  'Deliver Close': 'Dychwelyd yn Agos',
  'Add Distance': 'Ychwanegu Pellter',
  'Add Speed': 'Ychwanegu Cyflymder',
  'Different Places': 'Lleoedd Gwahanol',
  'Meet the Target': 'Cyfarfod â’r Targed',
  'Accurate Foot Placement': 'Lleoli Traed yn Gywir',
  'Drive to the Target': 'Gyrru at y Targed',
  'Turn Away': 'Troi i Ffwrdd',
  'Build Consistency': 'Adeiladu Cysondeb',
  'Safe Warm-Up & Surfaces': 'Cynhesu Diogel ac Arwynebau',
  'Slow Pole Work': 'Gwaith Polion Araf',
  'Rear-End Awareness': 'Ymwybyddiaeth o’r Coesau Ôl',
  'Balance & Weight Shift': 'Cydbwysedd a Symud Pwysau',
  'Wraps & Turns': 'Lapiau a Throeon',
  'Controlled Speed': 'Cyflymder Rheoledig',
  'Know the Threshold': 'Adnabod y Trothwy',
  'Start with Easy Distractions': 'Dechrau gyda Thyniadau Hawdd',
  'Reward Good Choices': 'Gwobrwyo Dewisiadau Da',
  'Movement Around You': 'Symudiad o’ch Cwmpas',
  'Reset & Recover': 'Ailosod ac Adfer',
  'Putting Skills Together': 'Rhoi Sgiliau at ei Gilydd',
  'Recall into Reward': 'Galw’n Ôl i Wobr',
  'Retrieve & Return': 'Nôl a Dychwelyd',
  'Target & Turn': 'Targed a Throi',
  'Low-Impact Movement': 'Symudiad Effaith Isel',
  'Work Near a Distraction': 'Gweithio Ger Peth sy’n Tynnu Sylw',
  'Handler Skills': 'Sgiliau’r Triniwr',
  'Assessment Preparation': 'Paratoi ar gyfer Asesiad',

  // Support & trainer communication
  'Training Support': 'Cymorth Hyfforddi',
  'Ask a Trainer': 'Gofyn i Hyfforddwr',
  'What can we help with?': 'Gyda beth allwn ni helpu?',
  'Tell us what is happening': 'Dywedwch wrthym beth sy’n digwydd',
  'Optional video link': 'Dolen fideo ddewisol',
  'SEND TO TRAINERS': 'ANFON AT YR HYFFORDDWYR',
  'What are you struggling with?': 'Gyda beth ydych chi’n cael trafferth?',
  'Reply to trainer': 'Ateb yr hyfforddwr',
  'SEND REPLY': 'ANFON ATEB',
  'DICTATE REPLY': 'ADRODD ATEB',
  'STOP LISTENING': 'RHOI\'R GORAU I WRANDO',
  'Listening… speak your reply.': 'Yn gwrando… dywedwch eich ateb.',
  'Speech recognition is not available on this device.':
      'Nid yw adnabod lleferydd ar gael ar y ddyfais hon.',
  'Speech recognition stopped. Please try again.':
      'Daeth adnabod lleferydd i ben. Rhowch gynnig arall arni.',
  'ADD VIDEO LINK': 'YCHWANEGU DOLEN FIDEO',
  'HIDE VIDEO LINK': 'CUDDIO DOLEN FIDEO',
  'Please enter a valid http:// or https:// video link.':
      'Rhowch ddolen fideo http:// neu https:// ddilys.',
  'Request a 1-to-1': 'Gofyn am 1-i-1',
  'What would you like help with?': 'Gyda beth hoffech chi help?',
  'Preferred trainer': 'Hyfforddwr dewisol',
  'No preference': 'Dim dewis',
  'Session type': 'Math o sesiwn',
  'Online video call': 'Galwad fideo ar-lein',
  'In-person session': 'Sesiwn wyneb yn wyneb',
  'Either': 'Naill ai',
  'General availability': 'Argaeledd cyffredinol',
  'Anything the trainer should know?':
      'Unrhyw beth y dylai’r hyfforddwr ei wybod?',
  'SEND REQUEST': 'ANFON CAIS',
  '1-to-1 request sent.': 'Cais 1-i-1 wedi’i anfon.',
  'Training Diary': 'Dyddiadur Hyfforddi',
  'What did you practise?': 'Beth wnaethoch chi ymarfer?',
  'How did it go?': 'Sut aeth hi?',
  'Struggled': 'Wedi cael trafferth',
  'Getting there': 'Yn gwella',
  'Good': 'Da',
  'Nailed it!': 'Wedi’i hoelio!',
  'SAVE TO DIARY': 'CADW I’R DYDDIADUR',
  'Training logged.': 'Hyfforddiant wedi’i gofnodi.',

  // Trophy cabin
  'Trophy Cabinet': 'Cwpwrdd Tlysau',
  'Captain’s Trophy Cabin': 'Caban Tlysau’r Capten',
  'Skill Trophies': 'Tlysau Sgiliau',
  'Milestone Trophies': 'Tlysau Cerrig Milltir',
  'Special Trophies': 'Tlysau Arbennig',
  'Start Lights Trophies': 'Tlysau Goleuadau Cychwyn',
  'SOMETHING ARRIVED IN THE CAPTAIN’S CABIN!':
      'MAE RHYWBETH WEDI CYRRAEDD CABAN Y CAPTEN!',
  'TROPHY ACCEPTED!': 'TLWS WEDI’I DDERBYN!',
  'ACCEPT TROPHY': 'DERBYN TLWS',
  'Opening...': 'Yn agor...',
  'Open it later': 'Agor yn nes ymlaen',
  'Focus First Mate': 'Prif Gymar Ffocws',
  'Rapid Recall Rookie': 'Rŵci Galw’n Ôl Cyflym',
  'Tugboat Champion': 'Pencampwr y Tynfad',
  'Dead Ball Deckhand': 'Morwr y Bêl Llonydd',
  'Target Treasure': 'Trysor y Targed',
  'Sea Legs': 'Coesau Môr',
  'Steady Shipmate': 'Cyd-forwr Cadarn',
  'Ready for the Crew': 'Barod i’r Criw',
  'First Steps Aboard': 'Camau Cyntaf Aboard',
  'Seven Days Aboard': 'Saith Diwrnod Aboard',
  'Sea Legs Streak': 'Cyfres Coesau Môr',
  'Month on Deck': 'Mis ar y Dec',
  'First Lesson Logged': 'Gwers Gyntaf wedi’i Chofnodi',
  'First Skill Mastered': 'Sgil Gyntaf wedi’i Meistroli',
  'Birthday Buccaneer': 'Bucaneer Pen-blwydd',

  // Games
  'Games & Practice': 'Gemau ac Ymarfer',
  'Useful little training tools with a bit of Muttineers mischief.':
      'Offer hyfforddi bach defnyddiol gydag ychydig o ddrygioni Muttineers.',
  'Start Lights': 'Goleuadau Cychwyn',
  'Training Timer': 'Amserydd Hyfforddi',
  'Flyball Start Lights': 'Goleuadau Cychwyn Flyball',
  'Press GO. React to the GREEN light — STOP too early gives a minus time; after green gives a plus time.': 'Pwyswch GO. Ymatebwch i’r golau GWYRDD — mae STOP yn rhy gynnar yn rhoi amser minws; ar ôl gwyrdd mae’n rhoi amser plws.',
  'GO': 'EWCH',
  'STOP': 'STOP',
  'Attempts': 'Ymdrechion',
  'Rolling starts': 'Cychwyniadau rholio',
  'Current streak': 'Cyfres bresennol',
  'Early starts': 'Cychwyniadau cynnar',
  'Best': 'Gorau',
  'Average': 'Cyfartaledd',
  '🎉 ROLLING START! That’s the treasure!': '🎉 CYCHWYN RHOLIO! Dyna’r trysor!',
  '😢 Awww! -0.00 — you could hardly be closer.':
      '😢 Awww! -0.00 — prin y gallech fod yn nes.',
  '🏴‍☠️ Too keen, matey! You left before green.':
      '🏴‍☠️ Rhy awyddus, gyfaill! Gadawsoch cyn y gwyrdd.',
  '⚡ Cracking reaction!': '⚡ Ymateb gwych!',
  '👍 Good start — keep practising.': '👍 Dechrau da — daliwch ati i ymarfer.',
  '🎯 Keep your eyes on the lights and have another go.':
      '🎯 Cadwch eich llygaid ar y goleuadau a rhowch gynnig arall.',
  'Short Training Timer': 'Amserydd Hyfforddi Byr',
  'Short, happy sessions are often better than drilling the same exercise.': 'Mae sesiynau byr a hapus yn aml yn well nag ailadrodd yr un ymarfer yn ormodol.',
  'START TIMER': 'DECHRAU’R AMSERYDD',
  'STOP TIMER': 'STOPIO’R AMSERYDD',
  'Time, matey! 🦜': 'Amser, gyfaill! 🦜',
  'Finish on a good one and give your dog a break. Want to save the session to the diary?': 'Gorffennwch ar nodyn da a rhowch seibiant i’ch ci. Eisiau cadw’r sesiwn yn y dyddiadur?',
  'Not this time': 'Nid y tro hwn',
  'Skill': 'Sgil',
  'General': 'Cyffredinol',
  'End sound: PARROT': 'Sain diwedd: PAROT',
  'Training timer sound': 'Sain amserydd hyfforddi',
  '🦜 Parrot Squawk': '🦜 Sgrech Parot',
  '🔔 Ship’s Bell': '🔔 Cloch y Llong',
  '💥 Tiny Cannon': '💥 Canon Bach',
  '🔇 None': '🔇 Dim',

  // Crew & Kudos
  'The Crew': 'Y Criw',
  'A positive little Academy community. Only names, dog names and shared achievements appear here.': 'Cymuned fach gadarnhaol yr Academi. Dim ond enwau, enwau cŵn a chyflawniadau a rennir sy’n ymddangos yma.',
  'Find Crew': 'Dod o Hyd i’r Criw',
  'Requests': 'Ceisiadau',
  'Crew Feed': 'Ffrwd y Criw',
  'ADD TO MY CREW': 'YCHWANEGU AT FY NGHRIW',
  'Accept': 'Derbyn',
  'Decline': 'Gwrthod',
  'Send Kudos': 'Anfon Kudos',
  'Great work!': 'Gwaith gwych!',
  'Ahoy, superstar!': 'Ahoy, seren!',
  'Brilliant progress!': 'Cynnydd gwych!',
  'Good dog!': 'Ci da!',
  'Well deserved!': 'Haeddiannol iawn!',
  'You have a new Crew mate!': 'Mae gennych gyd-aelod newydd o’r Criw!',

  // More, appearance, links, merch and privacy
  'Follow & Support': 'Dilyn a Chefnogi',
  'Treasure Chest': 'Cist Drysor',
  'Profile & Settings': 'Proffil a Gosodiadau',
  'Feedback': 'Adborth',
  'Facebook': 'Facebook',
  'Instagram': 'Instagram',
  'TikTok': 'TikTok',
  'YouTube': 'YouTube',
  'Website': 'Gwefan',
  'Easyfundraising': 'Easyfundraising',
  'GoFundMe': 'GoFundMe',
  'Support the Crew': 'Cefnogi’r Criw',
  'Bank & payment details': 'Manylion banc a thalu',
  'Coming Soon': 'Yn Dod yn Fuan',
  'Mugs': 'Mygiau',
  'Pens': 'Pinnau',
  'Bandanas': 'Bandanas',
  'Actual trophies': 'Tlysau go iawn',
  'Stickers': 'Sticeri',
  'Magnets': 'Magnetau',
  'Keyrings': 'Modrwyau allweddi',
  'Clothing': 'Dillad',
  'Register Interest': 'Cofrestru Diddordeb',
  'Pirate backgrounds': 'Cefndiroedd môr-leidr',
  'Background shanty music': 'Cerddoriaeth shanti yn y cefndir',
  'Music volume': 'Lefel sain cerddoriaeth',
  'Trophy celebration sounds': 'Seiniau dathlu tlysau',
  'Reduced animation': 'Llai o animeiddio',
  'Allow other learners to find me':
      'Caniatáu i ddysgwyr eraill ddod o hyd i mi',
  'Share achievements with my Crew': 'Rhannu cyflawniadau gyda fy Nghriw',
  'Push notifications': 'Hysbysiadau gwthio',
  'Language / Iaith': 'Language / Iaith',
  'Set Sail on a New Adventure': 'Hwylio ar Antur Newydd',
  'REQUEST TO LEAVE': 'GOFYN I ADAEL',
  'Are you sure you want to leave this adventure?':
      'Ydych chi’n siŵr eich bod am adael yr antur hon?',
  'PAUSE INSTEAD': 'OEDI YN LLE',
  'YES — REQUEST TO LEAVE': 'YDW — GOFYN I ADAEL',
  'Your request has been sent to Captain/Admin. You can cancel it until it is processed.': 'Mae eich cais wedi’i anfon at y Capten/Gweinyddwr. Gallwch ei ganslo nes iddo gael ei brosesu.',
  'Help us improve the ship': 'Helpwch ni i wella’r llong',
  'Suggestion': 'Awgrym',
  'Problem / bug': 'Problem / nam',
  'Something confusing': 'Rhywbeth dryslyd',
  'Course idea': 'Syniad cwrs',
  'Tell us about it': 'Dywedwch wrthym amdano',
  'SEND FEEDBACK': 'ANFON ADBORTH',

  // Staff navigation and tools
  'Bridge': 'Pont',
  'Tasks': 'Tasgau',
  'Dogs': 'Cŵn',
  'Reports': 'Adroddiadau',
  'Control': 'Rheoli',
  'Captain’s Bridge': 'Pont y Capten',
  'Trainer Desk': 'Desg yr Hyfforddwr',
  'What needs attention, who needs help, and what is happening aboard.': 'Beth sydd angen sylw, pwy sydd angen help, a beth sy’n digwydd ar fwrdd.',
  'Learners': 'Dysgwyr',
  'Active dogs': 'Cŵn gweithredol',
  'Assessments': 'Asesiadau',
  'Training help': 'Cymorth hyfforddi',
  '1-to-1 requests': 'Ceisiadau 1-i-1',
  'Payment checks': 'Gwiriadau talu',
  'Restart requests': 'Ceisiadau ailgychwyn',
  'Leaving requests': 'Ceisiadau gadael',
  'Follow-ups': 'Dilyniant',
  'Captain’s Watch': 'Gwylfa’r Capten',
  'Most requested help': 'Y cymorth a ofynnir amdano fwyaf',
  'No help patterns yet.': 'Dim patrymau cymorth eto.',
  'Action Centre': 'Canolfan Weithredu',
  'One place for trainer work — claim it, answer it, close it.':
      'Un lle ar gyfer gwaith hyfforddwyr — hawliwch, atebwch, caewch.',
  'Accounts': 'Cyfrifon',
  'Assessment inbox zero! 🎉': 'Dim asesiadau yn y blwch derbyn! 🎉',
  'Training help inbox zero! 🏴‍☠️': 'Dim ceisiadau cymorth hyfforddi! 🏴‍☠️',
  'CLAIM THIS': 'HAWLIO HWN',
  'PASS': 'PASIO',
  'KEEP PRACTISING': 'PARHAU I YMARFER',
  'PASS + TROPHY': 'PASIO + TLWS',
  'Trainer feedback': 'Adborth yr hyfforddwr',
  'SAVE & NOTIFY': 'CADW A HYSBYSU',
  'Private staff note': 'Nodyn staff preifat',
  'STAFF NOTE': 'NODYN STAFF',
  'RECOMMEND SKILL': 'ARGYMELL SGIL',
  'WATCH LIST': 'RHESTR WYLIO',
  'ADD CREDIT': 'YCHWANEGU CREDYD',
  'Learners & Dogs': 'Dysgwyr a Chŵn',
  'Search dog, learner or email': 'Chwilio ci, dysgwr neu e-bost',
  'AUTHORISE 30 DAYS': 'AWDURDODI 30 DIWRNOD',
  'RESTART 30 DAYS': 'AILGYCHWYN 30 DIWRNOD',
  'PAUSE AT PERIOD END': 'OEDI AR DDIWEDD Y CYFNOD',
  'VIEW DOG': 'GWELD Y CI',
  'PAUSE ALL DOGS': 'OEDI POB CI',
  'CANCEL ALL PAUSES': 'CANSLO POB OEDI',
  'Pause all active dogs?': 'Oedi pob ci gweithredol?',
  'Each active dog will keep its current paid access until the end date, then stop instead of renewing.': 'Bydd pob ci gweithredol yn cadw ei fynediad taledig presennol tan y dyddiad gorffen, yna’n stopio yn lle adnewyddu.',
  '30 days of access authorised.': '30 diwrnod o fynediad wedi’i awdurdodi.',
  'Not enough Doubloons. Add at least 1 Doubloon first.':
      'Dim digon o Doubloons. Ychwanegwch o leiaf 1 Doubloon yn gyntaf.',
  'Pause scheduled for the end of the current paid period.':
      'Oedi wedi’i drefnu ar gyfer diwedd y cyfnod taledig presennol.',
  'Scheduled pause cancelled.': 'Yr oedi a drefnwyd wedi’i ganslo.',
  'No active dogs needed pausing.':
      'Nid oedd angen oedi unrhyw gŵn gweithredol.',
  'All active dogs have been scheduled to pause.':
      'Mae pob ci gweithredol wedi’i drefnu i oedi.',
  'No scheduled pauses to cancel.': 'Dim oedi wedi’i drefnu i’w ganslo.',
  'All scheduled pauses have been cancelled.':
      'Mae pob oedi a drefnwyd wedi’i ganslo.',
  'Pause scheduled at the end of the paid period.':
      'Oedi wedi’i drefnu ar ddiwedd y cyfnod taledig.',
  'Quarterly Academy Report': 'Adroddiad Chwarterol yr Academi',
  'Generate quarterly report': 'Cynhyrchu adroddiad chwarterol',
  'Useful numbers for trainers, committee updates, grant evidence and privacy-safe social posts.': 'Ffigurau defnyddiol ar gyfer hyfforddwyr, diweddariadau pwyllgor, tystiolaeth grant a negeseuon cymdeithasol sy’n ddiogel o ran preifatrwydd.',
  'CREATE SOCIAL SUMMARY': 'CREU CRYNODEB CYMDEITHASOL',
  'Academy Settings': 'Gosodiadau’r Academi',
  'Academy price per dog (£)': 'Pris yr Academi fesul ci (£)',
  'Access period (days)': 'Cyfnod mynediad (diwrnodau)',
  'Typical 1-to-1 guide price (£)': 'Pris canllaw arferol 1-i-1 (£)',
  'Typical 1-to-1 minutes': 'Hyd arferol 1-i-1 mewn munudau',
  '1-to-1 wording shown to learners': 'Geiriad 1-i-1 a ddangosir i ddysgwyr',
  'Payment reference suffix': 'Ôl-ddodiad cyfeirnod talu',
  'Account closure wording': 'Geiriad cau cyfrif',
  'SAVE ACADEMY SETTINGS': 'CADW GOSODIADAU’R ACADEMI',
  'Links, Bank & Support': 'Dolenni, Banc a Chefnogaeth',
  'Bank name': 'Enw’r banc',
  'Account name': 'Enw’r cyfrif',
  'Sort code': 'Cod didoli',
  'Account number': 'Rhif y cyfrif',
  'Direct debit / standing order information':
      'Gwybodaeth debyd uniongyrchol / archeb sefydlog',
  'Payment note': 'Nodyn talu',
  'SAVE LINKS & BANK DETAILS': 'CADW DOLENNI A MANYLION BANC',
  'Captain Notices': 'Hysbysiadau’r Capten',
  'Notice title': 'Teitl yr hysbysiad',
  'Message': 'Neges',
  'Priority': 'Blaenoriaeth',
  'PUBLISH NOTICE': 'CYHOEDDI HYSBYSIAD',
  'Translate to Welsh': 'Cyfieithu i’r Gymraeg',
  'Translate to English': 'Cyfieithu i’r Saesneg',
  'Auto translated — please review':
      'Wedi’i gyfieithu’n awtomatig — gwiriwch os gwelwch yn dda',
  'Welsh checked': 'Cymraeg wedi’i wirio',
  'Preview notice': 'Rhagolwg o’r hysbysiad',
  'English': 'Saesneg',
  'Welsh': 'Cymraeg',
  'Celebration Calendar': 'Calendr Dathliadau',
  'Academy Music Library': 'Llyfrgell Gerddoriaeth yr Academi',
  'Track title': 'Teitl y trac',
  'Public MP3 URL': 'URL MP3 cyhoeddus',
  'ADD TRACK': 'YCHWANEGU TRAC',
  'Feature Switches': 'Switshis Nodweddion',
  'Manage Crew & Staff': 'Rheoli’r Criw a’r Staff',
  'Course Editor': 'Golygydd y Cwrs',
  'Captain’s Log': 'Log y Capten',
  'System Health': 'Iechyd y System',
  'Preview as Learner': 'Rhagolwg fel Dysgwr',
  'LEARNER PREVIEW MODE': 'MODD RHAGOLWG DYSGWR',
  'Return to Captain Mode': 'Dychwelyd i Fodd y Capten',

  // Automatic celebration messages
  'Happy New Year!': 'Blwyddyn Newydd Dda!',
  'A fresh year, a fresh voyage and plenty of good training ahead.':
      'Blwyddyn newydd, mordaith newydd a digon o hyfforddiant da o’n blaenau.',
  'Dydd Gŵyl Dewi Hapus!': 'Dydd Gŵyl Dewi Hapus!',
  'Happy St David’s Day from the Menai Muttineers crew.':
      'Dydd Gŵyl Dewi Hapus gan griw Menai Muttineers.',
  'National Pet Day': 'Diwrnod Cenedlaethol Anifeiliaid Anwes',
  'Give your four-legged shipmate an extra bit of fuss today.':
      'Rhowch ychydig o sylw ychwanegol i’ch cyd-forwr pedair coes heddiw.',
  'National Rum Day': 'Diwrnod Cenedlaethol Rym',
  'A suitably pirate-themed day. The dogs are on water, mind!':
      'Diwrnod addas iawn i fôr-ladron. Dŵr i’r cŵn, cofiwch!',
  'National Dog Day': 'Diwrnod Cenedlaethol y Ci',
  'Today is all about the dogs — as if every Academy day wasn’t already!': 'Heddiw mae’r cyfan am y cŵn — fel pe na bai pob diwrnod yn yr Academi eisoes!',
  'Talk Like a Pirate Day': 'Diwrnod Siarad fel Môr-leidr',
  'Arrr! Today the Academy officially permits excessive pirate nonsense.': 'Arrr! Heddiw mae’r Academi yn caniatáu tipyn gormod o lol môr-leidr yn swyddogol.',
  'World Animal Day': 'Diwrnod Anifeiliaid y Byd',
  'A good day to celebrate every animal that makes life better.':
      'Diwrnod da i ddathlu pob anifail sy’n gwneud bywyd yn well.',
  'Merry Christmas!': 'Nadolig Llawen!',
  'Merry Christmas from the whole Menai Muttineers crew.':
      'Nadolig Llawen gan holl griw Menai Muttineers.',
  'Boxing Day': 'Gŵyl San Steffan',
  'A day for leftovers, muddy walks and perhaps a very short training game.': 'Diwrnod i fwyd dros ben, teithiau cerdded mwdlyd ac efallai gêm hyfforddi fer iawn.',
  'Good Friday': 'Dydd Gwener y Groglith',
  'Wishing the crew a peaceful bank holiday weekend.':
      'Gan ddymuno penwythnos gŵyl banc heddychlon i’r criw.',
  'Easter Monday': 'Dydd Llun y Pasg',
  'A bank holiday Monday — a handy day for a little dog training adventure.': 'Dydd Llun gŵyl banc — diwrnod da ar gyfer antur hyfforddi fach gyda’r ci.',
  'Early May Bank Holiday': 'Gŵyl Banc Dechrau Mai',
  'A bank holiday voyage — enjoy the extra day with your dog.':
      'Mordaith gŵyl banc — mwynhewch y diwrnod ychwanegol gyda’ch ci.',
  'Spring Bank Holiday': 'Gŵyl Banc y Gwanwyn',
  'Enjoy the bank holiday, crew. Keep any training short and fun.': 'Mwynhewch y gŵyl banc, griw. Cadwch unrhyw hyfforddiant yn fyr ac yn hwyl.',
  'Summer Bank Holiday': 'Gŵyl Banc yr Haf',
  'A summer bank holiday from the Academy crew.':
      'Cyfarchion gŵyl banc yr haf gan griw’r Academi.',

  // Additional learner and staff interface text
  'Activate Academy': 'Gweithredu’r Academi',
  'Activation code': 'Cod gweithredu',
  'ADD': 'YCHWANEGU',
  'ADD ANNUAL DATE': 'YCHWANEGU DYDDIAD BLYNYDDOL',
  'ADD ANOTHER DOG': 'YCHWANEGU CI ARALL',
  'ADD SAVED REPLY': 'YCHWANEGU ATEB WEDI’I GADW',
  'ALLOW OTHER LEARNERS TO FIND ME':
      'CANIATÁU I DDYSGWYR ERAILL DDOD O HYD I MI',
  'APPROVE': 'CYMERADWYO',
  'Academy Price, Access & Wording': 'Pris, Mynediad a Geiriad yr Academi',
  'Academy settings saved. Everyone will see the new values.': 'Gosodiadau’r Academi wedi’u cadw. Bydd pawb yn gweld y gwerthoedd newydd.',
  'Account removed from the Academy.': 'Cyfrif wedi’i dynnu o’r Academi.',
  'Account/payment controls are Admin/Captain only.':
      'Dim ond y Gweinyddwr/Capten all ddefnyddio rheolaethau cyfrif a thalu.',
  'Add Academy Credit': 'Ychwanegu Credyd yr Academi',
  'Add Academy credit': 'Ychwanegu credyd yr Academi',
  'Add another Academy dog': 'Ychwanegu ci Academi arall',
  'Add dog': 'Ychwanegu ci',
  'Ahoy Test Learner & Test Dog!': 'Ahoy Ddysgwr Prawf a Chi Prawf!',
  'Amount £': 'Swm £',
  'Android push works when the Firebase push service is enabled; the in-app bell always works.': 'Mae hysbysiadau gwthio Android yn gweithio pan fydd gwasanaeth gwthio Firebase wedi’i alluogi; mae’r gloch yn yr ap bob amser yn gweithio.',
  'App version': 'Fersiwn yr ap',
  'Appearance & Sound': 'Golwg a Sain',
  'Ask a General Question': 'Gofyn Cwestiwn Cyffredinol',
  'Ask for help, request paid 1-to-1 training or keep a quick diary.': 'Gofynnwch am help, archebwch hyfforddiant 1-i-1 â thâl neu cadwch ddyddiadur cyflym.',
  'Assessment sent to the trainers.': 'Asesiad wedi’i anfon at yr hyfforddwyr.',
  'Assessment volume and pass rate help us spot where the course or assessment may need improving.': 'Mae nifer yr asesiadau a’r gyfradd basio yn ein helpu i weld ble gallai’r cwrs neu’r asesiad fod angen gwella.',
  'Automatic translation is not ready yet. Deploy the V1.4 Firebase Functions and enable Cloud Translation, or type the Welsh version manually.': 'Nid yw cyfieithu awtomatig yn barod eto. Defnyddiwch Firebase Functions V1.4 a galluogwch Cloud Translation, neu teipiwch y fersiwn Gymraeg â llaw.',
  'Automatic translation is not ready yet. You can still type both versions manually.': 'Nid yw cyfieithu awtomatig yn barod eto. Gallwch deipio’r ddwy fersiwn â llaw.',
  'Back': 'Yn ôl',
  'Background style': 'Arddull y cefndir',
  'Bank Transfer / Standing Order': 'Trosglwyddiad Banc / Archeb Sefydlog',
  'Best guess is fine': 'Mae amcangyfrif gorau yn iawn',
  'Built-in UK/Wales and fun dates are automatic. Add your own annual dates here.': 'Mae dyddiadau adeiledig y DU/Cymru a dyddiadau hwyliog yn awtomatig. Ychwanegwch eich dyddiadau blynyddol eich hun yma.',
  'CANCEL LEAVING REQUEST': 'CANSLO’R CAIS I ADAEL',
  'CHECK BACK IN 7 DAYS': 'GWIRIO ETO MEWN 7 DIWRNOD',
  'COMING SOON — tell us what treasure you’d actually like to buy.':
      'YN DOD YN FUAN — dywedwch wrthym pa drysor yr hoffech ei brynu.',
  'CONFIRM': 'CADARNHAU',
  'CONFIRM + CODE': 'CADARNHAU + COD',
  'CONTINUE': 'PARHAU',
  'COPY PRIVACY-SAFE SOCIAL SUMMARY': 'COPÏO CRYNODEB CYMDEITHASOL DIOGEL',
  'Cancel and return to start': 'Canslo a dychwelyd i’r dechrau',
  'Change each visit': 'Newid bob ymweliad',
  'Change individual lesson video links without rebuilding the app.':
      'Newidiwch ddolenni fideo gwersi unigol heb ailadeiladu’r ap.',
  'Change prices, access length and learner wording without rebuilding the app.':
      'Newidiwch brisiau, hyd mynediad a geiriad dysgwyr heb ailadeiladu’r ap.',
  'Change the timer sound in Settings: Parrot Squawk, Ship’s Bell, Tiny Cannon or None.': 'Newidiwch sain yr amserydd yn y Gosodiadau: Sgrech Parot, Cloch y Llong, Canon Bach neu Dim.',
  'Choose a Key Skill. Work through the short lessons at your own pace, then request assessment when you are ready.': 'Dewiswch Sgil Allweddol. Gweithiwch drwy’r gwersi byr ar eich cyflymder eich hun, yna gofynnwch am asesiad pan fyddwch yn barod.',
  'Coming soon': 'Yn dod yn fuan',
  'Connected — this screen is reading live Firestore data.':
      'Wedi cysylltu — mae’r sgrin hon yn darllen data Firestore byw.',
  'Control Room': 'Ystafell Reoli',
  'Create your login': 'Creu eich manylion mewngofnodi',
  'Crew Privacy': 'Preifatrwydd y Criw',
  'DONE': 'WEDI GORFFEN',
  'Date is estimated': 'Amcangyfrif yw’r dyddiad',
  'Diary': 'Dyddiadur',
  'Due renewals / pauses': 'Adnewyddiadau / oedi sy’n ddyledus',
  'Each dog has its own paid Academy adventure. The new dog will wait for Admin to activate it.': 'Mae gan bob ci ei antur Academi â thâl ei hun. Bydd y ci newydd yn aros i’r Gweinyddwr ei weithredu.',
  'Enter the 6-character Academy code issued after your payment was confirmed.':
      'Rhowch y cod Academi 6 nod a roddwyd ar ôl cadarnhau eich taliad.',
  'Favourite scene': 'Hoff olygfa',
  'Feed': 'Ffrwd',
  'Final check': 'Gwiriad terfynol',
  'Firebase connection': 'Cysylltiad Firebase',
  'First payment confirmed': 'Taliad cyntaf wedi’i gadarnhau',
  'Follow the Crew': 'Dilyn y Criw',
  'Follow-up / homework': 'Dilyniant / gwaith cartref',
  'For a question about a specific lesson, use Need Help directly under that video — it gives the trainer more context.': 'Ar gyfer cwestiwn am wers benodol, defnyddiwch Angen Cymorth o dan y fideo hwnnw — mae’n rhoi mwy o gyd-destun i’r hyfforddwr.',
  'Help': 'Cymorth',
  'Help request sent to the trainers.':
      'Cais cymorth wedi’i anfon at yr hyfforddwyr.',
  'I understand what the trainer is looking for.':
      'Rwy’n deall beth mae’r hyfforddwr yn chwilio amdano.',
  'Idea / action / follow-up': 'Syniad / gweithred / dilyniant',
  'Ideas, jobs and next-quarter actions live in Control.':
      'Mae syniadau, tasgau a gweithredoedd y chwarter nesaf yn byw yn Rheoli.',
  'If you need a break, pause a dog from Payments & Access. If you want to leave completely, you can ask us to close your Academy account.': 'Os oes angen seibiant arnoch, oediwch gi o Taliadau a Mynediad. Os hoffech adael yn llwyr, gallwch ofyn i ni gau eich cyfrif Academi.',
  'If you only want a break from payments, cancel this and pause your dog instead.': 'Os mai seibiant o daliadau sydd ei angen arnoch, canslwch hwn ac oediwch eich ci yn lle hynny.',
  'In-app notifications work on the normal setup. True background push and Firebase photo storage use optional Firebase services described in the V1.4 setup guide.': 'Mae hysbysiadau yn yr ap yn gweithio gyda’r gosodiad arferol. Mae gwthio cefndir a storio lluniau Firebase yn defnyddio gwasanaethau dewisol a ddisgrifir yng nghanllaw gosod V1.4.',
  'Issue the first activation code for brand-new learners.':
      'Rhowch y cod gweithredu cyntaf i ddysgwyr newydd sbon.',
  'I’ve made a payment': 'Rwyf wedi gwneud taliad',
  'JOIN': 'Ymuno',
  'KEEP ABOARD': 'AROS ABOARD',
  'KEEP ADVENTURE GOING': 'CADW’R ANTUR I FYND',
  'Keep up with the Muttineers and help support the Academy.':
      'Cadwch mewn cysylltiad â’r Muttineers a helpwch i gefnogi’r Academi.',
  'LOG TRAINING': 'COFNODI HYFFORDDIANT',
  'Learner Feedback Centre': 'Canolfan Adborth Dysgwyr',
  'Legacy / initial access': 'Mynediad etifeddol / cychwynnol',
  'Legacy dog moved onto a fresh V1.4 Academy voyage.':
      'Ci etifeddol wedi’i symud i fordaith Academi V1.4 newydd.',
  'Lesson progress': 'Cynnydd gwersi',
  'Let other learners find me': 'Gadael i ddysgwyr eraill ddod o hyd i mi',
  'Light pirate scenes behind the app. Turn off for a plain view.':
      'Golygfeydd môr-leidr ysgafn y tu ôl i’r ap. Diffoddwch am olwg syml.',
  'Link coming soon': 'Dolen yn dod yn fuan',
  'Links, Fundraising & Bank Details': 'Dolenni, Codi Arian a Manylion Banc',
  'Loops between Academy tracks. Off by default.':
      'Yn cylchdroi rhwng traciau’r Academi. Wedi’i ddiffodd yn ddiofyn.',
  'Manage': 'Rheoli',
  'Mark all read': 'Marcio pob un wedi’i ddarllen',
  'Meet link if online': 'Dolen Meet os ar-lein',
  'Menai Muttineers Treasure Chest': 'Cist Drysor Menai Muttineers',
  'Minutes': 'Munudau',
  'More From the Academy': 'Mwy o’r Academi',
  'My 1-to-1 Requests': 'Fy Ngheisiadau 1-i-1',
  'My Academy Account': 'Fy Nghyfrif Academi',
  'My Help Conversations': 'Fy Sgyrsiau Cymorth',
  'My Photo': 'Fy Llun',
  'My dog can do this in a familiar environment.':
      'Gall fy nghi wneud hyn mewn amgylchedd cyfarwydd.',
  'My dog is happy and confident doing it.':
      'Mae fy nghi yn hapus ac yn hyderus wrth wneud hyn.',
  'My favourite': 'Fy hoff un',
  'No 1-to-1 requests yet.': 'Dim ceisiadau 1-i-1 eto.',
  'No account activity recorded yet.':
      'Dim gweithgarwch cyfrif wedi’i gofnodi eto.',
  'No account removal requests.': 'Dim ceisiadau tynnu cyfrif.',
  'No assessments submitted in this quarter.':
      'Dim asesiadau wedi’u cyflwyno yn y chwarter hwn.',
  'No audit entries yet.': 'Dim cofnodion archwilio eto.',
  'No dog access periods are waiting to be processed.':
      'Dim cyfnodau mynediad cŵn yn aros i gael eu prosesu.',
  'No dog profile found. Please contact the Captain.':
      'Ni chanfuwyd proffil ci. Cysylltwch â’r Capten.',
  'No feedback yet.': 'Dim adborth eto.',
  'No help-request trends in this quarter.':
      'Dim tueddiadau ceisiadau cymorth yn y chwarter hwn.',
  'No messages in the ship’s postbox yet.':
      'Dim negeseuon ym mlwch post y llong eto.',
  'No new Crew requests.': 'Dim ceisiadau Criw newydd.',
  'No other discoverable learners yet.':
      'Dim dysgwyr eraill i’w darganfod eto.',
  'No payments waiting for confirmation.': 'Dim taliadau yn aros am gadarnhad.',
  'No private notes.': 'Dim nodiadau preifat.',
  'No requests for this dog yet.': 'Dim ceisiadau ar gyfer y ci hwn eto.',
  'No restart requests.': 'Dim ceisiadau ailgychwyn.',
  'No trainer follow-ups waiting. 🎉': 'Dim dilyniannau hyfforddwr yn aros. 🎉',
  'No training help conversations yet.': 'Dim sgyrsiau cymorth hyfforddi eto.',
  'Note': 'Nodyn',
  'Notice published in English and Welsh.':
      'Hysbysiad wedi’i gyhoeddi yn Saesneg ac yn Gymraeg.',
  'Official training tools stay locked while this dog is paused. Restart the adventure or use the 1-to-1 button on the anchored screen.': 'Mae offer hyfforddi swyddogol yn aros wedi’u cloi tra bo’r ci wedi’i oedi. Ailddechreuwch yr antur neu defnyddiwch y botwm 1-i-1 ar y sgrin angori.',
  'Once Admin confirms payment, you’ll receive your 6-character activation code. You are already logged in — there is no need to use Forgot Password or sign in again.': 'Unwaith y bydd y Gweinyddwr yn cadarnhau’r taliad, byddwch yn derbyn eich cod gweithredu 6 nod. Rydych eisoes wedi mewngofnodi — nid oes angen defnyddio Ailosod Cyfrinair na mewngofnodi eto.',
  'Open training video': 'Agor fideo hyfforddi',
  'Open video': 'Agor fideo',
  'Optional reason / message to Admin':
      'Rheswm / neges ddewisol i’r Gweinyddwr',
  'Pay outside the app using your normal bank. The app never handles your bank card or account login.': 'Talwch y tu allan i’r ap gan ddefnyddio eich banc arferol. Nid yw’r ap byth yn trin eich cerdyn banc na manylion mewngofnodi’r cyfrif.',
  'Payment confirmations': 'Cadarnhadau talu',
  'Payment notice sent to Admin.':
      'Hysbysiad talu wedi’i anfon at y Gweinyddwr.',
  'Payment notice sent. Admin will confirm it after checking the bank.': 'Hysbysiad talu wedi’i anfon. Bydd y Gweinyddwr yn ei gadarnhau ar ôl gwirio’r banc.',
  'Payments happen outside the app. The Academy does not collect your bank or card details.': 'Mae taliadau’n digwydd y tu allan i’r ap. Nid yw’r Academi yn casglu manylion eich banc na’ch cerdyn.',
  'Permanent account removal': 'Tynnu cyfrif yn barhaol',
  'Photo upload is currently disabled by Admin. This keeps the Academy on the low-cost setup until cloud photo storage is enabled.': 'Mae uwchlwytho lluniau wedi’i analluogi gan y Gweinyddwr ar hyn o bryd. Mae hyn yn cadw’r Academi ar y gosodiad cost isel nes galluogi storio lluniau yn y cwmwl.',
  'Photo upload is not available yet. Admin may need to enable Firebase Storage.': 'Nid yw uwchlwytho lluniau ar gael eto. Efallai y bydd angen i’r Gweinyddwr alluogi Firebase Storage.',
  'Please add an English title and message before publishing.':
      'Ychwanegwch deitl a neges Saesneg cyn cyhoeddi.',
  'Please add your assessment video link.':
      'Ychwanegwch ddolen eich fideo asesu.',
  'Please check the price and day/minute values.':
      'Gwiriwch y pris a gwerthoedd y diwrnodau/munudau.',
  'Please complete the Ready for Assessment checks first.':
      'Cwblhewch y gwiriadau Barod am Asesiad yn gyntaf.',
  'Practised or Confident counts as completed. Need Help sends a proper message to the trainers.': 'Mae Ymarferwyd neu Hyderus yn cyfrif fel wedi’i gwblhau. Mae Angen Cymorth yn anfon neges iawn at yr hyfforddwyr.',
  'Preview state': 'Statws rhagolwg',
  'Private staff notes': 'Nodiadau staff preifat',
  'Profile Photos': 'Lluniau Proffil',
  'Profile photo uploads': 'Uwchlwytho lluniau proffil',
  'Proposed/booked date & time': 'Dyddiad ac amser arfaethedig/archebedig',
  'Push & photo note': 'Nodyn gwthio a lluniau',
  'Quarter': 'Chwarter',
  'Quarterly numbers are operational Academy records. They are useful for committee/impact reporting but are not a replacement for formal club accounts.': 'Mae ffigurau chwarterol yn gofnodion gweithredol yr Academi. Maent yn ddefnyddiol ar gyfer adrodd i’r pwyllgor ac am effaith, ond nid ydynt yn lle cyfrifon ffurfiol y clwb.',
  'Quarterly social summary copied.':
      'Crynodeb cymdeithasol chwarterol wedi’i gopïo.',
  'Question sent to the trainers.': 'Cwestiwn wedi’i anfon at yr hyfforddwyr.',
  'Quoted price £': 'Pris a ddyfynnwyd £',
  'REGISTER MY INTEREST': 'COFRESTRU FY NIDDORDEB',
  'REQUEST SESSION': 'GOFYN AM SESIWN',
  'Recent important account and Academy changes.':
      'Newidiadau pwysig diweddar i gyfrifon a’r Academi.',
  'Recommended next skill': 'Sgil nesaf a argymhellir',
  'Recommended skill sent to the learner.':
      'Sgil a argymhellir wedi’i anfon at y dysgwr.',
  'Reply text': 'Testun yr ateb',
  'Reply to learner': 'Ateb y dysgwr',
  'Requires Firebase Cloud Storage / Blaze plan. Leave OFF until storage is set up.': 'Mae angen Firebase Cloud Storage / cynllun Blaze. Gadewch hwn WEDI’I DDIFFODD nes bod y storfa wedi’i sefydlu.',
  'Resolve': 'Datrys',
  'Reusable starting points that trainers can edit before sending.': 'Mannau cychwyn y gellir eu hailddefnyddio ac y gall hyfforddwyr eu golygu cyn anfon.',
  'SAVE LINKS & PAYMENT DETAILS': 'CADW DOLENNI A MANYLION TALU',
  'SEND KUDOS': 'ANFON KUDOS',
  'SEND MISSION': 'ANFON CENHADAETH',
  'SET SAIL ON A NEW ADVENTURE': 'HWYLIO AR ANTUR NEWYDD',
  'START V1.4 ACCESS': 'DECHRAU MYNEDIAD V1.4',
  'STAY ABOARD': 'AROS ABOARD',
  'Saved Trainer Replies': 'Atebion Hyfforddwr wedi’u Cadw',
  'Send this activation code to the learner:':
      'Anfonwch y cod gweithredu hwn at y dysgwr:',
  'Send to Trainers': 'Anfon at yr Hyfforddwyr',
  'Session length': 'Hyd y sesiwn',
  'Set Sail on a New Adventure?': 'Hwylio ar Antur Newydd?',
  'Set Sail — Account Removal Requests': 'Hwylio — Ceisiadau Tynnu Cyfrif',
  'Short name': 'Enw byr',
  'Show Treasure Chest': 'Dangos y Gist Drysor',
  'Skill performance': 'Perfformiad sgiliau',
  'Staff Audit Trail': 'Trywydd Archwilio Staff',
  'Standing order / Direct Debit information':
      'Gwybodaeth Archeb Sefydlog / Debyd Uniongyrchol',
  'TEST DECK — this is a safe preview. It does not change your staff permissions or real learner data.': 'DEC PRAWF — rhagolwg diogel yw hwn. Nid yw’n newid eich caniatâd staff na data dysgwyr go iawn.',
  'Tap the bell at the top to open your postbox.':
      'Tapiwch y gloch ar y brig i agor eich blwch post.',
  'Tell the trainers what is happening. This creates a conversation linked to this exact lesson.': 'Dywedwch wrth yr hyfforddwyr beth sy’n digwydd. Mae hyn yn creu sgwrs sy’n gysylltiedig â’r wers benodol hon.',
  'Tell us about you': 'Dywedwch wrthym amdanoch chi',
  'Tell us about your dog': 'Dywedwch wrthym am eich ci',
  'Test active, paused, awaiting and graduated views without changing your staff role.': 'Profwch olygfeydd gweithredol, wedi’u hoedi, yn aros ac wedi graddio heb newid eich rôl staff.',
  'Test the learner experience, edit the course and keep the Academy running without rebuilding the APK.': 'Profwch brofiad y dysgwr, golygwch y cwrs a chadwch yr Academi i redeg heb ailadeiladu’r APK.',
  'Thank you — feedback sent to the Captain.':
      'Diolch — adborth wedi’i anfon at y Capten.',
  'The deletion service is not ready yet. Set up V1.4 Firebase Functions using the included guide, then try again.': 'Nid yw’r gwasanaeth dileu yn barod eto. Sefydlwch Firebase Functions V1.4 gan ddefnyddio’r canllaw, yna rhowch gynnig arall.',
  'The first Academy access charge has been applied at the current Admin-set price. Any extra amount has been added as Academy credit.': 'Mae’r tâl mynediad Academi cyntaf wedi’i gymhwyso ar y pris presennol a osodwyd gan y Gweinyddwr. Mae unrhyw swm ychwanegol wedi’i ychwanegu fel credyd Academi.',
  'The two Gentle Tide tracks are built in. Add more by public MP3 URL without rebuilding.': 'Mae’r ddau drac Gentle Tide wedi’u cynnwys. Ychwanegwch fwy drwy URL MP3 cyhoeddus heb ailadeiladu.',
  'They only see your display name and dog name.':
      'Dim ond eich enw arddangos ac enw’r ci maent yn eu gweld.',
  'Trainer notes': 'Nodiadau’r hyfforddwr',
  'Training Help': 'Cymorth Hyfforddi',
  'Training intelligence': 'Deallusrwydd hyfforddi',
  'Use gentler movement and transitions.':
      'Defnyddiwch symudiadau a thrawsnewidiadau mwy ysgafn.',
  'Use this as a gentle check-in list, not a performance score.':
      'Defnyddiwch hwn fel rhestr wirio garedig, nid fel sgôr perfformiad.',
  'Uses Academy credit for a fresh voyage at the current Admin-set price and access period.': 'Yn defnyddio credyd Academi ar gyfer mordaith newydd ar y pris a’r cyfnod mynediad presennol a osodwyd gan y Gweinyddwr.',
  'Video': 'Fideo',
  'We have practised it on several occasions.':
      'Rydym wedi’i ymarfer ar sawl achlysur.',
  'When you and your Crew earn shared achievements, they’ll appear here.': 'Pan fyddwch chi a’ch Criw yn ennill cyflawniadau a rennir, byddant yn ymddangos yma.',
  'Write in English, auto-translate to Welsh, tweak it, preview both, then publish.': 'Ysgrifennwch yn Saesneg, cyfieithwch yn awtomatig i’r Gymraeg, addaswch, rhagolygwch y ddwy fersiwn, yna cyhoeddwch.',
  'YES — REMOVE ACCOUNT': 'YDW — TYNU’R CYFRIF',
  'You are currently hidden from Crew search.':
      'Rydych wedi’ch cuddio o chwiliad y Criw ar hyn o bryd.',
  'You can add more dogs later. Each registered dog has its own Academy adventure.': 'Gallwch ychwanegu mwy o gŵn yn ddiweddarach. Mae gan bob ci cofrestredig ei antur Academi ei hun.',
  'YouTube / video URL': 'URL YouTube / fideo',
  'Your payment reference:': 'Eich cyfeirnod talu:',
  'Your reference:': 'Eich cyfeirnod:',
  '♪ Skip music track': '♪ Neidio trac cerddoriaeth',
  '🔥 THREE ROLLING STARTS IN A ROW — Triple Broadside!':
      '🔥 TRI CHYCHWYN RHOLIO YN OLYNOL — Triple Broadside!',
  '🧪 Learner Preview Mode': '🧪 Modd Rhagolwg Dysgwr',

  'New Year Bank Holiday': 'Gŵyl Banc y Flwyddyn Newydd',
  'Enjoy the New Year bank holiday with your dog.':
      'Mwynhewch ŵyl banc y Flwyddyn Newydd gyda’ch ci.',
  'Christmas Bank Holiday': 'Gŵyl Banc y Nadolig',
  'An extra Christmas bank holiday day for the crew.':
      'Diwrnod gŵyl banc Nadolig ychwanegol i’r criw.',
  'Boxing Day Bank Holiday': 'Gŵyl Banc San Steffan',
  'Enjoy the Boxing Day bank holiday, crew.':
      'Mwynhewch ŵyl banc San Steffan, griw.',
  'Follow-up:': 'Dilyniant:',

  // V1.4 — Doubloons, complete Welsh coverage and Pirate Fun
  '1 Doubloon (£5) gives one dog 30 days of Academy access.':
      'Mae 1 Doubloon (£5) yn rhoi 30 diwrnod o fynediad Academi i un ci.',
  '1 Doubloon = £5 = 30 days access for one dog.':
      '1 Doubloon = £5 = 30 diwrnod o fynediad i un ci.',
  '1 Doubloon = £5 = 30 days of Academy access for one dog.':
      '1 Doubloon = £5 = 30 diwrnod o fynediad Academi i un ci.',
  'A rolling start in this practice game means your reaction is from +0.000 to +0.004 seconds. The display shows two decimals, while the app keeps thousandths internally. A tiny early start can therefore show -0.00 — painfully close!': 'Yn y gêm ymarfer hon, mae cychwyn rholio yn golygu ymateb rhwng +0.000 a +0.004 eiliad. Mae’r sgrin yn dangos dau le degol, ond mae’r ap yn cadw milfedau yn fewnol. Felly gall cychwyn ychydig yn gynnar iawn ddangos -0.00 — mor agos!',
  'ACCEPT': 'DERBYN',
  'ADJUST DOUBLOONS': 'ADDASU DOUBLOONS',
  'Academy Access & Wording': 'Mynediad a Geiriad yr Academi',
  'Academy Doubloons': 'Doubloons yr Academi',
  'Academy role': 'Rôl yr Academi',
  'Add Doubloons': 'Ychwanegu Doubloons',
  'Adjust Doubloons': 'Addasu Doubloons',
  'Admin will use 1 available Doubloon to start another 30 days of access.': 'Bydd y Gweinyddwr yn defnyddio 1 Doubloon sydd ar gael i ddechrau 30 diwrnod arall o fynediad.',
  'COPY': 'COPÏO',
  'COPY NAME': 'COPÏO’R ENW',
  'Doubloon History': 'Hanes Doubloons',
  'Doubloon access is fixed at £5 / 30 days. Edit the other learner wording and 1-to-1 guide here.': 'Mae mynediad Doubloon wedi’i osod ar £5 / 30 diwrnod. Golygwch y geiriad arall i ddysgwyr a’r canllaw 1-i-1 yma.',
  'Doubloon and payment controls are Admin/Captain only.':
      'Dim ond y Gweinyddwr neu’r Capten all reoli Doubloons a thaliadau.',
  'Doubloons appear here as soon as Admin confirms or adjusts your balance.': 'Bydd Doubloons yn ymddangos yma cyn gynted ag y bydd y Gweinyddwr yn cadarnhau neu’n addasu eich balans.',
  'English and Welsh use the Academy translation service. Pirate Talk is deliberately silly and is only for fun.': 'Mae Saesneg a Chymraeg yn defnyddio gwasanaeth cyfieithu’r Academi. Mae Iaith Môr-ladron yn fwriadol wirion ac ar gyfer hwyl yn unig.',
  'English/Welsh translation is not ready yet. The Captain may need to deploy the V1.4 Firebase Functions.': 'Nid yw’r cyfieithu Saesneg/Cymraeg yn barod eto. Efallai y bydd angen i’r Capten ddefnyddio Firebase Functions V1.4.',
  'Enter only the three letters below. You do not need to type your full name.': 'Rhowch y tri llythyren isod yn unig. Nid oes angen teipio eich enw llawn.',
  'First letter of first name': 'Llythyren gyntaf yr enw cyntaf',
  'From': 'O',
  'Just for laughs — this never changes your real Academy name or profile.': 'Dim ond am hwyl — nid yw hyn byth yn newid eich enw na’ch proffil go iawn yn yr Academi.',
  'Last letter of last name': 'Llythyren olaf y cyfenw',
  'Number of Doubloons': 'Nifer y Doubloons',
  'One Doubloon is £5 and gives one dog 30 days of Academy access.':
      'Mae un Doubloon yn £5 ac yn rhoi 30 diwrnod o fynediad Academi i un ci.',
  'People Manager': 'Rheoli Pobl',
  'Pirate Fun': 'Hwyl Môr-ladron',
  'Please check the 1-to-1 price and minute values.':
      'Gwiriwch y pris 1-i-1 a nifer y munudau.',
  'RANDOM NAME': 'ENW AR HAP',
  'REVEAL MY PIRATE NAME': 'DANGOS FY ENW MÔR-LEIDR',
  'That would take the Doubloon balance below zero.':
      'Byddai hynny’n mynd â balans y Doubloons o dan sero.',
  'The first £5 payment has opened the first 30-day voyage. Any extra full or part balance has been added as Doubloons.': 'Mae’r taliad cyntaf o £5 wedi agor y fordaith gyntaf o 30 diwrnod. Mae unrhyw falans ychwanegol, llawn neu rannol, wedi’i ychwanegu fel Doubloons.',
  'Third letter of first name': 'Trydedd lythyren yr enw cyntaf',
  'To': 'I',
  'Type something to translate': 'Teipiwch rywbeth i’w gyfieithu',
  'Uses 1 Doubloon for a fresh 30-day voyage.':
      'Yn defnyddio 1 Doubloon ar gyfer mordaith newydd o 30 diwrnod.',
  'V1.4.0+10 • Android + Web': 'V1.4.0+10 • Android + Gwe',
  'Welcome aboard, matey! For absolutely no official reason, ye shall be known as:': 'Croeso ar fwrdd, gyfaill! Am ddim rheswm swyddogol o gwbl, dyma dy enw môr-leidr:',
  '⚓  CAPTAIN’S TROPHY CABIN  ⚓': '⚓  CABAN TLYSAU’R CAPTEN  ⚓',
  '⚓ Pause scheduled. No new Doubloon will be used when this paid voyage ends.': '⚓ Mae’r saib wedi’i drefnu. Ni fydd Doubloon newydd yn cael ei ddefnyddio pan ddaw’r fordaith daledig hon i ben.',
  '🏴‍☠️ Pirate Name Generator': '🏴‍☠️ Cynhyrchydd Enwau Môr-ladron',
  '🦜 English / Welsh / Pirate Translator':
      '🦜 Cyfieithydd Saesneg / Cymraeg / Môr-ladron',
  '🪙 Academy access: 1 Doubloon = £5 = 30 days for one dog. This is fixed in V1.4.': '🪙 Mynediad yr Academi: 1 Doubloon = £5 = 30 diwrnod i un ci. Mae hyn wedi’i osod yn V1.4.',
  'Pirate Talk': 'Iaith Môr-ladron',
  'Swap languages': 'Cyfnewid ieithoedd',
  'Translating...': 'Yn cyfieithu...',
  'TRANSLATE': 'CYFIEITHU',
  'A special Academy trophy for the dog’s birthday.':
      'Tlws Academi arbennig ar gyfer pen-blwydd y ci.',
  'Add a little more pace while keeping the dog balanced and confident.': 'Ychwanegwch ychydig mwy o gyflymder gan gadw’r ci yn gytbwys ac yn hyderus.',
  'Add controlled forward movement towards the target.':
      'Ychwanegwch symudiad rheoledig ymlaen tuag at y targed.',
  'Add excitement and speed with a safe restrained release.':
      'Ychwanegwch gyffro a chyflymder gyda rhyddhad diogel o afael.',
  'Brave Enough to Be Judged': 'Digon Dewr i Gael ei Asesu',
  'Bring the foundation skills together before applying for an in-person beginners course.': 'Dewch â’r sgiliau sylfaen at ei gilydd cyn gwneud cais am gwrs dechreuwyr wyneb yn wyneb.',
  'Bring the whole recall together with speed and a useful finish.': 'Dewch â’r adalw cyfan at ei gilydd gyda chyflymder a gorffeniad defnyddiol.',
  'Build a dog that chooses you, enjoys working with you and can switch into training mode happily.': 'Adeiladwch gi sy’n eich dewis chi, yn mwynhau gweithio gyda chi ac yn gallu troi i fodd hyfforddi yn hapus.',
  'Build a sharp response to the dog’s name before adding distance.':
      'Adeiladwch ymateb sydyn i enw’r ci cyn ychwanegu pellter.',
  'Build a useful return that finishes close enough to reward well.': 'Adeiladwch ddychweliad defnyddiol sy’n gorffen yn ddigon agos i wobrwyo’n dda.',
  'Build awareness of where the dog is placing their feet.':
      'Adeiladwch ymwybyddiaeth o ble mae’r ci yn gosod ei draed.',
  'Build confidence while people or dogs move at a sensible distance.':
      'Adeiladwch hyder tra bo pobl neu gŵn yn symud o bellter synhwyrol.',
  'Build controlled movement without using high-impact exercises.':
      'Adeiladwch symudiad rheoledig heb ddefnyddio ymarferion effaith uchel.',
  'Build value in moving with the handler using short, lively games.':
      'Adeiladwch werth mewn symud gyda’r triniwr drwy gemau byr a bywiog.',
  'Build value in playing with the handler so rewards remain exciting around flyball.': 'Adeiladwch werth mewn chwarae gyda’r triniwr fel bod gwobrau’n parhau’n gyffrous o amgylch flyball.',
  'Check reward timing, clear cues and short positive sessions.':
      'Gwiriwch amseru gwobrau, ciwiau clir a sesiynau byr cadarnhaol.',
  'Choose sensible surfaces and prepare the dog before body-awareness work.': 'Dewiswch arwynebau synhwyrol a pharatowch y ci cyn gwaith ymwybyddiaeth o’r corff.',
  'Choose short clips that clearly show what you and your dog can do.': 'Dewiswch glipiau byr sy’n dangos yn glir beth allwch chi a’ch ci ei wneud.',
  'Combine a useful pickup with a direct return.':
      'Cyfunwch godi defnyddiol gyda dychweliad uniongyrchol.',
  'Completed the first Academy lesson.':
      'Wedi cwblhau gwers gyntaf yr Academi.',
  'Create a fast, happy response back to the handler with very little hesitation.':
      'Crëwch ymateb cyflym a hapus yn ôl at y triniwr heb fawr o betruso.',
  'Create more urgency while keeping the retrieve tidy.':
      'Crëwch fwy o frys gan gadw’r adalw’n daclus.',
  'Demonstrate that the dog can reconnect with you when something else is happening.': 'Dangoswch fod y ci yn gallu ailgysylltu â chi pan fydd rhywbeth arall yn digwydd.',
  'Earned the first trainer-verified skill trophy.':
      'Wedi ennill y tlws sgil cyntaf a wiriwyd gan hyfforddwr.',
  'Encourage the dog to return to the handler to restart the game.':
      'Anogwch y ci i ddychwelyd at y triniwr i ailgychwyn y gêm.',
  'Generalise the skill to new surfaces and mild distractions.':
      'Ymarferwch y sgil ar arwynebau newydd a gyda phethau bach i dynnu sylw.',
  'Help the dog understand and control movement of the back feet.':
      'Helpwch y ci i ddeall a rheoli symudiad y traed ôl.',
  'Help your dog move confidently, understand their body and build safe foundations for future flyball work.': 'Helpwch eich ci i symud yn hyderus, deall ei gorff ac adeiladu sylfeini diogel ar gyfer gwaith flyball yn y dyfodol.',
  'Increase distance without losing the quality of the pickup or return.':
      'Cynyddwch y pellter heb golli ansawdd y codi na’r dychwelyd.',
  'Increase the run gradually without losing enthusiasm.':
      'Cynyddwch y rhediad yn raddol heb golli brwdfrydedd.',
  'Introduce body awareness and targeting skills that will later support safe box work.': 'Cyflwynwch ymwybyddiaeth o’r corff a sgiliau targedu a fydd yn cefnogi gwaith bocs diogel yn nes ymlaen.',
  'Introduce the target calmly and reward confident interaction.':
      'Cyflwynwch y targed yn dawel a gwobrwywch ryngweithio hyderus.',
  'Keep connection with the handler while the world becomes a little more exciting.': 'Cadwch gysylltiad â’r triniwr wrth i’r byd fynd ychydig yn fwy cyffrous.',
  'Keep tugging controlled, comfortable and suitable for the individual dog.':
      'Cadwch y tynnu’n rheoledig, yn gyfforddus ac yn addas i’r ci unigol.',
  'Learn how to calmly reset when attention disappears.':
      'Dysgwch sut i ailosod yn dawel pan fydd sylw’n diflannu.',
  'Learn what useful engagement looks like before asking for formal behaviour.': 'Dysgwch sut mae ymgysylltu defnyddiol yn edrych cyn gofyn am ymddygiad ffurfiol.',
  'Learn when your dog can still think and when the environment is too difficult.': 'Dysgwch pryd mae eich ci yn dal i allu meddwl a phryd mae’r amgylchedd yn rhy anodd.',
  'Link simple skills without turning the session into a long drill.':
      'Cysylltwch sgiliau syml heb droi’r sesiwn yn ymarfer hir.',
  'Logged in for 14 days in a row.':
      'Wedi mewngofnodi am 14 diwrnod yn olynol.',
  'Logged in for 30 days in a row.':
      'Wedi mewngofnodi am 30 diwrnod yn olynol.',
  'Logged in for 7 days in a row.': 'Wedi mewngofnodi am 7 diwrnod yn olynol.',
  'Logged into the Academy for the first time.':
      'Wedi mewngofnodi i’r Academi am y tro cyntaf.',
  'Make the ball worth finding and picking up without creating conflict.':
      'Gwnewch y bêl yn werth ei darganfod a’i chodi heb greu gwrthdaro.',
  'Make the handler part of the fun rather than simply presenting a toy.':
      'Gwnewch y triniwr yn rhan o’r hwyl yn hytrach na dim ond cynnig tegan.',
  'Move between different rewards without losing drive.':
      'Symudwch rhwng gwahanol wobrau heb golli brwdfrydedd.',
  'Passed the Dead Ball Retrieve assessment.':
      'Wedi pasio asesiad Adalw Pêl Llonydd.',
  'Passed the Focus & Engagement assessment.':
      'Wedi pasio asesiad Ffocws ac Ymgysylltu.',
  'Passed the Movement & Body Awareness assessment.':
      'Wedi pasio asesiad Symud ac Ymwybyddiaeth o’r Corff.',
  'Passed the Rapid Recall assessment.': 'Wedi pasio asesiad Adalw Cyflym.',
  'Passed the Target Foundations assessment.':
      'Wedi pasio asesiad Sylfeini Targed.',
  'Passed the Toy & Tug Drive assessment.':
      'Wedi pasio asesiad Tegan a Thynnu.',
  'Passed the Working Around Distractions assessment.':
      'Wedi pasio asesiad Gweithio o Amgylch Pethau sy’n Tynnu Sylw.',
  'Passed the final Pre-Flyball Ready assessment.':
      'Wedi pasio’r asesiad terfynol Barod Cyn-Flyball.',
  'Pay the dog well for choosing the handler over the distraction.':
      'Gwobrwywch y ci’n dda am ddewis y triniwr dros y peth sy’n tynnu sylw.',
  'Practise a known skill while something mildly interesting is nearby.':
      'Ymarferwch sgil gyfarwydd tra bo rhywbeth ychydig yn ddiddorol gerllaw.',
  'Practise around mild distractions while keeping success high.': 'Ymarferwch o amgylch pethau bach sy’n tynnu sylw gan gadw llwyddiant yn uchel.',
  'Practise comfortable turns in both directions.':
      'Ymarferwch droadau cyfforddus i’r ddau gyfeiriad.',
  'Practise moving smoothly between food, toys and praise.':
      'Ymarferwch symud yn llyfn rhwng bwyd, teganau a chanmoliaeth.',
  'Repeat the skill from different starting points without rushing.':
      'Ailadroddwch y sgil o wahanol fannau cychwyn heb ruthro.',
  'Reward the first movement back towards you after pickup.':
      'Gwobrwywch y symudiad cyntaf yn ôl tuag atoch ar ôl codi.',
  'Reward your dog for choosing to look back and reconnect with you.':
      'Gwobrwywch eich ci am ddewis edrych yn ôl ac ailgysylltu â chi.',
  'Set up short, easy recalls where success is almost guaranteed.':
      'Gosodwch adalwadau byr a hawdd lle mae llwyddiant bron yn sicr.',
  'Shape a smooth turn away from the target rather than stopping on it.':
      'Siapiwch dro llyfn i ffwrdd o’r targed yn hytrach na stopio arno.',
  'Show a confident drive to the target, accurate body placement and a smooth turn away for reward.': 'Dangoswch yrru hyderus at y targed, lleoliad corff cywir a thro llyfn i ffwrdd am wobr.',
  'Show a confident pickup of a stationary ball and a direct, enthusiastic return to the handler.': 'Dangoswch godi pêl llonydd yn hyderus a dychwelyd yn uniongyrchol ac yn frwdfrydig at y triniwr.',
  'Show a fast return that flows straight into the dog’s preferred reward.':
      'Dangoswch ddychweliad cyflym sy’n llifo’n syth i hoff wobr y ci.',
  'Show a known skill around a mild distraction, with the dog able to reconnect quickly with the handler.': 'Dangoswch sgil gyfarwydd o amgylch peth bach sy’n tynnu sylw, gyda’r ci yn gallu ailgysylltu’n gyflym â’r triniwr.',
  'Show a quick, enthusiastic recall from a useful distance with a clean reward at the handler.': 'Dangoswch adalw cyflym a brwdfrydig o bellter defnyddiol gyda gwobr glir wrth y triniwr.',
  'Show calm body-awareness exercises, controlled movement and confidence on safe, suitable surfaces.': 'Dangoswch ymarferion ymwybyddiaeth o’r corff yn dawel, symudiad rheoledig a hyder ar arwynebau diogel ac addas.',
  'Show confident movement suitable for the dog’s age and ability.':
      'Dangoswch symudiad hyderus sy’n addas i oedran a gallu’r ci.',
  'Show the body-awareness and target foundations learned earlier.': 'Dangoswch y sylfeini ymwybyddiaeth o’r corff a tharged a ddysgwyd yn gynharach.',
  'Show your dog choosing to engage with you, following your movement and staying connected around a mild distraction.': 'Dangoswch eich ci yn dewis ymgysylltu â chi, yn dilyn eich symudiad ac yn cadw cysylltiad o amgylch peth bach sy’n tynnu sylw.',
  'Show your dog choosing to play, tugging confidently and re-engaging after the toy is released.': 'Dangoswch eich ci yn dewis chwarae, yn tynnu’n hyderus ac yn ailgysylltu ar ôl rhyddhau’r tegan.',
  'Submit one final video showing a selection of your best foundation skills. A trainer will check that you and your dog are ready for the next stage.': 'Cyflwynwch un fideo terfynol sy’n dangos detholiad o’ch sgiliau sylfaen gorau. Bydd hyfforddwr yn gwirio eich bod chi a’ch ci yn barod ar gyfer y cam nesaf.',
  'Submitted the first skill assessment.':
      'Wedi cyflwyno’r asesiad sgil cyntaf.',
  'Take the skill into a slightly busier setting without making it too hard.':
      'Ewch â’r sgil i le ychydig yn brysurach heb ei wneud yn rhy anodd.',
  'Teach a clean pickup from a ball placed on the ground.':
      'Dysgwch godi pêl o’r llawr yn lân.',
  'Teach a confident stationary ball pickup and a quick return to the handler.':
      'Dysgwch godi pêl llonydd yn hyderus a dychwelyd yn gyflym at y triniwr.',
  'Teach that releasing the toy does not mean the game is over.':
      'Dysgwch nad yw rhyddhau’r tegan yn golygu bod y gêm ar ben.',
  'Use clear timing so your dog understands exactly what earned the reward.': 'Defnyddiwch amseru clir fel bod eich ci yn deall yn union beth enillodd y wobr.',
  'Use low, safe poles to encourage careful foot placement.':
      'Defnyddiwch bolion isel a diogel i annog gosod traed yn ofalus.',
  'Use reward position to bring your dog right back to you.':
      'Defnyddiwch leoliad y wobr i ddod â’ch ci yn syth yn ôl atoch.',
  'Use reward position to support a clean, efficient movement pattern.':
      'Defnyddiwch leoliad y wobr i gefnogi patrwm symud glân ac effeithlon.',
  'Work out which toy and style of play your dog really values.': 'Darganfyddwch pa degan a pha fath o chwarae mae eich ci yn ei werthfawrogi fwyaf.',

  'Search people once, then manage their role, Doubloons and dogs from the same place.': 'Chwiliwch am bobl unwaith, yna rheolwch eu rôl, eu Doubloons a’u cŵn o’r un lle.',
  'No people match that search.':
      'Nid oes unrhyw un yn cyfateb i’r chwiliad hwnnw.',
  '+1 DOUBLOON': '+1 DOUBLOON',
  'No dogs on this account.': 'Dim cŵn ar y cyfrif hwn.',

  // Common controls
  'Save': 'Cadw',
  'SAVE': 'CADW',
  'Done': 'Wedi gorffen',
  'DELETE': 'DILEU',
  'REMOVE': 'TYNU',
  'Edit': 'Golygu',
  'Close': 'Cau',
  'Open': 'Agor',
  'Yes': 'Ie',
  'No': 'Na',
  'On': 'Ymlaen',
  'Off': 'I ffwrdd',
  'Normal': 'Arferol',
  'Important': 'Pwysig',
  'Status': 'Statws',
  'Title': 'Teitl',
  'Type': 'Math',
  'Day': 'Diwrnod',
  'Month': 'Mis',
  'Year': 'Blwyddyn',
  'Trainer': 'Hyfforddwr',
  'Admin': 'Gweinyddwr',
  'Captain': 'Capten',
  'Learner': 'Dysgwr',
};
