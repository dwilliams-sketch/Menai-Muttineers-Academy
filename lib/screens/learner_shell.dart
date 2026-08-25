import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../i18n.dart';
import 'package:url_launcher/url_launcher.dart';
import '../course_data.dart';
import '../models.dart';
import '../services/firestore_service.dart';
import '../services/music_service.dart';
import '../widgets/pirate_backdrop.dart';
import '../widgets/language_toggle.dart';
import 'learner/course_screen.dart';
import 'learner/crew_screen.dart';
import 'learner/more_screens.dart';
import 'learner/notification_screen.dart';
import 'learner/support_screen.dart';
import 'learner/trophy_cabin.dart';

class LearnerShell extends StatefulWidget {
  final AppUser profile;
  const LearnerShell({super.key, required this.profile});
  @override State<LearnerShell> createState()=>_LearnerShellState();
}

class _LearnerShellState extends State<LearnerShell>{
  final service=FirestoreService();final music=AcademyMusicService();
  int index=0;String? selectedDogId;String? celebrationDay;bool showingTrophy=false;final shown=<String>{};final dailyDogKeys=<String>{};
  @override void initState(){super.initState();Future.microtask(()async{await music.loadTracks();await music.configure(enabled:widget.profile.musicEnabled,volume:widget.profile.musicVolume);});}
  @override void didUpdateWidget(covariant LearnerShell oldWidget){super.didUpdateWidget(oldWidget);if(oldWidget.profile.musicEnabled!=widget.profile.musicEnabled||oldWidget.profile.musicVolume!=widget.profile.musicVolume){music.configure(enabled:widget.profile.musicEnabled,volume:widget.profile.musicVolume);}}
  @override void dispose(){music.dispose();super.dispose();}

  void _daily(List<DogProfile> dogs,DogProfile dog,bool active){final key='${DateTime.now().year}-${DateTime.now().month}-${DateTime.now().day}';final dogKey='$key:${dog.id}';Future.microtask(()async{if(celebrationDay!=key){celebrationDay=key;await service.ensureDailyCelebrations(user:widget.profile,dogs:dogs);}if(active&&!dailyDogKeys.contains(dogKey)){dailyDogKeys.add(dogKey);await service.recordDailyLoginAndAwards(uid:widget.profile.id,dogId:dog.id,dogName:dog.name,dateOfBirth:dog.dateOfBirth);}});}

  void _pendingDog(DogProfile dog,List<QueryDocumentSnapshot<Map<String,dynamic>>> docs){if(showingTrophy)return;QueryDocumentSnapshot<Map<String,dynamic>>? p;for(final d in docs){if(d.data()['accepted']!=true&&!shown.contains('dog_${d.id}')){p=d;break;}}if(p==null)return;showingTrophy=true;shown.add('dog_${p.id}');WidgetsBinding.instance.addPostFrameCallback((_)async{if(!mounted)return;await showDialog<void>(context:context,barrierDismissible:false,builder:(_)=>TrophyRevealDialog(profile:widget.profile,dog:dog,trophyId:p!.id,trophy:p.data()));if(mounted)setState(()=>showingTrophy=false);});}
  void _pendingHandler(List<QueryDocumentSnapshot<Map<String,dynamic>>> docs){if(showingTrophy)return;QueryDocumentSnapshot<Map<String,dynamic>>? p;for(final d in docs){if(d.data()['accepted']!=true&&!shown.contains('handler_${d.id}')){p=d;break;}}if(p==null)return;showingTrophy=true;shown.add('handler_${p.id}');WidgetsBinding.instance.addPostFrameCallback((_)async{if(!mounted)return;await showDialog<void>(context:context,barrierDismissible:false,builder:(_)=>TrophyRevealDialog(profile:widget.profile,dog:null,trophyId:p!.id,trophy:p.data(),handlerTrophy:true));if(mounted)setState(()=>showingTrophy=false);});}

  @override Widget build(BuildContext context)=>StreamBuilder<QuerySnapshot<Map<String,dynamic>>>(stream:service.dogsForOwner(widget.profile.id),builder:(context,dogSnap){
    if(!dogSnap.hasData)return const Scaffold(body:Center(child:CircularProgressIndicator()));
    final dogs=dogSnap.data!.docs.map(DogProfile.fromDoc).toList();if(dogs.isEmpty)return const Scaffold(body:Center(child:I18nText('No dog profile found. Please contact the Captain.')));
    selectedDogId ??= dogs.first.id;if(!dogs.any((d)=>d.id==selectedDogId))selectedDogId=dogs.first.id;final dog=dogs.firstWhere((d)=>d.id==selectedDogId);
    final status=dog.effectiveStatus(widget.profile);final active=status=='active';_daily(dogs,dog,active);
    return StreamBuilder<QuerySnapshot<Map<String,dynamic>>>(stream:service.trophiesForDog(dog.id),builder:(context,tSnap){if(tSnap.hasData)_pendingDog(dog,tSnap.data!.docs);return StreamBuilder<QuerySnapshot<Map<String,dynamic>>>(stream:service.handlerTrophies(widget.profile.id),builder:(context,hSnap){if(hSnap.hasData)_pendingHandler(hSnap.data!.docs);
      final pages=<Widget>[
        active?LearnerHome(profile:widget.profile,dog:dog,onGoTraining:()=>setState(()=>index=1)):PausedAdventureScreen(profile:widget.profile,dog:dog),
        active?CourseScreen(profile:widget.profile,dog:dog):PausedAdventureScreen(profile:widget.profile,dog:dog),
        active?TrophyCabin(profile:widget.profile,dog:dog):PausedAdventureScreen(profile:widget.profile,dog:dog),
        CrewScreen(profile:widget.profile),
        MoreScreen(profile:widget.profile,dog:dog),
      ];
      return PirateBackdrop(profile:widget.profile,child:Scaffold(
        backgroundColor:Colors.transparent,
        appBar:AppBar(
          backgroundColor:Theme.of(context).colorScheme.surface.withValues(alpha:.90),
          title: dogs.length == 1
              ? I18nText('${dog.name} • Academy')
              : DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: dog.id,
                    items: dogs
                        .map(
                          (d) => DropdownMenuItem(
                            value: d.id,
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  d.effectiveStatus(widget.profile) == 'active'
                                      ? Icons.pets
                                      : Icons.anchor,
                                  size: 18,
                                ),
                                const SizedBox(width: 7),
                                I18nText(d.name),
                              ],
                            ),
                          ),
                        )
                        .toList(),
                    onChanged: (v) => setState(() => selectedDogId = v),
                  ),
                ),
          actions:[LanguageToggle(userId: widget.profile.id), NotificationBell(profile:widget.profile),PopupMenuButton<String>(onSelected:(v){if(v=='skip')music.skip();if(v=='logout')FirebaseAuth.instance.signOut();},itemBuilder:(_)=>[if(widget.profile.musicEnabled)const PopupMenuItem(value:'skip',child:I18nText('♪ Skip music track')),const PopupMenuItem(value:'logout',child:I18nText('Sign out'))])],
        ),
        body:AnimatedSwitcher(duration:widget.profile.reducedMotion?Duration.zero:const Duration(milliseconds:260),child:KeyedSubtree(key:ValueKey('${index}_${dog.id}_${status}'),child:pages[index])),
        bottomNavigationBar:NavigationBar(selectedIndex:index,labelBehavior:NavigationDestinationLabelBehavior.onlyShowSelected,onDestinationSelected:(v)=>setState(()=>index=v),destinations:[
          NavigationDestination(icon:const Icon(Icons.home_outlined),selectedIcon:const Icon(Icons.home),label:tr('Home')),
          NavigationDestination(icon:const Icon(Icons.map_outlined),selectedIcon:const Icon(Icons.map),label:tr('Training')),
          NavigationDestination(icon:const Icon(Icons.emoji_events_outlined),selectedIcon:const Icon(Icons.emoji_events),label:tr('Trophies')),
          NavigationDestination(icon:const Icon(Icons.groups_outlined),selectedIcon:const Icon(Icons.groups),label:tr('The Crew')),
          NavigationDestination(icon:const Icon(Icons.menu),selectedIcon:const Icon(Icons.menu_open),label:tr('More')),
        ]),
      ));
    });});
  });
}

class LearnerHome extends StatelessWidget{
  final AppUser profile;final DogProfile dog;final VoidCallback onGoTraining;LearnerHome({super.key,required this.profile,required this.dog,required this.onGoTraining});final service=FirestoreService();
  Future<void> launch(String url)async{final u=Uri.tryParse(url);if(u!=null&&url.isNotEmpty)await launchUrl(u);}
  @override Widget build(BuildContext context)=>ListView(padding:const EdgeInsets.all(16),children:[
    I18nText('Ahoy ${profile.name} & ${dog.name}!',style:Theme.of(context).textTheme.headlineSmall),const I18nText('Welcome to your Home Deck.'),const SizedBox(height:10),
    StreamBuilder<QuerySnapshot<Map<String,dynamic>>>(stream:service.notificationsForUser(profile.id),builder:(context,n){final unread=(n.data?.docs??[]).where((d)=>d.data()['read']!=true).length;return unread>0?Card(color:Theme.of(context).colorScheme.secondaryContainer,child:ListTile(leading:const Icon(Icons.notifications_active),title:I18nText('$unread new message${unread==1?'':'s'} aboard'),subtitle:const I18nText('Tap the bell at the top to open your postbox.'))):const SizedBox.shrink();}),
    StreamBuilder<QuerySnapshot<Map<String,dynamic>>>(stream:service.trophiesForDog(dog.id),builder:(context,snap){final docs=snap.data?.docs??[];final skills=docs.where((d)=>courseModules.any((m)=>m.id==d.id)).length;final progress=(skills/courseModules.length).clamp(0.0,1.0);return Card(child:Padding(padding:const EdgeInsets.all(16),child:Column(crossAxisAlignment:CrossAxisAlignment.stretch,children:[Row(children:[Expanded(child:I18nText('Your Academy Voyage',style:Theme.of(context).textTheme.titleLarge)),I18nText('${(progress*100).round()}%')]),const SizedBox(height:8),LinearProgressIndicator(value:progress),const SizedBox(height:5),I18nText('$skills of ${courseModules.length} Key Skills trainer verified'),const SizedBox(height:10),FilledButton.icon(onPressed:onGoTraining,icon:const Icon(Icons.sailing),label:const I18nText('CONTINUE ADVENTURE'))])));}),
    StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: service.settings(),
      builder: (context, s) {
        final m = s.data?.data() ?? {};
        final welcome = (m['welcomeMessage'] ?? '').toString();
        final when = (m['meetWhen'] ?? '').toString();
        final topic = (m['meetTopic'] ?? '').toString();
        final url = (m['meetUrl'] ?? '').toString();

        return Column(
          children: [
            if (welcome.isNotEmpty)
              Card(
                child: ListTile(
                  leading: const Icon(Icons.campaign),
                  title: const I18nText('Captain’s Message'),
                  subtitle: I18nText(welcome),
                ),
              ),
            if (when.isNotEmpty || topic.isNotEmpty)
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      I18nText(
                        'Weekly Crew Catch-Up',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      if (when.isNotEmpty) I18nText(when),
                      if (topic.isNotEmpty) I18nText('This week: $topic'),
                      if (url.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: FilledButton.icon(
                            onPressed: () => launch(url),
                            icon: const Icon(Icons.video_call),
                            label: const I18nText('JOIN GOOGLE MEET'),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
          ],
        );
      },
    ),
    StreamBuilder<QuerySnapshot<Map<String,dynamic>>>(stream:service.notices(),builder:(context,snap){final docs=[...(snap.data?.docs??[])]..sort((a,b)=>((b.data()['createdAt'] as Timestamp?)?.millisecondsSinceEpoch??0).compareTo((a.data()['createdAt'] as Timestamp?)?.millisecondsSinceEpoch??0));if(docs.isEmpty)return const SizedBox.shrink();return Column(crossAxisAlignment:CrossAxisAlignment.stretch,children:[I18nText('Notices',style:Theme.of(context).textTheme.titleLarge),...docs.take(3).map((d){final m=d.data();final cy=LanguageController.current=='cy';final noticeTitle=(cy?(m['titleCy']??m['title']):(m['titleEn']??m['title'])).toString();final noticeMessage=(cy?(m['messageCy']??m['message']):(m['messageEn']??m['message'])).toString();return Card(child:ListTile(leading:Icon((m['priority']??'')=='important'?Icons.priority_high:Icons.info_outline),title:Text(noticeTitle),subtitle:Text(noticeMessage)));})]);}),
    _QuickStats(profile:profile,dog:dog),
  ]);
}

class _QuickStats extends StatelessWidget{final AppUser profile;final DogProfile dog;_QuickStats({required this.profile,required this.dog});final service=FirestoreService();@override Widget build(BuildContext context)=>Card(child:Padding(padding:const EdgeInsets.all(14),child:Wrap(spacing:24,runSpacing:12,children:[_s('Login streak','${profile.loginStreak} days'),_s('Academy credit','£${profile.academyCredit.toStringAsFixed(2)}'),if(dog.accessUntil!=null)_s('Access until','${dog.accessUntil!.day}/${dog.accessUntil!.month}/${dog.accessUntil!.year}')])));Widget _s(String a,String b)=>SizedBox(width:150,child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[I18nText(b,style:const TextStyle(fontWeight:FontWeight.bold,fontSize:18)),I18nText(a)]));}

class PausedAdventureScreen extends StatelessWidget{
  final AppUser profile;final DogProfile dog;PausedAdventureScreen({super.key,required this.profile,required this.dog});final service=FirestoreService();
  @override Widget build(BuildContext context){final status=dog.effectiveStatus(profile);return Center(child:SingleChildScrollView(padding:const EdgeInsets.all(20),child:ConstrainedBox(constraints:const BoxConstraints(maxWidth:620),child:Card(child:Padding(padding:const EdgeInsets.all(24),child:Column(children:[const Icon(Icons.anchor,size:70),const SizedBox(height:10),I18nText(status=='awaiting'?'${dog.name} is waiting to set sail':'${dog.name}’s adventure is currently anchored',style:Theme.of(context).textTheme.headlineSmall,textAlign:TextAlign.center),const SizedBox(height:8),I18nText(status=='awaiting'?'This dog needs Academy access before training progress, assessments, trophies and certificates unlock.':'All progress, trophies and training history are safely stored. Course lessons and official achievements stay locked while this dog is paused.',textAlign:TextAlign.center),if(dog.accessUntil!=null)Padding(padding:const EdgeInsets.only(top:8),child:I18nText('Last/current paid voyage: ${dog.accessUntil!.day}/${dog.accessUntil!.month}/${dog.accessUntil!.year}')),const SizedBox(height:18),SizedBox(width:double.infinity,child:FilledButton.icon(onPressed:()async{await service.requestRestart(uid:profile.id,dogId:dog.id,dogName:dog.name);if(context.mounted)ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content:I18nText('Restart request sent to Admin.')));},icon:const Icon(Icons.play_circle),label:const I18nText('RESTART ADVENTURE'))),const SizedBox(height:8),SizedBox(width:double.infinity,child:OutlinedButton.icon(onPressed:()=>Navigator.push(context,MaterialPageRoute(builder:(_)=>Scaffold(appBar:AppBar(title:const I18nText('Request a 1-to-1'),actions:[LanguageToggle(userId:profile.id)]),body:ListView(padding:const EdgeInsets.all(16),children:[OneToOnePanel(profile:profile,dog:dog)])))),icon:const Icon(Icons.support_agent),label:const I18nText('REQUEST A 1-to-1'))),const SizedBox(height:8),const I18nText('1-to-1 sessions are separate paid training sessions and remain available whether Academy access is active or paused.',textAlign:TextAlign.center)]))))));}
}
