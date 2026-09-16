import 'dart:async';
import 'package:audioplayers/audioplayers.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'audio_mix.dart';

class MusicTrack {
  final String id;
  final String title;
  final String source;
  final bool asset;
  const MusicTrack({required this.id, required this.title, required this.source, required this.asset});
}

class AcademyMusicService {
  final AudioPlayer _player = AudioPlayer();
  StreamSubscription<void>? _completeSub;
  List<MusicTrack> _tracks = const [];
  int _index = 0;
  bool _enabled = false;
  double _volume = .22;

  AcademyMusicService() {
    _completeSub = _player.onPlayerComplete.listen((_) => _playNext());
  }

  Future<void> configure({required bool enabled, required double volume}) async {
    _enabled = enabled;
    _volume = volume.clamp(0.0, 1.0);
    await _player.setVolume(_volume);
    if (!_enabled) {
      await _player.stop();
      return;
    }
    if (_tracks.isNotEmpty && _player.state != PlayerState.playing) {
      await _playCurrent();
    }
  }

  Future<void> loadTracks() async {
    final list = <MusicTrack>[
      const MusicTrack(id: 'built_in_1', title: 'The Gentle Tide I', source: 'music/gentle_tide_1.mp3', asset: true),
      const MusicTrack(id: 'built_in_2', title: 'The Gentle Tide II', source: 'music/gentle_tide_2.mp3', asset: true),
    ];
    try {
      final snap = await FirebaseFirestore.instance.collection('musicTracks').where('enabled', isEqualTo: true).get();
      final remote = snap.docs.map((d) {
        final m = d.data();
        return MusicTrack(id: d.id, title: (m['title'] ?? 'Academy Track').toString(), source: (m['url'] ?? '').toString(), asset: false);
      }).where((e) => e.source.startsWith('http')).toList();
      remote.sort((a, b) => a.title.compareTo(b.title));
      list.addAll(remote);
    } catch (_) {}
    _tracks = list;
    if (_index >= _tracks.length) _index = 0;
    if (_enabled) await _playCurrent();
  }

  Future<void> _playCurrent() async {
    if (!_enabled || _tracks.isEmpty) return;
    final track = _tracks[_index];
    try {
      await _player.setVolume(_volume);
      if (track.asset) {
        await _player.play(AssetSource(track.source), ctx: academyMixAudioContext);
      } else {
        await _player.play(UrlSource(track.source), ctx: academyMixAudioContext);
      }
    } catch (_) {
      await _playNext();
    }
  }

  Future<void> _playNext() async {
    if (!_enabled || _tracks.isEmpty) return;
    _index = (_index + 1) % _tracks.length;
    await _playCurrent();
  }

  Future<void> skip() => _playNext();

  Future<void> dispose() async {
    await _completeSub?.cancel();
    await _player.dispose();
  }
}
