import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../../i18n.dart';
import '../../models.dart';
import '../../services/firestore_service.dart';
import '../../widgets/language_toggle.dart';

class NotificationBell extends StatelessWidget {
  final AppUser profile;
  final Future<void> Function(
    BuildContext context,
    AcademyNotification notification,
  )?
  onOpenNotification;

  const NotificationBell({
    super.key,
    required this.profile,
    this.onOpenNotification,
  });
  @override
  Widget build(BuildContext context) {
    final service = FirestoreService();
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: service.notificationsForUser(profile.id),
      builder: (context, snap) {
        final unread = (snap.data?.docs ?? [])
            .where((d) => d.data()['read'] != true)
            .length;
        return Badge(
          isLabelVisible: unread > 0,
          label: I18nText(unread > 99 ? '99+' : '$unread'),
          child: IconButton(
            tooltip: 'Notifications',
            icon: const Icon(Icons.notifications_outlined),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => NotificationScreen(
                  profile: profile,
                  onOpenNotification: onOpenNotification,
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class NotificationScreen extends StatelessWidget {
  final AppUser profile;
  final Future<void> Function(
    BuildContext context,
    AcademyNotification notification,
  )?
  onOpenNotification;

  NotificationScreen({
    super.key,
    required this.profile,
    this.onOpenNotification,
  });

  final service = FirestoreService();

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: const I18nText('Notifications'),
      actions: [
        LanguageToggle(userId: profile.id),
        TextButton(
          onPressed: () => service.markAllNotificationsRead(profile.id),
          child: const I18nText('Mark all read'),
        ),
      ],
    ),
    body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: service.notificationsForUser(profile.id),
      builder: (context, snap) {
        final docs = [...(snap.data?.docs ?? [])];
        docs.sort((a, b) {
          final at =
              (a.data()['createdAt'] as Timestamp?)?.millisecondsSinceEpoch ??
              0;
          final bt =
              (b.data()['createdAt'] as Timestamp?)?.millisecondsSinceEpoch ??
              0;
          return bt.compareTo(at);
        });
        if (!snap.hasData)
          return const Center(child: CircularProgressIndicator());
        if (docs.isEmpty)
          return const Center(
            child: I18nText('No messages in the ship’s postbox yet.'),
          );
        return ListView(
          padding: const EdgeInsets.all(12),
          children: docs.map((d) {
            final n = AcademyNotification.fromDoc(d);
            return Card(
              color: n.read
                  ? null
                  : Theme.of(context).colorScheme.secondaryContainer
                        .withValues(alpha: .45),
              child: ListTile(
                leading: Icon(_icon(n.type)),
                title: I18nText(
                  n.title,
                  style: TextStyle(
                    fontWeight: n.read ? FontWeight.normal : FontWeight.bold,
                  ),
                ),
                subtitle: I18nText(n.body),
                trailing: n.read ? null : const Icon(Icons.circle, size: 10),
                onTap: () async {
                  await service.markNotificationRead(n.id);

                  final handler = onOpenNotification;
                  if (handler != null) {
                    await handler(context, n);
                  }
                },
              ),
            );
          }).toList(),
        );
      },
    ),
  );

  IconData _icon(String type) => switch (type) {
    'assessment' => Icons.emoji_events,
    'lesson_help' => Icons.chat,
    'one_to_one' => Icons.event_available,
    'account' => Icons.account_balance_wallet,
    'birthday' => Icons.cake,
    'kudos' => Icons.favorite,
    'crew' => Icons.groups,
    'notice' => Icons.campaign,
    'staff_help' => Icons.support_agent,
    'staff_assessment' => Icons.video_library,
    'staff_one_to_one' => Icons.event_available,
    'staff_account' => Icons.payments,
    _ => Icons.notifications,
  };
}
