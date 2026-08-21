import 'package:audioplayers/audioplayers.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:confetti/confetti.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:youtube_player_iframe/youtube_player_iframe.dart';
import '../course_data.dart';
import '../models.dart';
import '../services/firestore_service.dart';

class LearnerShell extends StatefulWidget {
  final AppUser profile;
  const LearnerShell({super.key, required this.profile});

  @override
  State<LearnerShell> createState() => _LearnerShellState();
}

class _LearnerShellState extends State<LearnerShell> {
  int index = 0;
  final service = FirestoreService();
  String? _dailyRecordedDogId;
  bool _showingTrophy = false;
  final Set<String> _shownThisSession = {};

  void _recordDaily(DogProfile dog) {
    if (_dailyRecordedDogId == dog.id) return;
    _dailyRecordedDogId = dog.id;
    Future.microtask(() => service.recordDailyLoginAndAwards(
          uid: widget.profile.id,
          dogId: dog.id,
          dogName: dog.name,
          dateOfBirth: dog.dateOfBirth,
        ));
  }

  void _maybeShowPendingTrophy(DogProfile dog, List<QueryDocumentSnapshot<Map<String, dynamic>>> docs) {
    if (_showingTrophy) return;
    QueryDocumentSnapshot<Map<String, dynamic>>? pending;
    for (final d in docs) {
      if (d.data()['accepted'] != true && !_shownThisSession.contains(d.id)) {
        pending = d;
        break;
      }
    }
    if (pending == null) return;
    _showingTrophy = true;
    _shownThisSession.add(pending.id);
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      await showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (_) => TrophyCelebrationDialog(
          dog: dog,
          trophyId: pending!.id,
          trophy: pending.data(),
          soundEnabled: widget.profile.celebrationSound,
        ),
      );
      if (mounted) setState(() => _showingTrophy = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: service.dogsForOwner(widget.profile.id),
      builder: (context, dogSnap) {
        if (!dogSnap.hasData) return const Scaffold(body: Center(child: CircularProgressIndicator()));
        if (dogSnap.data!.docs.isEmpty) return const Scaffold(body: Center(child: Text('No dog profile found. Please contact the Captain.')));
        final dog = DogProfile.fromDoc(dogSnap.data!.docs.first);
        _recordDaily(dog);
        final pages = [
          LearnerHome(profile: widget.profile, dog: dog),
          CourseScreen(profile: widget.profile, dog: dog),
          TrophyCabinet(dog: dog),
          SupportScreen(profile: widget.profile, dog: dog),
          TreasureChestScreen(profile: widget.profile),
          LearnerProfile(profile: widget.profile, dog: dog),
        ];
        const destinations = [
          NavigationDestination(icon: Icon(Icons.home_outlined), selectedIcon: Icon(Icons.home), label: 'Home'),
          NavigationDestination(icon: Icon(Icons.school_outlined), selectedIcon: Icon(Icons.school), label: 'Course'),
          NavigationDestination(icon: Icon(Icons.emoji_events_outlined), selectedIcon: Icon(Icons.emoji_events), label: 'Trophies'),
          NavigationDestination(icon: Icon(Icons.support_agent_outlined), selectedIcon: Icon(Icons.support_agent), label: 'Help'),
          NavigationDestination(icon: Icon(Icons.inventory_2_outlined), selectedIcon: Icon(Icons.inventory_2), label: 'Treasure'),
          NavigationDestination(icon: Icon(Icons.pets_outlined), selectedIcon: Icon(Icons.pets), label: 'My Dog'),
        ];
        return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
          stream: service.trophiesForDog(dog.id),
          builder: (context, trophySnap) {
            if (trophySnap.hasData) _maybeShowPendingTrophy(dog, trophySnap.data!.docs);
            return Scaffold(
              appBar: AppBar(
                title: const Text('Menai Muttineers Academy'),
                actions: [IconButton(onPressed: () => FirebaseAuth.instance.signOut(), tooltip: 'Sign out', icon: const Icon(Icons.logout))],
              ),
              body: pages[index],
              bottomNavigationBar: NavigationBar(
                selectedIndex: index,
                labelBehavior: NavigationDestinationLabelBehavior.onlyShowSelected,
                onDestinationSelected: (v) => setState(() => index = v),
                destinations: destinations,
              ),
            );
          },
        );
      },
    );
  }
}

class TrophyCelebrationDialog extends StatefulWidget {
  final DogProfile dog;
  final String trophyId;
  final Map<String, dynamic> trophy;
  final bool soundEnabled;

  const TrophyCelebrationDialog({
    super.key,
    required this.dog,
    required this.trophyId,
    required this.trophy,
    required this.soundEnabled,
  });

  @override
  State<TrophyCelebrationDialog> createState() => _TrophyCelebrationDialogState();
}

class _TrophyCelebrationDialogState extends State<TrophyCelebrationDialog> {
  final service = FirestoreService();
  final confetti = ConfettiController(duration: const Duration(seconds: 2));
  final player = AudioPlayer();
  bool accepting = false;
  bool accepted = false;

  @override
  void dispose() {
    confetti.dispose();
    player.dispose();
    super.dispose();
  }

  Future<void> accept() async {
    if (accepting || accepted) return;
    setState(() => accepting = true);
    await service.acceptTrophy(widget.dog.id, widget.trophyId);
    if (widget.soundEnabled) {
      try {
        await player.play(AssetSource('sounds/trophy_chime.wav'));
      } catch (_) {}
    }
    confetti.play();
    if (mounted) setState(() { accepting = false; accepted = true; });
    await Future.delayed(const Duration(milliseconds: 1800));
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final title = (widget.trophy['title'] ?? 'New Trophy').toString();
    final description = (widget.trophy['description'] ?? '').toString();
    final artKey = (widget.trophy['artKey'] ?? 'firstskill').toString();
    return Dialog(
      child: Stack(
        alignment: Alignment.topCenter,
        children: [
          Padding(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 440),
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                Text(accepted ? 'TROPHY ACCEPTED!' : 'TROPHY UNLOCKED!', style: Theme.of(context).textTheme.headlineSmall, textAlign: TextAlign.center),
                const SizedBox(height: 12),
                TrophyArt(artKey: artKey, locked: false, size: 150),
                const SizedBox(height: 12),
                Text(title, style: Theme.of(context).textTheme.titleLarge, textAlign: TextAlign.center),
                const SizedBox(height: 6),
                Text('Well done, ${widget.dog.name}!', style: const TextStyle(fontWeight: FontWeight.bold)),
                if (description.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Text(description, textAlign: TextAlign.center),
                ],
                const SizedBox(height: 18),
                if (!accepted) ...[
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed: accepting ? null : accept,
                      icon: const Icon(Icons.celebration),
                      label: Text(accepting ? 'Opening...' : 'Accept Trophy'),
                    ),
                  ),
                  TextButton(onPressed: () => Navigator.pop(context), child: const Text('Open it later')),
                ] else
                  const Padding(
                    padding: EdgeInsets.all(8),
                    child: Text('Into the Trophy Cabinet it goes! 🏴‍☠️', textAlign: TextAlign.center),
                  ),
              ]),
            ),
          ),
          IgnorePointer(
            child: ConfettiWidget(
              confettiController: confetti,
              blastDirectionality: BlastDirectionality.explosive,
              emissionFrequency: 0.08,
              numberOfParticles: 28,
              gravity: 0.18,
              shouldLoop: false,
            ),
          ),
        ],
      ),
    );
  }
}

class LearnerHome extends StatelessWidget {
  final AppUser profile;
  final DogProfile dog;
  LearnerHome({super.key, required this.profile, required this.dog});
  final service = FirestoreService();

  Future<void> _launch(String value) async {
    final uri = Uri.tryParse(value);
    if (uri != null) await launchUrl(uri, mode: LaunchMode.platformDefault);
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 900),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            Text('Ahoy ${profile.name} & ${dog.name}!', style: Theme.of(context).textTheme.headlineSmall),
            const Text('Pre-Flyball Skills — learn, practise, then go for assessment when you are ready.'),
            const SizedBox(height: 12),
            StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: service.trophiesForDog(dog.id),
              builder: (context, snap) {
                final docs = snap.data?.docs ?? [];
                final skillCount = docs.where((d) => courseModules.any((m) => m.id == d.id)).length;
                final progress = (skillCount / courseModules.length).clamp(0.0, 1.0);
                final unopened = docs.where((d) => d.data()['accepted'] != true).length;
                return Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text('Course progress', style: Theme.of(context).textTheme.titleMedium),
                      const SizedBox(height: 8),
                      LinearProgressIndicator(value: progress),
                      const SizedBox(height: 6),
                      Text('$skillCount of ${courseModules.length} key skills trainer verified'),
                      Text('Login streak: ${profile.loginStreak} day${profile.loginStreak == 1 ? '' : 's'}'),
                      if (unopened > 0) Text('$unopened new troph${unopened == 1 ? 'y' : 'ies'} waiting to be opened!', style: const TextStyle(fontWeight: FontWeight.bold)),
                      if (skillCount >= courseModules.length) ...[
                        const SizedBox(height: 10),
                        const ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: Icon(Icons.emoji_events, size: 38),
                          title: Text('READY TO JOIN THE CREW', style: TextStyle(fontWeight: FontWeight.bold)),
                          subtitle: Text('All required Pre-Flyball skills have been trainer verified.'),
                        ),
                      ],
                    ]),
                  ),
                );
              },
            ),
            StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: service.notices(),
              builder: (context, snap) {
                final docs = snap.data?.docs ?? [];
                if (docs.isEmpty) return const SizedBox.shrink();
                docs.sort((a, b) {
                  final at = (a.data()['createdAt'] as Timestamp?)?.millisecondsSinceEpoch ?? 0;
                  final bt = (b.data()['createdAt'] as Timestamp?)?.millisecondsSinceEpoch ?? 0;
                  return bt.compareTo(at);
                });
                return Column(children: docs.take(3).map((d) {
                  final m = d.data();
                  final important = m['priority'] == 'important';
                  return Card(
                    child: ListTile(
                      leading: Icon(important ? Icons.campaign : Icons.info_outline),
                      title: Text(m['title'] ?? 'Notice', style: const TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: Text(m['message'] ?? ''),
                    ),
                  );
                }).toList());
              },
            ),
            StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
              stream: service.settings(),
              builder: (context, snap) {
                final data = snap.data?.data() ?? {};
                final welcome = data['welcomeMessage'] ?? 'Welcome aboard! Work through the skills at your dog’s pace and ask for help whenever you need it.';
                final when = data['meetWhen'] ?? '';
                final topic = data['meetTopic'] ?? '';
                final url = data['meetUrl'] ?? '';
                return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                  Card(child: Padding(padding: const EdgeInsets.all(16), child: Text(welcome))),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text('Weekly Crew Catch-Up', style: Theme.of(context).textTheme.titleMedium),
                        if (when.toString().isNotEmpty) Text(when),
                        if (topic.toString().isNotEmpty) Text('Topic: $topic'),
                        const SizedBox(height: 10),
                        FilledButton.icon(
                          onPressed: url.toString().isEmpty ? null : () => _launch(url.toString()),
                          icon: const Icon(Icons.video_call),
                          label: const Text('Join Google Meet'),
                        ),
                      ]),
                    ),
                  ),
                ]);
              },
            ),
          ]),
        ),
      ),
    );
  }
}

class CourseScreen extends StatelessWidget {
  final AppUser profile;
  final DogProfile dog;
  CourseScreen({super.key, required this.profile, required this.dog});
  final service = FirestoreService();

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text('${dog.name}’s Training Journey', style: Theme.of(context).textTheme.headlineSmall),
        const SizedBox(height: 4),
        const Text('Choose a Key Skill. Each one has 5–9 short video lessons. Practise every lesson before the assessment unlocks.'),
        const SizedBox(height: 10),
        ...courseModules.map((module) => SkillModuleCard(profile: profile, dog: dog, module: module)),
      ],
    );
  }
}

class SkillModuleCard extends StatelessWidget {
  final AppUser profile;
  final DogProfile dog;
  final CourseModule module;
  SkillModuleCard({super.key, required this.profile, required this.dog, required this.module});
  final service = FirestoreService();

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: service.skillProgress(dog.id, module.id),
      builder: (context, progressSnap) {
        final data = progressSnap.data?.data() ?? {};
        final lessons = Map<String, dynamic>.from(data['lessons'] as Map? ?? {});
        final done = module.lessons.where((l) => lessons[l.id] == 'practised' || lessons[l.id] == 'confident').length;
        return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
          stream: service.trophiesForDog(dog.id),
          builder: (context, trophySnap) {
            final passed = (trophySnap.data?.docs ?? []).any((d) => d.id == module.id);
            return Card(
              child: ListTile(
                leading: TrophyArt(artKey: module.artKey, locked: !passed, size: 54),
                title: Text(module.title),
                subtitle: Text(passed ? 'Trainer verified • Trophy earned' : '$done of ${module.lessons.length} lessons practised'),
                trailing: Icon(passed ? Icons.verified : Icons.chevron_right),
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => ModuleScreen(profile: profile, dog: dog, module: module))),
              ),
            );
          },
        );
      },
    );
  }
}

class ModuleScreen extends StatefulWidget {
  final AppUser profile;
  final DogProfile dog;
  final CourseModule module;
  const ModuleScreen({super.key, required this.profile, required this.dog, required this.module});

  @override
  State<ModuleScreen> createState() => _ModuleScreenState();
}

class _ModuleScreenState extends State<ModuleScreen> {
  final service = FirestoreService();
  final video = TextEditingController();
  final note = TextEditingController();
  bool busy = false;

  Future<void> submit() async {
    if (video.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please add your assessment video link first.')));
      return;
    }
    setState(() => busy = true);
    await service.submitVideo(
      uid: widget.profile.id,
      dogId: widget.dog.id,
      module: widget.module,
      videoUrl: video.text,
      note: note.text,
      learnerName: widget.profile.name,
      dogName: widget.dog.name,
    );
    if (mounted) {
      video.clear();
      note.clear();
      setState(() => busy = false);
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Assessment sent to the trainers for review.')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.module.title)),
      body: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
        stream: service.skillProgress(widget.dog.id, widget.module.id),
        builder: (context, progressSnap) {
          final progressData = progressSnap.data?.data() ?? {};
          final lessonStates = Map<String, dynamic>.from(progressData['lessons'] as Map? ?? {});
          final completed = widget.module.lessons.where((l) => lessonStates[l.id] == 'practised' || lessonStates[l.id] == 'confident').length;
          final unlocked = completed == widget.module.lessons.length;
          return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
            stream: service.moduleSettings(widget.module.id),
            builder: (context, settingsSnap) {
              final settings = settingsSnap.data?.data() ?? {};
              final lessonVideos = Map<String, dynamic>.from(settings['lessonVideos'] as Map? ?? {});
              final oldVideo = (settings['videoUrl'] ?? '').toString();
              return ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  Center(child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 900),
                    child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                      Text(widget.module.stage, style: Theme.of(context).textTheme.labelLarge),
                      Text(widget.module.summary, style: Theme.of(context).textTheme.titleMedium),
                      const SizedBox(height: 12),
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                            Row(children: [
                              Expanded(child: Text('Lesson progress', style: Theme.of(context).textTheme.titleMedium)),
                              Text('$completed / ${widget.module.lessons.length}'),
                            ]),
                            const SizedBox(height: 8),
                            LinearProgressIndicator(value: completed / widget.module.lessons.length),
                            const SizedBox(height: 6),
                            const Text('A lesson counts as complete once you mark it Practised or Confident.'),
                          ]),
                        ),
                      ),
                      const SizedBox(height: 8),
                      ...widget.module.lessons.asMap().entries.map((entry) {
                        final i = entry.key;
                        final lesson = entry.value;
                        final url = (lessonVideos[lesson.id] ?? (i == 0 ? oldVideo : '')).toString();
                        final status = (lessonStates[lesson.id] ?? 'not_started').toString();
                        return LessonCard(
                          number: i + 1,
                          lesson: lesson,
                          videoUrl: url,
                          status: status,
                          onStatus: (value) => service.setLessonStatus(
                            dogId: widget.dog.id,
                            moduleId: widget.module.id,
                            lessonId: lesson.id,
                            status: value,
                          ),
                        );
                      }),
                      const SizedBox(height: 12),
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                            Row(children: [
                              Icon(unlocked ? Icons.lock_open : Icons.lock_outline),
                              const SizedBox(width: 8),
                              Expanded(child: Text(unlocked ? 'Assessment Unlocked' : 'Assessment Locked', style: Theme.of(context).textTheme.titleLarge)),
                            ]),
                            const SizedBox(height: 6),
                            Text(unlocked ? widget.module.assessmentText : 'Practise all ${widget.module.lessons.length} lessons first. You have completed $completed.'),
                            if (unlocked) ...[
                              const SizedBox(height: 12),
                              _AssessmentPanel(
                                profile: widget.profile,
                                dog: widget.dog,
                                module: widget.module,
                                video: video,
                                note: note,
                                busy: busy,
                                onSubmit: submit,
                              ),
                            ],
                          ]),
                        ),
                      ),
                    ]),
                  )),
                ],
              );
            },
          );
        },
      ),
    );
  }
}

class LessonCard extends StatelessWidget {
  final int number;
  final LessonDefinition lesson;
  final String videoUrl;
  final String status;
  final Future<void> Function(String) onStatus;

  const LessonCard({
    super.key,
    required this.number,
    required this.lesson,
    required this.videoUrl,
    required this.status,
    required this.onStatus,
  });

  @override
  Widget build(BuildContext context) {
    final done = status == 'practised' || status == 'confident';
    return Card(
      child: ExpansionTile(
        leading: CircleAvatar(child: done ? const Icon(Icons.check) : Text('$number')),
        title: Text(lesson.title),
        subtitle: Text(done ? 'Completed • ${_statusLabel(status)}' : _statusLabel(status)),
        childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        children: [
          Align(alignment: Alignment.centerLeft, child: Text(lesson.summary)),
          const SizedBox(height: 10),
          if (videoUrl.isEmpty)
            const Card(child: Padding(padding: EdgeInsets.all(12), child: Text('Video coming soon — the Captain/Admin still needs to add this lesson link.')))
          else
            LessonVideo(url: videoUrl),
          const SizedBox(height: 10),
          const Align(alignment: Alignment.centerLeft, child: Text('How are you getting on?', style: TextStyle(fontWeight: FontWeight.bold))),
          const SizedBox(height: 8),
          Wrap(spacing: 8, runSpacing: 8, children: [
            ChoiceChip(label: const Text('Watched'), selected: status == 'watched', onSelected: videoUrl.isEmpty ? null : (_) => onStatus('watched')),
            ChoiceChip(label: const Text('Practised'), selected: status == 'practised', onSelected: videoUrl.isEmpty ? null : (_) => onStatus('practised')),
            ChoiceChip(label: const Text('Confident'), selected: status == 'confident', onSelected: videoUrl.isEmpty ? null : (_) => onStatus('confident')),
            ChoiceChip(label: const Text('Need Help'), selected: status == 'need_help', onSelected: (_) => onStatus('need_help')),
          ]),
        ],
      ),
    );
  }

  static String _statusLabel(String value) {
    switch (value) {
      case 'watched': return 'Watched — ready to practise';
      case 'practised': return 'Practised';
      case 'confident': return 'Feeling confident';
      case 'need_help': return 'Help requested / needed';
      default: return 'Not started';
    }
  }
}

class _AssessmentPanel extends StatelessWidget {
  final AppUser profile;
  final DogProfile dog;
  final CourseModule module;
  final TextEditingController video;
  final TextEditingController note;
  final bool busy;
  final Future<void> Function() onSubmit;

  const _AssessmentPanel({
    required this.profile,
    required this.dog,
    required this.module,
    required this.video,
    required this.note,
    required this.busy,
    required this.onSubmit,
  });

  @override
  Widget build(BuildContext context) {
    final service = FirestoreService();
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: service.submissionsForUser(profile.id),
      builder: (context, snap) {
        final docs = (snap.data?.docs ?? []).where((d) => d.data()['moduleId'] == module.id).toList();
        docs.sort((a, b) {
          final at = (a.data()['submittedAt'] as Timestamp?)?.millisecondsSinceEpoch ?? 0;
          final bt = (b.data()['submittedAt'] as Timestamp?)?.millisecondsSinceEpoch ?? 0;
          return bt.compareTo(at);
        });
        final latest = docs.isEmpty ? null : docs.first.data();
        final status = (latest?['status'] ?? '').toString();
        final waiting = status == 'waiting';
        return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          if (latest != null)
            Card(
              child: ListTile(
                leading: Icon(status == 'passed' ? Icons.emoji_events : status == 'practise' ? Icons.build : Icons.hourglass_top),
                title: Text(status == 'passed' ? 'Passed — trophy awarded!' : status == 'practise' ? 'Keep practising, then submit again' : 'Assessment awaiting trainer review'),
                subtitle: (latest['feedback'] ?? '').toString().isEmpty ? null : Text(latest['feedback']),
              ),
            ),
          if (status != 'passed') ...[
            TextField(controller: video, enabled: !waiting, decoration: const InputDecoration(labelText: 'Assessment video — YouTube or Google Drive link')),
            const SizedBox(height: 8),
            TextField(controller: note, enabled: !waiting, maxLines: 3, decoration: const InputDecoration(labelText: 'Message for the trainer (optional)')),
            const SizedBox(height: 10),
            FilledButton.icon(
              onPressed: waiting || busy ? null : onSubmit,
              icon: const Icon(Icons.send),
              label: Text(waiting ? 'Awaiting review' : busy ? 'Sending...' : 'Request Assessment'),
            ),
          ],
        ]);
      },
    );
  }
}

class LessonVideo extends StatefulWidget {
  final String url;
  const LessonVideo({super.key, required this.url});

  @override
  State<LessonVideo> createState() => _LessonVideoState();
}

class _LessonVideoState extends State<LessonVideo> {
  YoutubePlayerController? controller;

  @override
  void initState() {
    super.initState();
    final id = YoutubePlayerController.convertUrlToId(widget.url);
    if (id != null) {
      controller = YoutubePlayerController.fromVideoId(
        videoId: id,
        autoPlay: false,
        params: const YoutubePlayerParams(showFullscreenButton: true),
      );
    }
  }

  @override
  void dispose() {
    controller?.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (controller == null) {
      return Card(child: ListTile(leading: const Icon(Icons.video_library), title: const Text('Training video'), subtitle: Text(widget.url)));
    }
    return Card(
      clipBehavior: Clip.antiAlias,
      child: YoutubePlayer(controller: controller!, aspectRatio: 16 / 9),
    );
  }
}

class TrophyCabinet extends StatelessWidget {
  final DogProfile dog;
  TrophyCabinet({super.key, required this.dog});
  final service = FirestoreService();

  QueryDocumentSnapshot<Map<String, dynamic>>? _earnedFor(TrophyDefinition def, List<QueryDocumentSnapshot<Map<String, dynamic>>> docs) {
    if (def.id == 'birthday') {
      for (final d in docs) {
        if (d.id.startsWith('birthday_')) return d;
      }
      return null;
    }
    for (final d in docs) {
      if (d.id == def.id) return d;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: service.trophiesForDog(dog.id),
      builder: (context, snap) {
        final docs = snap.data?.docs ?? [];
        final categories = <String>['Skill Trophies', 'Milestone Trophies', 'Special Trophies'];
        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Text('${dog.name}’s Trophy Cabinet', style: Theme.of(context).textTheme.headlineSmall),
            const Text('Every cabinet slot is waiting from day one. Locked trophies stay in shadow until they are earned and accepted.'),
            const SizedBox(height: 12),
            ...categories.map((category) {
              final definitions = trophyCatalog.where((t) => t.category == category).toList();
              return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                Padding(
                  padding: const EdgeInsets.only(top: 10, bottom: 6),
                  child: Text(category, style: Theme.of(context).textTheme.titleLarge),
                ),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: definitions.map((def) {
                    final earnedDoc = _earnedFor(def, docs);
                    final data = earnedDoc?.data();
                    final revealed = earnedDoc != null && data?['accepted'] == true;
                    return SizedBox(
                      width: 180,
                      child: Card(
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Column(children: [
                            TrophyArt(artKey: def.artKey, locked: !revealed, size: 105),
                            const SizedBox(height: 8),
                            Text(revealed ? (data?['title'] ?? def.title).toString() : '???', textAlign: TextAlign.center, style: const TextStyle(fontWeight: FontWeight.bold)),
                            const SizedBox(height: 4),
                            Text(
                              revealed ? (data?['description'] ?? def.description).toString() : earnedDoc != null ? 'New trophy waiting to be opened!' : 'Keep training to discover this award.',
                              textAlign: TextAlign.center,
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          ]),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ]);
            }),
          ],
        );
      },
    );
  }
}

class TrophyArt extends StatelessWidget {
  final String artKey;
  final bool locked;
  final double size;
  const TrophyArt({super.key, required this.artKey, required this.locked, this.size = 100});

  IconData _symbol() {
    switch (artKey) {
      case 'focus': return Icons.visibility;
      case 'recall': return Icons.bolt;
      case 'tug': return Icons.link;
      case 'deadball': return Icons.sports_tennis;
      case 'target': return Icons.gps_fixed;
      case 'movement': return Icons.accessibility_new;
      case 'distractions': return Icons.shield_outlined;
      case 'ready': return Icons.sailing;
      case 'login': return Icons.login;
      case 'streak7': return Icons.local_fire_department;
      case 'streak14': return Icons.whatshot;
      case 'streak30': return Icons.calendar_month;
      case 'lesson': return Icons.play_lesson;
      case 'assessment': return Icons.video_camera_front;
      case 'firstskill': return Icons.star;
      case 'birthday': return Icons.cake;
      default: return Icons.pets;
    }
  }

  @override
  Widget build(BuildContext context) {
    final gold = locked ? Colors.grey.shade600 : const Color(0xFFD7A132);
    final detail = locked ? Colors.grey.shade500 : Theme.of(context).colorScheme.primary;
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Positioned(bottom: size * 0.06, child: Icon(Icons.emoji_events, size: size * 0.78, color: gold)),
          Positioned(top: size * 0.03, child: Container(
            width: size * 0.40,
            height: size * 0.40,
            decoration: BoxDecoration(shape: BoxShape.circle, color: locked ? Colors.grey.shade700 : Colors.white, border: Border.all(color: gold, width: 3)),
            child: Icon(locked ? Icons.question_mark : _symbol(), color: locked ? Colors.grey.shade400 : detail, size: size * 0.24),
          )),
        ],
      ),
    );
  }
}

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
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        SegmentedButton<int>(
          segments: const [
            ButtonSegment(value: 0, label: Text('Ask a Trainer'), icon: Icon(Icons.question_answer)),
            ButtonSegment(value: 1, label: Text('1-to-1'), icon: Icon(Icons.event_available)),
            ButtonSegment(value: 2, label: Text('Diary'), icon: Icon(Icons.menu_book)),
          ],
          selected: {tab},
          onSelectionChanged: (s) => setState(() => tab = s.first),
        ),
        const SizedBox(height: 12),
        if (tab == 0) AskTrainerPanel(profile: widget.profile, dog: widget.dog),
        if (tab == 1) OneToOnePanel(profile: widget.profile, dog: widget.dog),
        if (tab == 2) TrainingDiaryPanel(profile: widget.profile, dog: widget.dog),
      ],
    );
  }
}

class AskTrainerPanel extends StatefulWidget {
  final AppUser profile;
  final DogProfile dog;
  const AskTrainerPanel({super.key, required this.profile, required this.dog});

  @override
  State<AskTrainerPanel> createState() => _AskTrainerPanelState();
}

class _AskTrainerPanelState extends State<AskTrainerPanel> {
  final service = FirestoreService();
  final question = TextEditingController();
  final video = TextEditingController();
  String category = 'Recall';
  final categories = ['Recall', 'Focus', 'Toy/Tug', 'Dead Ball', 'Target', 'Confidence', 'Behaviour', 'Course question', 'Other'];

  Future<void> submit() async {
    if (question.text.trim().isEmpty) return;
    await service.askTrainer(
      uid: widget.profile.id,
      dogId: widget.dog.id,
      learnerName: widget.profile.name,
      dogName: widget.dog.name,
      category: category,
      question: question.text,
      videoUrl: video.text,
    );
    question.clear();
    video.clear();
    if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Question sent to the trainers.')));
  }

  @override
  Widget build(BuildContext context) {
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      Text('Ask a Trainer', style: Theme.of(context).textTheme.headlineSmall),
      const Text('Keep course questions and feedback in one place.'),
      const SizedBox(height: 10),
      DropdownButtonFormField<String>(initialValue: category, items: categories.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(), onChanged: (v) => setState(() => category = v ?? category), decoration: const InputDecoration(labelText: 'Topic')),
      const SizedBox(height: 8),
      TextField(controller: question, maxLines: 4, decoration: const InputDecoration(labelText: 'Your question')),
      const SizedBox(height: 8),
      TextField(controller: video, decoration: const InputDecoration(labelText: 'Optional video link')),
      const SizedBox(height: 8),
      FilledButton.icon(onPressed: submit, icon: const Icon(Icons.send), label: const Text('Send question')),
      const SizedBox(height: 14),
      StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: service.questionsForUser(widget.profile.id),
        builder: (context, snap) {
          final docs = snap.data?.docs ?? [];
          if (docs.isEmpty) return const SizedBox.shrink();
          return Column(children: docs.map((d) {
            final m = d.data();
            return Card(child: ListTile(
              title: Text('${m['category'] ?? 'Question'} — ${m['status'] == 'answered' ? 'Answered' : 'Waiting'}'),
              subtitle: Text('${m['question'] ?? ''}${(m['answer'] ?? '').toString().isEmpty ? '' : '\n\nTrainer: ${m['answer']}'}'),
            ));
          }).toList());
        },
      ),
    ]);
  }
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
  String topic = 'Recall';
  String trainer = 'No preference';
  String format = 'Either';
  String availability = 'Weekday evening';

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
    );
    note.clear();
    if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('1-to-1 request sent.')));
  }

  Future<void> launch(String value) async {
    final uri = Uri.tryParse(value);
    if (uri != null) await launchUrl(uri, mode: LaunchMode.platformDefault);
  }

  @override
  Widget build(BuildContext context) {
    const topics = ['Recall', 'Focus', 'Toy/Tug', 'Dead Ball', 'Target Work', 'Confidence', 'General Training', 'Pre-Flyball Assessment', 'Other'];
    const availabilityOptions = ['Weekday daytime', 'Weekday evening', 'Saturday', 'Sunday', 'Flexible'];
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      Text('Request a 1-to-1', style: Theme.of(context).textTheme.headlineSmall),
      const Text('Tell the trainers what you need help with. They can suggest a time and send a Meet link if the session is online.'),
      const SizedBox(height: 10),
      DropdownButtonFormField<String>(initialValue: topic, items: topics.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(), onChanged: (v) => setState(() => topic = v ?? topic), decoration: const InputDecoration(labelText: 'What would you like help with?')),
      const SizedBox(height: 8),
      TextFormField(initialValue: trainer, decoration: const InputDecoration(labelText: 'Preferred trainer (or No preference)'), onChanged: (v) => trainer = v),
      const SizedBox(height: 8),
      DropdownButtonFormField<String>(initialValue: format, items: ['Online video call', 'In-person session', 'Either'].map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(), onChanged: (v) => setState(() => format = v ?? format), decoration: const InputDecoration(labelText: 'Session type')),
      const SizedBox(height: 8),
      DropdownButtonFormField<String>(initialValue: availability, items: availabilityOptions.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(), onChanged: (v) => setState(() => availability = v ?? availability), decoration: const InputDecoration(labelText: 'General availability')),
      const SizedBox(height: 8),
      TextField(controller: note, maxLines: 3, decoration: const InputDecoration(labelText: 'Anything else the trainer should know?')),
      const SizedBox(height: 8),
      FilledButton.icon(onPressed: request, icon: const Icon(Icons.event_available), label: const Text('Request session')),
      const SizedBox(height: 16),
      StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: service.oneToOnesForUser(widget.profile.id),
        builder: (context, snap) {
          final docs = snap.data?.docs ?? [];
          if (docs.isEmpty) return const Card(child: Padding(padding: EdgeInsets.all(16), child: Text('No 1-to-1 requests yet.')));
          return Column(children: docs.map((d) {
            final m = d.data();
            final status = m['status'] ?? 'requested';
            final when = (m['proposedWhen'] ?? '').toString();
            final meet = (m['meetUrl'] ?? '').toString();
            return Card(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                  Text('${m['topic'] ?? '1-to-1'} — ${status.toString().toUpperCase()}', style: const TextStyle(fontWeight: FontWeight.bold)),
                  Text('${m['format'] ?? ''} • ${m['availability'] ?? ''}'),
                  if ((m['trainerName'] ?? '').toString().isNotEmpty) Text('Trainer: ${m['trainerName']}'),
                  if (when.isNotEmpty) Text('Proposed/booked: $when'),
                  if ((m['homework'] ?? '').toString().isNotEmpty) Text('Homework: ${m['homework']}'),
                  const SizedBox(height: 8),
                  Wrap(spacing: 8, runSpacing: 8, children: [
                    if (status == 'proposed') FilledButton(onPressed: () => service.learnerAcceptOneToOne(d.id), child: const Text('Accept time')),
                    if (status == 'booked' && meet.isNotEmpty) FilledButton.icon(onPressed: () => launch(meet), icon: const Icon(Icons.video_call), label: const Text('Join session')),
                    if (status != 'completed' && status != 'cancelled' && status != 'declined') OutlinedButton(onPressed: () => service.learnerCancelOneToOne(d.id), child: const Text('Cancel request')),
                  ]),
                ]),
              ),
            );
          }).toList());
        },
      ),
    ]);
  }
}

class TrainingDiaryPanel extends StatefulWidget {
  final AppUser profile;
  final DogProfile dog;
  const TrainingDiaryPanel({super.key, required this.profile, required this.dog});

  @override
  State<TrainingDiaryPanel> createState() => _TrainingDiaryPanelState();
}

class _TrainingDiaryPanelState extends State<TrainingDiaryPanel> {
  final service = FirestoreService();
  final note = TextEditingController();
  String skill = 'Recall';
  String result = 'Good';

  @override
  Widget build(BuildContext context) {
    final skills = courseModules.map((m) => m.title).toList()..add('General');
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      Text('Training Diary', style: Theme.of(context).textTheme.headlineSmall),
      const Text('A quick record of what you practised and how it went.'),
      const SizedBox(height: 10),
      DropdownButtonFormField<String>(initialValue: skill, items: skills.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(), onChanged: (v) => setState(() => skill = v ?? skill), decoration: const InputDecoration(labelText: 'Skill')),
      const SizedBox(height: 8),
      DropdownButtonFormField<String>(initialValue: result, items: ['Brilliant', 'Good', 'Mixed', 'Difficult'].map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(), onChanged: (v) => setState(() => result = v ?? result), decoration: const InputDecoration(labelText: 'How did it go?')),
      const SizedBox(height: 8),
      TextField(controller: note, maxLines: 3, decoration: const InputDecoration(labelText: 'Optional note')),
      const SizedBox(height: 8),
      FilledButton.icon(onPressed: () async {
        await service.addTrainingLog(uid: widget.profile.id, dogId: widget.dog.id, skill: skill, result: result, note: note.text);
        note.clear();
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Training logged.')));
      }, icon: const Icon(Icons.add), label: const Text('Add diary entry')),
      const SizedBox(height: 14),
      StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: service.trainingLogsForUser(widget.profile.id),
        builder: (context, snap) {
          final docs = [...(snap.data?.docs ?? [])];
          docs.sort((a, b) {
            final at = (a.data()['createdAt'] as Timestamp?)?.millisecondsSinceEpoch ?? 0;
            final bt = (b.data()['createdAt'] as Timestamp?)?.millisecondsSinceEpoch ?? 0;
            return bt.compareTo(at);
          });
          return Column(children: docs.take(20).map((d) => Card(child: ListTile(
            leading: const Icon(Icons.menu_book),
            title: Text('${d.data()['skill'] ?? 'Training'} — ${d.data()['result'] ?? ''}'),
            subtitle: (d.data()['note'] ?? '').toString().isEmpty ? null : Text(d.data()['note']),
          ))).toList());
        },
      ),
    ]);
  }
}

class TreasureChestScreen extends StatefulWidget {
  final AppUser profile;
  const TreasureChestScreen({super.key, required this.profile});

  @override
  State<TreasureChestScreen> createState() => _TreasureChestScreenState();
}

class _TreasureChestScreenState extends State<TreasureChestScreen> {
  final service = FirestoreService();
  final Set<String> selected = {};

  static const products = <String, IconData>{
    'Mugs': Icons.coffee,
    'Pens': Icons.edit,
    'Dog Bandanas': Icons.pets,
    'Real Trophies': Icons.emoji_events,
    'Stickers': Icons.stars,
    'Magnets': Icons.push_pin,
    'Keyrings': Icons.key,
    'T-shirts & Hoodies': Icons.checkroom,
  };

  Future<void> register() async {
    if (selected.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Choose at least one treasure you would be interested in.')));
      return;
    }
    await service.registerMerchInterest(uid: widget.profile.id, name: widget.profile.name, items: selected.toList());
    if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Interest registered — we’ll know what treasure the crew wants most!')));
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text('Menai Muttineers Treasure Chest', style: Theme.of(context).textTheme.headlineSmall),
        const SizedBox(height: 4),
        const Text('COMING SOON — club merch, pirate goodies and a few treasures for dogs and humans.'),
        const SizedBox(height: 14),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: products.entries.map((entry) {
            final picked = selected.contains(entry.key);
            return SizedBox(
              width: 190,
              child: Card(
                child: InkWell(
                  onTap: () => setState(() => picked ? selected.remove(entry.key) : selected.add(entry.key)),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(children: [
                      Icon(entry.value, size: 52),
                      const SizedBox(height: 8),
                      Text(entry.key, textAlign: TextAlign.center, style: const TextStyle(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 4),
                      const Text('Coming soon', textAlign: TextAlign.center),
                      const SizedBox(height: 8),
                      Icon(picked ? Icons.check_circle : Icons.add_circle_outline),
                    ]),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 14),
        FilledButton.icon(onPressed: register, icon: const Icon(Icons.inventory_2), label: const Text('Register My Interest')),
      ],
    );
  }
}

class LearnerProfile extends StatefulWidget {
  final AppUser profile;
  final DogProfile dog;
  const LearnerProfile({super.key, required this.profile, required this.dog});

  @override
  State<LearnerProfile> createState() => _LearnerProfileState();
}

class _LearnerProfileState extends State<LearnerProfile> {
  late final TextEditingController dogName;
  late final TextEditingController breed;
  late final TextEditingController age;
  late final TextEditingController dateOfBirth;
  late final TextEditingController experience;
  late final TextEditingController notes;
  late bool dobEstimated;
  late bool celebrationSound;
  final service = FirestoreService();

  @override
  void initState() {
    super.initState();
    dogName = TextEditingController(text: widget.dog.name);
    breed = TextEditingController(text: widget.dog.breed);
    age = TextEditingController(text: widget.dog.ageText);
    dateOfBirth = TextEditingController(text: widget.dog.dateOfBirth);
    experience = TextEditingController(text: widget.dog.experience);
    notes = TextEditingController(text: widget.dog.notes);
    dobEstimated = widget.dog.dobEstimated;
    celebrationSound = widget.profile.celebrationSound;
  }

  Future<void> pickDob() async {
    final now = DateTime.now();
    final current = DateTime.tryParse(dateOfBirth.text);
    final chosen = await showDatePicker(
      context: context,
      firstDate: DateTime(now.year - 30),
      lastDate: now,
      initialDate: current ?? DateTime(now.year - 2, now.month, now.day),
      helpText: 'Dog date of birth — best guess is fine',
    );
    if (chosen != null) {
      setState(() => dateOfBirth.text = '${chosen.year.toString().padLeft(4, '0')}-${chosen.month.toString().padLeft(2, '0')}-${chosen.day.toString().padLeft(2, '0')}');
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Center(child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 700),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            Text('My Dog', style: Theme.of(context).textTheme.headlineSmall),
            Text('Owner: ${widget.profile.name}'),
            const SizedBox(height: 12),
            TextField(controller: dogName, decoration: const InputDecoration(labelText: 'Dog’s name')),
            const SizedBox(height: 8),
            TextField(controller: breed, decoration: const InputDecoration(labelText: 'Breed')),
            const SizedBox(height: 8),
            TextField(controller: age, decoration: const InputDecoration(labelText: 'Age')),
            const SizedBox(height: 8),
            TextField(controller: dateOfBirth, readOnly: true, onTap: pickDob, decoration: const InputDecoration(labelText: 'Date of birth', hintText: 'Best guess is fine', suffixIcon: Icon(Icons.cake_outlined))),
            CheckboxListTile(value: dobEstimated, contentPadding: EdgeInsets.zero, title: const Text('Date of birth is estimated'), onChanged: (v) => setState(() => dobEstimated = v ?? false)),
            const SizedBox(height: 8),
            TextField(controller: experience, maxLines: 3, decoration: const InputDecoration(labelText: 'Previous training experience')),
            const SizedBox(height: 8),
            TextField(controller: notes, maxLines: 4, decoration: const InputDecoration(labelText: 'Useful notes for trainers')),
            const SizedBox(height: 10),
            FilledButton(onPressed: () async {
              await service.updateDog(widget.dog.id, {
                'name': dogName.text.trim(),
                'breed': breed.text.trim(),
                'ageText': age.text.trim(),
                'dateOfBirth': dateOfBirth.text.trim(),
                'dobEstimated': dobEstimated,
                'experience': experience.text.trim(),
                'notes': notes.text.trim(),
              });
              if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Dog profile updated.')));
            }, child: const Text('Save profile')),
            const SizedBox(height: 14),
            Card(
              child: SwitchListTile(
                title: const Text('Trophy celebration sounds'),
                subtitle: const Text('Party poppers still show if sound is switched off.'),
                value: celebrationSound,
                onChanged: (v) async {
                  setState(() => celebrationSound = v);
                  await service.updateCelebrationSound(widget.profile.id, v);
                },
              ),
            ),
            const Center(child: Padding(padding: EdgeInsets.all(8), child: Text('Menai Muttineers Academy V1.2'))),
          ]),
        )),
      ],
    );
  }
}
