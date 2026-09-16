import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../../i18n.dart';

import 'package:url_launcher/url_launcher.dart';

import '../../course_data.dart';
import '../../models.dart';
import '../../services/firestore_service.dart';
import '../../widgets/language_toggle.dart';

class SupportScreen extends StatefulWidget {
  final AppUser profile;
  final DogProfile dog;
  const SupportScreen({super.key, required this.profile, required this.dog});
  @override
  State<SupportScreen> createState() => _SupportScreenState();
}

class _SupportScreenState extends State<SupportScreen> {
  int tab = 0;
  @override
  Widget build(BuildContext context) => ListView(
    padding: const EdgeInsets.all(16),
    children: [
      I18nText(
        'Training Support',
        style: Theme.of(context).textTheme.headlineSmall,
      ),
      const I18nText(
        'Ask for help, request paid 1-to-1 training or keep a quick diary.',
      ),
      const SizedBox(height: 10),
      SegmentedButton<int>(
        segments: const [
          ButtonSegment(
            value: 0,
            icon: Icon(Icons.chat),
            label: I18nText('Help'),
          ),
          ButtonSegment(
            value: 1,
            icon: Icon(Icons.event_available),
            label: I18nText('1-to-1'),
          ),
          ButtonSegment(
            value: 2,
            icon: Icon(Icons.menu_book),
            label: I18nText('Diary'),
          ),
        ],
        selected: {tab},
        onSelectionChanged: (s) => setState(() => tab = s.first),
      ),
      const SizedBox(height: 14),
      if (tab == 0) HelpPanel(profile: widget.profile, dog: widget.dog),
      if (tab == 1) OneToOnePanel(profile: widget.profile, dog: widget.dog),
      if (tab == 2)
        TrainingDiaryPanel(profile: widget.profile, dog: widget.dog),
    ],
  );
}

class HelpPanel extends StatefulWidget {
  final AppUser profile;
  final DogProfile dog;
  const HelpPanel({super.key, required this.profile, required this.dog});
  @override
  State<HelpPanel> createState() => _HelpPanelState();
}

class _HelpPanelState extends State<HelpPanel> {
  final service = FirestoreService();
  final question = TextEditingController();
  final video = TextEditingController();
  @override
  void dispose() {
    question.dispose();
    video.dispose();
    super.dispose();
  }

  Future<void> askGeneral() async {
    if (question.text.trim().isEmpty) return;
    await service.requestLessonHelp(
      uid: widget.profile.id,
      dogId: widget.dog.id,
      learnerName: widget.profile.name,
      dogName: widget.dog.name,
      moduleId: 'general',
      moduleTitle: 'General Training',
      lessonId: 'general',
      lessonTitle: 'General Question',
      message: question.text,
      videoUrl: video.text,
    );
    question.clear();
    video.clear();
    if (mounted)
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: I18nText('Question sent to the trainers.')),
      );
  }

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              I18nText(
                'Ask a General Question',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const I18nText(
                'For a question about a specific lesson, use Need Help directly under that video — it gives the trainer more context.',
              ),
              const SizedBox(height: 10),
              TextField(
                controller: question,
                maxLines: 4,
                decoration: const InputDecoration(
                  label: I18nText('What can we help with?'),
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: video,
                decoration: const InputDecoration(
                  label: I18nText('Optional video link'),
                ),
              ),
              const SizedBox(height: 8),
              FilledButton.icon(
                onPressed: askGeneral,
                icon: const Icon(Icons.send),
                label: const I18nText('SEND TO TRAINERS'),
              ),
            ],
          ),
        ),
      ),
      const SizedBox(height: 12),
      I18nText(
        'My Help Conversations',
        style: Theme.of(context).textTheme.titleLarge,
      ),
      StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: service.lessonHelpForUser(widget.profile.id),
        builder: (context, snap) {
          final docs = [...(snap.data?.docs ?? [])]
            ..sort(
              (a, b) =>
                  ((b.data()['updatedAt'] as Timestamp?)
                              ?.millisecondsSinceEpoch ??
                          0)
                      .compareTo(
                        (a.data()['updatedAt'] as Timestamp?)
                                ?.millisecondsSinceEpoch ??
                            0,
                      ),
            );
          if (docs.isEmpty)
            return const Card(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: I18nText('No training help conversations yet.'),
              ),
            );
          return Column(
            children: docs.map((d) {
              final m = d.data();
              if ((m['dogId'] ?? '') != widget.dog.id)
                return const SizedBox.shrink();
              return Card(
                child: ListTile(
                  leading: const Icon(Icons.forum),
                  title: I18nText(
                    '${m['moduleTitle'] ?? 'Training'} — ${m['lessonTitle'] ?? ''}',
                  ),
                  subtitle: I18nText(
                    (m['status'] ?? 'new')
                        .toString()
                        .replaceAll('_', ' ')
                        .toUpperCase(),
                  ),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => HelpThreadScreen(
                        profile: widget.profile,
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
      ),
    ],
  );
}

class HelpThreadScreen extends StatefulWidget {
  final AppUser profile;
  final String threadId;
  final Map<String, dynamic> thread;
  const HelpThreadScreen({
    super.key,
    required this.profile,
    required this.threadId,
    required this.thread,
  });
  @override
  State<HelpThreadScreen> createState() => _HelpThreadScreenState();
}

class _HelpThreadScreenState extends State<HelpThreadScreen> {
  final service = FirestoreService();
  final reply = TextEditingController();
  final scroll = ScrollController();
  bool sending = false;

  @override
  void dispose() {
    reply.dispose();
    scroll.dispose();
    super.dispose();
  }

  String _messageTime(Timestamp? timestamp) {
    if (timestamp == null) return '';
    final d = timestamp.toDate().toLocal();

    String two(int value) => value.toString().padLeft(2, '0');

    return '${two(d.day)}/${two(d.month)} '
        '${two(d.hour)}:${two(d.minute)}';
  }

  void _scrollToLatest() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!scroll.hasClients) return;

      scroll.animateTo(
        scroll.position.maxScrollExtent,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
      );
    });
  }

  Future<void> _send() async {
    final message = reply.text.trim();

    if (message.isEmpty || sending) return;

    setState(() => sending = true);

    try {
      await service.sendHelpMessage(
        threadId: widget.threadId,
        senderId: widget.profile.id,
        senderName: widget.profile.name,
        senderRole: 'learner',
        message: message,
      );

      if (!mounted) return;

      reply.clear();
      FocusScope.of(context).unfocus();
      setState(() {});

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: I18nText('Question sent to the trainers.')),
      );

      _scrollToLatest();
    } catch (_) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: I18nText('Message could not be sent. Please try again.'),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => sending = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: I18nText(widget.thread['lessonTitle'] ?? 'Training Help'),
      actions: [LanguageToggle(userId: widget.profile.id)],
    ),
    body: Column(
      children: [
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

              _scrollToLatest();

              return ListView(
                controller: scroll,
                padding: const EdgeInsets.all(12),
                children: docs.map((d) {
                  final m = d.data();
                  final mine = (m['senderRole'] ?? '') == 'learner';

                  final scheme = Theme.of(context).colorScheme;

                  final bubbleColour = mine
                      ? scheme.primary
                      : scheme.surfaceContainerHighest;

                  final textColour = mine ? scheme.onPrimary : scheme.onSurface;

                  final timestamp = m['createdAt'] as Timestamp?;

                  return Align(
                    alignment: mine
                        ? Alignment.centerRight
                        : Alignment.centerLeft,
                    child: Container(
                      margin: const EdgeInsets.symmetric(vertical: 5),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 10,
                      ),
                      constraints: const BoxConstraints(maxWidth: 520),
                      decoration: BoxDecoration(
                        color: bubbleColour,
                        borderRadius: BorderRadius.only(
                          topLeft: const Radius.circular(18),
                          topRight: const Radius.circular(18),
                          bottomLeft: Radius.circular(mine ? 18 : 4),
                          bottomRight: Radius.circular(mine ? 4 : 18),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            (m['senderName'] ?? '').toString(),
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: textColour,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            (m['message'] ?? '').toString(),
                            style: TextStyle(color: textColour),
                          ),
                          if ((m['videoUrl'] ?? '').toString().isNotEmpty)
                            TextButton.icon(
                              style: TextButton.styleFrom(
                                foregroundColor: textColour,
                              ),
                              onPressed: () async {
                                final u = Uri.tryParse(
                                  m['videoUrl'].toString(),
                                );

                                if (u != null) {
                                  await launchUrl(u);
                                }
                              },
                              icon: const Icon(Icons.play_circle),
                              label: const I18nText('Open video'),
                            ),
                          if (timestamp != null) ...[
                            const SizedBox(height: 3),
                            Align(
                              alignment: Alignment.centerRight,
                              child: Text(
                                _messageTime(timestamp),
                                style: TextStyle(
                                  fontSize: 11,
                                  color: textColour.withValues(alpha: 0.75),
                                ),
                              ),
                            ),
                          ],
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
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: reply,
                    enabled: !sending,
                    minLines: 1,
                    maxLines: 4,
                    textInputAction: TextInputAction.newline,
                    decoration: const InputDecoration(
                      label: I18nText('Reply to trainer'),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton.filled(
                  onPressed: sending ? null : _send,
                  icon: sending
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.send),
                ),
              ],
            ),
          ),
        ),
      ],
    ),
  );
}

class OneToOnePanel extends StatefulWidget {
  final AppUser profile;
  final DogProfile dog;
  const OneToOnePanel({super.key, required this.profile, required this.dog});
  @override
  State<OneToOnePanel> createState() => _OneToOnePanelState();
}

class _OneToOnePanelState extends State<OneToOnePanel> {
  final service = FirestoreService();
  final note = TextEditingController();
  final video = TextEditingController();
  String topic = 'General training';
  String trainer = 'No preference';
  String format = 'Either';
  String availability = 'Weekday evening';
  @override
  void dispose() {
    note.dispose();
    video.dispose();
    super.dispose();
  }

  Future<void> request() async {
    await service.requestOneToOne(
      uid: widget.profile.id,
      dogId: widget.dog.id,
      learnerName: widget.profile.name,
      dogName: widget.dog.name,
      topic: topic,
      preferredTrainer: trainer,
      format: format,
      availability: availability,
      note: note.text,
      videoUrl: video.text,
    );
    note.clear();
    video.clear();
    if (mounted)
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: I18nText('1-to-1 request sent.')));
  }

  @override
  Widget build(
    BuildContext context,
  ) => StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
    stream: service.academySettings(),
    builder: (context, academySnap) {
      final config = AcademyConfig.fromMap(academySnap.data?.data() ?? {});
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  I18nText(
                    'Request a 1-to-1',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  I18nText(config.oneToOneWording),
                  const SizedBox(height: 4),
                  I18nText(
                    'Typical guide: £${config.oneToOneGuidePrice.toStringAsFixed(2)} for ${config.oneToOneGuideMinutes} minutes. Your trainer will confirm the actual price and length before you accept.',
                  ),
                  const SizedBox(height: 10),
                  DropdownButtonFormField<String>(
                    initialValue: topic,
                    items:
                        [
                              'General training',
                              ...courseModules.map((m) => m.title),
                              'Confidence',
                              'Behaviour',
                              'Competition skills',
                              'Other',
                            ]
                            .map(
                              (e) => DropdownMenuItem(
                                value: e,
                                child: I18nText(e),
                              ),
                            )
                            .toList(),
                    onChanged: (v) => setState(() => topic = v ?? topic),
                    decoration: const InputDecoration(
                      label: I18nText('What would you like help with?'),
                    ),
                  ),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<String>(
                    initialValue: format,
                    items: ['In person', 'Online video call', 'Either']
                        .map(
                          (e) => DropdownMenuItem(value: e, child: I18nText(e)),
                        )
                        .toList(),
                    onChanged: (v) => setState(() => format = v ?? format),
                    decoration: const InputDecoration(
                      label: I18nText('Session type'),
                    ),
                  ),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<String>(
                    initialValue: availability,
                    items:
                        [
                              'Weekday daytime',
                              'Weekday evening',
                              'Saturday',
                              'Sunday',
                              'Flexible',
                            ]
                            .map(
                              (e) => DropdownMenuItem(
                                value: e,
                                child: I18nText(e),
                              ),
                            )
                            .toList(),
                    onChanged: (v) =>
                        setState(() => availability = v ?? availability),
                    decoration: const InputDecoration(
                      label: I18nText('General availability'),
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: note,
                    maxLines: 4,
                    decoration: const InputDecoration(
                      label: I18nText('Tell us what is happening'),
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: video,
                    decoration: const InputDecoration(
                      label: I18nText('Optional video link'),
                    ),
                  ),
                  const SizedBox(height: 8),
                  FilledButton.icon(
                    onPressed: request,
                    icon: const Icon(Icons.event_available),
                    label: const I18nText('REQUEST SESSION'),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          I18nText(
            'My 1-to-1 Requests',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
            stream: service.oneToOnesForUser(widget.profile.id),
            builder: (context, snap) {
              final docs = (snap.data?.docs ?? [])
                  .where((d) => d.data()['dogId'] == widget.dog.id)
                  .toList();
              if (docs.isEmpty)
                return const Card(
                  child: Padding(
                    padding: EdgeInsets.all(16),
                    child: I18nText('No requests for this dog yet.'),
                  ),
                );
              return Column(
                children: docs.map((d) {
                  final m = d.data();
                  final status = (m['status'] ?? 'requested').toString();
                  final meet = (m['meetUrl'] ?? '').toString();
                  final price = (m['quotedPrice'] as num?)?.toDouble();
                  final mins = (m['durationMinutes'] as num?)?.toInt();
                  return Card(
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          I18nText(
                            '${m['topic'] ?? '1-to-1'} — ${status.toUpperCase()}',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          if ((m['trainerName'] ?? '').toString().isNotEmpty)
                            I18nText('Trainer: ${m['trainerName']}'),
                          if ((m['proposedWhen'] ?? '').toString().isNotEmpty)
                            I18nText('When: ${m['proposedWhen']}'),
                          if (price != null)
                            I18nText(
                              'Quoted price: £${price.toStringAsFixed(2)}${mins == null ? '' : ' • $mins minutes'}',
                            ),
                          if ((m['homework'] ?? '').toString().isNotEmpty)
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const I18nText('Follow-up:'),
                                Text((m['homework'] ?? '').toString()),
                              ],
                            ),
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 8,
                            children: [
                              if (status == 'proposed')
                                FilledButton(
                                  onPressed: () =>
                                      service.learnerAcceptOneToOne(d.id),
                                  child: const I18nText('ACCEPT'),
                                ),
                              if (status == 'booked' && meet.isNotEmpty)
                                FilledButton.icon(
                                  onPressed: () async {
                                    final u = Uri.tryParse(meet);
                                    if (u != null) await launchUrl(u);
                                  },
                                  icon: const Icon(Icons.video_call),
                                  label: const I18nText('JOIN'),
                                ),
                              if (![
                                'completed',
                                'cancelled',
                                'declined',
                              ].contains(status))
                                OutlinedButton(
                                  onPressed: () =>
                                      service.learnerCancelOneToOne(d.id),
                                  child: const I18nText('Cancel'),
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
          ),
        ],
      );
    },
  );
}

class TrainingDiaryPanel extends StatefulWidget {
  final AppUser profile;
  final DogProfile dog;
  const TrainingDiaryPanel({
    super.key,
    required this.profile,
    required this.dog,
  });
  @override
  State<TrainingDiaryPanel> createState() => _TrainingDiaryPanelState();
}

class _TrainingDiaryPanelState extends State<TrainingDiaryPanel> {
  final service = FirestoreService();
  final note = TextEditingController();

  String skill = 'General';
  String result = 'Good';
  int minutes = 5;

  bool logging = false;
  bool showAll = false;

  @override
  void dispose() {
    note.dispose();
    super.dispose();
  }

  String _date(Timestamp? value) {
    if (value == null) return '';

    final d = value.toDate().toLocal();

    String two(int value) => value.toString().padLeft(2, '0');

    return '${two(d.day)}/${two(d.month)}/${d.year} '
        '${two(d.hour)}:${two(d.minute)}';
  }

  Future<void> _logTraining() async {
    if (logging) return;

    setState(() => logging = true);

    try {
      await service.addTrainingLog(
        uid: widget.profile.id,
        dogId: widget.dog.id,
        skill: skill,
        result: result,
        note: note.text,
        minutes: minutes,
      );

      if (!mounted) return;

      note.clear();
      FocusScope.of(context).unfocus();

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: I18nText('Training logged.')));
    } catch (_) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: I18nText('Training could not be saved. Please try again.'),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => logging = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final skills = ['General', ...courseModules.map((m) => m.title)];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        DropdownButtonFormField<String>(
          initialValue: skill,
          items: skills
              .map((e) => DropdownMenuItem(value: e, child: I18nText(e)))
              .toList(),
          onChanged: logging ? null : (v) => setState(() => skill = v ?? skill),
          decoration: const InputDecoration(
            label: I18nText('What did you practise?'),
          ),
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          initialValue: result,
          items: [
            'Struggled',
            'Getting there',
            'Good',
            'Nailed it!',
          ].map((e) => DropdownMenuItem(value: e, child: I18nText(e))).toList(),
          onChanged: logging
              ? null
              : (v) => setState(() => result = v ?? result),
          decoration: const InputDecoration(label: I18nText('How did it go?')),
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<int>(
          initialValue: minutes,
          items: [1, 2, 3, 5, 10]
              .map(
                (e) =>
                    DropdownMenuItem(value: e, child: I18nText('$e minutes')),
              )
              .toList(),
          onChanged: logging
              ? null
              : (v) => setState(() => minutes = v ?? minutes),
          decoration: const InputDecoration(label: I18nText('Session length')),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: note,
          enabled: !logging,
          maxLines: 3,
          decoration: const InputDecoration(label: I18nText('Optional note')),
        ),
        const SizedBox(height: 8),
        FilledButton.icon(
          onPressed: logging ? null : _logTraining,
          icon: logging
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.add),
          label: I18nText(logging ? 'SAVING...' : 'LOG TRAINING'),
        ),

        const SizedBox(height: 22),
        const Divider(),
        const SizedBox(height: 8),

        Row(
          children: [
            const Icon(Icons.history),
            const SizedBox(width: 8),
            Expanded(
              child: I18nText(
                'Diary',
                style: Theme.of(context).textTheme.titleLarge,
              ),
            ),
          ],
        ),

        const SizedBox(height: 8),

        StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
          stream: service.trainingLogsForDog(widget.dog.id),
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

            if (docs.isEmpty) {
              return const Card(
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: I18nText('No training diary entries yet.'),
                ),
              );
            }

            final visible = showAll ? docs : docs.take(10).toList();

            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                I18nText(
                  '${docs.length} saved training '
                  '${docs.length == 1 ? 'session' : 'sessions'}',
                ),
                const SizedBox(height: 6),

                ...visible.map((d) {
                  final m = d.data();
                  final createdAt = m['createdAt'] as Timestamp?;
                  final noteText = (m['note'] ?? '').toString();

                  return Card(
                    child: ListTile(
                      leading: const Icon(Icons.menu_book),
                      title: I18nText('${m['skill']} — ${m['result']}'),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          I18nText(
                            '${m['minutes'] ?? 0} min'
                            '${createdAt == null ? '' : ' • ${_date(createdAt)}'}',
                          ),
                          if (noteText.isNotEmpty) Text(noteText),
                        ],
                      ),
                    ),
                  );
                }),

                if (docs.length > 10)
                  Align(
                    alignment: Alignment.center,
                    child: TextButton.icon(
                      onPressed: () {
                        setState(() => showAll = !showAll);
                      },
                      icon: Icon(
                        showAll ? Icons.expand_less : Icons.expand_more,
                      ),
                      label: I18nText(
                        showAll ? 'SHOW RECENT' : 'VIEW ALL TRAINING HISTORY',
                      ),
                    ),
                  ),
              ],
            );
          },
        ),
      ],
    );
  }
}
