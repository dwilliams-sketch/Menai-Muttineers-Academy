import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;

import '../i18n.dart';

import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

import '../course_data.dart';
import '../models.dart';
import '../services/firestore_service.dart';
import '../services/admin_functions_service.dart';
import '../widgets/language_toggle.dart';
import 'learner/notification_screen.dart';

class StaffShell extends StatefulWidget {
  final AppUser profile;
  const StaffShell({super.key, required this.profile});

  @override
  State<StaffShell> createState() => _StaffShellState();
}

class _StaffShellState extends State<StaffShell> {
  int index = 0;
  int taskTab = 0;
  String helpFilter = '';
  final service = FirestoreService();

  StreamSubscription<RemoteMessage>? _pushOpenSubscription;

  @override
  void initState() {
    super.initState();

    _pushOpenSubscription = FirebaseMessaging.onMessageOpenedApp.listen(
      _openPushMessage,
    );

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final initialMessage = await FirebaseMessaging.instance
          .getInitialMessage();

      if (initialMessage != null && mounted) {
        await _openPushMessage(initialMessage);
      }
    });
  }

  @override
  void dispose() {
    _pushOpenSubscription?.cancel();
    super.dispose();
  }

  Future<void> _openPushMessage(RemoteMessage message) async {
    final type = (message.data['type'] ?? '').toString();
    final targetId = (message.data['targetId'] ?? '').toString();

    if (type.isEmpty) return;

    await _routeStaffTarget(type: type, targetId: targetId);
  }

  Future<void> _openStaffNotification(
    BuildContext notificationContext,
    AcademyNotification notification,
  ) async {
    Navigator.of(notificationContext).pop();

    await Future<void>.delayed(Duration.zero);

    if (!mounted) return;

    await _routeStaffTarget(
      type: notification.type,
      targetId: notification.targetId,
    );
  }

  Future<void> _routeStaffTarget({
    required String type,
    required String targetId,
  }) async {
    if (type == 'staff_help' && targetId.isNotEmpty) {
      final thread = await service.db
          .collection('lessonHelp')
          .doc(targetId)
          .get();

      if (!mounted) return;

      if (!thread.exists) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: I18nText('That help conversation could not be found.'),
          ),
        );
        return;
      }

      setState(() {
        index = 1;
        taskTab = 1;
        helpFilter = '';
      });

      await Future<void>.delayed(Duration.zero);

      if (!mounted) return;

      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => StaffHelpThread(
            profile: widget.profile,
            threadId: thread.id,
            thread: thread.data() ?? <String, dynamic>{},
          ),
        ),
      );

      return;
    }

    final tab = switch (type) {
      'staff_assessment' => 0,
      'staff_one_to_one' => 2,
      'staff_account' => 3,
      _ => null,
    };

    if (tab != null && mounted) {
      _openTasks(tab, '');
    }
  }

  void _openTasks(int tab, String filter) {
    setState(() {
      taskTab = tab;
      helpFilter = filter;
      index = 1;
    });
  }

  void _openDogs() {
    setState(() => index = 2);
  }

  void _openControl() {
    setState(() => index = widget.profile.canSeeReports ? 4 : 3);
  }

  @override
  Widget build(BuildContext context) {
    final pages = <Widget>[
      StaffDashboard(
        profile: widget.profile,
        onOpenTasks: _openTasks,
        onOpenDogs: _openDogs,
        onOpenControl: _openControl,
      ),
      StaffTasks(
        profile: widget.profile,
        initialTab: taskTab,
        initialHelpFilter: helpFilter,
      ),
      DogDirectory(profile: widget.profile),
      if (widget.profile.canSeeReports) ReportsScreen(profile: widget.profile),
      StaffControl(profile: widget.profile),
    ];

    final dest = <NavigationDestination>[
      NavigationDestination(
        icon: const Icon(Icons.dashboard_outlined),
        selectedIcon: const Icon(Icons.dashboard),
        label: tr('Bridge'),
      ),
      NavigationDestination(
        icon: const Icon(Icons.task_alt),
        selectedIcon: const Icon(Icons.task),
        label: tr('Tasks'),
      ),
      NavigationDestination(
        icon: const Icon(Icons.pets_outlined),
        selectedIcon: const Icon(Icons.pets),
        label: tr('Dogs'),
      ),
      if (widget.profile.canSeeReports)
        NavigationDestination(
          icon: const Icon(Icons.analytics_outlined),
          selectedIcon: const Icon(Icons.analytics),
          label: tr('Reports'),
        ),
      NavigationDestination(
        icon: const Icon(Icons.tune),
        selectedIcon: const Icon(Icons.settings),
        label: tr('Control'),
      ),
    ];

    if (index >= pages.length) index = 0;

    final role = widget.profile.isCaptain
        ? 'Captain'
        : widget.profile.isAdmin
        ? 'Admin'
        : 'Trainer';

    return Scaffold(
      appBar: AppBar(
        title: I18nText('$role — Academy V1.4'),
        actions: [
          LanguageToggle(userId: widget.profile.id),
          NotificationBell(
            profile: widget.profile,
            onOpenNotification: _openStaffNotification,
          ),
          IconButton(
            tooltip: 'Sign out',
            onPressed: () => FirebaseAuth.instance.signOut(),
            icon: const Icon(Icons.logout),
          ),
        ],
      ),
      body: pages[index],
      bottomNavigationBar: NavigationBar(
        selectedIndex: index,
        labelBehavior: NavigationDestinationLabelBehavior.onlyShowSelected,
        onDestinationSelected: (v) {
          setState(() {
            index = v;

            // Tapping Tasks directly opens the normal unfiltered inbox.
            if (v == 1) {
              taskTab = 0;
              helpFilter = '';
            }
          });
        },
        destinations: dest,
      ),
    );
  }
}

class StaffDashboard extends StatelessWidget {
  final AppUser profile;
  final void Function(int tab, String helpFilter) onOpenTasks;
  final VoidCallback onOpenDogs;
  final VoidCallback onOpenControl;

  StaffDashboard({
    super.key,
    required this.profile,
    required this.onOpenTasks,
    required this.onOpenDogs,
    required this.onOpenControl,
  });

  final service = FirestoreService();

  @override
  Widget build(BuildContext context) => ListView(
    padding: const EdgeInsets.all(16),
    children: [
      I18nText(
        profile.isCaptain ? 'Captain’s Bridge' : 'Trainer Desk',
        style: Theme.of(context).textTheme.headlineSmall,
      ),
      const I18nText(
        'What needs attention, who needs help, and what is happening aboard.',
      ),
      const SizedBox(height: 12),

      Wrap(
        spacing: 10,
        runSpacing: 10,
        children: [
          _count(
            'Learners',
            service.allUsers(),
            (d) => d.where((x) => x.data()['role'] == 'learner').length,
            onOpenDogs,
          ),
          _count(
            'Active dogs',
            service.allDogs(),
            (d) => d
                .where((x) => (x.data()['academyStatus'] ?? '') == 'active')
                .length,
            onOpenDogs,
          ),
          _count(
            'Assessments',
            service.allSubmissions(),
            (d) => d.where((x) => x.data()['status'] == 'waiting').length,
            () => onOpenTasks(0, ''),
          ),
          _count(
            'Training help',
            service.allLessonHelp(),
            (d) => d.where((x) => x.data()['status'] != 'resolved').length,
            () => onOpenTasks(1, ''),
          ),
          _count(
            '1-to-1 requests',
            service.allOneToOnes(),
            (d) => d.where((x) => x.data()['status'] == 'requested').length,
            () => onOpenTasks(2, ''),
          ),
          if (profile.canManageAccounts)
            _count(
              'Payment checks',
              service.allPaymentRequests(),
              (d) => d.where((x) => x.data()['status'] == 'waiting').length,
              () => onOpenTasks(3, ''),
            ),
          if (profile.canManageAccounts)
            _count(
              'Restart requests',
              service.allRestartRequests(),
              (d) => d.where((x) => x.data()['status'] == 'requested').length,
              () => onOpenTasks(3, ''),
            ),
          if (profile.canManageAccounts)
            _count(
              'Leaving requests',
              service.allAccountDeletionRequests(),
              (d) => d.where((x) => x.data()['status'] == 'requested').length,
              () => onOpenTasks(3, ''),
            ),
          _count(
            'Feedback',
            service.feedback(),
            (d) => d.where((x) => x.data()['status'] == 'new').length,
            () => onOpenTasks(5, ''),
          ),
          _count(
            'Follow-ups',
            service.staffTasks(),
            (d) => d.where((x) => x.data()['status'] == 'open').length,
            () => onOpenTasks(4, ''),
          ),
        ],
      ),

      const SizedBox(height: 14),
      I18nText(
        'Captain’s Watch',
        style: Theme.of(context).textTheme.titleLarge,
      ),

      StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: service.allUsers(),
        builder: (context, snap) {
          if (!snap.hasData) return const LinearProgressIndicator();

          final cutoff = DateTime.now().subtract(const Duration(days: 14));

          final quiet = snap.data!.docs.where((d) {
            final m = d.data();
            if (m['role'] != 'learner') return false;
            final dt = (m['lastActiveAt'] as Timestamp?)?.toDate();
            return dt == null || dt.isBefore(cutoff);
          }).toList();

          return Card(
            child: ListTile(
              leading: Icon(
                quiet.isEmpty ? Icons.check_circle : Icons.notifications_active,
              ),
              title: I18nText(
                quiet.isEmpty
                    ? 'No learners need a nudge'
                    : '${quiet.length} learner${quiet.length == 1 ? '' : 's'} quiet for 14+ days',
              ),
              subtitle: const I18nText(
                'Use this as a gentle check-in list, not a performance score.',
              ),
              trailing: const Icon(Icons.chevron_right),
              onTap: onOpenDogs,
            ),
          );
        },
      ),

      StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: service.allLessonHelp(),
        builder: (context, snap) {
          final counts = <String, int>{};

          for (final d in snap.data?.docs ?? []) {
            if (d.data()['status'] == 'resolved') continue;

            final k = (d.data()['lessonTitle'] ?? 'General').toString();
            counts[k] = (counts[k] ?? 0) + 1;
          }

          final list = counts.entries.toList()
            ..sort((a, b) => b.value.compareTo(a.value));

          return Card(
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  I18nText(
                    'Most requested help',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  if (list.isEmpty)
                    const I18nText('No help patterns yet.')
                  else
                    Wrap(
                      spacing: 7,
                      runSpacing: 7,
                      children: list
                          .take(6)
                          .map(
                            (e) => ActionChip(
                              label: I18nText('${e.key}: ${e.value}'),
                              avatar: const Icon(Icons.open_in_new, size: 16),
                              onPressed: () => onOpenTasks(1, e.key),
                            ),
                          )
                          .toList(),
                    ),
                ],
              ),
            ),
          );
        },
      ),

      if (profile.isCaptain || profile.isAdmin)
        StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
          stream: service.captainLog(),
          builder: (context, snap) {
            final open = (snap.data?.docs ?? [])
                .where((d) => d.data()['done'] != true)
                .length;

            return Card(
              child: ListTile(
                leading: const Icon(Icons.menu_book),
                title: I18nText(
                  'Captain’s Log — $open open item${open == 1 ? '' : 's'}',
                ),
                subtitle: const I18nText(
                  'Ideas, jobs and next-quarter actions live in Control.',
                ),
                trailing: const Icon(Icons.chevron_right),
                onTap: onOpenControl,
              ),
            );
          },
        ),
    ],
  );

  Widget _count(
    String title,
    Stream<QuerySnapshot<Map<String, dynamic>>> stream,
    int Function(List<QueryDocumentSnapshot<Map<String, dynamic>>>) count,
    VoidCallback onTap,
  ) => SizedBox(
    width: 178,
    child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: stream,
      builder: (context, snap) => Card(
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      I18nText(
                        snap.hasData ? '${count(snap.data!.docs)}' : '…',
                        style: Theme.of(context).textTheme.headlineMedium,
                      ),
                      I18nText(title),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right, size: 20),
              ],
            ),
          ),
        ),
      ),
    ),
  );
}

class StaffTasks extends StatefulWidget {
  final AppUser profile;
  final int initialTab;
  final String initialHelpFilter;

  const StaffTasks({
    super.key,
    required this.profile,
    this.initialTab = 0,
    this.initialHelpFilter = '',
  });

  @override
  State<StaffTasks> createState() => _StaffTasksState();
}

class _StaffTasksState extends State<StaffTasks> {
  late int tab;
  late String helpFilter;

  @override
  void initState() {
    super.initState();
    tab = widget.initialTab;
    helpFilter = widget.initialHelpFilter;
  }

  @override
  void didUpdateWidget(covariant StaffTasks oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.initialTab != widget.initialTab ||
        oldWidget.initialHelpFilter != widget.initialHelpFilter) {
      tab = widget.initialTab;
      helpFilter = widget.initialHelpFilter;
    }
  }

  @override
  Widget build(BuildContext context) => ListView(
    padding: const EdgeInsets.all(16),
    children: [
      I18nText(
        'Action Centre',
        style: Theme.of(context).textTheme.headlineSmall,
      ),
      const I18nText(
        'One place for trainer work — claim it, answer it, close it.',
      ),
      const SizedBox(height: 10),

      SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: SegmentedButton<int>(
          segments: const [
            ButtonSegment(
              value: 0,
              label: I18nText('Assessments'),
              icon: Icon(Icons.video_library),
            ),
            ButtonSegment(
              value: 1,
              label: I18nText('Training Help'),
              icon: Icon(Icons.chat),
            ),
            ButtonSegment(
              value: 2,
              label: I18nText('1-to-1'),
              icon: Icon(Icons.event),
            ),
            ButtonSegment(
              value: 3,
              label: I18nText('Accounts'),
              icon: Icon(Icons.payments),
            ),
            ButtonSegment(
              value: 4,
              label: I18nText('Follow-ups'),
              icon: Icon(Icons.schedule),
            ),
            ButtonSegment(
              value: 5,
              label: I18nText('Feedback'),
              icon: Icon(Icons.feedback),
            ),
          ],
          selected: {tab},
          onSelectionChanged: (s) {
            setState(() {
              tab = s.first;
              helpFilter = '';
            });
          },
        ),
      ),

      if (tab == 1 && helpFilter.isNotEmpty) ...[
        const SizedBox(height: 10),
        Align(
          alignment: Alignment.centerLeft,
          child: InputChip(
            avatar: const Icon(Icons.filter_alt, size: 18),
            label: I18nText(helpFilter),
            onDeleted: () => setState(() => helpFilter = ''),
          ),
        ),
      ],

      const SizedBox(height: 12),

      if (tab == 0) ReviewQueue(profile: widget.profile),
      if (tab == 1) HelpQueue(profile: widget.profile, filter: helpFilter),
      if (tab == 2) OneToOneQueue(profile: widget.profile),
      if (tab == 3) AccountQueue(profile: widget.profile),
      if (tab == 4) StaffFollowUpQueue(profile: widget.profile),
      if (tab == 5) FeedbackAdmin(),
    ],
  );
}

class ReviewQueue extends StatelessWidget {
  final AppUser profile;
  ReviewQueue({super.key, required this.profile});
  final service = FirestoreService();
  Future<void> review(
    BuildContext context,
    QueryDocumentSnapshot<Map<String, dynamic>> doc,
    bool passed,
  ) async {
    final feedback = TextEditingController();
    final m = doc.data();
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: I18nText(
          passed ? 'Pass skill and award trophy?' : 'Keep practising',
        ),
        content: SizedBox(
          width: 520,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              I18nText(
                '${m['learnerName']} & ${m['dogName']} — ${m['moduleTitle']}',
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 6,
                children:
                    [
                          'Great progress.',
                          'Please send another side-on video.',
                          'Keep this short and reward the return.',
                        ]
                        .map(
                          (e) => ActionChip(
                            label: I18nText(e),
                            onPressed: () => feedback.text = e,
                          ),
                        )
                        .toList(),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: feedback,
                maxLines: 5,
                decoration: const InputDecoration(
                  label: I18nText('Trainer feedback'),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const I18nText('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: I18nText(passed ? 'PASS + TROPHY' : 'SEND FEEDBACK'),
          ),
        ],
      ),
    );
    if (ok == true)
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
    feedback.dispose();
  }

  @override
  Widget build(
    BuildContext context,
  ) => StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
    stream: service.allSubmissions(),
    builder: (context, snap) {
      final docs = (snap.data?.docs ?? [])
          .where((d) => d.data()['status'] == 'waiting')
          .toList();
      if (docs.isEmpty)
        return const Card(
          child: Padding(
            padding: EdgeInsets.all(16),
            child: I18nText('Assessment inbox zero! 🎉'),
          ),
        );
      return Column(
        children: docs.map((d) {
          final m = d.data();
          final assigned = (m['assignedTo'] ?? '').toString();
          return Card(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  I18nText(
                    '${m['learnerName']} & ${m['dogName']} — ${m['moduleTitle']}',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  if (assigned.isNotEmpty) I18nText('Assigned: $assigned'),
                  if ((m['note'] ?? '').toString().isNotEmpty)
                    I18nText('Learner note: ${m['note']}'),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 7,
                    runSpacing: 7,
                    children: [
                      if ((m['videoUrl'] ?? '').toString().isNotEmpty)
                        OutlinedButton.icon(
                          onPressed: () async {
                            final u = Uri.tryParse(m['videoUrl']);
                            if (u != null) await launchUrl(u);
                          },
                          icon: const Icon(Icons.play_circle),
                          label: const I18nText('Video'),
                        ),
                      if (assigned.isEmpty)
                        OutlinedButton(
                          onPressed: () =>
                              service.claimSubmission(d.id, profile.name),
                          child: const I18nText('CLAIM THIS'),
                        ),
                      FilledButton.icon(
                        onPressed: () => review(context, d, true),
                        icon: const Icon(Icons.emoji_events),
                        label: const I18nText('PASS'),
                      ),
                      OutlinedButton(
                        onPressed: () => review(context, d, false),
                        child: const I18nText('KEEP PRACTISING'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      );
    },
  );
}

class HelpQueue extends StatelessWidget {
  final AppUser profile;
  final String filter;
  HelpQueue({super.key, required this.profile, this.filter = ''});
  final service = FirestoreService();
  @override
  Widget build(
    BuildContext context,
  ) => StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
    stream: service.allLessonHelp(),
    builder: (context, snap) {
      final docs =
          (snap.data?.docs ?? []).where((d) {
            final m = d.data();
            return m['status'] != 'resolved' &&
                (filter.isEmpty ||
                    (m['lessonTitle'] ?? '').toString() == filter);
          }).toList()..sort(
            (a, b) =>
                ((a.data()['updatedAt'] as Timestamp?)
                            ?.millisecondsSinceEpoch ??
                        0)
                    .compareTo(
                      (b.data()['updatedAt'] as Timestamp?)
                              ?.millisecondsSinceEpoch ??
                          0,
                    ),
          );
      if (docs.isEmpty)
        return const Card(
          child: Padding(
            padding: EdgeInsets.all(16),
            child: I18nText('Training help inbox zero! 🏴‍☠️'),
          ),
        );
      return Column(
        children: docs.map((d) {
          final m = d.data();
          return Card(
            child: ListTile(
              leading: const Icon(Icons.support_agent),
              title: I18nText(
                '${m['dogName']} — ${m['moduleTitle']} / ${m['lessonTitle']}',
              ),
              subtitle: I18nText(
                '${(m['status'] ?? 'new').toString().replaceAll('_', ' ').toUpperCase()}${(m['assignedTo'] ?? '').toString().isEmpty ? '' : ' • ${m['assignedTo']}'}',
              ),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => StaffHelpThread(
                    profile: profile,
                    threadId: d.id,
                    thread: m,
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      );
    },
  );
}

class StaffHelpThread extends StatefulWidget {
  final AppUser profile;
  final String threadId;
  final Map<String, dynamic> thread;
  const StaffHelpThread({
    super.key,
    required this.profile,
    required this.threadId,
    required this.thread,
  });
  @override
  State<StaffHelpThread> createState() => _StaffHelpThreadState();
}

class _StaffHelpThreadState extends State<StaffHelpThread> {
  final service = FirestoreService();
  final reply = TextEditingController();
  final videoLink = TextEditingController();
  final stt.SpeechToText speech = stt.SpeechToText();

  late String assignedTo;
  bool showVideoLink = false;
  bool sending = false;
  bool listening = false;
  bool speechReady = false;
  String speechSeed = '';

  @override
  void initState() {
    super.initState();
    assignedTo = (widget.thread['assignedTo'] ?? '').toString();
  }

  @override
  void dispose() {
    if (speech.isListening) {
      unawaited(speech.cancel());
    }
    reply.dispose();
    videoLink.dispose();
    super.dispose();
  }

  Future<void> _claim() async {
    await service.claimHelpThread(widget.threadId, widget.profile.name);

    if (!mounted) return;

    setState(() {
      assignedTo = widget.profile.name;
    });
  }

  Future<void> _resolve() async {
    await service.resolveHelpThread(widget.threadId);

    if (!mounted) return;
    Navigator.of(context).pop();
  }

  bool _validVideoLink(String value) {
    final uri = Uri.tryParse(value.trim());

    if (uri == null) return false;

    return (uri.scheme == 'http' || uri.scheme == 'https') &&
        uri.host.isNotEmpty;
  }

  Future<void> _toggleSpeech() async {
    if (speech.isListening || listening) {
      await speech.stop();

      if (mounted) {
        setState(() => listening = false);
      }
      return;
    }

    if (!speechReady) {
      final available = await speech.initialize(
        onStatus: (status) {
          if (!mounted) return;

          setState(() {
            listening = status == 'listening';
          });
        },
        onError: (error) {
          debugPrint('Academy speech recognition error: ${error.errorMsg}');

          if (!mounted) return;

          setState(() => listening = false);

          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: I18nText(
                'Speech recognition stopped. Please try again.',
              ),
            ),
          );
        },
      );

      if (!available) {
        if (!mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: I18nText(
              'Speech recognition is not available on this device.',
            ),
          ),
        );
        return;
      }

      speechReady = true;
    }

    speechSeed = reply.text.trim();

    await speech.listen(
      onResult: (result) {
        if (!mounted) return;

        final spoken = result.recognizedWords.trim();

        final combined = [
          if (speechSeed.isNotEmpty) speechSeed,
          if (spoken.isNotEmpty) spoken,
        ].join(' ');

        reply.value = TextEditingValue(
          text: combined,
          selection: TextSelection.collapsed(offset: combined.length),
        );
      },
      listenOptions: stt.SpeechListenOptions(
        partialResults: true,
        listenMode: stt.ListenMode.dictation,
        autoPunctuation: true,
      ),
    );

    if (mounted) {
      setState(() => listening = speech.isListening);
    }
  }

  Future<void> _sendReply() async {
    final message = reply.text.trim();
    final video = videoLink.text.trim();

    if (message.isEmpty && video.isEmpty) return;

    if (video.isNotEmpty && !_validVideoLink(video)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: I18nText(
            'Please enter a valid http:// or https:// video link.',
          ),
        ),
      );
      return;
    }

    setState(() => sending = true);

    try {
      await service.sendHelpMessage(
        threadId: widget.threadId,
        senderId: widget.profile.id,
        senderName: widget.profile.name,
        senderRole: widget.profile.role,
        message: message,
        videoUrl: video,
        learnerUid: (widget.thread['userId'] ?? '').toString(),
      );

      reply.clear();
      videoLink.clear();

      if (mounted) {
        setState(() {
          showVideoLink = false;
        });
      }
    } finally {
      if (mounted) {
        setState(() => sending = false);
      }
    }
  }

  Future<void> _followUp(int days) async {
    await service.createFollowUp(
      dogId: (widget.thread['dogId'] ?? '').toString(),
      dogName: (widget.thread['dogName'] ?? 'Dog').toString(),
      learnerUid: (widget.thread['userId'] ?? '').toString(),
      trainerName: widget.profile.name,
      days: days,
      note:
          'Check how the learner is getting on with ${widget.thread['lessonTitle'] ?? 'this training'}.',
    );
    if (mounted)
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: I18nText('Follow-up added for $days days.')),
      );
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: I18nText(
        '${widget.thread['dogName']} — ${widget.thread['lessonTitle']}',
      ),
      actions: [
        LanguageToggle(userId: widget.profile.id),
        TextButton(onPressed: _resolve, child: const I18nText('Resolve')),
      ],
    ),
    body: Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  if (assignedTo.isEmpty)
                    FilledButton.tonalIcon(
                      onPressed: _claim,
                      icon: const Icon(Icons.person_add_alt_1),
                      label: const I18nText('CLAIM THIS'),
                    )
                  else
                    Chip(
                      avatar: const Icon(Icons.person, size: 18),
                      label: I18nText('Assigned: $assignedTo'),
                    ),
                  OutlinedButton.icon(
                    onPressed: () => _followUp(7),
                    icon: const Icon(Icons.schedule),
                    label: const I18nText('CHECK BACK IN 7 DAYS'),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                stream: service.savedReplies(),
                builder: (context, snap) {
                  final builtIns = <Map<String, String>>[
                    {
                      'title': 'Shorter session',
                      'text':
                          'Try making the next session much shorter and finish while your dog is still keen.',
                    },
                    {
                      'title': 'Another angle',
                      'text':
                          'Could you send us another short video from the side so we can see the movement more clearly?',
                    },
                  ];
                  final saved = (snap.data?.docs ?? [])
                      .map(
                        (d) => {
                          'title': (d.data()['title'] ?? 'Saved reply')
                              .toString(),
                          'text': (d.data()['text'] ?? '').toString(),
                        },
                      )
                      .where((e) => e['text']!.isNotEmpty)
                      .toList();
                  final all = [...builtIns, ...saved];
                  return Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: all
                        .map(
                          (e) => ActionChip(
                            label: I18nText(e['title']!),
                            onPressed: () => reply.text = e['text']!,
                          ),
                        )
                        .toList(),
                  );
                },
              ),
            ],
          ),
        ),
        Expanded(
          child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
            stream: service.helpMessages(widget.threadId),
            builder: (context, snap) {
              final docs = [...(snap.data?.docs ?? [])]
                ..sort(
                  (a, b) =>
                      ((a.data()['createdAt'] as Timestamp?)
                                  ?.millisecondsSinceEpoch ??
                              0)
                          .compareTo(
                            (b.data()['createdAt'] as Timestamp?)
                                    ?.millisecondsSinceEpoch ??
                                0,
                          ),
                );
              return ListView(
                padding: const EdgeInsets.all(12),
                children: docs.map((d) {
                  final m = d.data();
                  final staff = (m['senderRole'] ?? '') != 'learner';
                  return Align(
                    alignment: staff
                        ? Alignment.centerRight
                        : Alignment.centerLeft,
                    child: Container(
                      margin: const EdgeInsets.symmetric(vertical: 4),
                      padding: const EdgeInsets.all(12),
                      constraints: const BoxConstraints(maxWidth: 560),
                      decoration: BoxDecoration(
                        color: staff
                            ? Theme.of(context).colorScheme.primaryContainer
                            : Theme.of(context).colorScheme.secondaryContainer,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            (m['senderName'] ?? '').toString(),
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          if ((m['message'] ?? '').toString().trim().isNotEmpty)
                            Text((m['message'] ?? '').toString()),
                          if ((m['videoUrl'] ?? '').toString().isNotEmpty)
                            TextButton.icon(
                              onPressed: () async {
                                final u = Uri.tryParse(m['videoUrl']);
                                if (u != null) await launchUrl(u);
                              },
                              icon: const Icon(Icons.play_circle),
                              label: const I18nText('Open video'),
                            ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              );
            },
          ),
        ),
        SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(10),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (showVideoLink) ...[
                  TextField(
                    controller: videoLink,
                    keyboardType: TextInputType.url,
                    decoration: const InputDecoration(
                      prefixIcon: Icon(Icons.link),
                      label: I18nText('Optional video link'),
                      hintText: 'https://',
                    ),
                  ),
                  const SizedBox(height: 8),
                ],
                TextField(
                  controller: reply,
                  minLines: 1,
                  maxLines: 4,
                  decoration: InputDecoration(
                    label: const I18nText('Reply to learner'),
                    helper: listening
                        ? const I18nText('Listening… speak your reply.')
                        : null,
                    suffixIcon: IconButton(
                      tooltip: tr(
                        listening ? 'STOP LISTENING' : 'DICTATE REPLY',
                      ),
                      onPressed: sending ? null : _toggleSpeech,
                      icon: Icon(
                        listening ? Icons.stop_circle : Icons.mic_none,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  alignment: WrapAlignment.end,
                  children: [
                    OutlinedButton.icon(
                      onPressed: sending
                          ? null
                          : () =>
                                setState(() => showVideoLink = !showVideoLink),
                      icon: Icon(
                        showVideoLink ? Icons.link_off : Icons.add_link,
                      ),
                      label: I18nText(
                        showVideoLink ? 'HIDE VIDEO LINK' : 'ADD VIDEO LINK',
                      ),
                    ),
                    FilledButton.icon(
                      onPressed: sending || listening ? null : _sendReply,
                      icon: sending
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.send),
                      label: const I18nText('SEND REPLY'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    ),
  );
}

class OneToOneQueue extends StatelessWidget {
  final AppUser profile;
  OneToOneQueue({super.key, required this.profile});
  final service = FirestoreService();
  Future<void> edit(
    BuildContext context,
    QueryDocumentSnapshot<Map<String, dynamic>> doc,
  ) async {
    final config = await service.getAcademyConfig();
    final m = doc.data();
    String status = (m['status'] ?? 'requested').toString();
    final trainer = TextEditingController(
      text: (m['trainerName'] ?? profile.name).toString(),
    );
    final when = TextEditingController(
      text: (m['proposedWhen'] ?? '').toString(),
    );
    final meet = TextEditingController(text: (m['meetUrl'] ?? '').toString());
    final notes = TextEditingController(
      text: (m['trainerNotes'] ?? '').toString(),
    );
    final homework = TextEditingController(
      text: (m['homework'] ?? '').toString(),
    );
    final price = TextEditingController(
      text:
          ((m['quotedPrice'] as num?)?.toDouble() ?? config.oneToOneGuidePrice)
              .toStringAsFixed(2),
    );
    final mins = TextEditingController(
      text:
          '${(m['durationMinutes'] as num?)?.toInt() ?? config.oneToOneGuideMinutes}',
    );
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setLocal) => AlertDialog(
          title: I18nText('${m['learnerName']} & ${m['dogName']}'),
          content: SizedBox(
            width: 560,
            child: SingleChildScrollView(
              child: Column(
                children: [
                  I18nText(
                    'Request: ${m['topic']} • ${m['format']} • ${m['availability']}',
                  ),
                  if ((m['note'] ?? '').toString().isNotEmpty)
                    I18nText('Learner note: ${m['note']}'),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<String>(
                    initialValue: status,
                    items:
                        [
                              'requested',
                              'proposed',
                              'booked',
                              'completed',
                              'declined',
                              'cancelled',
                            ]
                            .map(
                              (e) => DropdownMenuItem(
                                value: e,
                                child: I18nText(e.toUpperCase()),
                              ),
                            )
                            .toList(),
                    onChanged: (v) => setLocal(() => status = v ?? status),
                    decoration: const InputDecoration(
                      label: I18nText('Status'),
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: trainer,
                    decoration: const InputDecoration(
                      label: I18nText('Trainer'),
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: when,
                    decoration: const InputDecoration(
                      label: I18nText('Proposed/booked date & time'),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: mins,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            label: I18nText('Minutes'),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: TextField(
                          controller: price,
                          keyboardType: const TextInputType.numberWithOptions(
                            decimal: true,
                          ),
                          decoration: const InputDecoration(
                            label: I18nText('Quoted price £'),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: meet,
                    decoration: const InputDecoration(
                      label: I18nText('Meet link if online'),
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: notes,
                    maxLines: 3,
                    decoration: const InputDecoration(
                      label: I18nText('Trainer notes'),
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: homework,
                    maxLines: 3,
                    decoration: const InputDecoration(
                      label: I18nText('Follow-up / homework'),
                    ),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const I18nText('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const I18nText('SAVE & NOTIFY'),
            ),
          ],
        ),
      ),
    );
    if (ok == true)
      await service.staffUpdateOneToOne(
        id: doc.id,
        status: status,
        trainerName: trainer.text,
        proposedWhen: when.text,
        meetUrl: meet.text,
        trainerNotes: notes.text,
        homework: homework.text,
        durationMinutes: int.tryParse(mins.text) ?? config.oneToOneGuideMinutes,
        quotedPrice: double.tryParse(price.text) ?? config.oneToOneGuidePrice,
      );
    for (final c in [trainer, when, meet, notes, homework, price, mins])
      c.dispose();
  }

  @override
  Widget build(
    BuildContext context,
  ) => StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
    stream: service.allOneToOnes(),
    builder: (context, snap) {
      final docs = [...(snap.data?.docs ?? [])]
        ..sort(
          (a, b) => ((a.data()['status'] ?? '') == 'requested' ? 0 : 1)
              .compareTo((b.data()['status'] ?? '') == 'requested' ? 0 : 1),
        );
      if (docs.isEmpty)
        return const Card(
          child: Padding(
            padding: EdgeInsets.all(16),
            child: I18nText('No 1-to-1 requests yet.'),
          ),
        );
      return Column(
        children: docs.map((d) {
          final m = d.data();
          return Card(
            child: ListTile(
              leading: const Icon(Icons.event_available),
              title: I18nText(
                '${m['learnerName']} & ${m['dogName']} — ${m['topic']}',
              ),
              subtitle: I18nText(
                '${(m['status'] ?? 'requested').toString().toUpperCase()} • ${m['format']} • quoted individually',
              ),
              trailing: FilledButton(
                onPressed: () => edit(context, d),
                child: const I18nText('Manage'),
              ),
            ),
          );
        }).toList(),
      );
    },
  );
}

class AccountQueue extends StatelessWidget {
  final AppUser profile;
  AccountQueue({super.key, required this.profile});
  final service = FirestoreService();

  Future<void> _confirmPayment(
    BuildContext context,
    QueryDocumentSnapshot<Map<String, dynamic>> doc,
  ) async {
    final m = doc.data();
    final amount = (m['amount'] as num?)?.toDouble() ?? 0;
    final code = await service.confirmPaymentRequest(
      id: doc.id,
      uid: (m['userId'] ?? '').toString(),
      amount: amount,
      actor: profile.name,
    );
    if (code != null && context.mounted) {
      await showDialog<void>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const I18nText('First payment confirmed'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const I18nText('Send this activation code to the learner:'),
              const SizedBox(height: 8),
              SelectableText(
                code,
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              const SizedBox(height: 8),
              const I18nText(
                'The first £5 payment has opened the first 30-day voyage. Any extra full or part balance has been added as Doubloons.',
              ),
            ],
          ),
          actions: [
            FilledButton(
              onPressed: () => Navigator.pop(ctx),
              child: const I18nText('Done'),
            ),
          ],
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!profile.canManageAccounts) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: I18nText(
            'Doubloon and payment controls are Admin/Captain only.',
          ),
        ),
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        I18nText(
          'Payment confirmations',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
          stream: service.allPaymentRequests(),
          builder: (context, snap) {
            final docs = (snap.data?.docs ?? [])
                .where((d) => d.data()['status'] == 'waiting')
                .toList();
            if (docs.isEmpty)
              return const Card(
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: I18nText('No payments waiting for confirmation.'),
                ),
              );
            return Column(
              children: docs.map((d) {
                final m = d.data();
                final amount = (m['amount'] as num?)?.toDouble() ?? 0;
                return Card(
                  child: ListTile(
                    title: I18nText(
                      '${m['memberName']} — £${amount.toStringAsFixed(2)}',
                    ),
                    subtitle: I18nText(
                      '${m['dogName']} • ref ${m['reference']} • ${m['method']}',
                    ),
                    trailing: FilledButton(
                      onPressed: () => _confirmPayment(context, d),
                      child: const I18nText('CONFIRM'),
                    ),
                  ),
                );
              }).toList(),
            );
          },
        ),
        const SizedBox(height: 12),
        I18nText(
          'Restart requests',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
          stream: service.allRestartRequests(),
          builder: (context, snap) {
            final docs = (snap.data?.docs ?? [])
                .where((d) => d.data()['status'] == 'requested')
                .toList();
            if (docs.isEmpty)
              return const Card(
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: I18nText('No restart requests.'),
                ),
              );
            return Column(
              children: docs.map((d) {
                final m = d.data();
                return Card(
                  child: ListTile(
                    title: I18nText('${m['dogName']} wants to restart'),
                    subtitle: const I18nText(
                      'Uses 1 Doubloon for a fresh 30-day voyage.',
                    ),
                    trailing: FilledButton(
                      onPressed: () => service.approveRestart(
                        requestId: d.id,
                        uid: (m['userId'] ?? '').toString(),
                        dogId: (m['dogId'] ?? '').toString(),
                        actor: profile.name,
                      ),
                      child: const I18nText('APPROVE'),
                    ),
                  ),
                );
              }).toList(),
            );
          },
        ),
        const SizedBox(height: 12),
        I18nText(
          'Due renewals / pauses',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
          stream: service.allDogs(),
          builder: (context, snap) {
            final now = DateTime.now();
            final docs = (snap.data?.docs ?? []).where((d) {
              final m = d.data();
              final status = (m['academyStatus'] ?? '').toString();
              final until = (m['accessUntil'] as Timestamp?)?.toDate();
              return status == 'renewal_due' ||
                  (status == 'active' && until != null && !until.isAfter(now));
            }).toList();
            if (docs.isEmpty)
              return const Card(
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: I18nText(
                    'No dog access periods are waiting to be processed.',
                  ),
                ),
              );
            return Column(
              children: docs.map((d) {
                final dog = DogProfile.fromDoc(d);
                return Card(
                  child: ListTile(
                    leading: Icon(
                      dog.pauseRequested ? Icons.pause_circle : Icons.autorenew,
                    ),
                    title: I18nText(dog.name),
                    subtitle: I18nText(
                      dog.pauseRequested
                          ? 'Pause requested — close this voyage without another deduction.'
                          : 'Access period ended — use 1 available Doubloon for the next 30-day voyage.',
                    ),
                    trailing: FilledButton.tonal(
                      onPressed: () => service.processDueRenewal(
                        uid: dog.ownerId,
                        dog: dog,
                        actor: profile.name,
                      ),
                      child: I18nText(dog.pauseRequested ? 'PAUSE' : 'PROCESS'),
                    ),
                  ),
                );
              }).toList(),
            );
          },
        ),
      ],
    );
  }
}

class StaffFollowUpQueue extends StatelessWidget {
  final AppUser profile;
  StaffFollowUpQueue({super.key, required this.profile});
  final service = FirestoreService();

  @override
  Widget build(
    BuildContext context,
  ) => StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
    stream: service.staffTasks(),
    builder: (context, snap) {
      final docs =
          (snap.data?.docs ?? [])
              .where((d) => d.data()['status'] == 'open')
              .toList()
            ..sort(
              (a, b) =>
                  (((a.data()['dueAt'] as Timestamp?)?.millisecondsSinceEpoch ??
                          0)
                      .compareTo(
                        (b.data()['dueAt'] as Timestamp?)
                                ?.millisecondsSinceEpoch ??
                            0,
                      )),
            );
      if (docs.isEmpty) {
        return const Card(
          child: Padding(
            padding: EdgeInsets.all(16),
            child: I18nText('No trainer follow-ups waiting. 🎉'),
          ),
        );
      }
      return Column(
        children: docs.map((d) {
          final m = d.data();
          final due = (m['dueAt'] as Timestamp?)?.toDate();
          final dueText = due == null
              ? 'No date'
              : '${due.day}/${due.month}/${due.year}';
          return Card(
            child: ListTile(
              leading: const Icon(Icons.schedule),
              title: I18nText(
                '${m['dogName'] ?? 'Dog'} — follow up by $dueText',
              ),
              subtitle: I18nText(
                '${m['note'] ?? ''}${(m['assignedTo'] ?? '').toString().isEmpty ? '' : '\nAssigned: ${m['assignedTo']}'}',
              ),
              isThreeLine: true,
              trailing: FilledButton.tonal(
                onPressed: () => service.completeStaffTask(d.id),
                child: const I18nText('DONE'),
              ),
            ),
          );
        }).toList(),
      );
    },
  );
}

class DogDirectory extends StatefulWidget {
  final AppUser profile;
  const DogDirectory({super.key, required this.profile});
  @override
  State<DogDirectory> createState() => _DogDirectoryState();
}

class _DogDirectoryState extends State<DogDirectory> {
  final service = FirestoreService();
  String q = '';

  Future<void> _adjustDoubloons(
    BuildContext context,
    String uid,
    String learnerName,
  ) async {
    final controller = TextEditingController(text: '1');
    bool remove = false;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setLocal) => AlertDialog(
          title: I18nText('Adjust Doubloons — $learnerName'),
          content: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 430),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const I18nText(
                    '1 Doubloon = £5 = 30 days access for one dog.',
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [1, 2, 3, 6]
                        .map(
                          (n) => ActionChip(
                            label: I18nText('+$n'),
                            onPressed: () {
                              controller.text = '$n';
                              setLocal(() => remove = false);
                            },
                          ),
                        )
                        .toList(),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: controller,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    decoration: const InputDecoration(
                      label: I18nText('Number of Doubloons'),
                    ),
                  ),
                  const SizedBox(height: 8),
                  SegmentedButton<bool>(
                    segments: const [
                      ButtonSegment(
                        value: false,
                        icon: Icon(Icons.add_circle_outline),
                        label: I18nText('ADD'),
                      ),
                      ButtonSegment(
                        value: true,
                        icon: Icon(Icons.remove_circle_outline),
                        label: I18nText('REMOVE'),
                      ),
                    ],
                    selected: {remove},
                    onSelectionChanged: (v) => setLocal(() => remove = v.first),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const I18nText('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const I18nText('SAVE'),
            ),
          ],
        ),
      ),
    );
    final count = double.tryParse(controller.text.trim());
    if (ok == true && count != null && count > 0) {
      final changed = await service.adjustAcademyDoubloons(
        uid: uid,
        doubloons: remove ? -count : count,
        actor: widget.profile.name,
      );
      if (context.mounted && !changed) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: I18nText(
              'That would take the Doubloon balance below zero.',
            ),
          ),
        );
      }
    }
    controller.dispose();
  }

  String _dogStatus(Map<String, dynamic> dog, Map<String, dynamic> owner) {
    final raw = (dog['academyStatus'] ?? '').toString();

    if (raw.isEmpty) {
      return owner['activated'] == true ? 'active' : 'awaiting';
    }

    if (raw == 'active') {
      final until = (dog['accessUntil'] as Timestamp?)?.toDate();
      if (until != null && until.isBefore(DateTime.now())) {
        return 'renewal_due';
      }
    }

    return raw;
  }

  String _dateLabel(dynamic value) {
    if (value is! Timestamp) return '';
    final d = value.toDate();
    return '${d.day.toString().padLeft(2, '0')}/'
        '${d.month.toString().padLeft(2, '0')}/'
        '${d.year}';
  }

  Future<void> _authoriseDog(
    BuildContext context, {
    required String uid,
    required String dogId,
  }) async {
    final ok = await service.activateDogUsingCredit(
      uid: uid,
      dogId: dogId,
      actor: widget.profile.name,
    );

    if (!context.mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: I18nText(
          ok
              ? '30 days of access authorised.'
              : 'Not enough Doubloons. Add at least 1 Doubloon first.',
        ),
      ),
    );
  }

  Future<void> _pauseDog(
    BuildContext context, {
    required String uid,
    required String dogId,
  }) async {
    await service.requestDogPause(uid: uid, dogId: dogId);

    if (!context.mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: I18nText(
          'Pause scheduled for the end of the current paid period.',
        ),
      ),
    );
  }

  Future<void> _cancelDogPause(
    BuildContext context, {
    required String dogId,
  }) async {
    await service.cancelDogPause(dogId);

    if (!context.mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: I18nText('Scheduled pause cancelled.')),
    );
  }

  Future<void> _pauseAllDogs(
    BuildContext context, {
    required String uid,
  }) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const I18nText('Pause all active dogs?'),
        content: const I18nText(
          'Each active dog will keep its current paid access until the end date, then stop instead of renewing.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const I18nText('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const I18nText('PAUSE ALL DOGS'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    final changed = await service.requestAllDogsPause(
      uid: uid,
      actor: widget.profile.name,
    );

    if (!context.mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: I18nText(
          changed == 0
              ? 'No active dogs needed pausing.'
              : 'All active dogs have been scheduled to pause.',
        ),
      ),
    );
  }

  Future<void> _cancelAllPauses(
    BuildContext context, {
    required String uid,
  }) async {
    final changed = await service.cancelAllDogPauses(
      uid: uid,
      actor: widget.profile.name,
    );

    if (!context.mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: I18nText(
          changed == 0
              ? 'No scheduled pauses to cancel.'
              : 'All scheduled pauses have been cancelled.',
        ),
      ),
    );
  }

  @override
  Widget build(
    BuildContext context,
  ) => StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
    stream: service.allUsers(),
    builder: (context, uSnap) => StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: service.allDogs(),
      builder: (context, dSnap) {
        if (!uSnap.hasData || !dSnap.hasData)
          return const LinearProgressIndicator();

        final dogsByOwner =
            <String, List<QueryDocumentSnapshot<Map<String, dynamic>>>>{};
        for (final dog in dSnap.data!.docs) {
          final ownerId = (dog.data()['ownerId'] ?? '').toString();
          dogsByOwner.putIfAbsent(ownerId, () => []).add(dog);
        }

        final needle = q.trim().toLowerCase();
        final users =
            uSnap.data!.docs.where((u) {
              final m = u.data();
              final dogs = dogsByOwner[u.id] ?? const [];
              if (needle.isEmpty) return true;
              return (m['name'] ?? '').toString().toLowerCase().contains(
                    needle,
                  ) ||
                  (m['email'] ?? '').toString().toLowerCase().contains(
                    needle,
                  ) ||
                  (m['role'] ?? '').toString().toLowerCase().contains(needle) ||
                  dogs.any(
                    (d) => (d.data()['name'] ?? '')
                        .toString()
                        .toLowerCase()
                        .contains(needle),
                  );
            }).toList()..sort((a, b) {
              final an = (a.data()['name'] ?? '').toString().toLowerCase();
              final bn = (b.data()['name'] ?? '').toString().toLowerCase();
              return an.compareTo(bn);
            });

        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            I18nText(
              'People Manager',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const I18nText(
              'Search people once, then manage their role, Doubloons and dogs from the same place.',
            ),
            const SizedBox(height: 8),
            TextField(
              onChanged: (v) => setState(() => q = v),
              decoration: const InputDecoration(
                prefixIcon: Icon(Icons.search),
                label: I18nText('Search dog, learner or email'),
              ),
            ),
            const SizedBox(height: 10),
            if (users.isEmpty)
              const Card(
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: I18nText('No people match that search.'),
                ),
              ),
            ...users.map((u) {
              final owner = u.data();
              final role = (owner['role'] ?? 'learner').toString();
              final roleValue =
                  ['learner', 'trainer', 'admin', 'captain'].contains(role)
                  ? role
                  : 'learner';
              final balance = (owner['academyCredit'] as num?)?.toDouble() ?? 0;
              final dogs = dogsByOwner[u.id] ?? const [];
              final dogNames = dogs
                  .map((d) => (d.data()['name'] ?? 'Dog').toString())
                  .join(', ');

              final activeDogs = dogs.where((d) {
                return _dogStatus(d.data(), owner) == 'active';
              }).length;

              final renewingDogs = dogs.where((d) {
                return _dogStatus(d.data(), owner) == 'active' &&
                    d.data()['pauseRequested'] != true;
              }).length;

              final scheduledPauses = dogs
                  .where((d) => d.data()['pauseRequested'] == true)
                  .length;

              final renewalPounds = renewingDogs * academyDoubloonPounds;

              return Card(
                child: ExpansionTile(
                  leading: CircleAvatar(
                    backgroundImage:
                        (owner['photoUrl'] ?? '').toString().startsWith('http')
                        ? NetworkImage(owner['photoUrl'])
                        : null,
                    child: (owner['photoUrl'] ?? '').toString().isEmpty
                        ? const Icon(Icons.person)
                        : null,
                  ),
                  title: I18nText((owner['name'] ?? 'Learner').toString()),
                  subtitle: I18nText(
                    '${role.toUpperCase()} • ${doubloonBalanceLabel(balance)} • ${dogs.length} ${dogs.length == 1 ? 'dog' : 'dogs'}',
                  ),
                  childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                  children: [
                    if ((owner['email'] ?? '').toString().isNotEmpty)
                      Align(
                        alignment: Alignment.centerLeft,
                        child: I18nText((owner['email'] ?? '').toString()),
                      ),
                    if (widget.profile.canManageAccounts) ...[
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 10,
                        runSpacing: 8,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          SizedBox(
                            width: 210,
                            child: DropdownButtonFormField<String>(
                              initialValue: roleValue,
                              decoration: const InputDecoration(
                                label: I18nText('Academy role'),
                              ),
                              items: ['learner', 'trainer', 'admin', 'captain']
                                  .map(
                                    (r) => DropdownMenuItem(
                                      value: r,
                                      child: I18nText(r.toUpperCase()),
                                    ),
                                  )
                                  .toList(),
                              onChanged: (v) {
                                if (v != null && v != roleValue)
                                  service.setUserRole(
                                    u.id,
                                    v,
                                    actor: widget.profile.name,
                                  );
                              },
                            ),
                          ),
                          if (role == 'learner')
                            FilledButton.tonalIcon(
                              onPressed: () => service.adjustAcademyDoubloons(
                                uid: u.id,
                                doubloons: 1,
                                actor: widget.profile.name,
                              ),
                              icon: const Icon(Icons.add_circle_outline),
                              label: const I18nText('+1 DOUBLOON'),
                            ),
                          if (role == 'learner')
                            OutlinedButton.icon(
                              onPressed: () => _adjustDoubloons(
                                context,
                                u.id,
                                (owner['name'] ?? 'Learner').toString(),
                              ),
                              icon: const Icon(Icons.monetization_on_outlined),
                              label: const I18nText('ADJUST DOUBLOONS'),
                            ),
                        ],
                      ),
                    ],
                    if (role == 'learner' && dogs.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          Chip(
                            avatar: const Icon(Icons.pets, size: 18),
                            label: I18nText('Registered dogs: ${dogs.length}'),
                          ),
                          Chip(
                            avatar: const Icon(
                              Icons.play_circle_outline,
                              size: 18,
                            ),
                            label: I18nText('Active dogs now: $activeDogs'),
                          ),
                          Chip(
                            avatar: const Icon(
                              Icons.monetization_on_outlined,
                              size: 18,
                            ),
                            label: I18nText(
                              'Next 30-day renewal: $renewingDogs Doubloons / £${renewalPounds.toStringAsFixed(2)}',
                            ),
                          ),
                        ],
                      ),
                      if (widget.profile.canManageAccounts) ...[
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            if (renewingDogs > 0)
                              OutlinedButton.icon(
                                onPressed: () =>
                                    _pauseAllDogs(context, uid: u.id),
                                icon: const Icon(Icons.pause_circle_outline),
                                label: const I18nText('PAUSE ALL DOGS'),
                              ),
                            if (scheduledPauses > 0)
                              OutlinedButton.icon(
                                onPressed: () =>
                                    _cancelAllPauses(context, uid: u.id),
                                icon: const Icon(Icons.restart_alt),
                                label: const I18nText('CANCEL ALL PAUSES'),
                              ),
                          ],
                        ),
                      ],
                    ],
                    const Divider(height: 22),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: I18nText(
                        dogs.isEmpty
                            ? 'No dogs on this account.'
                            : 'Dogs: $dogNames',
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ),
                    ...dogs.map((d) {
                      final dog = d.data();
                      final status = _dogStatus(dog, owner);
                      final pauseRequested = dog['pauseRequested'] == true;
                      final accessUntil = _dateLabel(dog['accessUntil']);
                      final accountActivated = owner['activated'] == true;

                      final canStart =
                          accountActivated &&
                          [
                            'awaiting',
                            'paused',
                            'renewal_due',
                          ].contains(status);

                      return Card(
                        margin: const EdgeInsets.only(top: 8),
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Padding(
                                    padding: EdgeInsets.only(top: 3),
                                    child: Icon(Icons.pets),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        I18nText(
                                          (dog['name'] ?? 'Dog').toString(),
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 16,
                                          ),
                                        ),
                                        I18nText(
                                          '${(dog['breed'] ?? '')} • ${status.toUpperCase()}${dog['watchList'] == true ? ' • 👀 WATCH LIST' : ''}',
                                        ),
                                        if (accessUntil.isNotEmpty)
                                          I18nText(
                                            'Access until: $accessUntil',
                                          ),
                                        if (pauseRequested)
                                          const I18nText(
                                            'Pause scheduled at the end of the paid period.',
                                          ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              if (widget.profile.canManageAccounts) ...[
                                const SizedBox(height: 10),
                                Wrap(
                                  spacing: 8,
                                  runSpacing: 8,
                                  children: [
                                    if (canStart)
                                      FilledButton.icon(
                                        onPressed: () => _authoriseDog(
                                          context,
                                          uid: u.id,
                                          dogId: d.id,
                                        ),
                                        icon: const Icon(
                                          Icons.play_circle_fill,
                                        ),
                                        label: I18nText(
                                          status == 'paused'
                                              ? 'RESTART 30 DAYS'
                                              : 'AUTHORISE 30 DAYS',
                                        ),
                                      ),
                                    if (status == 'active' && !pauseRequested)
                                      OutlinedButton.icon(
                                        onPressed: () => _pauseDog(
                                          context,
                                          uid: u.id,
                                          dogId: d.id,
                                        ),
                                        icon: const Icon(
                                          Icons.pause_circle_outline,
                                        ),
                                        label: const I18nText(
                                          'PAUSE AT PERIOD END',
                                        ),
                                      ),
                                    if (pauseRequested)
                                      OutlinedButton.icon(
                                        onPressed: () => _cancelDogPause(
                                          context,
                                          dogId: d.id,
                                        ),
                                        icon: const Icon(Icons.restart_alt),
                                        label: const I18nText('CANCEL PAUSE'),
                                      ),
                                    TextButton.icon(
                                      onPressed: () => Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (_) => DogSnapshot(
                                            profile: widget.profile,
                                            dogId: d.id,
                                            dog: dog,
                                            ownerId: u.id,
                                            owner: owner,
                                          ),
                                        ),
                                      ),
                                      icon: const Icon(Icons.open_in_new),
                                      label: const I18nText('VIEW DOG'),
                                    ),
                                  ],
                                ),
                              ],
                            ],
                          ),
                        ),
                      );
                    }),
                  ],
                ),
              );
            }),
          ],
        );
      },
    ),
  );
}

class DogSnapshot extends StatelessWidget {
  final AppUser profile;
  final String dogId, ownerId;
  final Map<String, dynamic> dog, owner;
  DogSnapshot({
    super.key,
    required this.profile,
    required this.dogId,
    required this.dog,
    required this.ownerId,
    required this.owner,
  });
  final service = FirestoreService();

  Future<void> adjustDoubloons(BuildContext context) async {
    final c = TextEditingController(text: '1');
    bool remove = false;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setLocal) => AlertDialog(
          title: const I18nText('Adjust Doubloons'),
          content: SizedBox(
            width: 430,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const I18nText(
                    '1 Doubloon = £5 = 30 days access for one dog.',
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [1, 2, 3, 6]
                        .map(
                          (n) => ActionChip(
                            label: I18nText('+$n'),
                            onPressed: () {
                              c.text = '$n';
                              setLocal(() => remove = false);
                            },
                          ),
                        )
                        .toList(),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: c,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    decoration: const InputDecoration(
                      label: I18nText('Number of Doubloons'),
                    ),
                  ),
                  const SizedBox(height: 8),
                  SegmentedButton<bool>(
                    segments: const [
                      ButtonSegment(
                        value: false,
                        icon: Icon(Icons.add_circle_outline),
                        label: I18nText('ADD'),
                      ),
                      ButtonSegment(
                        value: true,
                        icon: Icon(Icons.remove_circle_outline),
                        label: I18nText('REMOVE'),
                      ),
                    ],
                    selected: {remove},
                    onSelectionChanged: (v) => setLocal(() => remove = v.first),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const I18nText('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const I18nText('SAVE'),
            ),
          ],
        ),
      ),
    );
    final count = double.tryParse(c.text.trim());
    if (ok == true && count != null && count > 0) {
      final changed = await service.adjustAcademyDoubloons(
        uid: ownerId,
        doubloons: remove ? -count : count,
        actor: profile.name,
      );
      if (context.mounted && !changed) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: I18nText(
              'That would take the Doubloon balance below zero.',
            ),
          ),
        );
      }
    }
    c.dispose();
  }

  Future<void> note(BuildContext context) async {
    final c = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const I18nText('Private staff note'),
        content: TextField(
          controller: c,
          maxLines: 5,
          decoration: const InputDecoration(label: I18nText('Note')),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const I18nText('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const I18nText('SAVE'),
          ),
        ],
      ),
    );
    if (ok == true && c.text.trim().isNotEmpty)
      await service.addStaffNote(
        dogId: dogId,
        dogName: (dog['name'] ?? 'Dog').toString(),
        author: profile.name,
        note: c.text,
      );
    c.dispose();
  }

  Future<void> _recommendSkill(BuildContext context) async {
    String moduleId = courseModules.first.id;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setLocal) => AlertDialog(
          title: I18nText('Recommend a skill for ${dog['name'] ?? 'this dog'}'),
          content: DropdownButtonFormField<String>(
            initialValue: moduleId,
            items: courseModules
                .map(
                  (m) =>
                      DropdownMenuItem(value: m.id, child: I18nText(m.title)),
                )
                .toList(),
            onChanged: (v) => setLocal(() => moduleId = v ?? moduleId),
            decoration: const InputDecoration(
              label: I18nText('Recommended next skill'),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const I18nText('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const I18nText('SEND MISSION'),
            ),
          ],
        ),
      ),
    );
    if (ok == true) {
      final module = courseModules.firstWhere((m) => m.id == moduleId);
      await service.recommendSkill(
        uid: ownerId,
        dogId: dogId,
        dogName: (dog['name'] ?? 'Dog').toString(),
        moduleId: module.id,
        moduleTitle: module.title,
        trainerName: profile.name,
      );
      if (context.mounted)
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: I18nText('Recommended skill sent to the learner.'),
          ),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final rawStatus = (dog['academyStatus'] ?? '').toString();
    final legacy = rawStatus.isEmpty && owner['activated'] == true;
    final status = rawStatus.isEmpty
        ? (owner['activated'] == true ? 'legacy active' : 'awaiting')
        : rawStatus;
    return Scaffold(
      appBar: AppBar(
        title: I18nText('${dog['name'] ?? 'Dog'} — Dog Snapshot'),
        actions: [LanguageToggle(userId: profile.id)],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  I18nText(
                    '${dog['name']} & ${owner['name']}',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  I18nText('${owner['email'] ?? ''} • ${owner['phone'] ?? ''}'),
                  I18nText(
                    'Breed: ${dog['breed'] ?? ''} • DOB: ${dog['dateOfBirth'] ?? 'Not set'}',
                  ),
                  I18nText('Academy status: ${status.toUpperCase()}'),
                  StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
                    stream: service.userStream(ownerId),
                    builder: (context, snap) {
                      final credit =
                          (snap.data?.data()?['academyCredit'] as num?)
                              ?.toDouble() ??
                          ((owner['academyCredit'] as num?)?.toDouble() ?? 0);
                      return I18nText(
                        'Doubloon balance: ${doubloonBalanceLabel(credit)}',
                      );
                    },
                  ),
                  if (profile.canManageAccounts)
                    StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
                      stream: service.userStream(ownerId),
                      builder: (context, snap) {
                        final data = snap.data?.data() ?? owner;
                        final role = (data['role'] ?? 'learner').toString();
                        final value =
                            [
                              'learner',
                              'trainer',
                              'admin',
                              'captain',
                            ].contains(role)
                            ? role
                            : 'learner';
                        return Row(
                          children: [
                            const Expanded(child: I18nText('Academy role')),
                            DropdownButton<String>(
                              value: value,
                              items: ['learner', 'trainer', 'admin', 'captain']
                                  .map(
                                    (r) => DropdownMenuItem(
                                      value: r,
                                      child: I18nText(r.toUpperCase()),
                                    ),
                                  )
                                  .toList(),
                              onChanged: (v) {
                                if (v != null)
                                  service.setUserRole(
                                    ownerId,
                                    v,
                                    actor: profile.name,
                                  );
                              },
                            ),
                          ],
                        );
                      },
                    ),
                  if ((dog['experience'] ?? '').toString().isNotEmpty)
                    I18nText('Experience: ${dog['experience']}'),
                  if ((dog['notes'] ?? '').toString().isNotEmpty)
                    I18nText('Learner notes: ${dog['notes']}'),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      OutlinedButton.icon(
                        onPressed: () => note(context),
                        icon: const Icon(Icons.note_add),
                        label: const I18nText('STAFF NOTE'),
                      ),
                      OutlinedButton.icon(
                        onPressed: () => _recommendSkill(context),
                        icon: const Icon(Icons.assistant_direction),
                        label: const I18nText('RECOMMEND SKILL'),
                      ),
                      OutlinedButton.icon(
                        onPressed: () => service.updateDog(dogId, {
                          'watchList': dog['watchList'] != true,
                        }),
                        icon: const Icon(Icons.visibility),
                        label: I18nText(
                          dog['watchList'] == true
                              ? 'REMOVE WATCH'
                              : 'WATCH LIST',
                        ),
                      ),
                      if (profile.canManageAccounts)
                        FilledButton.tonalIcon(
                          onPressed: () => adjustDoubloons(context),
                          icon: const Icon(Icons.monetization_on_outlined),
                          label: const I18nText('ADJUST DOUBLOONS'),
                        ),
                      if (legacy && profile.canManageAccounts)
                        FilledButton.icon(
                          onPressed: () async {
                            await service.migrateLegacyDog(
                              dogId: dogId,
                              uid: ownerId,
                              actor: profile.name,
                            );
                            if (context.mounted)
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: I18nText(
                                    'Legacy dog moved onto a fresh V1.4 Academy voyage.',
                                  ),
                                ),
                              );
                          },
                          icon: const Icon(Icons.upgrade),
                          label: const I18nText('START V1.4 ACCESS'),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
            stream: service.trophiesForDog(dogId),
            builder: (context, snap) => Card(
              child: ListTile(
                leading: const Icon(Icons.emoji_events),
                title: I18nText(
                  '${snap.data?.docs.length ?? 0} trophies earned',
                ),
              ),
            ),
          ),
          StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
            stream: service.trainingLogsForDog(dogId),
            builder: (context, snap) => Card(
              child: ListTile(
                leading: const Icon(Icons.menu_book),
                title: I18nText(
                  '${snap.data?.docs.length ?? 0} training diary entries',
                ),
              ),
            ),
          ),
          StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
            stream: service.staffNotesForDog(dogId),
            builder: (context, snap) {
              final docs = [...(snap.data?.docs ?? [])]
                ..sort(
                  (a, b) =>
                      ((b.data()['createdAt'] as Timestamp?)
                                  ?.millisecondsSinceEpoch ??
                              0)
                          .compareTo(
                            (a.data()['createdAt'] as Timestamp?)
                                    ?.millisecondsSinceEpoch ??
                                0,
                          ),
                );
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  I18nText(
                    'Private staff notes',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  if (docs.isEmpty)
                    const Card(
                      child: Padding(
                        padding: EdgeInsets.all(16),
                        child: I18nText('No private notes.'),
                      ),
                    ),
                  ...docs.map(
                    (d) => Card(
                      child: ListTile(
                        title: Text((d.data()['note'] ?? '').toString()),
                        subtitle: Text((d.data()['author'] ?? '').toString()),
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

class ReportsScreen extends StatefulWidget {
  final AppUser profile;
  const ReportsScreen({super.key, required this.profile});
  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  final service = FirestoreService();
  int quarter = ((DateTime.now().month - 1) ~/ 3) + 1;
  int year = DateTime.now().year;

  DateTime get start => DateTime(year, (quarter - 1) * 3 + 1, 1);
  DateTime get end => DateTime(year, quarter * 3 + 1, 1);
  bool inRange(dynamic ts) {
    final d = ts is Timestamp ? ts.toDate() : null;
    return d != null && !d.isBefore(start) && d.isBefore(end);
  }

  Future<Map<String, dynamic>> load() async {
    final results = await Future.wait([
      service.db.collection('users').get(),
      service.db.collection('dogs').get(),
      service.db.collection('submissions').get(),
      service.db.collection('trainingLogs').get(),
      service.db.collection('lessonHelp').get(),
      service.db.collection('oneToOneRequests').get(),
      service.db.collection('kudos').get(),
      service.db.collection('lightAttempts').get(),
      service.db.collectionGroup('trophies').get(),
      service.db.collection('restartRequests').get(),
    ]);
    return {
      'users': results[0].docs,
      'dogs': results[1].docs,
      'subs': results[2].docs,
      'logs': results[3].docs,
      'help': results[4].docs,
      'one': results[5].docs,
      'kudos': results[6].docs,
      'lights': results[7].docs,
      'trophies': results[8].docs,
      'restarts': results[9].docs,
    };
  }

  @override
  Widget build(BuildContext context) => ListView(
    padding: const EdgeInsets.all(16),
    children: [
      I18nText(
        'Quarterly Academy Report',
        style: Theme.of(context).textTheme.headlineSmall,
      ),
      const I18nText(
        'Useful numbers for trainers, committee updates, grant evidence and privacy-safe social posts.',
      ),
      const SizedBox(height: 10),
      Row(
        children: [
          Expanded(
            child: DropdownButtonFormField<int>(
              initialValue: quarter,
              items: [1, 2, 3, 4]
                  .map(
                    (q) => DropdownMenuItem(value: q, child: I18nText('Q$q')),
                  )
                  .toList(),
              onChanged: (v) => setState(() => quarter = v ?? quarter),
              decoration: const InputDecoration(label: I18nText('Quarter')),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: DropdownButtonFormField<int>(
              initialValue: year,
              items: [year - 2, year - 1, year, year + 1]
                  .toSet()
                  .map((y) => DropdownMenuItem(value: y, child: I18nText('$y')))
                  .toList(),
              onChanged: (v) => setState(() => year = v ?? year),
              decoration: const InputDecoration(label: I18nText('Year')),
            ),
          ),
        ],
      ),
      const SizedBox(height: 12),
      FutureBuilder<Map<String, dynamic>>(
        key: ValueKey('Q${quarter}_$year'),
        future: load(),
        builder: (context, snap) {
          if (!snap.hasData) return const LinearProgressIndicator();
          final d = snap.data!;
          final users = List<QueryDocumentSnapshot<Map<String, dynamic>>>.from(
            d['users'],
          );
          final dogs = List<QueryDocumentSnapshot<Map<String, dynamic>>>.from(
            d['dogs'],
          );
          final subs = List<QueryDocumentSnapshot<Map<String, dynamic>>>.from(
            d['subs'],
          );
          final logs = List<QueryDocumentSnapshot<Map<String, dynamic>>>.from(
            d['logs'],
          );
          final help = List<QueryDocumentSnapshot<Map<String, dynamic>>>.from(
            d['help'],
          );
          final one = List<QueryDocumentSnapshot<Map<String, dynamic>>>.from(
            d['one'],
          );
          final kudos = List<QueryDocumentSnapshot<Map<String, dynamic>>>.from(
            d['kudos'],
          );
          final lights = List<QueryDocumentSnapshot<Map<String, dynamic>>>.from(
            d['lights'],
          );
          final trophies =
              List<QueryDocumentSnapshot<Map<String, dynamic>>>.from(
                d['trophies'],
              );
          final restarts =
              List<QueryDocumentSnapshot<Map<String, dynamic>>>.from(
                d['restarts'],
              );
          final now = DateTime.now();
          final learners = users
              .where((u) => u.data()['role'] == 'learner')
              .length;
          final newLearners = users
              .where(
                (u) =>
                    u.data()['role'] == 'learner' &&
                    inRange(u.data()['createdAt']),
              )
              .length;
          final activeDogs = dogs.where((x) {
            final m = x.data();
            final status = (m['academyStatus'] ?? '').toString();
            final until = (m['accessUntil'] as Timestamp?)?.toDate();
            return status == 'active' && (until == null || until.isAfter(now));
          }).length;
          final pausedDogs = dogs
              .where((x) => (x.data()['academyStatus'] ?? '') == 'paused')
              .length;
          final quarterSubs = subs
              .where((x) => inRange(x.data()['submittedAt']))
              .toList();
          final passes = quarterSubs
              .where((x) => x.data()['status'] == 'passed')
              .length;
          final passRate = quarterSubs.isEmpty
              ? 0
              : (passes / quarterSubs.length * 100).round();
          final qLogs = logs
              .where((x) => inRange(x.data()['createdAt']))
              .length;
          final qHelpDocs = help
              .where((x) => inRange(x.data()['createdAt']))
              .toList();
          final qOne = one.where((x) => inRange(x.data()['createdAt'])).length;
          final qKudos = kudos
              .where((x) => inRange(x.data()['createdAt']))
              .length;
          final qTrophyDocs = trophies
              .where((x) => inRange(x.data()['awardedAt']))
              .toList();
          final qGraduates = qTrophyDocs
              .where((x) => x.id == 'flyballready')
              .length;
          final qLights = lights
              .where((x) => inRange(x.data()['createdAt']))
              .toList();
          final qRolling = qLights
              .where((x) => x.data()['isRolling'] == true)
              .length;
          final qRestarts = restarts
              .where((x) => inRange(x.data()['createdAt']))
              .length;
          final topics = <String, int>{};
          for (final h in qHelpDocs) {
            final k = (h.data()['lessonTitle'] ?? 'General').toString();
            topics[k] = (topics[k] ?? 0) + 1;
          }
          final top = topics.entries.toList()
            ..sort((a, b) => b.value.compareTo(a.value));
          final skillPerformance = <String, Map<String, int>>{};
          for (final submission in quarterSubs) {
            final title = (submission.data()['moduleTitle'] ?? 'Unknown skill')
                .toString();
            final row = skillPerformance.putIfAbsent(
              title,
              () => {'submitted': 0, 'passed': 0},
            );
            row['submitted'] = (row['submitted'] ?? 0) + 1;
            if (submission.data()['status'] == 'passed')
              row['passed'] = (row['passed'] ?? 0) + 1;
          }
          final skillRows = skillPerformance.entries.toList()
            ..sort(
              (a, b) => (b.value['submitted'] ?? 0).compareTo(
                a.value['submitted'] ?? 0,
              ),
            );
          final summary =
              '''MENAI MUTTINEERS ACADEMY — Q$quarter $year

🐕 $activeDogs active dogs aboard
👥 $learners learner accounts ($newLearners new this quarter)
🎥 ${quarterSubs.length} assessments submitted
🏆 $passes assessments passed ($passRate% pass rate)
🎓 $qGraduates Pre-Flyball graduates
🎖️ ${qTrophyDocs.length} trophies awarded
📝 $qLogs training sessions logged
💬 ${qHelpDocs.length} training help conversations started
📅 $qOne 1-to-1 requests
👏 $qKudos Kudos shared
🚦 ${qLights.length} start-light attempts / $qRolling rolling starts
▶️ $qRestarts Academy restart requests
${top.isEmpty ? '' : '\nMost requested help: ${top.first.key} (${top.first.value})'}

Small steps. Happy dogs. Future flyballers.''';
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [
                  _metric(context, 'Active dogs', '$activeDogs'),
                  _metric(context, 'Paused dogs', '$pausedDogs'),
                  _metric(context, 'New learners', '$newLearners'),
                  _metric(context, 'Assessments', '${quarterSubs.length}'),
                  _metric(context, 'Pass rate', '$passRate%'),
                  _metric(context, 'Graduates', '$qGraduates'),
                  _metric(context, 'Trophies', '${qTrophyDocs.length}'),
                  _metric(context, 'Training logs', '$qLogs'),
                  _metric(context, 'Help threads', '${qHelpDocs.length}'),
                  _metric(context, '1-to-1s', '$qOne'),
                  _metric(context, 'Kudos', '$qKudos'),
                  _metric(context, 'Light starts', '${qLights.length}'),
                ],
              ),
              const SizedBox(height: 12),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      I18nText(
                        'Skill performance',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const I18nText(
                        'Assessment volume and pass rate help us spot where the course or assessment may need improving.',
                      ),
                      const SizedBox(height: 8),
                      if (skillRows.isEmpty)
                        const I18nText(
                          'No assessments submitted in this quarter.',
                        )
                      else
                        ...skillRows.map((e) {
                          final submitted = e.value['submitted'] ?? 0;
                          final passed = e.value['passed'] ?? 0;
                          final rate = submitted == 0
                              ? 0
                              : (passed / submitted * 100).round();
                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 4),
                            child: Row(
                              children: [
                                Expanded(
                                  child: I18nText(
                                    e.key,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                                I18nText(
                                  '$passed / $submitted passed • $rate%',
                                ),
                              ],
                            ),
                          );
                        }),
                    ],
                  ),
                ),
              ),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      I18nText(
                        'Training intelligence',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      if (top.isEmpty)
                        const I18nText(
                          'No help-request trends in this quarter.',
                        )
                      else
                        ...top
                            .take(8)
                            .map(
                              (e) => I18nText(
                                '${e.key}: ${e.value} help request${e.value == 1 ? '' : 's'}',
                              ),
                            ),
                    ],
                  ),
                ),
              ),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: SelectableText(summary),
                ),
              ),
              FilledButton.icon(
                onPressed: () {
                  Clipboard.setData(ClipboardData(text: summary));
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: I18nText('Quarterly social summary copied.'),
                    ),
                  );
                },
                icon: const Icon(Icons.copy),
                label: const I18nText('COPY PRIVACY-SAFE SOCIAL SUMMARY'),
              ),
              const SizedBox(height: 8),
              const I18nText(
                'Quarterly numbers are operational Academy records. They are useful for committee/impact reporting but are not a replacement for formal club accounts.',
              ),
            ],
          );
        },
      ),
    ],
  );

  Widget _metric(BuildContext context, String label, String value) => SizedBox(
    width: 155,
    child: Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            I18nText(value, style: Theme.of(context).textTheme.headlineMedium),
            I18nText(label),
          ],
        ),
      ),
    ),
  );
}

class StaffControl extends StatefulWidget {
  final AppUser profile;
  const StaffControl({super.key, required this.profile});
  @override
  State<StaffControl> createState() => _StaffControlState();
}

class _StaffControlState extends State<StaffControl> {
  final service = FirestoreService();
  @override
  Widget build(BuildContext context) => ListView(
    padding: const EdgeInsets.all(16),
    children: [
      I18nText(
        'Control Room',
        style: Theme.of(context).textTheme.headlineSmall,
      ),
      const I18nText(
        'Test the learner experience, edit the course and keep the Academy running without rebuilding the APK.',
      ),
      const SizedBox(height: 10),
      Card(
        child: ListTile(
          leading: const Icon(Icons.visibility),
          title: const I18nText('Preview as Learner'),
          subtitle: const I18nText(
            'Test active, paused, awaiting and graduated views without changing your staff role.',
          ),
          trailing: const Icon(Icons.chevron_right),
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const LearnerPreviewScreen()),
          ),
        ),
      ),
      if (widget.profile.canManageAccounts)
        RoleManager(profile: widget.profile),
      if (widget.profile.canManageAccounts)
        AccountSettings(profile: widget.profile),
      if (widget.profile.canManageAccounts)
        AcademySettingsEditor(profile: widget.profile),
      if (widget.profile.canManageAccounts)
        DeletionRequestsPanel(profile: widget.profile),
      CourseEditor(profile: widget.profile),
      if (widget.profile.canManageAccounts)
        LinksEditor(profile: widget.profile),
      if (widget.profile.canManageAccounts) MusicEditor(),
      if (widget.profile.canManageAccounts) CalendarEditor(),
      if (widget.profile.canManageAccounts)
        SavedRepliesEditor(profile: widget.profile),
      if (widget.profile.canManageAccounts) FeatureEditor(),
      if (widget.profile.canManageAccounts)
        NoticeEditor(profile: widget.profile),
      FeedbackAdmin(),
      if (widget.profile.isCaptain || widget.profile.isAdmin)
        CaptainLogPanel(profile: widget.profile),
      if (widget.profile.canManageAccounts) AuditLogPanel(),
      if (widget.profile.canManageAccounts) SystemHealth(),
    ],
  );
}

class LearnerPreviewScreen extends StatefulWidget {
  const LearnerPreviewScreen({super.key});
  @override
  State<LearnerPreviewScreen> createState() => _LearnerPreviewScreenState();
}

class _LearnerPreviewScreenState extends State<LearnerPreviewScreen> {
  String state = 'active';
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const I18nText('🧪 Learner Preview Mode')),
    body: ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Card(
          color: Colors.amber.shade100,
          child: const Padding(
            padding: EdgeInsets.all(12),
            child: I18nText(
              'TEST DECK — this is a safe preview. It does not change your staff permissions or real learner data.',
            ),
          ),
        ),
        DropdownButtonFormField<String>(
          initialValue: state,
          items:
              [
                    'new / awaiting payment',
                    'active',
                    'paused',
                    'renewal due',
                    'graduated',
                  ]
                  .map(
                    (e) => DropdownMenuItem(
                      value: e.split(' / ').first.replaceAll(' ', '_'),
                      child: I18nText(e.toUpperCase()),
                    ),
                  )
                  .toList(),
          onChanged: (v) => setState(() => state = v ?? state),
          decoration: const InputDecoration(label: I18nText('Preview state')),
        ),
        const SizedBox(height: 12),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                const Icon(Icons.sailing, size: 60),
                I18nText(
                  'Ahoy Test Learner & Test Dog!',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: 8),
                I18nText(
                  state == 'paused'
                      ? '⚓ Test Dog’s adventure is currently anchored.'
                      : state == 'active'
                      ? '🏴‍☠️ Your next mission is Focus & Engagement — Lesson 3.'
                      : state == 'graduated'
                      ? '🏆 READY TO JOIN THE CREW — Pre-Flyball Skills completed!'
                      : '🔒 Academy access is waiting for the next step.',
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                if (state == 'paused') ...const [
                  FilledButton(
                    onPressed: null,
                    child: I18nText('RESTART ADVENTURE'),
                  ),
                  OutlinedButton(
                    onPressed: null,
                    child: I18nText('REQUEST A 1-to-1'),
                  ),
                ] else if (state == 'active')
                  const LinearProgressIndicator(value: .42),
              ],
            ),
          ),
        ),
      ],
    ),
  );
}

class RoleManager extends StatelessWidget {
  final AppUser profile;
  RoleManager({super.key, required this.profile});
  final service = FirestoreService();

  @override
  Widget build(BuildContext context) => ExpansionTile(
    leading: const Icon(Icons.manage_accounts),
    title: const I18nText('Manage Crew & Staff'),
    children: [
      StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: service.allUsers(),
        builder: (context, snap) {
          final docs = snap.data?.docs ?? [];
          return Column(
            children: docs.map((d) {
              final m = d.data();
              final role = (m['role'] ?? 'learner').toString();
              final validRole =
                  ['learner', 'trainer', 'admin', 'captain'].contains(role)
                  ? role
                  : 'learner';
              return ListTile(
                title: I18nText((m['name'] ?? 'User').toString()),
                subtitle: I18nText(
                  '${m['email'] ?? ''} • ${role.toUpperCase()}',
                ),
                trailing: DropdownButton<String>(
                  value: validRole,
                  items: ['learner', 'trainer', 'admin', 'captain']
                      .map(
                        (r) => DropdownMenuItem<String>(
                          value: r,
                          child: I18nText(r.toUpperCase()),
                        ),
                      )
                      .toList(),
                  onChanged: (v) {
                    if (v != null) {
                      service.setUserRole(d.id, v, actor: profile.name);
                    }
                  },
                ),
              );
            }).toList(),
          );
        },
      ),
    ],
  );
}

class AccountSettings extends StatelessWidget {
  final AppUser profile;
  AccountSettings({super.key, required this.profile});
  final service = FirestoreService();
  @override
  Widget build(BuildContext context) => ExpansionTile(
    leading: const Icon(Icons.account_balance_wallet),
    title: const I18nText('Legacy / initial access'),
    subtitle: const I18nText(
      'Issue the first activation code for brand-new learners.',
    ),
    children: [
      StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: service.allUsers(),
        builder: (context, snap) {
          final docs = (snap.data?.docs ?? [])
              .where(
                (d) =>
                    d.data()['role'] == 'learner' &&
                    d.data()['activated'] != true,
              )
              .toList();
          return Column(
            children: docs.map((d) {
              final m = d.data();
              return ListTile(
                title: I18nText(m['name'] ?? 'Learner'),
                subtitle: I18nText(
                  'Payment: ${(m['paymentStatus'] ?? 'unpaid').toString().toUpperCase()}',
                ),
                trailing: FilledButton(
                  onPressed: () async {
                    final code = await service.markPaid(d.id);
                    if (context.mounted)
                      showDialog(
                        context: context,
                        builder: (ctx) => AlertDialog(
                          title: const I18nText('Activation code'),
                          content: SelectableText(
                            code,
                            style: Theme.of(context).textTheme.headlineMedium,
                          ),
                          actions: [
                            FilledButton(
                              onPressed: () => Navigator.pop(ctx),
                              child: const I18nText('Done'),
                            ),
                          ],
                        ),
                      );
                  },
                  child: const I18nText('CONFIRM + CODE'),
                ),
              );
            }).toList(),
          );
        },
      ),
    ],
  );
}

class AcademySettingsEditor extends StatefulWidget {
  final AppUser profile;
  const AcademySettingsEditor({super.key, required this.profile});
  @override
  State<AcademySettingsEditor> createState() => _AcademySettingsEditorState();
}

class _AcademySettingsEditorState extends State<AcademySettingsEditor> {
  final service = FirestoreService();
  final onePrice = TextEditingController();
  final oneMinutes = TextEditingController();
  final oneWording = TextEditingController();
  final suffix = TextEditingController();
  final closure = TextEditingController();
  bool loaded = false;

  @override
  void dispose() {
    for (final c in [onePrice, oneMinutes, oneWording, suffix, closure])
      c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => ExpansionTile(
    leading: const Icon(Icons.tune),
    title: const I18nText('Academy Access & Wording'),
    subtitle: const I18nText(
      'Doubloon access is fixed at £5 / 30 days. Edit the other learner wording and 1-to-1 guide here.',
    ),
    children: [
      StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
        stream: service.academySettings(),
        builder: (context, snap) {
          if (snap.hasData && !loaded) {
            final c = AcademyConfig.fromMap(snap.data?.data() ?? {});
            onePrice.text = c.oneToOneGuidePrice.toStringAsFixed(2);
            oneMinutes.text = '${c.oneToOneGuideMinutes}';
            oneWording.text = c.oneToOneWording;
            suffix.text = c.paymentReferenceSuffix;
            closure.text = c.accountClosureWording;
            loaded = true;
          }
          if (!loaded) return const LinearProgressIndicator();
          return Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Card(
                  child: Padding(
                    padding: EdgeInsets.all(12),
                    child: I18nText(
                      '🪙 Academy access: 1 Doubloon = £5 = 30 days for one dog. This is fixed in V1.4.',
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: onePrice,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        decoration: const InputDecoration(
                          label: I18nText('Typical 1-to-1 guide price (£)'),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextField(
                        controller: oneMinutes,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          label: I18nText('Typical 1-to-1 minutes'),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: oneWording,
                  maxLines: 4,
                  decoration: const InputDecoration(
                    label: I18nText('1-to-1 wording shown to learners'),
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: suffix,
                  decoration: const InputDecoration(
                    label: I18nText('Payment reference suffix'),
                    hint: I18nText('007'),
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: closure,
                  maxLines: 4,
                  decoration: const InputDecoration(
                    label: I18nText('Account closure wording'),
                  ),
                ),
                const SizedBox(height: 10),
                FilledButton.icon(
                  onPressed: () async {
                    final p = double.tryParse(onePrice.text.trim());
                    final m = int.tryParse(oneMinutes.text.trim());
                    if (p == null || p < 0 || m == null || m <= 0) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: I18nText(
                            'Please check the 1-to-1 price and minute values.',
                          ),
                        ),
                      );
                      return;
                    }
                    await service.saveAcademySettings({
                      'dogPeriodCost': academyDoubloonPounds,
                      'dogPeriodDays': academyDoubloonAccessDays,
                      'oneToOneGuidePrice': p,
                      'oneToOneGuideMinutes': m,
                      'oneToOneWording': oneWording.text.trim(),
                      'paymentReferenceSuffix': suffix.text.trim().isEmpty
                          ? '007'
                          : suffix.text.trim(),
                      'accountClosureWording': closure.text.trim(),
                      'updatedBy': widget.profile.name,
                      'updatedAt': FieldValue.serverTimestamp(),
                    });
                    if (context.mounted)
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: I18nText(
                            'Academy settings saved. Everyone will see the new values.',
                          ),
                        ),
                      );
                  },
                  icon: const Icon(Icons.save),
                  label: const I18nText('SAVE ACADEMY SETTINGS'),
                ),
              ],
            ),
          );
        },
      ),
    ],
  );
}

class DeletionRequestsPanel extends StatelessWidget {
  final AppUser profile;
  DeletionRequestsPanel({super.key, required this.profile});
  final service = FirestoreService();
  final functions = AdminFunctionsService();

  Future<void> _delete(
    BuildContext context,
    QueryDocumentSnapshot<Map<String, dynamic>> doc,
  ) async {
    final m = doc.data();
    final name = (m['name'] ?? 'this learner').toString();
    final first = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const I18nText('Permanent account removal'),
        content: I18nText(
          'Permanently remove $name and their Academy data? This cannot be undone. Legitimate accounting records are kept only in anonymised form where required.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const I18nText('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const I18nText('CONTINUE'),
          ),
        ],
      ),
    );
    if (first != true || !context.mounted) return;
    final second = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const I18nText('Final check'),
        content: I18nText(
          'Are you completely sure you want to remove $name from the Academy?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const I18nText('No'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const I18nText('YES — REMOVE ACCOUNT'),
          ),
        ],
      ),
    );
    if (second != true) return;
    try {
      await service.markAccountClosureProcessing(doc.id, profile.name);
      await functions.permanentlyDeleteAcademyAccount(targetUid: doc.id);
      if (context.mounted)
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: I18nText('Account removed from the Academy.'),
          ),
        );
    } catch (_) {
      await service.updateAccountClosureStatus(doc.id, 'requested');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: I18nText(
              'The deletion service is not ready yet. Set up V1.4 Firebase Functions using the included guide, then try again.',
            ),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) => ExpansionTile(
    leading: const Icon(Icons.sailing),
    title: const I18nText('Set Sail — Account Removal Requests'),
    children: [
      StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: service.allAccountDeletionRequests(),
        builder: (context, snap) {
          final docs = (snap.data?.docs ?? [])
              .where(
                (d) => [
                  'requested',
                  'processing',
                ].contains((d.data()['status'] ?? '').toString()),
              )
              .toList();
          if (docs.isEmpty)
            return const ListTile(
              title: I18nText('No account removal requests.'),
            );
          return Column(
            children: docs.map((d) {
              final m = d.data();
              return ListTile(
                leading: const Icon(Icons.directions_boat),
                title: I18nText(m['name'] ?? 'Learner'),
                subtitle: I18nText(
                  '${(m['status'] ?? 'requested').toString().toUpperCase()}${(m['reason'] ?? '').toString().isEmpty ? '' : ' • ${m['reason']}'}',
                ),
                trailing: Wrap(
                  spacing: 6,
                  children: [
                    TextButton(
                      onPressed: () =>
                          service.updateAccountClosureStatus(d.id, 'cancelled'),
                      child: const I18nText('KEEP ABOARD'),
                    ),
                    FilledButton.tonal(
                      onPressed: () => _delete(context, d),
                      child: const I18nText('REMOVE'),
                    ),
                  ],
                ),
              );
            }).toList(),
          );
        },
      ),
    ],
  );
}

class CourseEditor extends StatelessWidget {
  final AppUser profile;
  CourseEditor({super.key, required this.profile});
  final service = FirestoreService();
  @override
  Widget build(BuildContext context) => ExpansionTile(
    leading: const Icon(Icons.school),
    title: const I18nText('Course Editor'),
    subtitle: const I18nText(
      'Change individual lesson video links without rebuilding the app.',
    ),
    children: courseModules
        .map(
          (m) => ExpansionTile(
            title: I18nText(m.title),
            children: m.lessons
                .map((l) => _LessonEditor(module: m, lesson: l))
                .toList(),
          ),
        )
        .toList(),
  );
}

class _LessonEditor extends StatefulWidget {
  final CourseModule module;
  final LessonDefinition lesson;
  const _LessonEditor({required this.module, required this.lesson});
  @override
  State<_LessonEditor> createState() => _LessonEditorState();
}

class _LessonEditorState extends State<_LessonEditor> {
  final service = FirestoreService();
  final c = TextEditingController();
  @override
  void dispose() {
    c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
    child: Row(
      children: [
        Expanded(
          child: TextField(
            controller: c,
            decoration: InputDecoration(
              label: I18nText(widget.lesson.title),
              hint: const I18nText('YouTube / video URL'),
            ),
          ),
        ),
        const SizedBox(width: 6),
        IconButton.filled(
          onPressed: () => service.saveLessonVideo(
            widget.module.id,
            widget.lesson.id,
            c.text,
          ),
          icon: const Icon(Icons.save),
        ),
      ],
    ),
  );
}

class LinksEditor extends StatefulWidget {
  final AppUser profile;
  const LinksEditor({super.key, required this.profile});
  @override
  State<LinksEditor> createState() => _LinksEditorState();
}

class _LinksEditorState extends State<LinksEditor> {
  final service = FirestoreService();
  final ctrls = <String, TextEditingController>{};
  bool loaded = false;
  final fields = {
    'facebook': 'Facebook URL',
    'instagram': 'Instagram URL',
    'tiktok': 'TikTok URL',
    'youtube': 'YouTube URL',
    'website': 'Website URL',
    'easyfundraising': 'Easyfundraising URL',
    'gofundme': 'GoFundMe URL',
    'bankName': 'Bank name',
    'accountName': 'Account name',
    'sortCode': 'Sort code',
    'accountNumber': 'Account number',
    'directDebitInfo': 'Standing order / Direct Debit instructions',
    'paymentNote': 'Payment note',
  };
  @override
  void dispose() {
    for (final c in ctrls.values) c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => ExpansionTile(
    leading: const Icon(Icons.link),
    title: const I18nText('Links, Fundraising & Bank Details'),
    children: [
      StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
        stream: service.linkSettings(),
        builder: (context, snap) {
          if (snap.hasData && !loaded) {
            final m = snap.data?.data() ?? {};
            for (final e in fields.entries)
              ctrls[e.key] = TextEditingController(
                text: (m[e.key] ?? '').toString(),
              );
            loaded = true;
          }
          if (!loaded) return const LinearProgressIndicator();
          return Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              children: [
                ...fields.entries.map(
                  (e) => Padding(
                    padding: const EdgeInsets.only(bottom: 7),
                    child: TextField(
                      controller: ctrls[e.key],
                      maxLines:
                          ['directDebitInfo', 'paymentNote'].contains(e.key)
                          ? 3
                          : 1,
                      decoration: InputDecoration(label: I18nText(e.value)),
                    ),
                  ),
                ),
                FilledButton.icon(
                  onPressed: () => service.saveLinkSettings({
                    for (final e in ctrls.entries) e.key: e.value.text,
                  }),
                  icon: const Icon(Icons.save),
                  label: const I18nText('SAVE LINKS & PAYMENT DETAILS'),
                ),
              ],
            ),
          );
        },
      ),
    ],
  );
}

class MusicEditor extends StatefulWidget {
  const MusicEditor({super.key});
  @override
  State<MusicEditor> createState() => _MusicEditorState();
}

class _MusicEditorState extends State<MusicEditor> {
  final service = FirestoreService();
  final title = TextEditingController();
  final url = TextEditingController();
  @override
  void dispose() {
    title.dispose();
    url.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => ExpansionTile(
    leading: const Icon(Icons.music_note),
    title: const I18nText('Academy Music Library'),
    subtitle: const I18nText(
      'The two Gentle Tide tracks are built in. Add more by public MP3 URL without rebuilding.',
    ),
    children: [
      Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            TextField(
              controller: title,
              decoration: const InputDecoration(label: I18nText('Track title')),
            ),
            const SizedBox(height: 7),
            TextField(
              controller: url,
              decoration: const InputDecoration(
                label: I18nText('Public MP3 URL'),
              ),
            ),
            const SizedBox(height: 7),
            FilledButton.icon(
              onPressed: () async {
                if (title.text.trim().isEmpty || !url.text.startsWith('http'))
                  return;
                await service.addMusicTrack(title: title.text, url: url.text);
                title.clear();
                url.clear();
              },
              icon: const Icon(Icons.add),
              label: const I18nText('ADD TRACK'),
            ),
            const Divider(),
            StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: service.musicTracks(),
              builder: (context, snap) => Column(
                children: (snap.data?.docs ?? []).map((d) {
                  final m = d.data();
                  return SwitchListTile(
                    title: I18nText(m['title'] ?? 'Track'),
                    subtitle: I18nText(m['url'] ?? ''),
                    value: m['enabled'] != false,
                    onChanged: (v) => service.setMusicTrackEnabled(d.id, v),
                    secondary: IconButton(
                      onPressed: () => service.deleteMusicTrack(d.id),
                      icon: const Icon(Icons.delete_outline),
                    ),
                  );
                }).toList(),
              ),
            ),
          ],
        ),
      ),
    ],
  );
}

class CalendarEditor extends StatefulWidget {
  const CalendarEditor({super.key});
  @override
  State<CalendarEditor> createState() => _CalendarEditorState();
}

class _CalendarEditorState extends State<CalendarEditor> {
  final service = FirestoreService();
  final month = TextEditingController();
  final day = TextEditingController();
  final title = TextEditingController();
  final msg = TextEditingController();
  @override
  void dispose() {
    for (final c in [month, day, title, msg]) c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => ExpansionTile(
    leading: const Icon(Icons.celebration),
    title: const I18nText('Celebration Calendar'),
    subtitle: const I18nText(
      'Built-in UK/Wales and fun dates are automatic. Add your own annual dates here.',
    ),
    children: [
      Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: day,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(label: I18nText('Day')),
                  ),
                ),
                const SizedBox(width: 7),
                Expanded(
                  child: TextField(
                    controller: month,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(label: I18nText('Month')),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 7),
            TextField(
              controller: title,
              decoration: const InputDecoration(label: I18nText('Title')),
            ),
            const SizedBox(height: 7),
            TextField(
              controller: msg,
              maxLines: 3,
              decoration: const InputDecoration(label: I18nText('Message')),
            ),
            const SizedBox(height: 7),
            FilledButton(
              onPressed: () async {
                final d = int.tryParse(day.text), m = int.tryParse(month.text);
                if (d != null && m != null && title.text.trim().isNotEmpty) {
                  await service.addCalendarEvent(
                    month: m,
                    day: d,
                    title: title.text,
                    message: msg.text,
                  );
                  day.clear();
                  month.clear();
                  title.clear();
                  msg.clear();
                }
              },
              child: const I18nText('ADD ANNUAL DATE'),
            ),
            StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: service.calendarEvents(),
              builder: (context, snap) => Column(
                children: (snap.data?.docs ?? [])
                    .map(
                      (d) => ListTile(
                        title: I18nText(
                          '${d.data()['day']}/${d.data()['month']} — ${d.data()['title']}',
                        ),
                        subtitle: Text((d.data()['message'] ?? '').toString()),
                        trailing: IconButton(
                          onPressed: () => service.deleteCalendarEvent(d.id),
                          icon: const Icon(Icons.delete_outline),
                        ),
                      ),
                    )
                    .toList(),
              ),
            ),
          ],
        ),
      ),
    ],
  );
}

class SavedRepliesEditor extends StatefulWidget {
  final AppUser profile;
  const SavedRepliesEditor({super.key, required this.profile});
  @override
  State<SavedRepliesEditor> createState() => _SavedRepliesEditorState();
}

class _SavedRepliesEditorState extends State<SavedRepliesEditor> {
  final service = FirestoreService();
  final title = TextEditingController();
  final text = TextEditingController();
  @override
  void dispose() {
    title.dispose();
    text.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => ExpansionTile(
    leading: const Icon(Icons.quickreply),
    title: const I18nText('Saved Trainer Replies'),
    subtitle: const I18nText(
      'Reusable starting points that trainers can edit before sending.',
    ),
    children: [
      Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            TextField(
              controller: title,
              decoration: const InputDecoration(label: I18nText('Short name')),
            ),
            const SizedBox(height: 7),
            TextField(
              controller: text,
              maxLines: 4,
              decoration: const InputDecoration(label: I18nText('Reply text')),
            ),
            const SizedBox(height: 7),
            FilledButton.icon(
              onPressed: () async {
                if (title.text.trim().isEmpty || text.text.trim().isEmpty)
                  return;
                await service.addSavedReply(
                  title: title.text,
                  text: text.text,
                  actor: widget.profile.name,
                );
                title.clear();
                text.clear();
              },
              icon: const Icon(Icons.add),
              label: const I18nText('ADD SAVED REPLY'),
            ),
            const Divider(),
            StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: service.savedReplies(),
              builder: (context, snap) => Column(
                children: (snap.data?.docs ?? [])
                    .map(
                      (d) => ListTile(
                        title: I18nText(d.data()['title'] ?? 'Reply'),
                        subtitle: I18nText(d.data()['text'] ?? ''),
                        trailing: IconButton(
                          onPressed: () => service.deleteSavedReply(d.id),
                          icon: const Icon(Icons.delete_outline),
                        ),
                      ),
                    )
                    .toList(),
              ),
            ),
          ],
        ),
      ),
    ],
  );
}

class AuditLogPanel extends StatelessWidget {
  AuditLogPanel({super.key});
  final service = FirestoreService();
  @override
  Widget build(BuildContext context) => ExpansionTile(
    leading: const Icon(Icons.history),
    title: const I18nText('Staff Audit Trail'),
    subtitle: const I18nText('Recent important account and Academy changes.'),
    children: [
      StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: service.auditLog(),
        builder: (context, snap) {
          final docs = [...(snap.data?.docs ?? [])]
            ..sort(
              (a, b) =>
                  (((b.data()['createdAt'] as Timestamp?)
                              ?.millisecondsSinceEpoch ??
                          0)
                      .compareTo(
                        (a.data()['createdAt'] as Timestamp?)
                                ?.millisecondsSinceEpoch ??
                            0,
                      )),
            );
          if (docs.isEmpty)
            return const ListTile(title: I18nText('No audit entries yet.'));
          return Column(
            children: docs.take(50).map((d) {
              final m = d.data();
              return ListTile(
                dense: true,
                title: I18nText(m['action'] ?? 'Change'),
                subtitle: I18nText(
                  '${m['actor'] ?? ''} • ${m['detail'] ?? ''}',
                ),
              );
            }).toList(),
          );
        },
      ),
    ],
  );
}

class FeatureEditor extends StatelessWidget {
  FeatureEditor({super.key});
  final service = FirestoreService();
  @override
  Widget build(BuildContext context) => ExpansionTile(
    leading: const Icon(Icons.toggle_on),
    title: const I18nText('Feature Switches'),
    children: [
      StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
        stream: service.featureSettings(),
        builder: (context, snap) {
          final m = snap.data?.data() ?? {};
          return Column(
            children: [
              SwitchListTile(
                title: const I18nText('Profile photo uploads'),
                subtitle: const I18nText(
                  'Requires Firebase Cloud Storage / Blaze plan. Leave OFF until storage is set up.',
                ),
                value: m['photoUploadsEnabled'] == true,
                onChanged: (v) =>
                    service.saveFeatureSettings({'photoUploadsEnabled': v}),
              ),
              SwitchListTile(
                title: const I18nText('Show Treasure Chest'),
                value: m['treasureChestEnabled'] != false,
                onChanged: (v) =>
                    service.saveFeatureSettings({'treasureChestEnabled': v}),
              ),
            ],
          );
        },
      ),
    ],
  );
}

class NoticeEditor extends StatefulWidget {
  final AppUser profile;
  const NoticeEditor({super.key, required this.profile});
  @override
  State<NoticeEditor> createState() => _NoticeEditorState();
}

class _NoticeEditorState extends State<NoticeEditor> {
  final service = FirestoreService();
  final functions = AdminFunctionsService();
  final titleEn = TextEditingController();
  final msgEn = TextEditingController();
  final titleCy = TextEditingController();
  final msgCy = TextEditingController();
  String priority = 'normal';
  bool translating = false;
  bool welshReviewed = false;

  @override
  void dispose() {
    for (final c in [titleEn, msgEn, titleCy, msgCy]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _translateToWelsh() async {
    if (titleEn.text.trim().isEmpty && msgEn.text.trim().isEmpty) return;
    setState(() {
      translating = true;
      welshReviewed = false;
    });
    try {
      final translated = await Future.wait([
        functions.translateAdminText(
          text: titleEn.text,
          sourceLanguage: 'en',
          targetLanguage: 'cy',
        ),
        functions.translateAdminText(
          text: msgEn.text,
          sourceLanguage: 'en',
          targetLanguage: 'cy',
        ),
      ]);
      titleCy.text = translated[0];
      msgCy.text = translated[1];
      if (mounted)
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: I18nText('Auto translated — please review')),
        );
    } catch (_) {
      if (mounted)
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: I18nText(
              'Automatic translation is not ready yet. Deploy the V1.4 Firebase Functions and enable Cloud Translation, or type the Welsh version manually.',
            ),
          ),
        );
    } finally {
      if (mounted) setState(() => translating = false);
    }
  }

  Future<void> _translateToEnglish() async {
    if (titleCy.text.trim().isEmpty && msgCy.text.trim().isEmpty) return;
    setState(() => translating = true);
    try {
      final translated = await Future.wait([
        functions.translateAdminText(
          text: titleCy.text,
          sourceLanguage: 'cy',
          targetLanguage: 'en',
        ),
        functions.translateAdminText(
          text: msgCy.text,
          sourceLanguage: 'cy',
          targetLanguage: 'en',
        ),
      ]);
      titleEn.text = translated[0];
      msgEn.text = translated[1];
    } catch (_) {
      if (mounted)
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: I18nText(
              'Automatic translation is not ready yet. You can still type both versions manually.',
            ),
          ),
        );
    } finally {
      if (mounted) setState(() => translating = false);
    }
  }

  Future<void> _preview() async {
    await showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const I18nText('Preview notice'),
        content: SizedBox(
          width: 560,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const I18nText(
                'English',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              Text(
                titleEn.text.isEmpty ? '—' : titleEn.text,
                style: Theme.of(context).textTheme.titleMedium,
              ),
              Text(msgEn.text.isEmpty ? '—' : msgEn.text),
              const Divider(height: 28),
              const I18nText(
                'Welsh',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              Text(
                titleCy.text.isEmpty ? titleEn.text : titleCy.text,
                style: Theme.of(context).textTheme.titleMedium,
              ),
              Text(msgCy.text.isEmpty ? msgEn.text : msgCy.text),
            ],
          ),
        ),
        actions: [
          FilledButton(
            onPressed: () => Navigator.pop(ctx),
            child: const I18nText('Done'),
          ),
        ],
      ),
    );
  }

  Future<void> _publish() async {
    if (titleEn.text.trim().isEmpty || msgEn.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: I18nText(
            'Please add an English title and message before publishing.',
          ),
        ),
      );
      return;
    }
    await service.addNotice(
      titleEn: titleEn.text,
      messageEn: msgEn.text,
      titleCy: titleCy.text,
      messageCy: msgCy.text,
      priority: priority,
      actor: widget.profile.name,
      welshReviewed: welshReviewed,
    );
    titleEn.clear();
    msgEn.clear();
    titleCy.clear();
    msgCy.clear();
    if (mounted)
      setState(() {
        priority = 'normal';
        welshReviewed = false;
      });
    if (mounted)
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: I18nText('Notice published in English and Welsh.'),
        ),
      );
  }

  @override
  Widget build(BuildContext context) => ExpansionTile(
    leading: const Icon(Icons.campaign),
    title: const I18nText('Captain Notices'),
    subtitle: const I18nText(
      'Write in English, auto-translate to Welsh, tweak it, preview both, then publish.',
    ),
    children: [
      Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const I18nText(
              'English',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            TextField(
              controller: titleEn,
              onChanged: (_) => setState(() => welshReviewed = false),
              decoration: const InputDecoration(
                label: I18nText('Notice title'),
              ),
            ),
            const SizedBox(height: 7),
            TextField(
              controller: msgEn,
              onChanged: (_) => setState(() => welshReviewed = false),
              maxLines: 3,
              decoration: const InputDecoration(label: I18nText('Message')),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                FilledButton.tonalIcon(
                  onPressed: translating ? null : _translateToWelsh,
                  icon: const Icon(Icons.translate),
                  label: I18nText(
                    translating ? 'Translating...' : 'Translate to Welsh',
                  ),
                ),
                OutlinedButton.icon(
                  onPressed: _preview,
                  icon: const Icon(Icons.preview),
                  label: const I18nText('Preview notice'),
                ),
              ],
            ),
            const Divider(height: 28),
            Row(
              children: [
                const Expanded(
                  child: I18nText(
                    'Welsh',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                if (titleCy.text.isNotEmpty || msgCy.text.isNotEmpty)
                  I18nText(
                    welshReviewed
                        ? '✅ Welsh checked'
                        : '🟡 Auto translated — please review',
                  ),
              ],
            ),
            TextField(
              controller: titleCy,
              onChanged: (_) => setState(() => welshReviewed = true),
              decoration: const InputDecoration(
                label: I18nText('Notice title'),
              ),
            ),
            const SizedBox(height: 7),
            TextField(
              controller: msgCy,
              onChanged: (_) => setState(() => welshReviewed = true),
              maxLines: 3,
              decoration: const InputDecoration(label: I18nText('Message')),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                OutlinedButton.icon(
                  onPressed: translating ? null : _translateToEnglish,
                  icon: const Icon(Icons.translate),
                  label: const I18nText('Translate to English'),
                ),
                FilterChip(
                  selected: welshReviewed,
                  onSelected: (v) => setState(() => welshReviewed = v),
                  label: const I18nText('Welsh checked'),
                ),
              ],
            ),
            const SizedBox(height: 10),
            DropdownButtonFormField<String>(
              initialValue: priority,
              items: ['normal', 'important']
                  .map(
                    (e) => DropdownMenuItem(
                      value: e,
                      child: I18nText(e.toUpperCase()),
                    ),
                  )
                  .toList(),
              onChanged: (v) => setState(() => priority = v ?? priority),
              decoration: const InputDecoration(label: I18nText('Priority')),
            ),
            const SizedBox(height: 10),
            FilledButton.icon(
              onPressed: _publish,
              icon: const Icon(Icons.publish),
              label: const I18nText('PUBLISH NOTICE'),
            ),
          ],
        ),
      ),
    ],
  );
}

class FeedbackAdmin extends StatelessWidget {
  FeedbackAdmin({super.key});
  final service = FirestoreService();
  @override
  Widget build(BuildContext context) => ExpansionTile(
    leading: const Icon(Icons.feedback),
    title: const I18nText('Learner Feedback Centre'),
    children: [
      StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: service.feedback(),
        builder: (context, snap) {
          final docs = [...(snap.data?.docs ?? [])]
            ..sort(
              (a, b) =>
                  ((b.data()['createdAt'] as Timestamp?)
                              ?.millisecondsSinceEpoch ??
                          0)
                      .compareTo(
                        (a.data()['createdAt'] as Timestamp?)
                                ?.millisecondsSinceEpoch ??
                            0,
                      ),
            );
          if (docs.isEmpty)
            return const ListTile(title: I18nText('No feedback yet.'));
          return Column(
            children: docs
                .map(
                  (d) => ListTile(
                    title: I18nText(
                      '${d.data()['type'] ?? 'Feedback'} — ${d.data()['name'] ?? ''}',
                    ),
                    subtitle: Text((d.data()['message'] ?? '').toString()),
                    trailing: DropdownButton<String>(
                      value: (d.data()['status'] ?? 'new').toString(),
                      items: ['new', 'reviewing', 'done']
                          .map(
                            (e) =>
                                DropdownMenuItem(value: e, child: I18nText(e)),
                          )
                          .toList(),
                      onChanged: (v) {
                        if (v != null) service.updateFeedbackStatus(d.id, v);
                      },
                    ),
                  ),
                )
                .toList(),
          );
        },
      ),
    ],
  );
}

class CaptainLogPanel extends StatefulWidget {
  final AppUser profile;
  const CaptainLogPanel({super.key, required this.profile});
  @override
  State<CaptainLogPanel> createState() => _CaptainLogPanelState();
}

class _CaptainLogPanelState extends State<CaptainLogPanel> {
  final service = FirestoreService();
  final c = TextEditingController();
  @override
  void dispose() {
    c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => ExpansionTile(
    leading: const Icon(Icons.menu_book),
    title: const I18nText('Captain’s Log'),
    children: [
      Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: c,
                decoration: const InputDecoration(
                  label: I18nText('Idea / action / follow-up'),
                ),
              ),
            ),
            const SizedBox(width: 7),
            IconButton.filled(
              onPressed: () {
                if (c.text.trim().isNotEmpty) {
                  service.addCaptainLog(
                    author: widget.profile.name,
                    text: c.text,
                  );
                  c.clear();
                }
              },
              icon: const Icon(Icons.add),
            ),
          ],
        ),
      ),
      StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: service.captainLog(),
        builder: (context, snap) {
          final docs = [...(snap.data?.docs ?? [])]
            ..sort(
              (a, b) =>
                  ((b.data()['createdAt'] as Timestamp?)
                              ?.millisecondsSinceEpoch ??
                          0)
                      .compareTo(
                        (a.data()['createdAt'] as Timestamp?)
                                ?.millisecondsSinceEpoch ??
                            0,
                      ),
            );
          return Column(
            children: docs
                .map(
                  (d) => CheckboxListTile(
                    value: d.data()['done'] == true,
                    title: Text((d.data()['text'] ?? '').toString()),
                    subtitle: Text((d.data()['author'] ?? '').toString()),
                    onChanged: (v) =>
                        service.toggleCaptainLog(d.id, v ?? false),
                  ),
                )
                .toList(),
          );
        },
      ),
    ],
  );
}

class SystemHealth extends StatelessWidget {
  SystemHealth({super.key});
  final service = FirestoreService();
  @override
  Widget build(BuildContext context) => ExpansionTile(
    leading: const Icon(Icons.health_and_safety),
    title: const I18nText('System Health'),
    children: [
      const ListTile(
        leading: Icon(Icons.check_circle, color: Colors.green),
        title: I18nText('Firebase connection'),
        subtitle: I18nText(
          'Connected — this screen is reading live Firestore data.',
        ),
      ),
      const ListTile(
        leading: Icon(Icons.info),
        title: I18nText('App version'),
        subtitle: I18nText('V1.4.0+10 • Android + Web'),
      ),
      StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
        stream: service.linkSettings(),
        builder: (context, snap) {
          final m = snap.data?.data() ?? {};
          final missing = [
            'facebook',
            'instagram',
            'tiktok',
            'easyfundraising',
            'gofundme',
          ].where((k) => (m[k] ?? '').toString().isEmpty).length;
          return ListTile(
            leading: Icon(
              missing == 0 ? Icons.check_circle : Icons.warning_amber,
            ),
            title: I18nText('$missing social/fundraising links still blank'),
          );
        },
      ),
      const ListTile(
        leading: Icon(Icons.cloud_outlined),
        title: I18nText('Push & photo note'),
        subtitle: I18nText(
          'In-app notifications work on the normal setup. True background push and Firebase photo storage use optional Firebase services described in the V1.4 setup guide.',
        ),
      ),
    ],
  );
}
