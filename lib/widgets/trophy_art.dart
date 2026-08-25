import 'package:flutter/material.dart';
import '../i18n.dart';

class TrophyArt extends StatelessWidget {
  final String artKey;
  final bool locked;
  final double size;
  const TrophyArt({super.key, required this.artKey, required this.locked, this.size = 74});

  IconData _motif() {
    switch (artKey) {
      case 'focus': return Icons.visibility;
      case 'recall': return Icons.bolt;
      case 'tug': return Icons.sports_handball;
      case 'deadball': return Icons.sports_soccer;
      case 'target': return Icons.adjust;
      case 'movement': return Icons.directions_run;
      case 'distraction': case 'distractions': return Icons.psychology_alt;
      case 'ready': return Icons.flag_circle;
      case 'birthday': return Icons.cake;
      case 'login': return Icons.login;
      case 'streak7': case 'streak14': case 'streak30': return Icons.local_fire_department;
      case 'lesson': return Icons.school;
      case 'assessment': return Icons.video_camera_front;
      case 'firstskill': return Icons.star;
      case 'lights': return Icons.traffic;
      case 'rolling': case 'rolling10': case 'rolling25': return Icons.timer;
      case 'triple': return Icons.filter_3;
      case 'rolling50': return Icons.flash_on;
      case 'rolling100': return Icons.workspace_premium;
      case 'too_keen': return Icons.sentiment_dissatisfied;
      default: return Icons.pets;
    }
  }

  @override
  Widget build(BuildContext context) {
    final gold = locked ? Colors.blueGrey.shade300 : const Color(0xFFD7A63E);
    final dark = locked ? Colors.blueGrey.shade500 : const Color(0xFF7B4D13);
    final glow = locked ? Colors.transparent : const Color(0xFFFFE6A4);
    return SizedBox(
      width: size,
      height: size,
      child: Stack(alignment: Alignment.center, children: [
        if (!locked) Container(width: size * .78, height: size * .78, decoration: BoxDecoration(shape: BoxShape.circle, color: glow.withValues(alpha: .35))),
        Positioned(top: size * .10, child: Icon(Icons.emoji_events, size: size * .72, color: gold)),
        Positioned(top: size * .23, child: Icon(_motif(), size: size * .27, color: dark)),
        Positioned(bottom: size * .10, child: Container(width: size * .55, height: size * .10, decoration: BoxDecoration(color: dark, borderRadius: BorderRadius.circular(4)))),
        if (locked) Positioned.fill(child: Center(child: I18nText('?', style: TextStyle(fontSize: size * .30, fontWeight: FontWeight.bold, color: Colors.white.withValues(alpha: .88))))),
      ]),
    );
  }
}
