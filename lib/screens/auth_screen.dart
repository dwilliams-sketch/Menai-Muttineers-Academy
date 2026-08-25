import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../i18n.dart';
import '../services/firestore_service.dart';
import '../widgets/language_toggle.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  String mode = 'landing';
  int step = 0;
  bool busy = false;
  bool dobEstimated = false;
  String error = '';

  final email = TextEditingController();
  final password = TextEditingController();
  final name = TextEditingController();
  final phone = TextEditingController();
  final dogName = TextEditingController();
  final breed = TextEditingController();
  final age = TextEditingController();
  final dateOfBirth = TextEditingController();
  final experience = TextEditingController();
  final notes = TextEditingController();
  final service = FirestoreService();

  Future<void> resetPassword() async {
    String addressDraft = email.text.trim();
    final submittedEmail = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const I18nText('Reset your password'),
        content: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          const I18nText('Enter the email address you used for the Academy. We’ll send a secure reset link.'),
          const SizedBox(height: 14),
          TextFormField(
            initialValue: addressDraft,
            autofocus: true,
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.done,
            decoration: const InputDecoration(label: I18nText('Email address')),
            onChanged: (value) => addressDraft = value,
            onFieldSubmitted: (value) => Navigator.of(dialogContext).pop(value),
          ),
        ]),
        actions: [
          TextButton(onPressed: () => Navigator.of(dialogContext).pop(), child: const I18nText('Cancel')),
          FilledButton(onPressed: () => Navigator.of(dialogContext).pop(addressDraft), child: const I18nText('Send reset link')),
        ],
      ),
    );
    if (!mounted || submittedEmail == null) return;
    final address = submittedEmail.trim();
    if (address.isEmpty || !address.contains('@')) {
      setState(() => error = 'Please enter a valid email address.');
      return;
    }
    setState(() { busy = true; error = ''; });
    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(email: address);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: I18nText('Password reset email sent. Check your inbox and junk/spam folder.'),
        duration: Duration(seconds: 7),
      ));
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;
      setState(() => error = e.code == 'too-many-requests'
          ? 'Too many attempts. Please wait a little and try again.'
          : e.code == 'network-request-failed'
              ? 'Please check your internet connection and try again.'
              : 'If an Academy account exists for that email, a reset link will be sent.');
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  Future<void> pickDob() async {
    final now = DateTime.now();
    final chosen = await showDatePicker(
      context: context,
      firstDate: DateTime(now.year - 30),
      lastDate: now,
      initialDate: DateTime(now.year - 2, now.month, now.day),
      helpText: tr('Dog date of birth — best guess is fine'),
    );
    if (chosen != null) {
      dateOfBirth.text = '${chosen.year.toString().padLeft(4, '0')}-${chosen.month.toString().padLeft(2, '0')}-${chosen.day.toString().padLeft(2, '0')}';
      setState(() {});
    }
  }

  Future<void> signIn() async {
    if (email.text.trim().isEmpty || password.text.length < 6) {
      setState(() => error = 'Please enter your email and password.');
      return;
    }
    setState(() { busy = true; error = ''; });
    try {
      await FirebaseAuth.instance.signInWithEmailAndPassword(email: email.text.trim(), password: password.text);
    } on FirebaseAuthException catch (e) {
      if (mounted) setState(() => error = e.message ?? 'Could not sign in.');
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  bool _validateStep() {
    if (step == 0 && (name.text.trim().isEmpty || phone.text.trim().isEmpty)) {
      setState(() => error = 'Please add your name and telephone number.');
      return false;
    }
    if (step == 1 && dogName.text.trim().isEmpty) {
      setState(() => error = 'Please add your dog’s name.');
      return false;
    }
    setState(() => error = '');
    return true;
  }

  Future<void> createAccount() async {
    if (email.text.trim().isEmpty || password.text.length < 6) {
      setState(() => error = 'Please enter a valid email and a password of at least 6 characters.');
      return;
    }
    setState(() { busy = true; error = ''; });
    try {
      final result = await FirebaseAuth.instance.createUserWithEmailAndPassword(email: email.text.trim(), password: password.text);
      await service.createLearner(
        uid: result.user!.uid,
        name: name.text,
        email: email.text,
        phone: phone.text,
        dogName: dogName.text,
        breed: breed.text,
        ageText: age.text,
        dateOfBirth: dateOfBirth.text,
        dobEstimated: dobEstimated,
        experience: experience.text,
        notes: notes.text,
        languageCode: LanguageController.current,
      );
      // Firebase keeps the new learner signed in. AuthGate takes them straight to their waiting/account screen.
    } on FirebaseAuthException catch (e) {
      if (mounted) setState(() => error = e.message ?? 'Could not create your account.');
    } catch (_) {
      if (mounted) setState(() => error = 'Something went wrong while creating the Academy profile.');
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  void dispose() {
    for (final c in [email, password, name, phone, dogName, breed, age, dateOfBirth, experience, notes]) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(backgroundColor: Colors.transparent, surfaceTintColor: Colors.transparent, elevation: 0, actions: const [Padding(padding: EdgeInsets.only(right: 12), child: LanguageToggle())]),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [Color(0xFFFDF8EB), Color(0xFFE8F2F4)]),
        ),
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 620),
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 260),
                    child: mode == 'landing' ? _landing() : mode == 'signin' ? _signIn() : _register(),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _header(String subtitle) => Column(children: [
        const Icon(Icons.sailing, size: 62),
        const SizedBox(height: 8),
        I18nText('Menai Muttineers Academy', textAlign: TextAlign.center, style: Theme.of(context).textTheme.headlineSmall),
        const SizedBox(height: 5),
        I18nText(subtitle, textAlign: TextAlign.center),
      ]);

  Widget _landing() => Column(key: const ValueKey('landing'), crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        _header('Your pre-flyball adventure starts here.'),
        const SizedBox(height: 28),
        I18nText('New to the Academy?', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        SizedBox(
          height: 62,
          child: FilledButton.icon(
            onPressed: () => setState(() { mode = 'register'; step = 0; error = ''; }),
            icon: const Icon(Icons.flag_circle, size: 27),
            label: const I18nText('CREATE MY ACCOUNT', style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
          ),
        ),
        const SizedBox(height: 22),
        I18nText('Already aboard?', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        SizedBox(
          height: 58,
          child: OutlinedButton.icon(
            onPressed: () => setState(() { mode = 'signin'; error = ''; }),
            icon: const Icon(Icons.login, size: 26),
            label: const I18nText('EXISTING USER — SIGN IN', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          ),
        ),
        const SizedBox(height: 18),
        const I18nText('Create an account once, then use the same login on the Android app or the web Academy.', textAlign: TextAlign.center),
      ]);

  Widget _signIn() => Column(key: const ValueKey('signin'), crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        _header('Welcome back aboard.'),
        const SizedBox(height: 22),
        TextField(controller: email, keyboardType: TextInputType.emailAddress, decoration: const InputDecoration(label: I18nText('Email'))),
        const SizedBox(height: 10),
        TextField(controller: password, obscureText: true, onSubmitted: (_) => signIn(), decoration: const InputDecoration(label: I18nText('Password'))),
        if (error.isNotEmpty) ...[const SizedBox(height: 10), I18nText(error, style: TextStyle(color: Theme.of(context).colorScheme.error))],
        const SizedBox(height: 16),
        SizedBox(height: 54, child: FilledButton(onPressed: busy ? null : signIn, child: I18nText(busy ? 'Signing in...' : 'SIGN IN'))),
        TextButton.icon(onPressed: busy ? null : resetPassword, icon: const Icon(Icons.lock_reset), label: const I18nText('Forgot password?')),
        const Divider(height: 24),
        OutlinedButton(onPressed: busy ? null : () => setState(() { mode = 'landing'; error = ''; }), child: const I18nText('Back to account choices')),
      ]);

  Widget _register() {
    final steps = [
      _registerPerson(),
      _registerDog(),
      _registerLogin(),
    ];
    return Column(key: const ValueKey('register'), crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      _header('Welcome aboard — we’ll set you up in three simple steps.'),
      const SizedBox(height: 18),
      Row(children: List.generate(3, (i) => Expanded(child: Padding(
        padding: EdgeInsets.only(right: i == 2 ? 0 : 5),
        child: LinearProgressIndicator(value: i <= step ? 1 : 0, minHeight: 7, borderRadius: BorderRadius.circular(8)),
      )))),
      const SizedBox(height: 10),
      I18nText('Step ${step + 1} of 3', textAlign: TextAlign.center, style: const TextStyle(fontWeight: FontWeight.bold)),
      const SizedBox(height: 18),
      steps[step],
      if (error.isNotEmpty) ...[const SizedBox(height: 10), I18nText(error, style: TextStyle(color: Theme.of(context).colorScheme.error))],
      const SizedBox(height: 18),
      Row(children: [
        if (step > 0) Expanded(child: OutlinedButton(onPressed: busy ? null : () => setState(() { step--; error = ''; }), child: const I18nText('Back'))),
        if (step > 0) const SizedBox(width: 10),
        Expanded(child: FilledButton(
          onPressed: busy ? null : () {
            if (step < 2) {
              if (_validateStep()) setState(() => step++);
            } else {
              createAccount();
            }
          },
          child: I18nText(busy ? 'Please wait...' : step == 2 ? 'CREATE ACCOUNT' : 'Continue'),
        )),
      ]),
      const SizedBox(height: 8),
      TextButton(onPressed: busy ? null : () => setState(() { mode = 'landing'; error = ''; }), child: const I18nText('Cancel and return to start')),
    ]);
  }

  Widget _registerPerson() => Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        I18nText('Tell us about you', style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 10),
        TextField(controller: name, decoration: const InputDecoration(label: I18nText('Your name'))),
        const SizedBox(height: 10),
        TextField(controller: phone, keyboardType: TextInputType.phone, decoration: const InputDecoration(label: I18nText('Telephone number'))),
      ]);

  Widget _registerDog() => Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        I18nText('Tell us about your dog', style: Theme.of(context).textTheme.titleLarge),
        const I18nText('You can add more dogs later. Each registered dog has its own Academy adventure.'),
        const SizedBox(height: 10),
        TextField(controller: dogName, decoration: const InputDecoration(label: I18nText('Dog’s name'))),
        const SizedBox(height: 10),
        TextField(controller: breed, decoration: const InputDecoration(label: I18nText('Breed'))),
        const SizedBox(height: 10),
        TextField(controller: age, decoration: const InputDecoration(label: I18nText('Dog’s age (optional)'))),
        const SizedBox(height: 10),
        TextField(controller: dateOfBirth, readOnly: true, onTap: pickDob, decoration: const InputDecoration(label: I18nText('Date of birth (optional)'), hint: I18nText('Best guess is fine'), suffixIcon: Icon(Icons.cake_outlined))),
        CheckboxListTile(value: dobEstimated, contentPadding: EdgeInsets.zero, title: const I18nText('This date is an estimate'), onChanged: (v) => setState(() => dobEstimated = v ?? false)),
        TextField(controller: experience, minLines: 2, maxLines: 3, decoration: const InputDecoration(label: I18nText('Previous training experience (optional)'))),
        const SizedBox(height: 10),
        TextField(controller: notes, minLines: 2, maxLines: 4, decoration: const InputDecoration(label: I18nText('Anything the trainers should know (optional)'))),
      ]);

  Widget _registerLogin() => Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        I18nText('Create your login', style: Theme.of(context).textTheme.titleLarge),
        const I18nText('You will stay signed in after registration — there is no need to sign in again.'),
        const SizedBox(height: 10),
        TextField(controller: email, keyboardType: TextInputType.emailAddress, decoration: const InputDecoration(label: I18nText('Email'))),
        const SizedBox(height: 10),
        TextField(controller: password, obscureText: true, decoration: const InputDecoration(label: I18nText('Password'), helperText: 'At least 6 characters')),
      ]);
}
