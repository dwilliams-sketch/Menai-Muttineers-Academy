import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'firebase_options.dart';
import 'models.dart';
import 'screens/auth_screen.dart';
import 'screens/learner_shell.dart';
import 'screens/staff_shell.dart';
import 'services/firestore_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(const AcademyApp());
}

class AcademyApp extends StatelessWidget {
  const AcademyApp({super.key});

  @override
  Widget build(BuildContext context) {
    const navy = Color(0xFF132238);
    const gold = Color(0xFFD9A441);
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Menai Muttineers Academy',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: navy, primary: navy, secondary: gold),
        scaffoldBackgroundColor: const Color(0xFFF7F8FA),
        useMaterial3: true,
        cardTheme: const CardThemeData(margin: EdgeInsets.symmetric(vertical: 6), elevation: 0.7),
        inputDecorationTheme: const InputDecorationTheme(border: OutlineInputBorder()),
      ),
      home: const AuthGate(),
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
  String? _touchedUid;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, authSnap) {
        if (authSnap.connectionState == ConnectionState.waiting) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }
        final user = authSnap.data;
        if (user == null) return const AuthScreen();
        return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
          stream: service.userStream(user.uid),
          builder: (context, profileSnap) {
            if (!profileSnap.hasData) {
              return const Scaffold(body: Center(child: CircularProgressIndicator()));
            }
            final doc = profileSnap.data!;
            if (!doc.exists) {
              return MissingProfileScreen(uid: user.uid);
            }
            final profile = AppUser.fromDoc(doc);
            if (_touchedUid != user.uid) {
              _touchedUid = user.uid;
              Future.microtask(() => service.touch(user.uid));
            }
            if (profile.isStaff) return StaffShell(profile: profile);
            if (!profile.isPaid) return PaymentWaitingScreen(profile: profile);
            if (!profile.activated) return ActivationScreen(profile: profile);
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
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Account setup')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            const Text('Your login exists, but the Academy profile was not found.'),
            const SizedBox(height: 12),
            FilledButton(onPressed: () => FirebaseAuth.instance.signOut(), child: const Text('Sign out and register again')),
          ]),
        ),
      ),
    );
  }
}

class PaymentWaitingScreen extends StatelessWidget {
  final AppUser profile;
  const PaymentWaitingScreen({super.key, required this.profile});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Menai Muttineers Academy'), actions: [
        IconButton(onPressed: () => FirebaseAuth.instance.signOut(), icon: const Icon(Icons.logout)),
      ]),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 520),
          child: Card(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                const Icon(Icons.lock_clock, size: 56),
                const SizedBox(height: 14),
                Text('Ahoy ${profile.name}', style: Theme.of(context).textTheme.headlineSmall),
                const SizedBox(height: 8),
                const Text('Your account is ready. Course access will unlock once the Captain/Admin confirms your payment.'),
                const SizedBox(height: 14),
                const Text('Payment status: Awaiting confirmation', style: TextStyle(fontWeight: FontWeight.bold)),
              ]),
            ),
          ),
        ),
      ),
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
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Activate course'), actions: [
        IconButton(onPressed: () => FirebaseAuth.instance.signOut(), icon: const Icon(Icons.logout)),
      ]),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 480),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              Text('Welcome aboard, ${widget.profile.name}', style: Theme.of(context).textTheme.headlineSmall),
              const SizedBox(height: 10),
              const Text('Enter the 6-character Academy access code issued after your payment was confirmed.'),
              const SizedBox(height: 18),
              TextField(controller: controller, textCapitalization: TextCapitalization.characters, maxLength: 6, decoration: const InputDecoration(labelText: 'Access code')),
              if (error.isNotEmpty) Text(error, style: TextStyle(color: Theme.of(context).colorScheme.error)),
              const SizedBox(height: 10),
              SizedBox(width: double.infinity, child: FilledButton(onPressed: busy ? null : activate, child: Text(busy ? 'Checking...' : 'Join the Crew'))),
            ]),
          ),
        ),
      ),
    );
  }
}
