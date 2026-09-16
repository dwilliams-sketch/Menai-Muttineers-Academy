import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../i18n.dart';
import '../../services/admin_functions_service.dart';

class PirateFunScreen extends StatefulWidget {
  const PirateFunScreen({super.key});

  @override
  State<PirateFunScreen> createState() => _PirateFunScreenState();
}

class _PirateFunScreenState extends State<PirateFunScreen> {
  final functions = AdminFunctionsService();
  final input = TextEditingController();
  final letterOne = TextEditingController();
  final letterTwo = TextEditingController();
  final letterThree = TextEditingController();
  String source = 'en';
  String target = 'pirate';
  String output = '';
  String pirateName = '';
  bool translating = false;

  static const roles = [
    'Captain', 'Quartermaster', 'Boatswain', 'Shipcook', 'Gunner', 'Navigator',
    'Deckhand', 'Lookout', 'Sailmaker', 'Carpenter', 'Helmsman', 'Cabin Mate',
    'Powder Monkey', 'Treasure Keeper', 'Map Keeper', 'Rigging Rat', 'First Mate',
    'Sea Scout', 'Cannon Master', 'Rum Runner', 'Anchor Keeper', 'Storm Chaser',
    'Rope Wrangler', 'Harbour Rogue', 'Wave Rider', 'Jolly Buccaneer',
  ];
  static const firstNames = [
    'Barnacle Bill', 'Black Jack', 'Bonny Belle', 'Cannon Kate', 'Daring Dai',
    'Eagle-Eye Ed', 'Fishhook Finn', 'Giggling Grace', 'Harbour Harry',
    'Iron Izzy', 'Jolly Jim', 'Keelhaul Kelly', 'Lucky Lou', 'Mad Molly',
    'Nifty Ned', 'One-Eyed Ollie', 'Peg-Leg Penny', 'Quick Quinn', 'Red Rosie',
    'Salty Sam', 'Treasure Tess', 'Unlucky Uther', 'Velvet Vic', 'Wild Will',
    'X Marks Max', 'Yo-Ho Yanni',
  ];
  static const surnames = [
    'Anchors', 'Blackbeard', 'Cutlass', 'Doubloons', 'Eyepatch', 'Flint',
    'Goldtooth', 'Hooks', 'Ironboots', 'Jollybones', 'Kraken', 'Longboat',
    'Moonwake', 'Nightrudder', 'Oldrope', 'Pistols', 'Quicktide', 'Redflag',
    'Storms', 'Tanglebeard', 'Undertow', 'Vane', 'Wavebreaker', 'X-Marks',
    'Yardarm', 'Zigzag',
  ];

  @override
  void dispose() {
    input.dispose();
    letterOne.dispose();
    letterTwo.dispose();
    letterThree.dispose();
    super.dispose();
  }

  int _letterIndex(String raw) {
    final text = raw.trim().toUpperCase();
    if (text.isEmpty) return Random().nextInt(26);
    final code = text.codeUnitAt(0);
    if (code < 65 || code > 90) return Random().nextInt(26);
    return code - 65;
  }

  void _generateFromLetters() {
    final a = _letterIndex(letterOne.text);
    final b = _letterIndex(letterTwo.text);
    final c = _letterIndex(letterThree.text);
    setState(() => pirateName = '${roles[a]} ${firstNames[b]} ${surnames[c]}');
  }

  void _randomName() {
    final r = Random();
    setState(() => pirateName = '${roles[r.nextInt(roles.length)]} ${firstNames[r.nextInt(firstNames.length)]} ${surnames[r.nextInt(surnames.length)]}');
  }

  String _pirateify(String text) {
    var out = text.trim();
    if (out.isEmpty) return '';
    final replacements = <RegExp, String>{
      RegExp(r'\bhello\b', caseSensitive: false): 'ahoy',
      RegExp(r'\bhi\b', caseSensitive: false): 'ahoy',
      RegExp(r'\bmy\b', caseSensitive: false): 'me',
      RegExp(r'\byour\b', caseSensitive: false): 'yer',
      RegExp(r'\byou\b', caseSensitive: false): 'ye',
      RegExp(r'\byes\b', caseSensitive: false): 'aye',
      RegExp(r'\bno\b', caseSensitive: false): 'nay',
      RegExp(r'\bfriend\b', caseSensitive: false): 'matey',
      RegExp(r'\bfriends\b', caseSensitive: false): 'crew',
      RegExp(r'\bpeople\b', caseSensitive: false): 'crew',
      RegExp(r'\bmoney\b', caseSensitive: false): 'doubloons',
      RegExp(r'\bfood\b', caseSensitive: false): 'grub',
      RegExp(r'\blook\b', caseSensitive: false): 'spy',
      RegExp(r'\bgo\b', caseSensitive: false): 'set sail',
      RegExp(r'\bstop\b', caseSensitive: false): 'drop anchor',
      RegExp(r'\bgood\b', caseSensitive: false): 'fine',
      RegExp(r'\bgreat\b', caseSensitive: false): 'grand',
      RegExp(r'\bthe\b', caseSensitive: false): "th'",
    };
    replacements.forEach((pattern, replacement) => out = out.replaceAll(pattern, replacement));
    if (!RegExp(r'^(ahoy|arr|arrr|aye)', caseSensitive: false).hasMatch(out)) out = 'Arrr! $out';
    if (!RegExp(r'[.!?]$').hasMatch(out)) out += '!';
    if (!RegExp(r'\b(matey|crew|ye)\b', caseSensitive: false).hasMatch(out)) out += ' 🏴‍☠️';
    return out;
  }

  String _dePirate(String text) {
    var out = text.trim();
    out = out.replaceFirst(RegExp(r'^arrr?!?\s*', caseSensitive: false), '');
    final replacements = <RegExp, String>{
      RegExp(r"\bth'", caseSensitive: false): 'the',
      RegExp(r'\bahoy\b', caseSensitive: false): 'hello',
      RegExp(r'\baye\b', caseSensitive: false): 'yes',
      RegExp(r'\bnay\b', caseSensitive: false): 'no',
      RegExp(r'\bme\b', caseSensitive: false): 'my',
      RegExp(r'\byer\b', caseSensitive: false): 'your',
      RegExp(r'\bye\b', caseSensitive: false): 'you',
      RegExp(r'\bmatey\b', caseSensitive: false): 'friend',
      RegExp(r'\bcrew\b', caseSensitive: false): 'friends',
      RegExp(r'\bdoubloons\b', caseSensitive: false): 'money',
      RegExp(r'\bgrub\b', caseSensitive: false): 'food',
      RegExp(r'\bset sail\b', caseSensitive: false): 'go',
      RegExp(r'\bdrop anchor\b', caseSensitive: false): 'stop',
    };
    replacements.forEach((pattern, replacement) => out = out.replaceAll(pattern, replacement));
    return out.replaceAll('🏴‍☠️', '').trim();
  }

  Future<String> _cloudTranslate(String text, String from, String to) => functions.translateAcademyText(
        text: text,
        sourceLanguage: from,
        targetLanguage: to,
      );

  Future<void> _translate() async {
    final value = input.text.trim();
    if (value.isEmpty) return;
    setState(() {
      translating = true;
      output = '';
    });
    try {
      String result;
      if (source == target) {
        result = value;
      } else if (target == 'pirate') {
        final english = source == 'cy' ? await _cloudTranslate(value, 'cy', 'en') : (source == 'pirate' ? _dePirate(value) : value);
        result = _pirateify(english);
      } else if (source == 'pirate') {
        final english = _dePirate(value);
        result = target == 'en' ? english : await _cloudTranslate(english, 'en', 'cy');
      } else {
        result = await _cloudTranslate(value, source, target);
      }
      if (mounted) setState(() => output = result);
    } catch (_) {
      if (mounted) {
        setState(() => output = '');
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: I18nText('English/Welsh translation is not ready yet. The Captain may need to deploy the V1.4 Firebase Functions.')));
      }
    } finally {
      if (mounted) setState(() => translating = false);
    }
  }

  String _languageLabel(String code) => switch (code) {
        'cy' => 'Welsh',
        'pirate' => 'Pirate Talk',
        _ => 'English',
      };

  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                I18nText('🏴‍☠️ Pirate Name Generator', style: Theme.of(context).textTheme.titleLarge),
                const I18nText('Just for laughs — this never changes your real Academy name or profile.'),
                const SizedBox(height: 10),
                const I18nText('Enter only the three letters below. You do not need to type your full name.'),
                const SizedBox(height: 8),
                Wrap(spacing: 8, runSpacing: 8, children: [
                  SizedBox(width: 190, child: TextField(controller: letterOne, maxLength: 1, textCapitalization: TextCapitalization.characters, decoration: const InputDecoration(label: I18nText('First letter of first name'), counterText: ''))),
                  SizedBox(width: 190, child: TextField(controller: letterTwo, maxLength: 1, textCapitalization: TextCapitalization.characters, decoration: const InputDecoration(label: I18nText('Last letter of last name'), counterText: ''))),
                  SizedBox(width: 190, child: TextField(controller: letterThree, maxLength: 1, textCapitalization: TextCapitalization.characters, decoration: const InputDecoration(label: I18nText('Third letter of first name'), counterText: ''))),
                ]),
                const SizedBox(height: 10),
                Wrap(spacing: 8, runSpacing: 8, children: [
                  FilledButton.icon(onPressed: _generateFromLetters, icon: const Icon(Icons.casino), label: const I18nText('REVEAL MY PIRATE NAME')),
                  OutlinedButton.icon(onPressed: _randomName, icon: const Icon(Icons.shuffle), label: const I18nText('RANDOM NAME')),
                ]),
                if (pirateName.isNotEmpty) ...[
                  const Divider(height: 28),
                  const I18nText('Welcome aboard, matey! For absolutely no official reason, ye shall be known as:'),
                  const SizedBox(height: 8),
                  SelectableText(pirateName, textAlign: TextAlign.center, style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 6),
                  Center(child: TextButton.icon(onPressed: () => Clipboard.setData(ClipboardData(text: pirateName)), icon: const Icon(Icons.copy), label: const I18nText('COPY NAME'))),
                ],
              ]),
            ),
          ),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                I18nText('🦜 English / Welsh / Pirate Translator', style: Theme.of(context).textTheme.titleLarge),
                const I18nText('English and Welsh use the Academy translation service. Pirate Talk is deliberately silly and is only for fun.'),
                const SizedBox(height: 10),
                Wrap(spacing: 8, runSpacing: 8, crossAxisAlignment: WrapCrossAlignment.center, children: [
                  SizedBox(width: 180, child: DropdownButtonFormField<String>(initialValue: source, decoration: const InputDecoration(label: I18nText('From')), items: ['en', 'cy', 'pirate'].map((e) => DropdownMenuItem(value: e, child: I18nText(_languageLabel(e)))).toList(), onChanged: (v) => setState(() => source = v ?? source))),
                  IconButton(onPressed: () => setState(() { final old = source; source = target; target = old; }), icon: const Icon(Icons.swap_horiz), tooltip: tr('Swap languages')),
                  SizedBox(width: 180, child: DropdownButtonFormField<String>(initialValue: target, decoration: const InputDecoration(label: I18nText('To')), items: ['en', 'cy', 'pirate'].map((e) => DropdownMenuItem(value: e, child: I18nText(_languageLabel(e)))).toList(), onChanged: (v) => setState(() => target = v ?? target))),
                ]),
                const SizedBox(height: 8),
                TextField(controller: input, minLines: 3, maxLines: 6, maxLength: 800, decoration: const InputDecoration(label: I18nText('Type something to translate'))),
                FilledButton.icon(onPressed: translating ? null : _translate, icon: const Icon(Icons.translate), label: I18nText(translating ? 'Translating...' : 'TRANSLATE')),
                if (output.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Container(padding: const EdgeInsets.all(14), decoration: BoxDecoration(border: Border.all(color: Theme.of(context).colorScheme.outlineVariant), borderRadius: BorderRadius.circular(12)), child: SelectableText(output)),
                  Align(alignment: Alignment.centerRight, child: TextButton.icon(onPressed: () => Clipboard.setData(ClipboardData(text: output)), icon: const Icon(Icons.copy), label: const I18nText('COPY'))),
                ],
              ]),
            ),
          ),
        ],
      );
}
