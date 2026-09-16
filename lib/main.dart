import 'package:flutter/cupertino.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'i18n.dart';
import 'firebase_options.dart';
import 'models.dart';
import 'screens/auth_screen.dart';
import 'screens/learner_shell.dart';
import 'screens/staff_shell.dart';
import 'services/firestore_service.dart';
import 'services/push_service.dart';
import 'widgets/language_toggle.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await LanguageController.init();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(const AcademyApp());
}

class AcademyApp extends StatelessWidget {
  const AcademyApp({super.key});

  @override
  Widget build(BuildContext context) {
    const navy = Color(0xFF132238);
    const gold = Color(0xFFD9A441);
    return ValueListenableBuilder<String>(
      valueListenable: LanguageController.language,
      builder: (context, languageCode, _) => MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Menai Muttineers Academy',
      locale: Locale(languageCode),
      supportedLocales: const [Locale('en'), Locale('cy')],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: navy, primary: navy, secondary: gold),
        scaffoldBackgroundColor: const Color(0xFFF7F8FA),
        useMaterial3: true,
        cardTheme: const CardThemeData(margin: EdgeInsets.symmetric(vertical: 6), elevation: 0.8),
        inputDecorationTheme: const InputDecorationTheme(border: OutlineInputBorder()),
        pageTransitionsTheme: PageTransitionsTheme(builders: {
          TargetPlatform.android: const FadeForwardsPageTransitionsBuilder(),
          TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
          TargetPlatform.windows: const FadeForwardsPageTransitionsBuilder(),
          TargetPlatform.macOS: CupertinoPageTransitionsBuilder(),
          TargetPlatform.linux: const FadeForwardsPageTransitionsBuilder(),
        }),
      ),
      home: const AuthGate(),
    ));
  }
}

class AuthGate extends StatefulWidget {
  const AuthGate({super.key});
  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  final service = FirestoreService();
  final push = PushService();
  String? touchedUid;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, authSnap) {
        if (authSnap.connectionState == ConnectionState.waiting) return const Scaffold(body: Center(child: CircularProgressIndicator()));
        final user = authSnap.data;
        if (user == null) return const AuthScreen();
        return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
          stream: service.userStream(user.uid),
          builder: (context, profileSnap) {
            if (!profileSnap.hasData) return const Scaffold(body: Center(child: CircularProgressIndicator()));
            final doc = profileSnap.data!;
            if (!doc.exists) return MissingProfileScreen(uid: user.uid);
            final profile = AppUser.fromDoc(doc);
            if (profile.languageCode != LanguageController.current) {
              Future.microtask(() => LanguageController.set(profile.languageCode));
            }
            if (touchedUid != user.uid) {
              touchedUid = user.uid;
              Future.microtask(() async {
                await service.touch(user.uid);
                await push.registerForUser(user.uid, enabled: profile.pushEnabled);
              });
            }
            if (profile.isStaff) return StaffShell(profile: profile);
            if (!profile.activated && !profile.isPaid) return PaymentWaitingScreen(profile: profile);
            if (!profile.activated && profile.isPaid) return ActivationScreen(profile: profile);
            return LearnerShell(profile: profile);
          },
        );
      },
    );
  }
}

class MissingProfileScreen extends StatelessWidget {
  final String uid;
  const MissingProfileScreen({super.key, required this.uid});
  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const I18nText('Account setup'), actions: const [Padding(padding: EdgeInsets.only(right: 8), child: LanguageToggle())]),
        body: Center(child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            const I18nText('Your login exists, but the Academy profile was not found.'),
            const SizedBox(height: 12),
            FilledButton(onPressed: () => FirebaseAuth.instance.signOut(), child: const I18nText('Sign out and register again')),
          ]),
        )),
      );
}

class PaymentWaitingScreen extends StatefulWidget {
  final AppUser profile;
  const PaymentWaitingScreen({super.key, required this.profile});
  @override
  State<PaymentWaitingScreen> createState() => _PaymentWaitingScreenState();
}

class _PaymentWaitingScreenState extends State<PaymentWaitingScreen> {
  final service = FirestoreService();

  Future<void> _reportPayment(DogProfile dog) async {
    final amount = TextEditingController(text: academyDoubloonPounds.toStringAsFixed(2));
    String method = 'Bank transfer';
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(builder: (ctx, setLocal) => AlertDialog(
        title: const I18nText('I’ve made a payment'),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          TextField(controller: amount, keyboardType: const TextInputType.numberWithOptions(decimal: true), decoration: const InputDecoration(label: I18nText('Amount sent (£)'))),
          const SizedBox(height: 8),
          DropdownButtonFormField<String>(
            initialValue: method,
            items: const ['Bank transfer', 'Standing order', 'Other'].map((e) => DropdownMenuItem(value: e, child: I18nText(e))).toList(),
            onChanged: (v) => setLocal(() => method = v ?? method),
            decoration: const InputDecoration(label: I18nText('Method')),
          ),
        ]),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const I18nText('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const I18nText('Send to Admin')),
        ],
      )),
    );
    final value = double.tryParse(amount.text.trim());
    if (ok == true && value != null && value > 0) {
      await service.submitPaymentNotice(uid: widget.profile.id, dogId: dog.id, dogName: dog.name, memberName: widget.profile.name, amount: value, method: method);
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: I18nText('Payment notice sent. Admin will confirm it after checking the bank.')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: service.dogsForOwner(widget.profile.id),
      builder: (context, dogSnap) {
        if (!dogSnap.hasData || dogSnap.data!.docs.isEmpty) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }
        final dog = DogProfile.fromDoc(dogSnap.data!.docs.first);
        return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
          stream: service.academySettings(),
          builder: (context, academySnap) {
            final config = AcademyConfig.fromMap(academySnap.data?.data() ?? {});
            final reference = service.paymentReference(
              dogName: dog.name,
              memberName: widget.profile.name,
              suffix: config.paymentReferenceSuffix,
            );
            return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
              stream: service.linkSettings(),
              builder: (context, linkSnap) {
                final links = AppLinks.fromMap(linkSnap.data?.data() ?? {});
                return Scaffold(
                  appBar: AppBar(
                    title: const I18nText('Menai Muttineers Academy'),
                    actions: [LanguageToggle(userId: widget.profile.id), IconButton(onPressed: () => FirebaseAuth.instance.signOut(), icon: const Icon(Icons.logout))],
                  ),
                  body: Center(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(20),
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 620),
                        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                          Card(child: Padding(padding: const EdgeInsets.all(22), child: Column(children: [
                            const Icon(Icons.anchor, size: 56),
                            const SizedBox(height: 10),
                            I18nText('Welcome aboard, ${widget.profile.name}', style: Theme.of(context).textTheme.headlineSmall, textAlign: TextAlign.center),
                            const SizedBox(height: 8),
                            I18nText('Your account and ${dog.name}’s profile are safely created. We just need to confirm the first Academy payment before the course unlocks.', textAlign: TextAlign.center),
                          ]))),
                          const SizedBox(height: 10),
                          Card(child: Padding(padding: const EdgeInsets.all(18), child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                            I18nText('Pay outside the app', style: Theme.of(context).textTheme.titleLarge),
                            const I18nText('The Academy never takes card or bank details inside the app. Use your normal banking app / standing order.'),
                            const SizedBox(height: 6),
                            const I18nText('1 Doubloon (£5) gives one dog 30 days of Academy access.'),
                            const SizedBox(height: 12),
                            if (links.accountName.isNotEmpty) I18nText('Account name: ${links.accountName}'),
                            if (links.bankName.isNotEmpty) I18nText('Bank: ${links.bankName}'),
                            if (links.sortCode.isNotEmpty) I18nText('Sort code: ${links.sortCode}'),
                            if (links.accountNumber.isNotEmpty) I18nText('Account number: ${links.accountNumber}'),
                            const SizedBox(height: 12),
                            const I18nText('Use this payment reference:', style: TextStyle(fontWeight: FontWeight.bold)),
                            SelectableText(reference, style: Theme.of(context).textTheme.headlineSmall),
                            I18nText('Dog name + your initials + ${config.paymentReferenceSuffix} helps us match the payment quickly.'),
                            if (links.paymentNote.isNotEmpty) ...[const SizedBox(height: 8), I18nText(links.paymentNote)],
                            if (links.directDebitInfo.isNotEmpty) ...[
                              const Divider(height: 24),
                              I18nText('Standing order / Direct Debit information', style: Theme.of(context).textTheme.titleMedium),
                              I18nText(links.directDebitInfo),
                            ],
                            const SizedBox(height: 14),
                            FilledButton.icon(onPressed: () => _reportPayment(dog), icon: const Icon(Icons.outgoing_mail), label: const I18nText('I’VE MADE A PAYMENT')),
                          ]))),
                          const SizedBox(height: 10),
                          const Card(child: Padding(padding: EdgeInsets.all(16), child: I18nText('Once Admin confirms payment, you’ll receive your 6-character activation code. You are already logged in — there is no need to use Forgot Password or sign in again.'))),
                        ]),
                      ),
                    ),
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

}

class ActivationScreen extends StatefulWidget {
  final AppUser profile;
  const ActivationScreen({super.key, required this.profile});
  @override
  State<ActivationScreen> createState() => _ActivationScreenState();
}

class _ActivationScreenState extends State<ActivationScreen> {
  final controller = TextEditingController();
  final service = FirestoreService();
  String error = '';
  bool busy = false;

  Future<void> activate() async {
    final entered = service.hashAccessCode(controller.text);
    if (entered != widget.profile.accessCodeHash || controller.text.trim().isEmpty) {
      setState(() => error = 'That access code does not match. Please check the code issued to you.');
      return;
    }
    setState(() { busy = true; error = ''; });
    await service.activate(widget.profile.id);
    if (mounted) setState(() => busy = false);
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const I18nText('Activate Academy'), actions: [LanguageToggle(userId: widget.profile.id), IconButton(onPressed: () => FirebaseAuth.instance.signOut(), icon: const Icon(Icons.logout))]),
        body: Center(child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 480),
          child: Padding(padding: const EdgeInsets.all(24), child: Column(mainAxisSize: MainAxisSize.min, children: [
            const Icon(Icons.flag_circle, size: 58),
            I18nText('Your adventure is ready!', style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: 8),
            const I18nText('Enter the 6-character Academy code issued after your payment was confirmed.'),
            const SizedBox(height: 18),
            TextField(controller: controller, textCapitalization: TextCapitalization.characters, maxLength: 6, decoration: const InputDecoration(label: I18nText('Access code'))),
            if (error.isNotEmpty) I18nText(error, style: TextStyle(color: Theme.of(context).colorScheme.error)),
            const SizedBox(height: 10),
            SizedBox(width: double.infinity, child: FilledButton(onPressed: busy ? null : activate, child: I18nText(busy ? 'Checking...' : 'JOIN THE CREW'))),
          ])),
        )),
      );
}
