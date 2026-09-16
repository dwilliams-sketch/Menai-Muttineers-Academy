import 'dart:async';
import 'dart:math';
import 'package:audioplayers/audioplayers.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:confetti/confetti.dart';
import 'package:flutter/material.dart';
import '../../i18n.dart';
import 'package:flutter/services.dart';
import '../../course_data.dart';
import '../../models.dart';
import '../../services/firestore_service.dart';
import '../../services/audio_mix.dart';
import 'pirate_fun_screen.dart';

class GamesScreen extends StatefulWidget {
  final AppUser profile;
  final DogProfile dog;
  const GamesScreen({super.key, required this.profile, required this.dog});
  @override State<GamesScreen> createState()=>_GamesScreenState();
}
class _GamesScreenState extends State<GamesScreen>{
  int tab=0;
  @override Widget build(BuildContext context)=>ListView(padding:const EdgeInsets.all(16),children:[
    I18nText('Games & Practice',style:Theme.of(context).textTheme.headlineSmall),
    const I18nText('Useful little training tools with a bit of Muttineers mischief.'),const SizedBox(height:10),
    SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: SegmentedButton<int>(
        segments: const [
          ButtonSegment(value:0,icon:Icon(Icons.traffic),label:I18nText('Start Lights')),
          ButtonSegment(value:1,icon:Icon(Icons.timer),label:I18nText('Training Timer')),
          ButtonSegment(value:2,icon:Icon(Icons.flag),label:I18nText('Pirate Fun')),
        ],
        selected:{tab},
        onSelectionChanged:(s)=>setState(()=>tab=s.first),
      ),
    ),
    const SizedBox(height:14),
    if(tab==0)LightsPractice(profile:widget.profile),
    if(tab==1)TrainingTimer(profile:widget.profile,dog:widget.dog),
    if(tab==2)const PirateFunScreen(),
  ]);
}

class LightsPractice extends StatefulWidget{final AppUser profile;const LightsPractice({super.key,required this.profile});@override State<LightsPractice> createState()=>_LightsPracticeState();}
class _LightsPracticeState extends State<LightsPractice>{
  final service=FirestoreService();final audio=AudioPlayer();final confetti=ConfettiController(duration:const Duration(seconds:2));final timers=<Timer>[];
  int light=0;bool running=false;DateTime? greenAt;double? result;
  @override void dispose(){for(final t in timers)t.cancel();audio.dispose();confetti.dispose();super.dispose();}
  Future<void> go()async{for(final t in timers)t.cancel();timers.clear();final delay=Duration(milliseconds:600+Random().nextInt(1000));final now=DateTime.now();greenAt=now.add(delay+const Duration(seconds:3));setState((){running=true;light=0;result=null;});timers.add(Timer(delay,(){if(mounted)setState(()=>light=1);}));timers.add(Timer(delay+const Duration(seconds:1),(){if(mounted)setState(()=>light=2);}));timers.add(Timer(delay+const Duration(seconds:2),(){if(mounted)setState(()=>light=3);}));timers.add(Timer(delay+const Duration(seconds:3),(){if(mounted)setState(()=>light=4);}));}
  Future<void> stop()async{if(!running||greenAt==null)return;final delta=DateTime.now().difference(greenAt!).inMicroseconds/1000000.0;for(final t in timers)t.cancel();timers.clear();setState((){running=false;result=delta;});final stats=await service.recordLightAttempt(uid:widget.profile.id,deltaSeconds:delta);if(delta>=0&&delta<.005){confetti.play();try{await audio.play(AssetSource('sounds/trophy_chime.wav'), ctx: academyMixAudioContext);}catch(_){}}else if(delta<0&&delta>-.005){try{await audio.play(AssetSource('sounds/aww_chime.wav'), ctx: academyMixAudioContext);}catch(_){}}if(mounted&&stats['rollingStreak']==3){ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content:I18nText('🔥 THREE ROLLING STARTS IN A ROW — Triple Broadside!')));}}
  Color c(int n)=>light==n||(light>n&&n<4)?Colors.red.shade600:Colors.black12;
  @override Widget build(BuildContext context)=>Column(crossAxisAlignment:CrossAxisAlignment.stretch,children:[
    Card(child:Padding(padding:const EdgeInsets.all(16),child:Column(children:[
      I18nText('Flyball Start Lights',style:Theme.of(context).textTheme.titleLarge),const I18nText('Press GO. React to the GREEN light — STOP too early gives a minus time; after green gives a plus time.'),const SizedBox(height:14),
      Container(width:150,padding:const EdgeInsets.all(16),decoration:BoxDecoration(color:Colors.black87,borderRadius:BorderRadius.circular(20)),child:Column(children:[_lamp(c(1)),const SizedBox(height:8),_lamp(c(2)),const SizedBox(height:8),_lamp(c(3)),const SizedBox(height:8),_lamp(light==4?Colors.greenAccent.shade400:Colors.black12)])),
      const SizedBox(height:14),
      if(result!=null)...[I18nText(_display(result!),style:TextStyle(fontSize:48,fontWeight:FontWeight.bold,color:result!<0?Colors.red.shade700:Colors.green.shade700)),I18nText(_message(result!),textAlign:TextAlign.center,style:Theme.of(context).textTheme.titleMedium),const SizedBox(height:10)],
      Row(children:[Expanded(child:FilledButton.icon(onPressed:running?null:go,icon:const Icon(Icons.play_arrow),label:const I18nText('GO'))),const SizedBox(width:10),Expanded(child:FilledButton.tonalIcon(onPressed:running?stop:null,icon:const Icon(Icons.stop),label:const I18nText('STOP')))]),
      ConfettiWidget(confettiController:confetti,blastDirectionality:BlastDirectionality.explosive,numberOfParticles:28,gravity:.15),
    ]))),
    StreamBuilder<DocumentSnapshot<Map<String,dynamic>>>(stream:service.lightStats(widget.profile.id),builder:(context,snap){final m=snap.data?.data()??{};final attempts=(m['attempts']as num?)?.toInt()??0;final rolling=(m['rollingTotal']as num?)?.toInt()??0;final streak=(m['rollingStreak']as num?)?.toInt()??0;final early=(m['early']as num?)?.toInt()??0;final best=(m['bestPositive']as num?)?.toDouble();final sum=(m['sumDelta']as num?)?.toDouble()??0;return Card(child:Padding(padding:const EdgeInsets.all(16),child:Wrap(spacing:22,runSpacing:12,children:[_stat('Attempts','$attempts'),_stat('Rolling starts','$rolling'),_stat('Current streak','$streak'),_stat('Early starts','$early'),_stat('Best',best==null?'—':_display(best)),_stat('Average',attempts==0?'—':_display(sum/attempts))])));}),
    const Card(child:Padding(padding:EdgeInsets.all(14),child:I18nText('A rolling start in this practice game means your reaction is from +0.000 to +0.004 seconds. The display shows two decimals, while the app keeps thousandths internally. A tiny early start can therefore show -0.00 — painfully close!'))),
  ]);
  Widget _lamp(Color color)=>AnimatedContainer(duration:const Duration(milliseconds:120),width:72,height:42,decoration:BoxDecoration(color:color,borderRadius:BorderRadius.circular(22),boxShadow:[if(color!=Colors.black12)BoxShadow(color:color.withValues(alpha:.45),blurRadius:14)]));
  Widget _stat(String a,String b)=>SizedBox(width:125,child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[I18nText(b,style:const TextStyle(fontWeight:FontWeight.bold,fontSize:20)),I18nText(a)]));
  String _display(double v)=>'${v>=0?'+':''}${v.toStringAsFixed(2)}';
  String _message(double v){if(v>=0&&v<.005)return'🎉 ROLLING START! That’s the treasure!';if(v<0&&v>-.005)return'😢 Awww! -0.00 — you could hardly be closer.';if(v<0)return'🏴‍☠️ Too keen, matey! You left before green.';if(v<.05)return'⚡ Cracking reaction!';if(v<.12)return'👍 Good start — keep practising.';return'🎯 Keep your eyes on the lights and have another go.';}
}

class TrainingTimer extends StatefulWidget {
  final AppUser profile;
  final DogProfile dog;
  const TrainingTimer({super.key, required this.profile, required this.dog});

  @override
  State<TrainingTimer> createState() => _TrainingTimerState();
}

class _TrainingTimerState extends State<TrainingTimer> {
  final audio = AudioPlayer();
  final service = FirestoreService();
  Timer? timer;
  int selected = 2;
  int left = 120;
  bool running = false;

  @override
  void dispose() {
    timer?.cancel();
    audio.dispose();
    super.dispose();
  }

  void start() {
    timer?.cancel();
    setState(() {
      left = selected * 60;
      running = true;
    });
    timer = Timer.periodic(const Duration(seconds: 1), (t) async {
      if (left <= 1) {
        t.cancel();
        setState(() {
          left = 0;
          running = false;
        });
        await _alarm();
        if (mounted) _finishDialog();
      } else if (mounted) {
        setState(() => left--);
      }
    });
  }

  Future<void> _alarm() async {
    HapticFeedback.mediumImpact();
    final file = switch (widget.profile.timerSound) {
      'bell' => 'ship_bell.wav',
      'cannon' => 'tiny_cannon.wav',
      'none' => '',
      'parrot' => 'parrot_squawk.wav',
      _ => 'parrot_squawk.wav',
    };
    if (file.isNotEmpty) {
      try {
        await audio.play(AssetSource('sounds/$file'), ctx: academyMixAudioContext);
      } catch (_) {}
    }
  }

  Future<void> _finishDialog() async {
    String result = 'Good';
    String skill = 'General';
    final note = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setLocal) => AlertDialog(
          title: const I18nText('Time, matey! 🦜'),
          content: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: SingleChildScrollView(
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                const I18nText(
                  'Finish on a good one and give your dog a break. Want to save the session to the diary?',
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 10),
                DropdownButtonFormField<String>(
                  isExpanded: true,
                  initialValue: skill,
                  items: ['General', ...courseModules.map((m) => m.title)]
                      .map((e) => DropdownMenuItem(value: e, child: I18nText(e, maxLines: 2, overflow: TextOverflow.ellipsis)))
                      .toList(),
                  onChanged: (v) => setLocal(() => skill = v ?? skill),
                  decoration: const InputDecoration(label: I18nText('Skill')),
                ),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  isExpanded: true,
                  initialValue: result,
                  items: ['Struggled', 'Getting there', 'Good', 'Nailed it!']
                      .map((e) => DropdownMenuItem(value: e, child: I18nText(e)))
                      .toList(),
                  onChanged: (v) => setLocal(() => result = v ?? result),
                  decoration: const InputDecoration(label: I18nText('How did it go?')),
                ),
                const SizedBox(height: 8),
                TextField(controller: note, decoration: const InputDecoration(label: I18nText('Optional note'))),
              ]),
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const I18nText('Not this time')),
            FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const I18nText('SAVE TO DIARY')),
          ],
        ),
      ),
    );
    if (ok == true) {
      await service.addTrainingLog(
        uid: widget.profile.id,
        dogId: widget.dog.id,
        skill: skill,
        result: result,
        note: note.text,
        minutes: selected,
      );
    }
    note.dispose();
  }

  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Column(children: [
                I18nText('Short Training Timer', style: Theme.of(context).textTheme.titleLarge),
                const I18nText('Short, happy sessions are often better than drilling the same exercise.'),
                const SizedBox(height: 14),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  child: I18nText(
                    '${left ~/ 60}:${(left % 60).toString().padLeft(2, '0')}',
                    style: const TextStyle(fontSize: 56, fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(height: 12),
                if (!running)
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    alignment: WrapAlignment.center,
                    children: [1, 2, 3, 5, 10]
                        .map((m) => ChoiceChip(
                              label: I18nText('$m min'),
                              selected: selected == m,
                              onSelected: (_) => setState(() {
                                selected = m;
                                left = m * 60;
                              }),
                            ))
                        .toList(),
                  ),
                const SizedBox(height: 12),
                ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 320),
                  child: SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed: running
                          ? () {
                              timer?.cancel();
                              setState(() => running = false);
                            }
                          : start,
                      icon: Icon(running ? Icons.stop : Icons.play_arrow),
                      label: I18nText(running ? 'STOP TIMER' : 'START TIMER'),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                I18nText('End sound: ${widget.profile.timerSound.toUpperCase()}'),
              ]),
            ),
          ),
          const Card(
            child: Padding(
              padding: EdgeInsets.all(14),
              child: I18nText('Change the timer sound in Settings: Parrot Squawk, Ship’s Bell, Tiny Cannon or None.'),
            ),
          ),
        ],
      );
}
