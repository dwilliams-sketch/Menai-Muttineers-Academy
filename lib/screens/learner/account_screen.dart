import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../../i18n.dart';
import '../../models.dart';
import '../../services/firestore_service.dart';

class AccountScreen extends StatefulWidget {
  final AppUser profile;
  final DogProfile dog;
  const AccountScreen({super.key, required this.profile, required this.dog});
  @override
  State<AccountScreen> createState() => _AccountScreenState();
}

class _AccountScreenState extends State<AccountScreen> {
  final service = FirestoreService();

  Future<void> _reportPayment(AppLinks links, AcademyConfig config) async {
    final amount = TextEditingController(text: config.dogPeriodCost.toStringAsFixed(2));
    String method = 'Bank transfer';
    final ok = await showDialog<bool>(context: context, builder: (ctx) => StatefulBuilder(builder: (ctx, setLocal) => AlertDialog(
      title: const I18nText('I’ve made a payment'),
      content: Column(mainAxisSize: MainAxisSize.min, children: [
        TextField(controller: amount, keyboardType: const TextInputType.numberWithOptions(decimal: true), decoration: const InputDecoration(label: I18nText('Amount sent (£)'))),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(initialValue: method, items: const ['Bank transfer','Standing order','Other'].map((e) => DropdownMenuItem(value: e, child: I18nText(e))).toList(), onChanged: (v) => setLocal(() => method = v ?? method), decoration: const InputDecoration(label: I18nText('Method'))),
      ]),
      actions: [TextButton(onPressed: () => Navigator.pop(ctx, false), child: const I18nText('Cancel')), FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const I18nText('Send to Admin'))],
    )));
    final value = double.tryParse(amount.text.trim());
    if (ok == true && value != null && value > 0) {
      await service.submitPaymentNotice(uid: widget.profile.id, dogId: widget.dog.id, dogName: widget.dog.name, memberName: widget.profile.name, amount: value, method: method);
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: I18nText('Payment notice sent to Admin.')));
    }
    amount.dispose();
  }

  Future<void> _addDog() async {
    final name = TextEditingController();
    final breed = TextEditingController();
    final dob = TextEditingController();
    bool estimated = false;
    final ok = await showDialog<bool>(context: context, builder: (ctx) => StatefulBuilder(builder: (ctx, setLocal) => AlertDialog(
      title: const I18nText('Add another Academy dog'),
      content: SizedBox(width: 480, child: SingleChildScrollView(child: Column(children: [
        TextField(controller: name, decoration: const InputDecoration(label: I18nText('Dog name'))),
        const SizedBox(height: 8),
        TextField(controller: breed, decoration: const InputDecoration(label: I18nText('Breed'))),
        const SizedBox(height: 8),
        TextField(controller: dob, decoration: const InputDecoration(label: I18nText('Date of birth YYYY-MM-DD (optional)'))),
        CheckboxListTile(contentPadding: EdgeInsets.zero, value: estimated, onChanged: (v) => setLocal(() => estimated = v ?? false), title: const I18nText('Date is estimated')),
        const I18nText('Each dog has its own paid Academy adventure. The new dog will wait for Admin to activate it.'),
      ]))),
      actions: [TextButton(onPressed: () => Navigator.pop(ctx, false), child: const I18nText('Cancel')), FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const I18nText('Add dog'))],
    )));
    if (ok == true && name.text.trim().isNotEmpty) {
      await service.addDog(uid: widget.profile.id, name: name.text, breed: breed.text, dateOfBirth: dob.text, dobEstimated: estimated);
    }
    name.dispose(); breed.dispose(); dob.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final status = widget.dog.effectiveStatus(widget.profile);
    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: service.academySettings(),
      builder: (context, academySnap) {
        final config = AcademyConfig.fromMap(academySnap.data?.data() ?? {});
        final ref = service.paymentReference(
          dogName: widget.dog.name,
          memberName: widget.profile.name,
          suffix: config.paymentReferenceSuffix,
        );
        return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
          stream: service.linkSettings(),
          builder: (context, linkSnap) {
            final links = AppLinks.fromMap(linkSnap.data?.data() ?? {});
            return ListView(padding: const EdgeInsets.all(16), children: [
              I18nText('My Academy Account', style: Theme.of(context).textTheme.headlineSmall),
              const SizedBox(height: 8),
              Card(child: Padding(padding: const EdgeInsets.all(16), child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                Row(children: [const Icon(Icons.account_balance_wallet), const SizedBox(width: 8), Expanded(child: I18nText('Academy Credit', style: Theme.of(context).textTheme.titleLarge)), I18nText('£${widget.profile.academyCredit.toStringAsFixed(2)}', style: Theme.of(context).textTheme.headlineSmall)]),
                const SizedBox(height: 8),
                I18nText('Credit is added by Admin after checking your payment. Each active dog uses ${config.priceLabel()} for a ${config.dogPeriodDays}-day Academy voyage.'),
              ]))),
              Card(child: Padding(padding: const EdgeInsets.all(16), child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                I18nText('${widget.dog.name} — ${status.toUpperCase()}', style: Theme.of(context).textTheme.titleLarge),
                if (widget.dog.accessUntil != null) I18nText('Current paid access ends: ${_date(widget.dog.accessUntil!)}'),
                if (status == 'active') ...[
                  const SizedBox(height: 8),
                  if (widget.dog.pauseRequested) ...[
                    I18nText('⚓ Pause scheduled. No new ${config.priceLabel()} period will start when this paid voyage ends.'),
                    OutlinedButton(onPressed: () => service.cancelDogPause(widget.dog.id), child: const I18nText('KEEP ADVENTURE GOING')),
                  ] else
                    OutlinedButton.icon(onPressed: () => service.requestDogPause(uid: widget.profile.id, dogId: widget.dog.id), icon: const Icon(Icons.pause_circle_outline), label: const I18nText('PAUSE AT END OF CURRENT VOYAGE')),
                ],
                if (status == 'paused' || status == 'renewal_due' || status == 'awaiting') ...[
                  const SizedBox(height: 8),
                  FilledButton.icon(onPressed: () async {
                    await service.requestRestart(uid: widget.profile.id, dogId: widget.dog.id, dogName: widget.dog.name);
                    if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: I18nText('Restart request sent to Admin.')));
                  }, icon: const Icon(Icons.play_circle), label: const I18nText('RESTART ADVENTURE')),
                  I18nText('Admin will use ${config.priceLabel()} of available Academy credit to start another ${config.dogPeriodDays} days.'),
                ],
              ]))),
              Card(child: Padding(padding: const EdgeInsets.all(16), child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                I18nText('Add Academy Credit', style: Theme.of(context).textTheme.titleLarge),
                const I18nText('Pay outside the app using your normal bank. The app never handles your bank card or account login.'),
                const SizedBox(height: 10),
                if (links.accountName.isNotEmpty) I18nText('Account name: ${links.accountName}'),
                if (links.bankName.isNotEmpty) I18nText('Bank: ${links.bankName}'),
                if (links.sortCode.isNotEmpty) I18nText('Sort code: ${links.sortCode}'),
                if (links.accountNumber.isNotEmpty) I18nText('Account number: ${links.accountNumber}'),
                const SizedBox(height: 10),
                const I18nText('Your payment reference:', style: TextStyle(fontWeight: FontWeight.bold)),
                SelectableText(ref, style: Theme.of(context).textTheme.titleLarge),
                I18nText('Please use this exact reference so we know who and which dog the payment relates to. Reference suffix: ${config.paymentReferenceSuffix}.'),
                if (links.directDebitInfo.isNotEmpty) ...[const Divider(), I18nText(links.directDebitInfo)],
                const SizedBox(height: 10),
                FilledButton.icon(onPressed: () => _reportPayment(links, config), icon: const Icon(Icons.outgoing_mail), label: const I18nText('I’VE MADE A PAYMENT')),
              ]))),
              const SizedBox(height: 8),
              FilledButton.tonalIcon(onPressed: _addDog, icon: const Icon(Icons.add), label: const I18nText('ADD ANOTHER DOG')),
              const SizedBox(height: 12),
              I18nText('Account History', style: Theme.of(context).textTheme.titleLarge),
              StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                stream: service.ledgerForUser(widget.profile.id),
                builder: (context, snap) {
                  final docs = [...(snap.data?.docs ?? [])];
                  docs.sort((a,b) => ((b.data()['createdAt'] as Timestamp?)?.millisecondsSinceEpoch ?? 0).compareTo((a.data()['createdAt'] as Timestamp?)?.millisecondsSinceEpoch ?? 0));
                  if (docs.isEmpty) return const Card(child: Padding(padding: EdgeInsets.all(16), child: I18nText('No account activity recorded yet.')));
                  return Column(children: docs.take(30).map((d) {
                    final m = d.data(); final amount = (m['amount'] as num?)?.toDouble() ?? 0;
                    return Card(child: ListTile(leading: Icon(amount >= 0 ? Icons.add_circle : Icons.remove_circle), title: I18nText(m['description'] ?? 'Academy account'), trailing: I18nText('${amount >= 0 ? '+' : ''}£${amount.toStringAsFixed(2)}')));
                  }).toList());
                },
              ),
            ]);
          },
        );
      },
    );
  }

  String _date(DateTime d) => '${d.day.toString().padLeft(2,'0')}/${d.month.toString().padLeft(2,'0')}/${d.year}';
}
