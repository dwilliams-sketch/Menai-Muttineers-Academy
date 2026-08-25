import 'package:audioplayers/audioplayers.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:confetti/confetti.dart';
import 'package:flutter/material.dart';
import '../../i18n.dart';
import '../../course_data.dart';
import '../../models.dart';
import '../../services/firestore_service.dart';
import '../../widgets/trophy_art.dart';

class TrophyCabin extends StatelessWidget {
  final AppUser profile;
  final DogProfile dog;
  TrophyCabin({super.key, required this.profile, required this.dog});
  final service = FirestoreService();

  @override
  Widget build(BuildContext context) => Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Color(0xFF4A2A18), Color(0xFF7C4A27), Color(0xFF3B2316)]),
        ),
        child: ListView(padding: const EdgeInsets.all(16), children: [
          Center(child: Column(children: [
            const I18nText('⚓  CAPTAIN’S TROPHY CABIN  ⚓', style: TextStyle(color: Color(0xFFFFE2A2), fontSize: 22, fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            I18nText('${dog.name}’s cabinet', style: const TextStyle(color: Colors.white70, fontSize: 16)),
            const SizedBox(height: 12),
            Container(width: 92, height: 92, decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: const Color(0xFFD7A63E), width: 5), gradient: const RadialGradient(colors: [Color(0xFFBFE6F4), Color(0xFF245B74)])), child: const Center(child: I18nText('⛵', style: TextStyle(fontSize: 44)))),
          ])),
          const SizedBox(height: 16),
          StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
            stream: service.trophiesForDog(dog.id),
            builder: (context, snap) {
              final earned = {for (final d in snap.data?.docs ?? []) d.id: d.data()};
              final definitions = <Map<String, String>>[
                ...courseModules.map((m) => {'id': m.id, 'title': m.trophyTitle, 'artKey': m.artKey}),
                {'id':'first_login','title':'First Steps Aboard','artKey':'login'},
                {'id':'streak_7','title':'Seven Days Aboard','artKey':'streak7'},
                {'id':'streak_14','title':'Sea Legs Streak','artKey':'streak14'},
                {'id':'streak_30','title':'Month on Deck','artKey':'streak30'},
                {'id':'first_lesson','title':'First Lesson Logged','artKey':'lesson'},
                {'id':'first_assessment','title':'Brave Enough to Be Judged','artKey':'assessment'},
                {'id':'first_skill','title':'First Skill Mastered','artKey':'firstskill'},
              ];
              final birthday = earned.entries.where((e)=>e.key.startsWith('birthday_')).map((e)=>{'id':e.key,'title':'Birthday Buccaneer','artKey':'birthday'});
              return _CabinetSection(
                title: 'DOG ACHIEVEMENTS',
                children: [...definitions, ...birthday].map((def) {
                  final data = earned[def['id']];
                  return _TrophySlot(title: data == null ? '???' : (data['title'] ?? def['title']).toString(), artKey: def['artKey']!, locked: data == null, subtitle: data == null ? 'Keep sailing to discover this trophy' : (data['description'] ?? '').toString());
                }).toList(),
              );
            },
          ),
          const SizedBox(height: 16),
          StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
            stream: service.handlerTrophies(profile.id),
            builder: (context, snap) {
              final earned = {for (final d in snap.data?.docs ?? []) d.id: d.data()};
              const defs = [
                {'id':'lights_first','title':'Lantern Lubber','artKey':'lights'},
                {'id':'rolling_first','title':'Rolling Roger','artKey':'rolling'},
                {'id':'rolling_three','title':'Triple Broadside','artKey':'triple'},
                {'id':'rolling_10','title':'Start Line Scallywag','artKey':'rolling10'},
                {'id':'rolling_25','title':'Quickdraw Quartermaster','artKey':'rolling25'},
                {'id':'rolling_50','title':'Cannon-Fire Reflexes','artKey':'rolling50'},
                {'id':'rolling_100','title':'Master of the Lights','artKey':'rolling100'},
                {'id':'too_keen','title':'Too Keen, Captain!','artKey':'too_keen'},
              ];
              return _CabinetSection(title: 'HANDLER TROPHIES', children: defs.map((def){final data=earned[def['id']];return _TrophySlot(title:data==null?'???':(data['title']??def['title']).toString(),artKey:def['artKey']!,locked:data==null,subtitle:data==null?'A hidden handler challenge awaits':(data['description']??'').toString());}).toList());
            },
          ),
        ]),
      );
}

class _CabinetSection extends StatelessWidget {
  final String title;
  final List<Widget> children;
  const _CabinetSection({required this.title, required this.children});
  @override Widget build(BuildContext context)=>Container(
    padding:const EdgeInsets.all(14),
    decoration:BoxDecoration(color:const Color(0xFF2B170E).withValues(alpha:.86),border:Border.all(color:const Color(0xFFB88A47),width:2),borderRadius:BorderRadius.circular(12),boxShadow:const [BoxShadow(color:Colors.black38,blurRadius:8,offset:Offset(0,4))]),
    child:Column(crossAxisAlignment:CrossAxisAlignment.stretch,children:[I18nText(title,textAlign:TextAlign.center,style:const TextStyle(color:Color(0xFFFFD88A),fontWeight:FontWeight.bold,letterSpacing:1.4)),const SizedBox(height:10),LayoutBuilder(builder:(context,c){final w=c.maxWidth;final columns=w>800?5:w>560?4:w>360?3:2;return GridView.count(crossAxisCount:columns,shrinkWrap:true,physics:const NeverScrollableScrollPhysics(),childAspectRatio:.72,crossAxisSpacing:8,mainAxisSpacing:8,children:children);})]),
  );
}

class _TrophySlot extends StatelessWidget {
  final String title,artKey,subtitle; final bool locked;
  const _TrophySlot({required this.title,required this.artKey,required this.locked,required this.subtitle});
  @override Widget build(BuildContext context)=>Container(
    decoration:BoxDecoration(gradient:const LinearGradient(begin:Alignment.topCenter,end:Alignment.bottomCenter,colors:[Color(0xFF7C4B28),Color(0xFF3B2213)]),border:Border.all(color:const Color(0xFF9D6E3C)),borderRadius:BorderRadius.circular(8)),
    child:Padding(padding:const EdgeInsets.all(8),child:Column(mainAxisAlignment:MainAxisAlignment.center,children:[TrophyArt(artKey:artKey,locked:locked,size:78),const SizedBox(height:4),I18nText(title,textAlign:TextAlign.center,maxLines:2,overflow:TextOverflow.ellipsis,style:TextStyle(color:locked?Colors.white54:const Color(0xFFFFE3A5),fontWeight:FontWeight.bold)),const SizedBox(height:3),I18nText(subtitle,textAlign:TextAlign.center,maxLines:3,overflow:TextOverflow.ellipsis,style:TextStyle(color:Colors.white.withValues(alpha:.62),fontSize:11))])));
}

class TrophyRevealDialog extends StatefulWidget {
  final AppUser profile; final DogProfile? dog; final String trophyId; final Map<String,dynamic> trophy; final bool handlerTrophy;
  const TrophyRevealDialog({super.key,required this.profile,required this.dog,required this.trophyId,required this.trophy,this.handlerTrophy=false});
  @override State<TrophyRevealDialog> createState()=>_TrophyRevealDialogState();
}
class _TrophyRevealDialogState extends State<TrophyRevealDialog>{
  final confetti=ConfettiController(duration:const Duration(seconds:2)); final player=AudioPlayer(); final service=FirestoreService(); bool accepted=false,busy=false;
  @override void dispose(){confetti.dispose();player.dispose();super.dispose();}
  Future<void> accept()async{if(busy)return;setState(()=>busy=true);if(widget.handlerTrophy){await service.acceptHandlerTrophy(widget.profile.id,widget.trophyId);}else if(widget.dog!=null){await service.acceptTrophy(widget.dog!.id,widget.trophyId);}if(widget.profile.celebrationSound){try{await player.play(AssetSource('sounds/trophy_chime.wav'));}catch(_){}}confetti.play();if(mounted)setState((){accepted=true;busy=false;});await Future.delayed(const Duration(milliseconds:1700));if(mounted)Navigator.pop(context);}
  @override Widget build(BuildContext context){final title=(widget.trophy['title']??'New Trophy').toString();final desc=(widget.trophy['description']??'').toString();final art=(widget.trophy['artKey']??'firstskill').toString();return Dialog(child:Stack(alignment:Alignment.topCenter,children:[Padding(padding:const EdgeInsets.all(24),child:ConstrainedBox(constraints:const BoxConstraints(maxWidth:440),child:Column(mainAxisSize:MainAxisSize.min,children:[I18nText(accepted?'TROPHY ACCEPTED!':'SOMETHING ARRIVED IN THE CAPTAIN’S CABIN!',style:Theme.of(context).textTheme.headlineSmall,textAlign:TextAlign.center),const SizedBox(height:12),TrophyArt(artKey:art,locked:false,size:150),I18nText(title,style:Theme.of(context).textTheme.titleLarge,textAlign:TextAlign.center),if(desc.isNotEmpty)Padding(padding:const EdgeInsets.only(top:6),child:I18nText(desc,textAlign:TextAlign.center)),const SizedBox(height:18),if(!accepted)SizedBox(width:double.infinity,child:FilledButton.icon(onPressed:busy?null:accept,icon:const Icon(Icons.celebration),label:I18nText(busy?'Opening...':'ACCEPT TROPHY'))),if(!accepted)TextButton(onPressed:()=>Navigator.pop(context),child:const I18nText('Open it later'))]))),IgnorePointer(child:ConfettiWidget(confettiController:confetti,blastDirectionality:BlastDirectionality.explosive,numberOfParticles:32,gravity:.16))]));}
}
