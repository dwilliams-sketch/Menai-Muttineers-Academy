import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../../i18n.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:youtube_player_iframe/youtube_player_iframe.dart';
import '../../course_data.dart';
import '../../models.dart';
import '../../services/firestore_service.dart';
import '../../widgets/trophy_art.dart';
import '../../widgets/language_toggle.dart';

class CourseScreen extends StatelessWidget {
  final AppUser profile;
  final DogProfile dog;
  CourseScreen({super.key, required this.profile, required this.dog});
  final service = FirestoreService();

  @override
  Widget build(BuildContext context) => ListView(
        padding: const EdgeInsets.all(16),
        children: [
          I18nText('${dog.name}’s Adventure Map', style: Theme.of(context).textTheme.headlineSmall),
          const I18nText('Choose a Key Skill. Work through the short lessons at your own pace, then request assessment when you are ready.'),
          const SizedBox(height: 10),
          ...courseModules.asMap().entries.map((entry) {
            final module = entry.value;
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
                        leading: TrophyArt(artKey: module.artKey, locked: !passed, size: 58),
                        title: I18nText('${entry.key + 1}. ${module.title}'),
                        subtitle: I18nText(passed ? 'Trainer verified • Trophy earned' : '$done of ${module.lessons.length} lessons practised'),
                        trailing: Icon(passed ? Icons.verified : Icons.chevron_right),
                        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => ModuleScreen(profile: profile, dog: dog, module: module))),
                      ),
                    );
                  },
                );
              },
            );
          }),
        ],
      );
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
  bool ready1 = false, ready2 = false, ready3 = false, ready4 = false;

  Future<void> submit() async {
    if (!(ready1 && ready2 && ready3 && ready4)) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: I18nText('Please complete the Ready for Assessment checks first.')));
      return;
    }
    if (video.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: I18nText('Please add your assessment video link.')));
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
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: I18nText('Assessment sent to the trainers.')));
    }
  }

  @override
  void dispose() { video.dispose(); note.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: I18nText(widget.module.title), actions: [LanguageToggle(userId: widget.profile.id)]),
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
                return ListView(padding: const EdgeInsets.all(16), children: [
                  Center(child: ConstrainedBox(constraints: const BoxConstraints(maxWidth: 900), child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                    I18nText(widget.module.stage, style: Theme.of(context).textTheme.labelLarge),
                    I18nText(widget.module.title, style: Theme.of(context).textTheme.headlineSmall),
                    const SizedBox(height: 8),
                    Card(child: Padding(padding: const EdgeInsets.all(16), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      I18nText('Why this matters', style: Theme.of(context).textTheme.titleMedium),
                      const SizedBox(height: 5),
                      I18nText(widget.module.summary),
                    ]))),
                    Card(child: Padding(padding: const EdgeInsets.all(16), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Row(children: [Expanded(child: I18nText('Lesson progress', style: Theme.of(context).textTheme.titleMedium)), I18nText('$completed / ${widget.module.lessons.length}')]),
                      const SizedBox(height: 8), LinearProgressIndicator(value: completed / widget.module.lessons.length),
                      const SizedBox(height: 5), const I18nText('Practised or Confident counts as completed. Need Help sends a proper message to the trainers.'),
                    ]))),
                    ...widget.module.lessons.asMap().entries.map((entry) {
                      final lesson = entry.value;
                      final url = (lessonVideos[lesson.id] ?? (entry.key == 0 ? oldVideo : '')).toString();
                      return _LessonCard(
                        profile: widget.profile,
                        dog: widget.dog,
                        module: widget.module,
                        lesson: lesson,
                        number: entry.key + 1,
                        videoUrl: url,
                        status: (lessonStates[lesson.id] ?? 'not_started').toString(),
                      );
                    }),
                    const SizedBox(height: 10),
                    Card(child: Padding(padding: const EdgeInsets.all(16), child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                      Row(children: [Icon(unlocked ? Icons.lock_open : Icons.lock_outline), const SizedBox(width: 8), Expanded(child: I18nText(unlocked ? 'Ready for Assessment?' : 'Assessment Locked', style: Theme.of(context).textTheme.titleLarge))]),
                      const SizedBox(height: 7),
                      I18nText(unlocked ? widget.module.assessmentText : 'Practise all ${widget.module.lessons.length} lessons first.'),
                      if (unlocked) ...[
                        CheckboxListTile(contentPadding: EdgeInsets.zero, value: ready1, onChanged: (v) => setState(() => ready1 = v ?? false), title: const I18nText('My dog can do this in a familiar environment.')),
                        CheckboxListTile(contentPadding: EdgeInsets.zero, value: ready2, onChanged: (v) => setState(() => ready2 = v ?? false), title: const I18nText('We have practised it on several occasions.')),
                        CheckboxListTile(contentPadding: EdgeInsets.zero, value: ready3, onChanged: (v) => setState(() => ready3 = v ?? false), title: const I18nText('I understand what the trainer is looking for.')),
                        CheckboxListTile(contentPadding: EdgeInsets.zero, value: ready4, onChanged: (v) => setState(() => ready4 = v ?? false), title: const I18nText('My dog is happy and confident doing it.')),
                        TextField(controller: video, decoration: const InputDecoration(label: I18nText('Assessment video link'), hint: I18nText('YouTube / Google Drive / other share link'))),
                        const SizedBox(height: 8),
                        TextField(controller: note, maxLines: 3, decoration: const InputDecoration(label: I18nText('Anything the trainer should know?'))),
                        const SizedBox(height: 8),
                        FilledButton.icon(onPressed: busy ? null : submit, icon: const Icon(Icons.upload), label: I18nText(busy ? 'Sending...' : 'REQUEST ASSESSMENT')),
                      ],
                    ]))),
                  ]))),
                ]);
              },
            );
          },
        ),
      );
}

class _LessonCard extends StatelessWidget {
  final AppUser profile;
  final DogProfile dog;
  final CourseModule module;
  final LessonDefinition lesson;
  final int number;
  final String videoUrl;
  final String status;
  _LessonCard({required this.profile, required this.dog, required this.module, required this.lesson, required this.number, required this.videoUrl, required this.status});
  final service = FirestoreService();

  Future<void> _needHelp(BuildContext context) async {
    final message = TextEditingController();
    final video = TextEditingController();
    final ok = await showDialog<bool>(context: context, builder: (ctx) => AlertDialog(
      title: I18nText('Need help — ${lesson.title}'),
      content: SizedBox(width: 520, child: SingleChildScrollView(child: Column(children: [
        const I18nText('Tell the trainers what is happening. This creates a conversation linked to this exact lesson.'),
        const SizedBox(height: 10),
        TextField(controller: message, maxLines: 5, decoration: const InputDecoration(label: I18nText('What are you struggling with?'))),
        const SizedBox(height: 8),
        TextField(controller: video, decoration: const InputDecoration(label: I18nText('Optional video link'))),
      ]))),
      actions: [TextButton(onPressed: () => Navigator.pop(ctx, false), child: const I18nText('Cancel')), FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const I18nText('Send to Trainers'))],
    ));
    if (ok == true && message.text.trim().isNotEmpty) {
      await service.requestLessonHelp(uid: profile.id, dogId: dog.id, learnerName: profile.name, dogName: dog.name, moduleId: module.id, moduleTitle: module.title, lessonId: lesson.id, lessonTitle: lesson.title, message: message.text, videoUrl: video.text);
      await service.setLessonStatus(dogId: dog.id, moduleId: module.id, lessonId: lesson.id, status: 'need_help');
      if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: I18nText('Help request sent to the trainers.')));
    }
    message.dispose(); video.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final done = status == 'practised' || status == 'confident';
    return Card(child: ExpansionTile(
      leading: CircleAvatar(child: done ? const Icon(Icons.check) : I18nText('$number')),
      title: I18nText(lesson.title),
      subtitle: I18nText(_label(status)),
      childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      children: [
        Align(alignment: Alignment.centerLeft, child: I18nText(lesson.summary)),
        const SizedBox(height: 10),
        if (videoUrl.trim().isNotEmpty) _LessonVideo(url: videoUrl) else const Card(child: Padding(padding: EdgeInsets.all(12), child: I18nText('Video coming soon — the Captain can add the link from Course Editor.'))),
        const SizedBox(height: 10),
        Wrap(spacing: 7, runSpacing: 7, children: [
          OutlinedButton(onPressed: () => service.setLessonStatus(dogId: dog.id, moduleId: module.id, lessonId: lesson.id, status: 'watched'), child: const I18nText('Watched')),
          FilledButton.tonal(onPressed: () => service.setLessonStatus(dogId: dog.id, moduleId: module.id, lessonId: lesson.id, status: 'practised'), child: const I18nText('Practised')),
          FilledButton(onPressed: () => service.setLessonStatus(dogId: dog.id, moduleId: module.id, lessonId: lesson.id, status: 'confident'), child: const I18nText('Confident')),
          OutlinedButton.icon(onPressed: () => _needHelp(context), icon: const Icon(Icons.support_agent), label: const I18nText('Need Help')),
        ]),
      ],
    ));
  }

  String _label(String s) => switch (s) {
    'watched' => 'Watched', 'practised' => 'Practised', 'confident' => 'Confident', 'need_help' => 'Help requested', _ => 'Not started',
  };
}

class _LessonVideo extends StatefulWidget {
  final String url;
  const _LessonVideo({required this.url});
  @override State<_LessonVideo> createState() => _LessonVideoState();
}
class _LessonVideoState extends State<_LessonVideo> {
  YoutubePlayerController? controller;
  @override void initState() { super.initState(); final id = YoutubePlayerController.convertUrlToId(widget.url); if (id != null) controller = YoutubePlayerController.fromVideoId(videoId: id, autoPlay: false, params: const YoutubePlayerParams(showFullscreenButton: true)); }
  @override void dispose() { controller?.close(); super.dispose(); }
  @override Widget build(BuildContext context) {
    if (controller != null) return ClipRRect(borderRadius: BorderRadius.circular(12), child: YoutubePlayer(controller: controller!, aspectRatio: 16 / 9));
    return OutlinedButton.icon(onPressed: () async { final u = Uri.tryParse(widget.url); if (u != null) await launchUrl(u); }, icon: const Icon(Icons.open_in_new), label: const I18nText('Open training video'));
  }
}
