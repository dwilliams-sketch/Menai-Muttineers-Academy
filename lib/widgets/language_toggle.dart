import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../i18n.dart';

class LanguageToggle extends StatelessWidget {
  final String? userId;
  const LanguageToggle({super.key, this.userId});

  Future<void> _set(String code) async {
    // Switch the interface immediately. Firestore persistence happens after;
    // AuthGate no longer overwrites this with an older snapshot.
    await LanguageController.set(code);
    final uid = userId;
    if (uid != null && uid.isNotEmpty) {
      try {
        await FirebaseFirestore.instance.collection('users').doc(uid).update({'languageCode': code});
      } catch (_) {}
    }
  }

  @override
  Widget build(BuildContext context) => ValueListenableBuilder<String>(
        valueListenable: LanguageController.language,
        builder: (context, current, _) => Container(
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface.withValues(alpha: .92),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
          ),
          padding: const EdgeInsets.all(2),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            _choice(context, 'EN', 'en', current),
            _choice(context, 'CY', 'cy', current),
          ]),
        ),
      );

  Widget _choice(BuildContext context, String label, String code, String current) {
    final selected = current == code;
    return InkWell(
      borderRadius: BorderRadius.circular(15),
      onTap: () => _set(code),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
        decoration: BoxDecoration(
          color: selected ? Theme.of(context).colorScheme.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(15),
        ),
        child: Text(label, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: selected ? Theme.of(context).colorScheme.onPrimary : null)),
      ),
    );
  }
}
