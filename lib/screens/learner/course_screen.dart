import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../../i18n.dart';

import 'package:url_launcher/url_launcher.dart';
import 'package:youtube_player_iframe/youtube_player_iframe.dart';

import '../../course_data.dart';
import '../../models.dart';
import '../../services/firestore_service.dart';
import '../../services/media_service.dart';
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
      I18nText(
        '${dog.name}’s Adventure Map',
        style: Theme.of(context).textTheme.headlineSmall,
      ),
      const I18nText(
        'Choose a Key Skill. Work through the short lessons at your own pace, then request assessment when you are ready.',
      ),
      const SizedBox(height: 10),
      ...courseModules.asMap().entries.map((entry) {
        final module = entry.value;
        return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
          stream: service.skillProgress(dog.id, module.id),
          builder: (context, progressSnap) {
            final data = progressSnap.data?.data() ?? {};
            final lessons = Map<String, dynamic>.from(
              data['lessons'] as Map? ?? {},
            );
            final done = module.lessons
                .where(
                  (l) =>
                      lessons[l.id] == 'practised' ||
                      lessons[l.id] == 'confident',
                )
                .length;
            return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: service.trophiesForDog(dog.id),
              builder: (context, trophySnap) {
                final passed = (trophySnap.data?.docs ?? []).any(
                  (d) => d.id == module.id,
                );
                return Card(
                  child: ListTile(
                    leading: TrophyArt(
                      artKey: module.artKey,
                      locked: !passed,
                      size: 58,
                    ),
                    title: I18nText('${entry.key + 1}. ${module.title}'),
                    subtitle: I18nText(
                      passed
                          ? 'Trainer verified • Trophy earned'
                          : '$done of ${module.lessons.length} lessons practised',
                    ),
                    trailing: Icon(
                      passed ? Icons.verified : Icons.chevron_right,
                    ),
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ModuleScreen(
                          profile: profile,
                          dog: dog,
                          module: module,
                        ),
                      ),
                    ),
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
  const ModuleScreen({
    super.key,
    required this.profile,
    required this.dog,
    required this.module,
  });
  @override
  State<ModuleScreen> createState() => _ModuleScreenState();
}

class _ModuleScreenState extends State<ModuleScreen> {
  final service = FirestoreService();
  final media = MediaService();
  final video = TextEditingController();
  final note = TextEditingController();
  bool busy = false;
  bool uploadingVideo = false;
  bool assessmentSubmitted = false;
  UploadedAcademyVideo? uploadedAssessmentVideo;
  bool ready1 = false, ready2 = false, ready3 = false, ready4 = false;

  Future<void> _pickAssessmentVideo({required bool record}) async {
    if (uploadingVideo) return;

    setState(() => uploadingVideo = true);

    try {
      final result = record
          ? await media.recordAssessmentVideo(uid: widget.profile.id)
          : await media.chooseAssessmentVideo(uid: widget.profile.id);

      if (result == null) return;

      if (!mounted) {
        try {
          await media.deleteAcademyVideo(result.storagePath);
        } catch (_) {}
        return;
      }

      final previous = uploadedAssessmentVideo;

      setState(() {
        uploadedAssessmentVideo = result;
        video.clear();
      });

      if (previous != null && previous.storagePath != result.storagePath) {
        try {
          await media.deleteAcademyVideo(previous.storagePath);
        } catch (_) {}
      }
    } on AcademyVideoTooLargeException {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: I18nText(
              'That video is too large. Please choose a shorter clip under 100 MB.',
            ),
          ),
        );
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: I18nText(
              'We could not upload that video. Please try again or use a video link instead.',
            ),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => uploadingVideo = false);
    }
  }

  Future<void> _removeAssessmentVideo() async {
    final current = uploadedAssessmentVideo;
    if (current == null) return;

    setState(() => uploadingVideo = true);

    try {
      await media.deleteAcademyVideo(current.storagePath);
      if (mounted) {
        setState(() => uploadedAssessmentVideo = null);
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: I18nText(
              'We could not remove that video. Please try again.',
            ),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => uploadingVideo = false);
    }
  }

  Future<void> submit() async {
    if (!(ready1 && ready2 && ready3 && ready4)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: I18nText(
            'Please complete the Ready for Assessment checks first.',
          ),
        ),
      );
      return;
    }
    if (uploadedAssessmentVideo == null && video.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: I18nText(
            'Please record a video, choose one from your phone, or add a video link.',
          ),
        ),
      );
      return;
    }
    setState(() => busy = true);
    await service.submitVideo(
      uid: widget.profile.id,
      dogId: widget.dog.id,
      module: widget.module,
      videoUrl: uploadedAssessmentVideo?.downloadUrl ?? video.text.trim(),
      storagePath: uploadedAssessmentVideo?.storagePath ?? '',
      videoSource: uploadedAssessmentVideo != null
          ? 'academy_upload'
          : 'external_link',
      videoSizeBytes: uploadedAssessmentVideo?.sizeBytes ?? 0,
      note: note.text,
      learnerName: widget.profile.name,
      dogName: widget.dog.name,
    );

    assessmentSubmitted = true;

    if (mounted) {
      video.clear();
      note.clear();
      setState(() {
        busy = false;
        uploadedAssessmentVideo = null;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: I18nText('Assessment sent to the trainers.')),
      );
    }
  }

  @override
  void dispose() {
    final abandonedVideo = uploadedAssessmentVideo;

    if (!assessmentSubmitted && abandonedVideo != null) {
      unawaited(
        media.deleteAcademyVideo(abandonedVideo.storagePath).catchError((_) {}),
      );
    }

    video.dispose();
    note.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: I18nText(widget.module.title),
      actions: [LanguageToggle(userId: widget.profile.id)],
    ),
    body: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: service.skillProgress(widget.dog.id, widget.module.id),
      builder: (context, progressSnap) {
        final progressData = progressSnap.data?.data() ?? {};
        final lessonStates = Map<String, dynamic>.from(
          progressData['lessons'] as Map? ?? {},
        );
        final completed = widget.module.lessons
            .where(
              (l) =>
                  lessonStates[l.id] == 'practised' ||
                  lessonStates[l.id] == 'confident',
            )
            .length;
        final unlocked = completed == widget.module.lessons.length;
        return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
          stream: service.moduleSettings(widget.module.id),
          builder: (context, settingsSnap) {
            final settings = settingsSnap.data?.data() ?? {};
            final lessonVideos = Map<String, dynamic>.from(
              settings['lessonVideos'] as Map? ?? {},
            );
            final oldVideo = (settings['videoUrl'] ?? '').toString();
            return ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 900),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        I18nText(
                          widget.module.stage,
                          style: Theme.of(context).textTheme.labelLarge,
                        ),
                        I18nText(
                          widget.module.title,
                          style: Theme.of(context).textTheme.headlineSmall,
                        ),
                        const SizedBox(height: 8),
                        Card(
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                I18nText(
                                  'Why this matters',
                                  style: Theme.of(context)
                                      .textTheme
                                      .titleMedium,
                                ),
                                const SizedBox(height: 5),
                                I18nText(widget.module.summary),
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
                                Row(
                                  children: [
                                    Expanded(
                                      child: I18nText(
                                        'Lesson progress',
                                        style: Theme.of(context)
                                            .textTheme
                                            .titleMedium,
                                      ),
                                    ),
                                    I18nText(
                                      '$completed / ${widget.module.lessons.length}',
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                LinearProgressIndicator(
                                  value:
                                      completed / widget.module.lessons.length,
                                ),
                                const SizedBox(height: 5),
                                const I18nText(
                                  'Practised or Confident counts as completed. Need Help sends a proper message to the trainers.',
                                ),
                              ],
                            ),
                          ),
                        ),
                        ...widget.module.lessons.asMap().entries.map((entry) {
                          final lesson = entry.value;
                          final url =
                              (lessonVideos[lesson.id] ??
                                      (entry.key == 0 ? oldVideo : ''))
                                  .toString();
                          return _LessonCard(
                            profile: widget.profile,
                            dog: widget.dog,
                            module: widget.module,
                            lesson: lesson,
                            number: entry.key + 1,
                            videoUrl: url,
                            status: (lessonStates[lesson.id] ?? 'not_started')
                                .toString(),
                          );
                        }),
                        const SizedBox(height: 10),
                        Card(
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                Row(
                                  children: [
                                    Icon(
                                      unlocked
                                          ? Icons.lock_open
                                          : Icons.lock_outline,
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: I18nText(
                                        unlocked
                                            ? 'Ready for Assessment?'
                                            : 'Assessment Locked',
                                        style: Theme.of(context)
                                            .textTheme
                                            .titleLarge,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 7),
                                I18nText(
                                  unlocked
                                      ? widget.module.assessmentText
                                      : 'Practise all ${widget.module.lessons.length} lessons first.',
                                ),
                                if (unlocked) ...[
                                  CheckboxListTile(
                                    contentPadding: EdgeInsets.zero,
                                    value: ready1,
                                    onChanged: (v) =>
                                        setState(() => ready1 = v ?? false),
                                    title: const I18nText(
                                      'My dog can do this in a familiar environment.',
                                    ),
                                  ),
                                  CheckboxListTile(
                                    contentPadding: EdgeInsets.zero,
                                    value: ready2,
                                    onChanged: (v) =>
                                        setState(() => ready2 = v ?? false),
                                    title: const I18nText(
                                      'We have practised it on several occasions.',
                                    ),
                                  ),
                                  CheckboxListTile(
                                    contentPadding: EdgeInsets.zero,
                                    value: ready3,
                                    onChanged: (v) =>
                                        setState(() => ready3 = v ?? false),
                                    title: const I18nText(
                                      'I understand what the trainer is looking for.',
                                    ),
                                  ),
                                  CheckboxListTile(
                                    contentPadding: EdgeInsets.zero,
                                    value: ready4,
                                    onChanged: (v) =>
                                        setState(() => ready4 = v ?? false),
                                    title: const I18nText(
                                      'My dog is happy and confident doing it.',
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  const I18nText(
                                    'Send us a short video showing the skill. The easiest option is to record one now or choose one already on your phone.',
                                  ),
                                  const SizedBox(height: 10),
                                  Wrap(
                                    spacing: 8,
                                    runSpacing: 8,
                                    children: [
                                      FilledButton.icon(
                                        onPressed: uploadingVideo
                                            ? null
                                            : () => _pickAssessmentVideo(
                                                record: true,
                                              ),
                                        icon: const Icon(Icons.videocam),
                                        label: const I18nText(
                                          'RECORD VIDEO NOW',
                                        ),
                                      ),
                                      FilledButton.tonalIcon(
                                        onPressed: uploadingVideo
                                            ? null
                                            : () => _pickAssessmentVideo(
                                                record: false,
                                              ),
                                        icon: const Icon(Icons.video_library),
                                        label: const I18nText(
                                          'CHOOSE FROM PHONE',
                                        ),
                                      ),
                                    ],
                                  ),
                                  if (uploadingVideo) ...[
                                    const SizedBox(height: 12),
                                    const LinearProgressIndicator(),
                                    const SizedBox(height: 6),
                                    const I18nText('Uploading your video...'),
                                  ],
                                  if (uploadedAssessmentVideo != null) ...[
                                    const SizedBox(height: 10),
                                    Card(
                                      child: ListTile(
                                        leading: const Icon(
                                          Icons.check_circle,
                                          color: Colors.green,
                                        ),
                                        title: const I18nText('Video ready'),
                                        subtitle: I18nText(
                                          '${(uploadedAssessmentVideo!.sizeBytes / (1024 * 1024)).toStringAsFixed(1)} MB • Ready to send to the trainers',
                                        ),
                                        trailing: IconButton(
                                          tooltip: 'Remove video',
                                          onPressed: uploadingVideo
                                              ? null
                                              : _removeAssessmentVideo,
                                          icon: const Icon(
                                            Icons.delete_outline,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ] else ...[
                                    const SizedBox(height: 12),
                                    const Row(
                                      children: [
                                        Expanded(child: Divider()),
                                        Padding(
                                          padding: EdgeInsets.symmetric(
                                            horizontal: 10,
                                          ),
                                          child: I18nText('OR USE A LINK'),
                                        ),
                                        Expanded(child: Divider()),
                                      ],
                                    ),
                                    const SizedBox(height: 8),
                                    TextField(
                                      controller: video,
                                      decoration: const InputDecoration(
                                        label: I18nText('Video link'),
                                        hint: I18nText(
                                          'YouTube / Google Drive / iCloud / other share link',
                                        ),
                                        prefixIcon: Icon(Icons.link),
                                      ),
                                    ),
                                  ],
                                  const SizedBox(height: 6),
                                  const I18nText(
                                    'Keep clips short and clear. Recordings are limited to 90 seconds and Academy uploads have a 100 MB maximum.',
                                  ),
                                  const SizedBox(height: 10),
                                  TextField(
                                    controller: note,
                                    maxLines: 3,
                                    decoration: const InputDecoration(
                                      label: I18nText(
                                        'Anything the trainer should know?',
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  FilledButton.icon(
                                    onPressed: busy ? null : submit,
                                    icon: const Icon(Icons.upload),
                                    label: I18nText(
                                      busy
                                          ? 'Sending...'
                                          : 'REQUEST ASSESSMENT',
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            );
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
  _LessonCard({
    required this.profile,
    required this.dog,
    required this.module,
    required this.lesson,
    required this.number,
    required this.videoUrl,
    required this.status,
  });
  final service = FirestoreService();

  Future<void> _needHelp(BuildContext context) async {
    final message = TextEditingController();
    final video = TextEditingController();
    final media = MediaService();

    UploadedAcademyVideo? uploadedHelpVideo;
    bool uploadingVideo = false;

    final ok = await showDialog<bool>(
      context: context,
      barrierDismissible: !uploadingVideo,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) {
          Future<void> chooseVideo({required bool record}) async {
            if (uploadingVideo) return;

            setDialogState(() => uploadingVideo = true);

            try {
              final result = record
                  ? await media.recordHelpVideo(uid: profile.id)
                  : await media.chooseHelpVideo(uid: profile.id);

              if (result == null) return;

              final previous = uploadedHelpVideo;

              setDialogState(() {
                uploadedHelpVideo = result;
                video.clear();
              });

              if (previous != null &&
                  previous.storagePath != result.storagePath) {
                try {
                  await media.deleteAcademyVideo(previous.storagePath);
                } catch (_) {}
              }
            } on AcademyVideoTooLargeException {
              if (ctx.mounted) {
                ScaffoldMessenger.of(ctx).showSnackBar(
                  const SnackBar(
                    content: I18nText(
                      'That video is too large. Please choose a shorter clip under 100 MB.',
                    ),
                  ),
                );
              }
            } catch (_) {
              if (ctx.mounted) {
                ScaffoldMessenger.of(ctx).showSnackBar(
                  const SnackBar(
                    content: I18nText(
                      'We could not upload that video. Please try again or use a video link instead.',
                    ),
                  ),
                );
              }
            } finally {
              if (ctx.mounted) {
                setDialogState(() => uploadingVideo = false);
              }
            }
          }

          Future<void> removeVideo() async {
            final current = uploadedHelpVideo;
            if (current == null || uploadingVideo) return;

            setDialogState(() => uploadingVideo = true);

            try {
              await media.deleteAcademyVideo(current.storagePath);

              if (ctx.mounted) {
                setDialogState(() => uploadedHelpVideo = null);
              }
            } catch (_) {
              if (ctx.mounted) {
                ScaffoldMessenger.of(ctx).showSnackBar(
                  const SnackBar(
                    content: I18nText(
                      'We could not remove that video. Please try again.',
                    ),
                  ),
                );
              }
            } finally {
              if (ctx.mounted) {
                setDialogState(() => uploadingVideo = false);
              }
            }
          }

          return AlertDialog(
            title: I18nText('Need help — ${lesson.title}'),
            content: SizedBox(
              width: 560,
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const I18nText(
                      'Tell the trainers what is happening. You can also send us a short video so we can see exactly what you mean.',
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: message,
                      maxLines: 5,
                      onChanged: (_) => setDialogState(() {}),
                      decoration: const InputDecoration(
                        label: I18nText('What are you struggling with?'),
                      ),
                    ),
                    const SizedBox(height: 14),
                    const I18nText(
                      'Show us the problem',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        FilledButton.icon(
                          onPressed: uploadingVideo
                              ? null
                              : () => chooseVideo(record: true),
                          icon: const Icon(Icons.videocam),
                          label: const I18nText('RECORD VIDEO'),
                        ),
                        FilledButton.tonalIcon(
                          onPressed: uploadingVideo
                              ? null
                              : () => chooseVideo(record: false),
                          icon: const Icon(Icons.video_library),
                          label: const I18nText('CHOOSE FROM PHONE'),
                        ),
                      ],
                    ),
                    if (uploadingVideo) ...[
                      const SizedBox(height: 12),
                      const LinearProgressIndicator(),
                      const SizedBox(height: 6),
                      const I18nText('Uploading your video...'),
                    ],
                    if (uploadedHelpVideo != null) ...[
                      const SizedBox(height: 10),
                      Card(
                        child: ListTile(
                          leading: const Icon(
                            Icons.check_circle,
                            color: Colors.green,
                          ),
                          title: const I18nText('Video ready'),
                          subtitle: I18nText(
                            '${(uploadedHelpVideo!.sizeBytes / (1024 * 1024)).toStringAsFixed(1)} MB • Ready for the trainers',
                          ),
                          trailing: IconButton(
                            tooltip: 'Remove video',
                            onPressed: uploadingVideo ? null : removeVideo,
                            icon: const Icon(Icons.delete_outline),
                          ),
                        ),
                      ),
                    ] else ...[
                      const SizedBox(height: 12),
                      const Row(
                        children: [
                          Expanded(child: Divider()),
                          Padding(
                            padding: EdgeInsets.symmetric(horizontal: 10),
                            child: I18nText('OR USE A LINK'),
                          ),
                          Expanded(child: Divider()),
                        ],
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: video,
                        decoration: const InputDecoration(
                          label: I18nText('Optional video link'),
                          hint: I18nText(
                            'YouTube / Google Drive / iCloud / other share link',
                          ),
                          prefixIcon: Icon(Icons.link),
                        ),
                      ),
                    ],
                    const SizedBox(height: 8),
                    const I18nText(
                      'A short clip is normally plenty. Recordings are limited to 90 seconds.',
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: uploadingVideo
                    ? null
                    : () => Navigator.pop(ctx, false),
                child: const I18nText('Cancel'),
              ),
              FilledButton(
                onPressed: uploadingVideo || message.text.trim().isEmpty
                    ? null
                    : () => Navigator.pop(ctx, true),
                child: const I18nText('Send to Trainers'),
              ),
            ],
          );
        },
      ),
    );

    if (ok == true && message.text.trim().isNotEmpty) {
      await service.requestLessonHelp(
        uid: profile.id,
        dogId: dog.id,
        learnerName: profile.name,
        dogName: dog.name,
        moduleId: module.id,
        moduleTitle: module.title,
        lessonId: lesson.id,
        lessonTitle: lesson.title,
        message: message.text,
        videoUrl: uploadedHelpVideo?.downloadUrl ?? video.text.trim(),
        storagePath: uploadedHelpVideo?.storagePath ?? '',
        videoSource: uploadedHelpVideo != null
            ? 'academy_upload'
            : 'external_link',
        videoSizeBytes: uploadedHelpVideo?.sizeBytes ?? 0,
      );

      await service.setLessonStatus(
        dogId: dog.id,
        moduleId: module.id,
        lessonId: lesson.id,
        status: 'need_help',
      );

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: I18nText('Help request sent to the trainers.'),
          ),
        );
      }
    } else if (uploadedHelpVideo != null) {
      // Learner uploaded a clip but then cancelled the Help Me request.
      // Remove it so abandoned videos do not waste storage.
      try {
        await media.deleteAcademyVideo(uploadedHelpVideo!.storagePath);
      } catch (_) {}
    }

    message.dispose();
    video.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final done = status == 'practised' || status == 'confident';
    return Card(
      child: ExpansionTile(
        leading: CircleAvatar(
          child: done ? const Icon(Icons.check) : I18nText('$number'),
        ),
        title: I18nText(lesson.title),
        subtitle: I18nText(_label(status)),
        childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: I18nText(lesson.summary),
          ),
          const SizedBox(height: 10),
          if (videoUrl.trim().isNotEmpty)
            _LessonVideo(url: videoUrl)
          else
            const Card(
              child: Padding(
                padding: EdgeInsets.all(12),
                child: I18nText(
                  'Video coming soon — the Captain can add the link from Course Editor.',
                ),
              ),
            ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 7,
            runSpacing: 7,
            children: [
              OutlinedButton(
                onPressed: () => service.setLessonStatus(
                  dogId: dog.id,
                  moduleId: module.id,
                  lessonId: lesson.id,
                  status: 'watched',
                ),
                child: const I18nText('Watched'),
              ),
              FilledButton.tonal(
                onPressed: () => service.setLessonStatus(
                  dogId: dog.id,
                  moduleId: module.id,
                  lessonId: lesson.id,
                  status: 'practised',
                ),
                child: const I18nText('Practised'),
              ),
              FilledButton(
                onPressed: () => service.setLessonStatus(
                  dogId: dog.id,
                  moduleId: module.id,
                  lessonId: lesson.id,
                  status: 'confident',
                ),
                child: const I18nText('Confident'),
              ),
              OutlinedButton.icon(
                onPressed: () => _needHelp(context),
                icon: const Icon(Icons.support_agent),
                label: const I18nText('Need Help'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _label(String s) => switch (s) {
    'watched' => 'Watched',
    'practised' => 'Practised',
    'confident' => 'Confident',
    'need_help' => 'Help requested',
    _ => 'Not started',
  };
}

class _LessonVideo extends StatefulWidget {
  final String url;
  const _LessonVideo({required this.url});
  @override
  State<_LessonVideo> createState() => _LessonVideoState();
}

class _LessonVideoState extends State<_LessonVideo> {
  YoutubePlayerController? controller;
  @override
  void initState() {
    super.initState();
    final id = YoutubePlayerController.convertUrlToId(widget.url);
    if (id != null)
      controller = YoutubePlayerController.fromVideoId(
        videoId: id,
        autoPlay: false,
        params: const YoutubePlayerParams(showFullscreenButton: true),
      );
  }

  @override
  void dispose() {
    controller?.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (controller != null)
      return ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: YoutubePlayer(controller: controller!, aspectRatio: 16 / 9),
      );
    return OutlinedButton.icon(
      onPressed: () async {
        final u = Uri.tryParse(widget.url);
        if (u != null) await launchUrl(u);
      },
      icon: const Icon(Icons.open_in_new),
      label: const I18nText('Open training video'),
    );
  }
}
