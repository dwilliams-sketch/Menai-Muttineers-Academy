import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';
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

  // Draw a Flutter screen immediately. Previously the app waited for
  // SharedPreferences and Firebase before runApp(), so any startup problem
  // left Android showing only the native logo indefinitely.
  runApp(const AcademyBootstrap());
}

class AcademyBootstrap extends StatefulWidget {
  const AcademyBootstrap({super.key});

  @override
  State<AcademyBootstrap> createState() => _AcademyBootstrapState();
}

class _AcademyBootstrapState extends State<AcademyBootstrap> {
  bool _ready = false;
  bool _starting = true;
  String? _error;
  String? _nativeDiagnostics;

  @override
  void initState() {
    super.initState();
    _startAcademy();
  }

  Future<void> _startAcademy() async {
    if (mounted) {
      setState(() {
        _starting = true;
        _error = null;
      });
    }

    // Language preference is helpful, but it must never prevent the app
    // opening. English remains the safe fallback if local preferences fail.
    try {
      await LanguageController.init().timeout(const Duration(seconds: 5));
    } catch (error, stack) {
      debugPrint('Academy language startup warning: $error');
      debugPrintStack(stackTrace: stack);
    }

    _nativeDiagnostics = await _readNativeStartupDiagnostics();

    try {
      final options = DefaultFirebaseOptions.currentPlatform;

      // Give a clear diagnostic if a GitHub build secret was accidentally
      // missing instead of leaving the native splash screen visible forever.
      if (options.apiKey.isEmpty ||
          options.appId.isEmpty ||
          options.messagingSenderId.isEmpty ||
          options.projectId.isEmpty) {
        throw StateError(
          'Firebase build settings are missing. Check the FIREBASE_* GitHub repository secrets and rebuild the app.',
        );
      }

      if (Firebase.apps.isEmpty) {
        await Firebase.initializeApp(options: options)
            .timeout(const Duration(seconds: 20));
      }

      if (!mounted) return;
      setState(() {
        _ready = true;
        _starting = false;
        _error = null;
      });
    } on TimeoutException catch (error, stack) {
      debugPrint('Academy Firebase startup timeout: $error');
      debugPrintStack(stackTrace: stack);
      if (!mounted) return;
      setState(() {
        _starting = false;
        _error = 'Firebase did not finish connecting within 20 seconds. Check your internet connection and tap Retry.';
      });
    } catch (error, stack) {
      debugPrint('Academy Firebase startup error: $error');
      debugPrintStack(stackTrace: stack);
      if (!mounted) return;
      setState(() {
        _starting = false;
        final base = _startupErrorText(error);
        final native = _nativeDiagnostics?.trim();
        _error = native == null || native.isEmpty
            ? base
            : '$base\n\nAndroid diagnostics:\n$native';
      });
    }
  }

  Future<String?> _readNativeStartupDiagnostics() async {
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) {
      return null;
    }

    const channel = MethodChannel('academy/startup_diagnostics');

    try {
      final result = await channel
          .invokeMapMethod<String, dynamic>('getStartupDiagnostics')
          .timeout(const Duration(seconds: 3));

      if (result == null) {
        return 'MainActivity replied, but no diagnostic data was returned.';
      }

      final lines = <String>[
        'MainActivity diagnostic channel: CONNECTED',
        'Manual Firebase Core registration completed: ${result['manualFirebaseCoreCompleted']}',
        'Firebase Core listed in engine: ${result['firebaseCoreListed']}',
        'Generated registrant completed: ${result['generatedRegistrantCompleted']}',
      ];

      final manualError = result['manualFirebaseCoreError']?.toString();
      if (manualError != null && manualError.trim().isNotEmpty) {
        lines.add('Manual Firebase Core error:\n$manualError');
      }

      final generatedError = result['generatedRegistrantError']?.toString();
      if (generatedError != null && generatedError.trim().isNotEmpty) {
        lines.add('Generated registrant error:\n$generatedError');
      }

      return lines.join('\n');
    } catch (error) {
      return 'MainActivity diagnostic channel FAILED: $error';
    }
  }

  String _startupErrorText(Object error) {
    if (error is FirebaseException) {
      final message = error.message?.trim();
      return 'Firebase ${error.code}${message == null || message.isEmpty ? '' : ': $message'}';
    }

    final text = error.toString().trim();
    return text.isEmpty ? 'Unknown startup error.' : text;
  }

  @override
  Widget build(BuildContext context) {
    if (_ready) return const AcademyApp();

    const navy = Color(0xFF132238);
    const gold = Color(0xFFD9A441);

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Menai Muttineers Academy',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: navy,
          primary: navy,
          secondary: gold,
        ),
        scaffoldBackgroundColor: const Color(0xFFF7F8FA),
        useMaterial3: true,
      ),
      home: Scaffold(
        body: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(28),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 520),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.anchor, size: 72, color: navy),
                    const SizedBox(height: 18),
                    I18nText(
                      'Menai Muttineers Academy',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.headlineSmall
                          ?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 6),
                    const I18nText(
                      'Academy V1.4',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 16),
                    if (_starting) ...[
                      const CircularProgressIndicator(),
                      const SizedBox(height: 18),
                      const I18nText(
                        'Preparing the Academy…',
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 6),
                      const I18nText(
                        'This should only take a few seconds.',
                        textAlign: TextAlign.center,
                      ),
                    ] else ...[
                      Icon(
                        Icons.cloud_off_outlined,
                        size: 48,
                        color: Theme.of(context).colorScheme.error,
                      ),
                      const SizedBox(height: 14),
                      I18nText(
                        'The Academy could not finish starting.',
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 8),
                      const I18nText(
                        'Nothing has been deleted. Check your internet connection, then tap Retry.',
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(14),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              const I18nText(
                                'Startup details',
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(height: 6),
                              SelectableText(
                                _error ?? tr('Unknown startup error.'),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 18),
                      FilledButton.icon(
                        onPressed: _startAcademy,
                        icon: const Icon(Icons.refresh),
                        label: const I18nText('RETRY'),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
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
        locale: Locale(languageCode == 'cy' ? 'cy' : 'en'),
        supportedLocales: const [Locale('en'), Locale('cy')],
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(
            seedColor: navy,
            primary: navy,
            secondary: gold,
          ),
          scaffoldBackgroundColor: const Color(0xFFF7F8FA),
          useMaterial3: true,
          cardTheme: const CardThemeData(
            margin: EdgeInsets.symmetric(vertical: 6),
            elevation: 0.8,
          ),
          inputDecorationTheme: const InputDecorationTheme(
            border: OutlineInputBorder(),
          ),
          pageTransitionsTheme: PageTransitionsTheme(
            builders: {
              TargetPlatform.android:
                  const FadeForwardsPageTransitionsBuilder(),
              TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
              TargetPlatform.windows:
                  const FadeForwardsPageTransitionsBuilder(),
              TargetPlatform.macOS: CupertinoPageTransitionsBuilder(),
              TargetPlatform.linux: const FadeForwardsPageTransitionsBuilder(),
            },
          ),
        ),
        home: const AuthGate(),
      ),
    );
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
  String? languageSyncedUid;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, authSnap) {
        if (authSnap.connectionState == ConnectionState.waiting)
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        final user = authSnap.data;
        if (user == null) {
          languageSyncedUid = null;
          return const AuthScreen();
        }
        return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
          stream: service.userStream(user.uid),
          builder: (context, profileSnap) {
            if (!profileSnap.hasData)
              return const Scaffold(
                body: Center(child: CircularProgressIndicator()),
              );
            final doc = profileSnap.data!;
            if (!doc.exists) return MissingProfileScreen(uid: user.uid);
            final profile = AppUser.fromDoc(doc);
            // Apply the saved account language once when this user session loads.
            // Do not continuously force Firestore's last snapshot back over a
            // language button the user has just tapped.
            if (languageSyncedUid != user.uid) {
              languageSyncedUid = user.uid;
              if (profile.languageCode != LanguageController.current) {
                Future.microtask(
                  () => LanguageController.set(profile.languageCode),
                );
              }
            }
            if (touchedUid != user.uid) {
              touchedUid = user.uid;
              Future.microtask(() async {
                await service.touch(user.uid);
                await push.registerForUser(
                  user.uid,
                  enabled: profile.pushEnabled,
                );
              });
            }
            if (profile.isStaff) return StaffShell(profile: profile);
            if (!profile.activated && !profile.isPaid)
              return PaymentWaitingScreen(profile: profile);
            if (!profile.activated && profile.isPaid)
              return ActivationScreen(profile: profile);
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
    appBar: AppBar(
      title: const I18nText('Account setup'),
      actions: const [
        Padding(padding: EdgeInsets.only(right: 8), child: LanguageToggle()),
      ],
    ),
    body: Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const I18nText(
              'Your login exists, but the Academy profile was not found.',
            ),
            const SizedBox(height: 12),
            FilledButton(
              onPressed: () => FirebaseAuth.instance.signOut(),
              child: const I18nText('Sign out and register again'),
            ),
          ],
        ),
      ),
    ),
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
    final amount = TextEditingController(
      text: academyDoubloonPounds.toStringAsFixed(2),
    );
    String method = 'Bank transfer';
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setLocal) => AlertDialog(
          title: const I18nText('I’ve made a payment'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: amount,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: const InputDecoration(
                  label: I18nText('Amount sent (£)'),
                ),
              ),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                initialValue: method,
                items: const ['Bank transfer', 'Standing order', 'Other']
                    .map((e) => DropdownMenuItem(value: e, child: I18nText(e)))
                    .toList(),
                onChanged: (v) => setLocal(() => method = v ?? method),
                decoration: const InputDecoration(label: I18nText('Method')),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const I18nText('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const I18nText('Send to Admin'),
            ),
          ],
        ),
      ),
    );
    final value = double.tryParse(amount.text.trim());
    if (ok == true && value != null && value > 0) {
      await service.submitPaymentNotice(
        uid: widget.profile.id,
        dogId: dog.id,
        dogName: dog.name,
        memberName: widget.profile.name,
        amount: value,
        method: method,
      );
      if (mounted)
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: I18nText(
              'Payment notice sent. Admin will confirm it after checking the bank.',
            ),
          ),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: service.dogsForOwner(widget.profile.id),
      builder: (context, dogSnap) {
        if (!dogSnap.hasData || dogSnap.data!.docs.isEmpty) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        final dog = DogProfile.fromDoc(dogSnap.data!.docs.first);
        return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
          stream: service.academySettings(),
          builder: (context, academySnap) {
            final config = AcademyConfig.fromMap(
              academySnap.data?.data() ?? {},
            );
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
                    actions: [
                      LanguageToggle(userId: widget.profile.id),
                      IconButton(
                        onPressed: () => FirebaseAuth.instance.signOut(),
                        icon: const Icon(Icons.logout),
                      ),
                    ],
                  ),
                  body: Center(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(20),
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 620),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Card(
                              child: Padding(
                                padding: const EdgeInsets.all(22),
                                child: Column(
                                  children: [
                                    const Icon(Icons.anchor, size: 56),
                                    const SizedBox(height: 10),
                                    I18nText(
                                      'Welcome aboard, ${widget.profile.name}',
                                      style: Theme.of(context)
                                          .textTheme
                                          .headlineSmall,
                                      textAlign: TextAlign.center,
                                    ),
                                    const SizedBox(height: 8),
                                    I18nText(
                                      'Your account and ${dog.name}’s profile are safely created. We just need to confirm the first Academy payment before the course unlocks.',
                                      textAlign: TextAlign.center,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(height: 10),
                            Card(
                              child: Padding(
                                padding: const EdgeInsets.all(18),
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.stretch,
                                  children: [
                                    I18nText(
                                      'Pay outside the app',
                                      style: Theme.of(context)
                                          .textTheme
                                          .titleLarge,
                                    ),
                                    const I18nText(
                                      'The Academy never takes card or bank details inside the app. Use your normal banking app / standing order.',
                                    ),
                                    const SizedBox(height: 6),
                                    const I18nText(
                                      '1 Doubloon (£5) gives one dog 30 days of Academy access.',
                                    ),
                                    const SizedBox(height: 12),
                                    if (links.accountName.isNotEmpty)
                                      I18nText(
                                        'Account name: ${links.accountName}',
                                      ),
                                    if (links.bankName.isNotEmpty)
                                      I18nText('Bank: ${links.bankName}'),
                                    if (links.sortCode.isNotEmpty)
                                      I18nText('Sort code: ${links.sortCode}'),
                                    if (links.accountNumber.isNotEmpty)
                                      I18nText(
                                        'Account number: ${links.accountNumber}',
                                      ),
                                    const SizedBox(height: 12),
                                    const I18nText(
                                      'Use this payment reference:',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    SelectableText(
                                      reference,
                                      style: Theme.of(context)
                                          .textTheme
                                          .headlineSmall,
                                    ),
                                    I18nText(
                                      'Dog name + your initials + ${config.paymentReferenceSuffix} helps us match the payment quickly.',
                                    ),
                                    if (links.paymentNote.isNotEmpty) ...[
                                      const SizedBox(height: 8),
                                      I18nText(links.paymentNote),
                                    ],
                                    if (links.directDebitInfo.isNotEmpty) ...[
                                      const Divider(height: 24),
                                      I18nText(
                                        'Standing order / Direct Debit information',
                                        style: Theme.of(context)
                                            .textTheme
                                            .titleMedium,
                                      ),
                                      I18nText(links.directDebitInfo),
                                    ],
                                    const SizedBox(height: 14),
                                    FilledButton.icon(
                                      onPressed: () => _reportPayment(dog),
                                      icon: const Icon(Icons.outgoing_mail),
                                      label: const I18nText(
                                        'I’VE MADE A PAYMENT',
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(height: 10),
                            const Card(
                              child: Padding(
                                padding: EdgeInsets.all(16),
                                child: I18nText(
                                  'Once Admin confirms payment, you’ll receive your 6-character activation code. You are already logged in — there is no need to use Forgot Password or sign in again.',
                                ),
                              ),
                            ),
                          ],
                        ),
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
    if (entered != widget.profile.accessCodeHash ||
        controller.text.trim().isEmpty) {
      setState(
        () => error = 'That access code does not match. Please check the code issued to you.',
      );
      return;
    }
    setState(() {
      busy = true;
      error = '';
    });
    await service.activate(widget.profile.id);
    if (mounted) setState(() => busy = false);
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: const I18nText('Activate Academy'),
      actions: [
        LanguageToggle(userId: widget.profile.id),
        IconButton(
          onPressed: () => FirebaseAuth.instance.signOut(),
          icon: const Icon(Icons.logout),
        ),
      ],
    ),
    body: Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 480),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.flag_circle, size: 58),
              I18nText(
                'Your adventure is ready!',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 8),
              const I18nText(
                'Enter the 6-character Academy code issued after your payment was confirmed.',
              ),
              const SizedBox(height: 18),
              TextField(
                controller: controller,
                textCapitalization: TextCapitalization.characters,
                maxLength: 6,
                decoration: const InputDecoration(
                  label: I18nText('Access code'),
                ),
              ),
              if (error.isNotEmpty)
                I18nText(
                  error,
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: busy ? null : activate,
                  child: I18nText(busy ? 'Checking...' : 'JOIN THE CREW'),
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}
