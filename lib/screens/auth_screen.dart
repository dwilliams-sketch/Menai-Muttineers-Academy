import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../services/firestore_service.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  bool registering = false;
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

  Future<void> pickDob() async {
    final now = DateTime.now();
    final chosen = await showDatePicker(
      context: context,
      firstDate: DateTime(now.year - 30),
      lastDate: now,
      initialDate: DateTime(now.year - 2, now.month, now.day),
      helpText: 'Dog date of birth — best guess is fine',
    );
    if (chosen != null) {
      dateOfBirth.text = '${chosen.year.toString().padLeft(4, '0')}-${chosen.month.toString().padLeft(2, '0')}-${chosen.day.toString().padLeft(2, '0')}';
    }
  }

  Future<void> submit() async {
    if (email.text.trim().isEmpty || password.text.length < 6) {
      setState(() => error = 'Please enter an email address and a password of at least 6 characters.');
      return;
    }
    if (registering && (name.text.trim().isEmpty || dogName.text.trim().isEmpty)) {
      setState(() => error = 'Please enter your name and your dog’s name.');
      return;
    }
    setState(() { busy = true; error = ''; });
    try {
      if (registering) {
        final result = await FirebaseAuth.instance.createUserWithEmailAndPassword(
          email: email.text.trim(),
          password: password.text,
        );
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
        );
      } else {
        await FirebaseAuth.instance.signInWithEmailAndPassword(
          email: email.text.trim(),
          password: password.text,
        );
      }
    } on FirebaseAuthException catch (e) {
      setState(() => error = e.message ?? 'Could not sign in.');
    } catch (e) {
      setState(() => error = 'Something went wrong while setting up the account.');
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 560),
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                  const Icon(Icons.sailing, size: 58),
                  const SizedBox(height: 8),
                  Text('Menai Muttineers Academy', textAlign: TextAlign.center, style: Theme.of(context).textTheme.headlineSmall),
                  const SizedBox(height: 4),
                  Text(registering ? 'Create your learner and dog profile' : 'Sign in to continue your pre-flyball journey', textAlign: TextAlign.center),
                  const SizedBox(height: 20),
                  if (registering) ...[
                    TextField(controller: name, decoration: const InputDecoration(labelText: 'Your name')),
                    const SizedBox(height: 10),
                    TextField(controller: phone, decoration: const InputDecoration(labelText: 'Telephone number')),
                    const SizedBox(height: 10),
                    TextField(controller: dogName, decoration: const InputDecoration(labelText: 'Dog’s name')),
                    const SizedBox(height: 10),
                    TextField(controller: breed, decoration: const InputDecoration(labelText: 'Breed')),
                    const SizedBox(height: 10),
                    TextField(controller: age, decoration: const InputDecoration(labelText: 'Dog’s age (optional)')),
                    const SizedBox(height: 10),
                    TextField(
                      controller: dateOfBirth,
                      readOnly: true,
                      onTap: pickDob,
                      decoration: const InputDecoration(
                        labelText: 'Dog’s date of birth (optional)',
                        hintText: 'Best guess is fine',
                        suffixIcon: Icon(Icons.cake_outlined),
                      ),
                    ),
                    CheckboxListTile(
                      value: dobEstimated,
                      contentPadding: EdgeInsets.zero,
                      title: const Text('This date is an estimate'),
                      subtitle: const Text('That is absolutely fine — we mainly use it for birthday celebrations.'),
                      onChanged: (v) => setState(() => dobEstimated = v ?? false),
                    ),
                    TextField(controller: experience, minLines: 2, maxLines: 3, decoration: const InputDecoration(labelText: 'Previous training experience')),
                    const SizedBox(height: 10),
                    TextField(controller: notes, minLines: 2, maxLines: 4, decoration: const InputDecoration(labelText: 'Anything the trainers should know')),
                    const SizedBox(height: 10),
                  ],
                  TextField(controller: email, keyboardType: TextInputType.emailAddress, decoration: const InputDecoration(labelText: 'Email')),
                  const SizedBox(height: 10),
                  TextField(controller: password, obscureText: true, decoration: const InputDecoration(labelText: 'Password')),
                  if (error.isNotEmpty) ...[
                    const SizedBox(height: 10),
                    Text(error, style: TextStyle(color: Theme.of(context).colorScheme.error)),
                  ],
                  const SizedBox(height: 16),
                  FilledButton(onPressed: busy ? null : submit, child: Text(busy ? 'Please wait...' : registering ? 'Create account' : 'Sign in')),
                  TextButton(
                    onPressed: busy ? null : () => setState(() { registering = !registering; error = ''; }),
                    child: Text(registering ? 'Already registered? Sign in' : 'New learner? Create account'),
                  ),
                ]),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
