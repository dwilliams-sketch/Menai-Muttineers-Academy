import 'dart:math';
import 'package:flutter/material.dart';
import '../i18n.dart';
import '../models.dart';

class PirateBackdrop extends StatefulWidget {
  final AppUser profile;
  final Widget child;
  const PirateBackdrop({super.key, required this.profile, required this.child});

  @override
  State<PirateBackdrop> createState() => _PirateBackdropState();
}

class _PirateBackdropState extends State<PirateBackdrop> {
  static const scenes = ['cove', 'deck', 'island', 'parrot', 'cannon', 'harbour'];
  late String visitScene;

  @override
  void initState() {
    super.initState();
    visitScene = scenes[Random().nextInt(scenes.length)];
  }

  @override
  void didUpdateWidget(covariant PirateBackdrop oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.profile.backgroundMode != widget.profile.backgroundMode && widget.profile.backgroundMode == 'rotate') {
      setState(() => visitScene = scenes[Random().nextInt(scenes.length)]);
    }
  }

  String _scene() => widget.profile.backgroundMode == 'fixed' ? widget.profile.backgroundChoice : visitScene;

  @override
  Widget build(BuildContext context) {
    if (!widget.profile.pirateBackgrounds) return widget.child;
    final data = _sceneData(_scene());
    return Stack(children: [
      Positioned.fill(child: DecoratedBox(decoration: BoxDecoration(gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: data.colors)))),
      Positioned(top: 36, left: 18, child: _ghost(data.left, 52)),
      Positioned(top: 115, right: 20, child: _ghost(data.right, 58)),
      Positioned(bottom: 90, left: 34, child: _ghost(data.bottomLeft, 44)),
      Positioned(bottom: 35, right: 30, child: _ghost(data.bottomRight, 48)),
      widget.child,
    ]);
  }

  Widget _ghost(String emoji, double size) => Opacity(opacity: .10, child: I18nText(emoji, style: TextStyle(fontSize: size)));

  _SceneData _sceneData(String key) {
    switch (key) {
      case 'deck': return const _SceneData([Color(0xFFF5EFE5), Color(0xFFE6F0F2)], '⚓', '⛵', '🪢', '🌊');
      case 'island': return const _SceneData([Color(0xFFFFF4D8), Color(0xFFE2F3E8)], '🌴', '🗺️', '🏝️', '💰');
      case 'parrot': return const _SceneData([Color(0xFFF3F7E6), Color(0xFFE8F0F7)], '🦜', '🌴', '⚓', '🐾');
      case 'cannon': return const _SceneData([Color(0xFFF2EEE8), Color(0xFFE7EEF3)], '💣', '🏴‍☠️', '⚓', '💥');
      case 'harbour': return const _SceneData([Color(0xFFE9EEF7), Color(0xFFF2EAF5)], '🌙', '⛵', '⭐', '⚓');
      default: return const _SceneData([Color(0xFFFDF6E3), Color(0xFFE3F2F1)], '🌴', '⛵', '🐚', '🏴‍☠️');
    }
  }
}

class _SceneData {
  final List<Color> colors;
  final String left;
  final String right;
  final String bottomLeft;
  final String bottomRight;
  const _SceneData(this.colors, this.left, this.right, this.bottomLeft, this.bottomRight);
}
