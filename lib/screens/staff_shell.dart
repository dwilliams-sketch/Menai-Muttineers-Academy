import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../course_data.dart';
import '../models.dart';
import '../services/firestore_service.dart';

class StaffShell extends StatefulWidget {
  final AppUser profile;
  const StaffShell({super.key, required this.profile});

  @override
  State<StaffShell> createState() => _StaffShellState();
}

class _StaffShellState extends State<StaffShell> {
  int index = 0;

  @override
  Widget build(BuildContext context) {
    final pages = <Widget>[
      StaffDashboard(profile: widget.profile),
      ReviewQueue(profile: widget.profile),
      QuestionQueue(profile: widget.profile),
      OneToOneQueue(profile: widget.profile),
      LearnerList(profile: widget.profile),
      if (widget.profile.isAdmin) AdminCourse(profile: widget.profile),
    ];
    final destinations = <NavigationDestination>[
      const NavigationDestination(icon: Icon(Icons.dashboard_outlined), selectedIcon: Icon(Icons.dashboard), label: 'Dashboard'),
      const NavigationDestination(icon: Icon(Icons.video_library_outlined), selectedIcon: Icon(Icons.video_library), label: 'Reviews'),
      const NavigationDestination(icon: Icon(Icons.question_answer_outlined), selectedIcon: Icon(Icons.question_answer), label: 'Questions'),
      const NavigationDestination(icon: Icon(Icons.event_available_outlined), selectedIcon: Icon(Icons.event_available), label: '1-to-1'),
      const NavigationDestination(icon: Icon(Icons.groups_outlined), selectedIcon: Icon(Icons.groups), label: 'Learners'),
      if (widget.profile.isAdmin)
        const NavigationDestination(icon: Icon(Icons.admin_panel_settings_outlined), selectedIcon: Icon(Icons.admin_panel_settings), label: 'Admin'),
    ];
    if (index >= pages.length) index = 0;
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.profile.isAdmin ? 'Captain/Admin — Academy V1.2' : 'Trainer — Academy V1.2'),
        actions: [IconButton(onPressed: () => FirebaseAuth.instance.signOut(), icon: const Icon(Icons.logout))],
      ),
      body: pages[index],
      bottomNavigationBar: NavigationBar(
        selectedIndex: index,
        labelBehavior: NavigationDestinationLabelBehavior.onlyShowSelected,
        onDestinationSelected: (v) => setState(() => index = v),
        destinations: destinations,
      ),
    );
  }
}

class StaffDashboard extends StatelessWidget {
  final AppUser profile;
  StaffDashboard({super.key, required this.profile});
  final service = FirestoreService();

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1000),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            Text('Academy Overview', style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: 12),
            Wrap(spacing: 10, runSpacing: 10, children: [
              _CountCard(title: 'Learners', stream: service.allUsers(), count: (docs) => docs.where((d) => d.data()['role'] == 'learner').length),
              _CountCard(title: 'Awaiting payment', stream: service.allUsers(), count: (docs) => docs.where((d) => d.data()['role'] == 'learner' && d.data()['paymentStatus'] == 'unpaid').length),
              _CountCard(title: 'Assessments waiting', stream: service.allSubmissions(), count: (docs) => docs.where((d) => d.data()['status'] == 'waiting').length),
              _CountCard(title: 'Open questions', stream: service.allQuestions(), count: (docs) => docs.where((d) => d.data()['status'] == 'open').length),
              _CountCard(title: '1-to-1 requests', stream: service.allOneToOnes(), count: (docs) => docs.where((d) => d.data()['status'] == 'requested').length),
              _CountCard(title: 'Merch interest', stream: service.allMerchInterest(), count: (docs) => docs.length),
            ]),
            const SizedBox(height: 14),
            Text('Needs a nudge', style: Theme.of(context).textTheme.titleLarge),
            StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: service.allUsers(),
              builder: (context, snap) {
                if (!snap.hasData) return const LinearProgressIndicator();
                final cutoff = DateTime.now().subtract(const Duration(days: 14));
                final quiet = snap.data!.docs.where((d) {
                  final m = d.data();
                  if (m['role'] != 'learner') return false;
                  final ts = m['lastActiveAt'];
                  final dt = ts is Timestamp ? ts.toDate() : null;
                  return dt == null || dt.isBefore(cutoff);
                }).toList();
                if (quiet.isEmpty) return const Card(child: Padding(padding: EdgeInsets.all(16), child: Text('No learners have been inactive for 14+ days.')));
                return Column(children: quiet.map((d) => Card(child: ListTile(
                  leading: const Icon(Icons.notifications_active_outlined),
                  title: Text(d.data()['name'] ?? 'Learner'),
                  subtitle: const Text('No recorded activity for 14+ days'),
                ))).toList());
              },
            ),
            const SizedBox(height: 14),
            Text('Common training topics', style: Theme.of(context).textTheme.titleLarge),
            StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: service.allQuestions(),
              builder: (context, snap) {
                final counts = <String, int>{};
                for (final d in snap.data?.docs ?? []) {
                  final c = (d.data()['category'] ?? 'Other').toString();
                  counts[c] = (counts[c] ?? 0) + 1;
                }
                final items = counts.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
                if (items.isEmpty) return const Card(child: Padding(padding: EdgeInsets.all(16), child: Text('No training questions recorded yet.')));
                return Card(child: Padding(padding: const EdgeInsets.all(12), child: Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: items.take(8).map((e) => Chip(label: Text('${e.key}: ${e.value}'))).toList(),
                )));
              },
            ),
          ]),
        ),
      ),
    );
  }
}

class _CountCard extends StatelessWidget {
  final String title;
  final Stream<QuerySnapshot<Map<String, dynamic>>> stream;
  final int Function(List<QueryDocumentSnapshot<Map<String, dynamic>>>) count;
  const _CountCard({required this.title, required this.stream, required this.count});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 180,
      child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: stream,
        builder: (context, snap) => Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(snap.hasData ? count(snap.data!.docs).toString() : '…', style: Theme.of(context).textTheme.headlineMedium),
              Text(title),
            ]),
          ),
        ),
      ),
    );
  }
}

class ReviewQueue extends StatelessWidget {
  final AppUser profile;
  ReviewQueue({super.key, required this.profile});
  final service = FirestoreService();

  Future<void> _launch(String url) async {
    final uri = Uri.tryParse(url);
    if (uri != null) await launchUrl(uri, mode: LaunchMode.platformDefault);
  }

  Future<void> _review(BuildContext context, QueryDocumentSnapshot<Map<String, dynamic>> doc, bool passed) async {
    final feedback = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(passed ? 'Pass skill and award trophy?' : 'Keep practising'),
        content: TextField(controller: feedback, maxLines: 4, decoration: const InputDecoration(labelText: 'Trainer feedback')),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: Text(passed ? 'Pass + Trophy' : 'Send feedback')),
        ],
      ),
    );
    if (ok != true) return;
    final m = doc.data();
    await service.reviewSubmission(
      submissionId: doc.id,
      dogId: m['dogId'] ?? '',
      moduleId: m['moduleId'] ?? '',
      trophyTitle: m['trophyTitle'] ?? 'Achievement',
      moduleTitle: m['moduleTitle'] ?? 'Skill',
      artKey: m['artKey'] ?? 'firstskill',
      reviewerName: profile.name,
      feedback: feedback.text,
      passed: passed,
    );
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: service.allSubmissions(),
      builder: (context, snap) {
        final docs = (snap.data?.docs ?? []).where((d) => d.data()['status'] == 'waiting').toList();
        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Text('Assessments Awaiting Review', style: Theme.of(context).textTheme.headlineSmall),
            const Text('Learners can only reach this queue after completing all lessons in that Key Skill.'),
            const SizedBox(height: 8),
            if (!snap.hasData) const LinearProgressIndicator(),
            if (snap.hasData && docs.isEmpty) const Card(child: Padding(padding: EdgeInsets.all(16), child: Text('No assessments are waiting.'))),
            ...docs.map((d) {
              final m = d.data();
              return Card(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                    Text('${m['learnerName'] ?? 'Learner'} & ${m['dogName'] ?? 'Dog'}', style: Theme.of(context).textTheme.titleMedium),
                    Text(m['moduleTitle'] ?? 'Skill'),
                    if ((m['note'] ?? '').toString().isNotEmpty) Text('Note: ${m['note']}'),
                    const SizedBox(height: 8),
                    Wrap(spacing: 8, runSpacing: 8, children: [
                      OutlinedButton.icon(onPressed: () => _launch((m['videoUrl'] ?? '').toString()), icon: const Icon(Icons.play_arrow), label: const Text('Open video')),
                      FilledButton.icon(onPressed: () => _review(context, d, true), icon: const Icon(Icons.emoji_events), label: const Text('Pass + Trophy')),
                      OutlinedButton.icon(onPressed: () => _review(context, d, false), icon: const Icon(Icons.build), label: const Text('Keep practising')),
                    ]),
                  ]),
                ),
              );
            }),
          ],
        );
      },
    );
  }
}

class QuestionQueue extends StatelessWidget {
  final AppUser profile;
  QuestionQueue({super.key, required this.profile});
  final service = FirestoreService();

  Future<void> answer(BuildContext context, QueryDocumentSnapshot<Map<String, dynamic>> doc) async {
    final controller = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Reply to learner'),
        content: TextField(controller: controller, maxLines: 5, decoration: const InputDecoration(labelText: 'Trainer answer')),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Send reply')),
        ],
      ),
    );
    if (ok == true && controller.text.trim().isNotEmpty) await service.answerQuestion(doc.id, controller.text, profile.name);
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: service.allQuestions(),
      builder: (context, snap) {
        final docs = (snap.data?.docs ?? []).where((d) => d.data()['status'] == 'open').toList();
        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Text('Questions Waiting', style: Theme.of(context).textTheme.headlineSmall),
            if (docs.isEmpty) const Card(child: Padding(padding: EdgeInsets.all(16), child: Text('No open questions.'))),
            ...docs.map((d) {
              final m = d.data();
              return Card(child: ListTile(
                title: Text('${m['learnerName'] ?? 'Learner'} & ${m['dogName'] ?? 'Dog'} — ${m['category'] ?? 'Question'}'),
                subtitle: Text(m['question'] ?? ''),
                trailing: FilledButton(onPressed: () => answer(context, d), child: const Text('Reply')),
              ));
            }),
          ],
        );
      },
    );
  }
}

class OneToOneQueue extends StatelessWidget {
  final AppUser profile;
  OneToOneQueue({super.key, required this.profile});
  final service = FirestoreService();

  Future<void> edit(BuildContext context, QueryDocumentSnapshot<Map<String, dynamic>> doc) async {
    final m = doc.data();
    String status = (m['status'] ?? 'requested').toString();
    final trainer = TextEditingController(text: (m['trainerName'] ?? profile.name).toString());
    final when = TextEditingController(text: (m['proposedWhen'] ?? '').toString());
    final meet = TextEditingController(text: (m['meetUrl'] ?? '').toString());
    final notes = TextEditingController(text: (m['trainerNotes'] ?? '').toString());
    final homework = TextEditingController(text: (m['homework'] ?? '').toString());
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(builder: (ctx, setLocal) => AlertDialog(
        title: Text('${m['learnerName']} & ${m['dogName']}'),
        content: SizedBox(
          width: 520,
          child: SingleChildScrollView(
            child: Column(children: [
              DropdownButtonFormField<String>(
                initialValue: status,
                decoration: const InputDecoration(labelText: 'Status'),
                items: const ['requested', 'proposed', 'booked', 'completed', 'declined', 'cancelled'].map((e) => DropdownMenuItem(value: e, child: Text(e.toUpperCase()))).toList(),
                onChanged: (v) => setLocal(() => status = v ?? status),
              ),
              const SizedBox(height: 8),
              TextField(controller: trainer, decoration: const InputDecoration(labelText: 'Trainer')),
              const SizedBox(height: 8),
              TextField(controller: when, decoration: const InputDecoration(labelText: 'Proposed / booked date and time')),
              const SizedBox(height: 8),
              TextField(controller: meet, decoration: const InputDecoration(labelText: 'Google Meet link (if online)')),
              const SizedBox(height: 8),
              TextField(controller: notes, maxLines: 3, decoration: const InputDecoration(labelText: 'Trainer notes')),
              const SizedBox(height: 8),
              TextField(controller: homework, maxLines: 3, decoration: const InputDecoration(labelText: 'Homework / next steps')),
            ]),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Save')),
        ],
      )),
    );
    if (ok == true) {
      await service.staffUpdateOneToOne(
        id: doc.id,
        status: status,
        trainerName: trainer.text,
        proposedWhen: when.text,
        meetUrl: meet.text,
        trainerNotes: notes.text,
        homework: homework.text,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: service.allOneToOnes(),
      builder: (context, snap) {
        final docs = [...(snap.data?.docs ?? [])];
        const order = {'requested': 0, 'proposed': 1, 'booked': 2, 'completed': 3, 'declined': 4, 'cancelled': 5};
        docs.sort((a, b) => (order[a.data()['status']] ?? 9).compareTo(order[b.data()['status']] ?? 9));
        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Text('1-to-1 Requests & Bookings', style: Theme.of(context).textTheme.headlineSmall),
            const Text('Assign a trainer, suggest a time, add a Meet link, then record notes and homework after the session.'),
            const SizedBox(height: 8),
            if (docs.isEmpty) const Card(child: Padding(padding: EdgeInsets.all(16), child: Text('No requests yet.'))),
            ...docs.map((d) {
              final m = d.data();
              return Card(child: ListTile(
                leading: const Icon(Icons.event_available),
                title: Text('${m['learnerName'] ?? 'Learner'} & ${m['dogName'] ?? 'Dog'} — ${m['topic'] ?? '1-to-1'}'),
                subtitle: Text('${(m['status'] ?? 'requested').toString().toUpperCase()} • ${m['format'] ?? ''} • ${m['availability'] ?? ''}${(m['proposedWhen'] ?? '').toString().isEmpty ? '' : '\n${m['proposedWhen']}'}'),
                trailing: FilledButton(onPressed: () => edit(context, d), child: const Text('Manage')),
              ));
            }),
          ],
        );
      },
    );
  }
}

class LearnerList extends StatelessWidget {
  final AppUser profile;
  LearnerList({super.key, required this.profile});
  final service = FirestoreService();

  Future<void> showCode(BuildContext context, String code) async {
    await showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Access code issued'),
        content: SelectableText(code, style: Theme.of(context).textTheme.headlineMedium),
        actions: [FilledButton(onPressed: () => Navigator.pop(ctx), child: const Text('Done'))],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: service.allUsers(),
      builder: (context, userSnap) {
        final users = (userSnap.data?.docs ?? []).where((d) => d.data()['role'] == 'learner').toList();
        return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
          stream: service.allDogs(),
          builder: (context, dogSnap) {
            final dogByOwner = <String, Map<String, dynamic>>{};
            for (final d in dogSnap.data?.docs ?? []) {
              dogByOwner[(d.data()['ownerId'] ?? '').toString()] = {'id': d.id, ...d.data()};
            }
            return ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Text('Learners & Dogs', style: Theme.of(context).textTheme.headlineSmall),
                const SizedBox(height: 8),
                ...users.map((u) {
                  final m = u.data();
                  final dog = dogByOwner[u.id] ?? {};
                  final paid = m['paymentStatus'] ?? 'unpaid';
                  final streak = (m['loginStreak'] as num?)?.toInt() ?? 0;
                  return Card(
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                        Text('${m['name'] ?? 'Learner'} & ${dog['name'] ?? 'Dog'}', style: Theme.of(context).textTheme.titleMedium),
                        Text('${m['email'] ?? ''} • ${m['phone'] ?? ''}'),
                        Text('Dog: ${dog['breed'] ?? ''} • ${dog['ageText'] ?? ''}'),
                        if ((dog['dateOfBirth'] ?? '').toString().isNotEmpty) Text('DOB: ${dog['dateOfBirth']}${dog['dobEstimated'] == true ? ' (estimated)' : ''}'),
                        Text('Login streak: $streak days'),
                        if ((dog['experience'] ?? '').toString().isNotEmpty) Text('Experience: ${dog['experience']}'),
                        if ((dog['notes'] ?? '').toString().isNotEmpty) Text('Notes: ${dog['notes']}'),
                        Text('Payment: ${paid.toString().toUpperCase()} • Access: ${(m['activated'] == true) ? 'ACTIVE' : 'LOCKED'}', style: const TextStyle(fontWeight: FontWeight.bold)),
                        if (profile.isAdmin) ...[
                          const SizedBox(height: 8),
                          Wrap(spacing: 8, runSpacing: 8, children: [
                            FilledButton(onPressed: () async { final code = await service.markPaid(u.id); if (context.mounted) await showCode(context, code); }, child: const Text('Mark paid + issue code')),
                            OutlinedButton(onPressed: () async { final code = await service.regenerateCode(u.id); if (context.mounted) await showCode(context, code); }, child: const Text('New access code')),
                            OutlinedButton(onPressed: () => service.markComplimentary(u.id), child: const Text('Complimentary')),
                            OutlinedButton(onPressed: () => service.markUnpaid(u.id), child: const Text('Mark unpaid')),
                          ]),
                        ],
                      ]),
                    ),
                  );
                }),
              ],
            );
          },
        );
      },
    );
  }
}

class AdminCourse extends StatefulWidget {
  final AppUser profile;
  const AdminCourse({super.key, required this.profile});

  @override
  State<AdminCourse> createState() => _AdminCourseState();
}

class _AdminCourseState extends State<AdminCourse> {
  final service = FirestoreService();
  final welcome = TextEditingController();
  final meetWhen = TextEditingController();
  final meetTopic = TextEditingController();
  final meetUrl = TextEditingController();
  final lessonControllers = <String, TextEditingController>{};
  bool loaded = false;

  String _controllerKey(String moduleId, String lessonId) => '$moduleId::$lessonId';

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Center(child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 950),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            Text('Captain/Admin Controls', style: Theme.of(context).textTheme.headlineSmall),
            const Text('V1.2 — live sessions, lesson videos, notices and crew roles can all be managed here.'),
            const SizedBox(height: 10),
            StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
              stream: service.settings(),
              builder: (context, snap) {
                if (snap.hasData && !loaded) {
                  final m = snap.data!.data() ?? {};
                  welcome.text = m['welcomeMessage'] ?? '';
                  meetWhen.text = m['meetWhen'] ?? '';
                  meetTopic.text = m['meetTopic'] ?? '';
                  meetUrl.text = m['meetUrl'] ?? '';
                  loaded = true;
                }
                return Card(child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                    Text('Weekly live session', style: Theme.of(context).textTheme.titleLarge),
                    const SizedBox(height: 8),
                    TextField(controller: welcome, maxLines: 3, decoration: const InputDecoration(labelText: 'Welcome / home message')),
                    const SizedBox(height: 8),
                    TextField(controller: meetWhen, decoration: const InputDecoration(labelText: 'Next session date / time')),
                    const SizedBox(height: 8),
                    TextField(controller: meetTopic, decoration: const InputDecoration(labelText: 'Session topic')),
                    const SizedBox(height: 8),
                    TextField(controller: meetUrl, decoration: const InputDecoration(labelText: 'Google Meet link')),
                    const SizedBox(height: 8),
                    FilledButton(onPressed: () async {
                      await service.saveCourseSettings(welcome: welcome.text, meetWhen: meetWhen.text, meetTopic: meetTopic.text, meetUrl: meetUrl.text);
                      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Course settings saved.')));
                    }, child: const Text('Save live-session settings')),
                  ]),
                ));
              },
            ),
            const SizedBox(height: 10),
            Text('Key Skill video lessons', style: Theme.of(context).textTheme.titleLarge),
            const Text('Each Key Skill now contains 5–9 lessons. Paste an unlisted YouTube URL into every lesson you want learners to complete.'),
            ...courseModules.map((module) => StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
              stream: service.moduleSettings(module.id),
              builder: (context, snap) {
                final data = snap.data?.data() ?? {};
                final videos = Map<String, dynamic>.from(data['lessonVideos'] as Map? ?? {});
                final oldVideo = (data['videoUrl'] ?? '').toString();
                return Card(
                  child: ExpansionTile(
                    title: Text('${module.stage}: ${module.title}'),
                    subtitle: Text('${module.lessons.length} lessons • Trophy: ${module.trophyTitle}'),
                    childrenPadding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                    children: module.lessons.asMap().entries.map((entry) {
                      final i = entry.key;
                      final lesson = entry.value;
                      final key = _controllerKey(module.id, lesson.id);
                      final controller = lessonControllers.putIfAbsent(key, () => TextEditingController());
                      if (controller.text.isEmpty) controller.text = (videos[lesson.id] ?? (i == 0 ? oldVideo : '')).toString();
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 6),
                        child: Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
                          Expanded(child: TextField(controller: controller, decoration: InputDecoration(labelText: '${i + 1}. ${lesson.title} — YouTube URL'))),
                          const SizedBox(width: 8),
                          OutlinedButton(onPressed: () async {
                            await service.saveLessonVideo(module.id, lesson.id, controller.text);
                            if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('${lesson.title} saved.')));
                          }, child: const Text('Save')),
                        ]),
                      );
                    }).toList(),
                  ),
                );
              },
            )),
            const SizedBox(height: 10),
            Text('Captain notices', style: Theme.of(context).textTheme.titleLarge),
            FilledButton.icon(onPressed: () => _addNotice(context), icon: const Icon(Icons.campaign), label: const Text('Publish notice')),
            StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: service.notices(),
              builder: (context, snap) => Column(children: (snap.data?.docs ?? []).map((d) => Card(child: ListTile(
                title: Text(d.data()['title'] ?? 'Notice'),
                subtitle: Text(d.data()['message'] ?? ''),
                trailing: IconButton(onPressed: () => service.removeNotice(d.id), icon: const Icon(Icons.delete_outline)),
              ))).toList()),
            ),
            const SizedBox(height: 14),
            Text('Manage Crew & Staff', style: Theme.of(context).textTheme.titleLarge),
            const Text('Promote registered accounts to Trainer or Admin without going back into Firebase.'),
            StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: service.allUsers(),
              builder: (context, snap) {
                final docs = [...(snap.data?.docs ?? [])]..sort((a, b) => (a.data()['name'] ?? '').toString().compareTo((b.data()['name'] ?? '').toString()));
                return Column(children: docs.map((d) {
                  final m = d.data();
                  final role = (m['role'] ?? 'learner').toString();
                  final self = d.id == widget.profile.id;
                  return Card(child: ListTile(
                    leading: Icon(role == 'admin' ? Icons.admin_panel_settings : role == 'trainer' ? Icons.sports : Icons.person),
                    title: Text(m['name'] ?? 'User'),
                    subtitle: Text('${m['email'] ?? ''}\nCurrent role: ${role.toUpperCase()}${self ? ' • You' : ''}'),
                    isThreeLine: true,
                    trailing: self ? const Chip(label: Text('Captain')) : PopupMenuButton<String>(
                      onSelected: (v) => service.setUserRole(d.id, v),
                      itemBuilder: (_) => const [
                        PopupMenuItem(value: 'learner', child: Text('Set as Learner')),
                        PopupMenuItem(value: 'trainer', child: Text('Set as Trainer')),
                        PopupMenuItem(value: 'admin', child: Text('Set as Admin')),
                      ],
                    ),
                  ));
                }).toList());
              },
            ),
          ]),
        )),
      ],
    );
  }

  Future<void> _addNotice(BuildContext context) async {
    final title = TextEditingController();
    final message = TextEditingController();
    String priority = 'normal';
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(builder: (ctx, setLocal) => AlertDialog(
        title: const Text('Publish Captain notice'),
        content: SizedBox(width: 500, child: Column(mainAxisSize: MainAxisSize.min, children: [
          TextField(controller: title, decoration: const InputDecoration(labelText: 'Title')),
          const SizedBox(height: 8),
          TextField(controller: message, maxLines: 4, decoration: const InputDecoration(labelText: 'Message')),
          const SizedBox(height: 8),
          DropdownButtonFormField<String>(initialValue: priority, items: const [DropdownMenuItem(value: 'normal', child: Text('Normal')), DropdownMenuItem(value: 'important', child: Text('Important'))], onChanged: (v) => setLocal(() => priority = v ?? priority), decoration: const InputDecoration(labelText: 'Priority')),
        ])),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Publish')),
        ],
      )),
    );
    if (ok == true && title.text.trim().isNotEmpty) await service.addNotice(title.text, message.text, priority);
  }
}
