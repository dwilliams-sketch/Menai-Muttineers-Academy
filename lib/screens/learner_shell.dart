import 'package:cloud_firestore/cloud_firestore.dart';
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

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: service.dogsForOwner(widget.profile.id),
      builder: (context, dogSnap) {
        if (!dogSnap.hasData) return const Scaffold(body: Center(child: CircularProgressIndicator()));
        if (dogSnap.data!.docs.isEmpty) return const Scaffold(body: Center(child: Text('No dog profile found. Please contact the Captain.')));
        final dog = DogProfile.fromDoc(dogSnap.data!.docs.first);
        final pages = [
          LearnerHome(profile: widget.profile, dog: dog),
          CourseScreen(profile: widget.profile, dog: dog),
          TrophyCabinet(dog: dog),
          SupportScreen(profile: widget.profile, dog: dog),
          LearnerProfile(profile: widget.profile, dog: dog),
        ];
        final destinations = const [
          NavigationDestination(icon: Icon(Icons.home_outlined), selectedIcon: Icon(Icons.home), label: 'Home'),
          NavigationDestination(icon: Icon(Icons.school_outlined), selectedIcon: Icon(Icons.school), label: 'Course'),
          NavigationDestination(icon: Icon(Icons.emoji_events_outlined), selectedIcon: Icon(Icons.emoji_events), label: 'Trophies'),
          NavigationDestination(icon: Icon(Icons.support_agent_outlined), selectedIcon: Icon(Icons.support_agent), label: 'Help'),
          NavigationDestination(icon: Icon(Icons.pets_outlined), selectedIcon: Icon(Icons.pets), label: 'My Dog'),
        ];
        return Scaffold(
          appBar: AppBar(
            title: const Text('Menai Muttineers Academy'),
            actions: [IconButton(onPressed: () => FirebaseAuth.instance.signOut(), tooltip: 'Sign out', icon: const Icon(Icons.logout))],
          ),
          body: pages[index],
          bottomNavigationBar: NavigationBar(
            selectedIndex: index,
            onDestinationSelected: (v) => setState(() => index = v),
            destinations: destinations,
          ),
        );
      },
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
            const Text('Pre-Flyball Skills — go at your dog’s pace.'),
            const SizedBox(height: 12),
            StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: service.trophiesForDog(dog.id),
              builder: (context, snap) {
                final count = snap.data?.docs.length ?? 0;
                final progress = (count / courseModules.length).clamp(0.0, 1.0);
                return Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text('Course progress', style: Theme.of(context).textTheme.titleMedium),
                      const SizedBox(height: 8),
                      LinearProgressIndicator(value: progress),
                      const SizedBox(height: 6),
                      Text('$count of ${courseModules.length} trainer-verified trophies earned'),
                      if (count >= courseModules.length) ...[
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
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: service.trophiesForDog(dog.id),
      builder: (context, trophySnap) {
        final passed = (trophySnap.data?.docs ?? []).map((e) => e.id).toSet();
        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Text('${dog.name}’s Training Journey', style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: 4),
            const Text('Watch the lesson, practise the exercises, then send a video when you are ready for trainer review.'),
            const SizedBox(height: 10),
            ...courseModules.map((module) => Card(
              child: ListTile(
                leading: CircleAvatar(child: Text(module.stage.replaceAll('Module ', ''))),
                title: Text(module.title),
                subtitle: Text(passed.contains(module.id) ? 'Trophy earned: ${module.trophyTitle}' : module.summary),
                trailing: Icon(passed.contains(module.id) ? Icons.verified : Icons.chevron_right),
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => ModuleScreen(profile: profile, dog: dog, module: module))),
              ),
            )),
          ],
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
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please add your video link first.')));
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
      video.clear(); note.clear();
      setState(() => busy = false);
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Video sent to the trainers for review.')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.module.title)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Center(child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 900),
            child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
              Text(widget.module.stage, style: Theme.of(context).textTheme.labelLarge),
              Text(widget.module.summary, style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 12),
              StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
                stream: service.moduleSettings(widget.module.id),
                builder: (context, snap) {
                  final url = snap.data?.data()?['videoUrl']?.toString() ?? '';
                  if (url.isEmpty) {
                    return const Card(child: Padding(padding: EdgeInsets.all(16), child: Text('Training video coming soon.')));
                  }
                  return LessonVideo(url: url);
                },
              ),
              const SizedBox(height: 12),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text('Exercises', style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: 8),
                    ...widget.module.exercises.map((e) => Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        const Icon(Icons.check_circle_outline, size: 20),
                        const SizedBox(width: 8),
                        Expanded(child: Text(e)),
                      ]),
                    )),
                  ]),
                ),
              ),
              const SizedBox(height: 12),
              Text('Send your attempt', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              TextField(controller: video, decoration: const InputDecoration(labelText: 'YouTube or Google Drive video link')),
              const SizedBox(height: 8),
              TextField(controller: note, maxLines: 3, decoration: const InputDecoration(labelText: 'Message for the trainer (optional)')),
              const SizedBox(height: 10),
              FilledButton.icon(onPressed: busy ? null : submit, icon: const Icon(Icons.send), label: Text(busy ? 'Sending...' : 'Send for trainer review')),
              const SizedBox(height: 14),
              StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                stream: service.submissionsForUser(widget.profile.id),
                builder: (context, snap) {
                  final docs = (snap.data?.docs ?? []).where((d) => d.data()['moduleId'] == widget.module.id).toList();
                  docs.sort((a, b) {
                    final at = (a.data()['submittedAt'] as Timestamp?)?.millisecondsSinceEpoch ?? 0;
                    final bt = (b.data()['submittedAt'] as Timestamp?)?.millisecondsSinceEpoch ?? 0;
                    return bt.compareTo(at);
                  });
                  if (docs.isEmpty) return const SizedBox.shrink();
                  final m = docs.first.data();
                  final status = m['status'] ?? 'waiting';
                  return Card(
                    child: ListTile(
                      leading: Icon(status == 'passed' ? Icons.emoji_events : status == 'practise' ? Icons.build : Icons.hourglass_top),
                      title: Text(status == 'passed' ? 'Passed — trophy awarded!' : status == 'practise' ? 'Keep practising' : 'Awaiting trainer review'),
                      subtitle: (m['feedback'] ?? '').toString().isEmpty ? null : Text(m['feedback']),
                    ),
                  );
                },
              ),
            ]),
          )),
        ],
      ),
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

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: service.trophiesForDog(dog.id),
      builder: (context, snap) {
        final docs = snap.data?.docs ?? [];
        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Text('${dog.name}’s Trophy Cabinet', style: Theme.of(context).textTheme.headlineSmall),
            const Text('Trainer-verified achievements earned through the Academy.'),
            const SizedBox(height: 12),
            if (docs.length >= courseModules.length)
              const Card(child: ListTile(leading: Icon(Icons.workspace_premium, size: 42), title: Text('READY TO JOIN THE CREW', style: TextStyle(fontWeight: FontWeight.bold)), subtitle: Text('Pre-Flyball Skills course completed.'))),
            if (docs.isEmpty)
              const Card(child: Padding(padding: EdgeInsets.all(18), child: Text('Your cabinet is waiting for its first trophy. Submit a skill video when you are ready.'))),
            ...docs.map((d) {
              final m = d.data();
              return Card(child: ListTile(
                leading: const Icon(Icons.emoji_events, size: 38),
                title: Text(m['title'] ?? 'Trophy'),
                subtitle: Text('${m['description'] ?? ''}\nApproved by ${m['reviewerName'] ?? 'Trainer'}'),
                isThreeLine: true,
              ));
            }),
          ],
        );
      },
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
    question.clear(); video.clear();
    if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Question sent to the trainers.')));
  }

  @override
  Widget build(BuildContext context) {
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      Text('Ask a Trainer', style: Theme.of(context).textTheme.headlineSmall),
      const Text('Keep course questions and feedback in one place.'),
      const SizedBox(height: 10),
      DropdownButtonFormField<String>(value: category, items: categories.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(), onChanged: (v) => setState(() => category = v ?? category), decoration: const InputDecoration(labelText: 'Topic')),
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
      DropdownButtonFormField<String>(value: topic, items: topics.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(), onChanged: (v) => setState(() => topic = v ?? topic), decoration: const InputDecoration(labelText: 'What would you like help with?')),
      const SizedBox(height: 8),
      TextFormField(initialValue: trainer, decoration: const InputDecoration(labelText: 'Preferred trainer (or No preference)'), onChanged: (v) => trainer = v),
      const SizedBox(height: 8),
      DropdownButtonFormField<String>(value: format, items: ['Online video call', 'In-person session', 'Either'].map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(), onChanged: (v) => setState(() => format = v ?? format), decoration: const InputDecoration(labelText: 'Session type')),
      const SizedBox(height: 8),
      DropdownButtonFormField<String>(value: availability, items: availabilityOptions.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(), onChanged: (v) => setState(() => availability = v ?? availability), decoration: const InputDecoration(labelText: 'General availability')),
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
    final skills = ['Focus', 'Recall', 'Toy/Tug', 'Dead Ball', 'Target', 'Movement', 'Distractions', 'General'];
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      Text('Training Diary', style: Theme.of(context).textTheme.headlineSmall),
      const Text('A quick record of what you practised and how it went.'),
      const SizedBox(height: 10),
      DropdownButtonFormField<String>(value: skill, items: skills.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(), onChanged: (v) => setState(() => skill = v ?? skill), decoration: const InputDecoration(labelText: 'Skill')),
      const SizedBox(height: 8),
      DropdownButtonFormField<String>(value: result, items: ['Brilliant', 'Good', 'Mixed', 'Difficult'].map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(), onChanged: (v) => setState(() => result = v ?? result), decoration: const InputDecoration(labelText: 'How did it go?')),
      const SizedBox(height: 8),
      TextField(controller: note, maxLines: 3, decoration: const InputDecoration(labelText: 'Note (optional)')),
      const SizedBox(height: 8),
      FilledButton(onPressed: () async {
        await service.addTrainingLog(uid: widget.profile.id, dogId: widget.dog.id, skill: skill, result: result, note: note.text);
        note.clear();
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Training added to the diary.')));
      }, child: const Text('Save training')),
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
          return Column(children: docs.take(20).map((d) {
            final m = d.data();
            return Card(child: ListTile(title: Text('${m['skill']} — ${m['result']}'), subtitle: (m['note'] ?? '').toString().isEmpty ? null : Text(m['note'])));
          }).toList());
        },
      ),
    ]);
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
  late final TextEditingController experience;
  late final TextEditingController notes;
  final service = FirestoreService();

  @override
  void initState() {
    super.initState();
    dogName = TextEditingController(text: widget.dog.name);
    breed = TextEditingController(text: widget.dog.breed);
    age = TextEditingController(text: widget.dog.ageText);
    experience = TextEditingController(text: widget.dog.experience);
    notes = TextEditingController(text: widget.dog.notes);
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
            TextField(controller: experience, maxLines: 3, decoration: const InputDecoration(labelText: 'Previous training experience')),
            const SizedBox(height: 8),
            TextField(controller: notes, maxLines: 4, decoration: const InputDecoration(labelText: 'Useful notes for trainers')),
            const SizedBox(height: 10),
            FilledButton(onPressed: () async {
              await service.updateDog(widget.dog.id, {
                'name': dogName.text.trim(),
                'breed': breed.text.trim(),
                'ageText': age.text.trim(),
                'experience': experience.text.trim(),
                'notes': notes.text.trim(),
              });
              if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Dog profile updated.')));
            }, child: const Text('Save profile')),
          ]),
        )),
      ],
    );
  }
}
