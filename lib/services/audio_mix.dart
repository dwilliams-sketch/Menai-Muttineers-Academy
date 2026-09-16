import 'package:audioplayers/audioplayers.dart';

// Short Academy effects should mix with the background shanty instead of
// taking audio focus and stopping it.
final AudioContext academyMixAudioContext = AudioContextConfig(
  focus: AudioContextConfigFocus.mixWithOthers,
).build();
