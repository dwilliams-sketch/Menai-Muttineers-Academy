import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../../i18n.dart';
import '../../models.dart';
import '../../services/firestore_service.dart';

class CrewScreen extends StatefulWidget {
  final AppUser profile;
  const CrewScreen({super.key, required this.profile});
  @override State<CrewScreen> createState()=>_CrewScreenState();
}
class _CrewScreenState extends State<CrewScreen>{
  final service=FirestoreService();int tab=0;
  @override Widget build(BuildContext context)=>ListView(padding:const EdgeInsets.all(16),children:[
    I18nText('The Crew',style:Theme.of(context).textTheme.headlineSmall),
    const I18nText('A positive little Academy community. Only names, dog names and shared achievements appear here.'),const SizedBox(height:10),
    if(!widget.profile.discoverable)Card(child:Padding(padding:const EdgeInsets.all(14),child:Column(crossAxisAlignment:CrossAxisAlignment.stretch,children:[const I18nText('You are currently hidden from Crew search.'),const SizedBox(height:6),FilledButton.tonal(onPressed:()=>service.updateUserPreferences(widget.profile.id,{'discoverable':true}),child:const I18nText('ALLOW OTHER LEARNERS TO FIND ME'))]))),
    SegmentedButton<int>(segments:const [ButtonSegment(value:0,icon:Icon(Icons.dynamic_feed),label:I18nText('Feed')),ButtonSegment(value:1,icon:Icon(Icons.person_add),label:I18nText('Find Crew')),ButtonSegment(value:2,icon:Icon(Icons.mail),label:I18nText('Requests'))],selected:{tab},onSelectionChanged:(s)=>setState(()=>tab=s.first)),const SizedBox(height:14),
    if(tab==0)_Feed(profile:widget.profile),if(tab==1)_FindCrew(profile:widget.profile),if(tab==2)_Requests(profile:widget.profile),
  ]);
}

class _FriendIds extends StatelessWidget{
  final AppUser profile; final Widget Function(Set<String>) builder; const _FriendIds({required this.profile,required this.builder});
  @override Widget build(BuildContext context){final s=FirestoreService();return StreamBuilder<QuerySnapshot<Map<String,dynamic>>>(stream:s.crewLinksForUser(profile.id),builder:(context,snap){final ids=<String>{profile.id};for(final d in snap.data?.docs??[]){for(final m in List<String>.from(d.data()['members']??[])){ids.add(m);}}return builder(ids);});}
}

class _Feed extends StatelessWidget{final AppUser profile;const _Feed({required this.profile});
  @override Widget build(BuildContext context){final service=FirestoreService();return _FriendIds(profile:profile,builder:(ids)=>StreamBuilder<QuerySnapshot<Map<String,dynamic>>>(stream:service.crewAchievements(),builder:(context,snap){final docs=(snap.data?.docs??[]).where((d)=>ids.contains((d.data()['userId']??'').toString())).toList()..sort((a,b)=>((b.data()['createdAt'] as Timestamp?)?.millisecondsSinceEpoch??0).compareTo((a.data()['createdAt'] as Timestamp?)?.millisecondsSinceEpoch??0));if(docs.isEmpty)return const Card(child:Padding(padding:EdgeInsets.all(16),child:I18nText('When you and your Crew earn shared achievements, they’ll appear here.')));return Column(children:docs.take(50).map((d){final m=d.data();return Card(child:Padding(padding:const EdgeInsets.all(12),child:Column(crossAxisAlignment:CrossAxisAlignment.stretch,children:[I18nText('🏆 ${m['dogName']??'Dog'} earned ${m['title']??'an achievement'}!',style:const TextStyle(fontWeight:FontWeight.bold)),I18nText('${m['displayName']??'Crew mate'} • ${m['description']??''}'),const SizedBox(height:8),StreamBuilder<QuerySnapshot<Map<String,dynamic>>>(stream:service.kudosForAchievement(d.id),builder:(context,k){final count=k.data?.docs.length??0;return Row(children:[I18nText('👏 $count Kudos'),const Spacer(),if((m['userId']??'')!=profile.id)PopupMenuButton<String>(onSelected:(msg)=>service.sendKudos(achievementId:d.id,fromUid:profile.id,fromName:profile.name,toUid:(m['userId']??'').toString(),message:msg),itemBuilder:(_)=>['Great work!','Ahoy, superstar!','Brilliant progress!','Good dog!','Well deserved!'].map((e)=>PopupMenuItem(value:e,child:I18nText('👏 $e'))).toList(),child:const Chip(label:I18nText('SEND KUDOS')))]);})])));}).toList());}));}
}

class _FindCrew extends StatelessWidget{final AppUser profile;const _FindCrew({required this.profile});
  @override Widget build(BuildContext context){final service=FirestoreService();return _FriendIds(profile:profile,builder:(friends)=>StreamBuilder<QuerySnapshot<Map<String,dynamic>>>(stream:service.crewProfiles(),builder:(context,snap){final docs=(snap.data?.docs??[]).where((d)=>d.id!=profile.id).toList();if(docs.isEmpty)return const Card(child:Padding(padding:EdgeInsets.all(16),child:I18nText('No other discoverable learners yet.')));return Column(children:docs.map((d){final m=d.data();final already=friends.contains(d.id);return Card(child:ListTile(leading:CircleAvatar(backgroundImage:(m['dogPhotoUrl']??'').toString().startsWith('http')?NetworkImage(m['dogPhotoUrl']):null,child:(m['dogPhotoUrl']??'').toString().isEmpty?const Icon(Icons.pets):null),title:I18nText('${m['displayName']??'Learner'} & ${m['primaryDogName']??'Dog'}'),subtitle:I18nText(already?'Already in your Crew':'Pre-Flyball Academy'),trailing:already?const Icon(Icons.check_circle):FilledButton.tonal(onPressed:()=>service.sendCrewRequest(fromUid:profile.id,fromName:profile.name,toUid:d.id),child:const I18nText('ADD'))));}).toList());}));}
}

class _Requests extends StatelessWidget{final AppUser profile;const _Requests({required this.profile});
  @override Widget build(BuildContext context){final service=FirestoreService();return StreamBuilder<QuerySnapshot<Map<String,dynamic>>>(stream:service.crewRequestsForUser(profile.id),builder:(context,snap){final docs=(snap.data?.docs??[]).where((d)=>d.data()['status']=='requested').toList();if(docs.isEmpty)return const Card(child:Padding(padding:EdgeInsets.all(16),child:I18nText('No new Crew requests.')));return Column(children:docs.map((d){final m=d.data();return Card(child:ListTile(leading:const Icon(Icons.groups),title:I18nText('${m['fromName']??'A learner'} would like to add you'),trailing:Wrap(spacing:6,children:[IconButton.filled(onPressed:()=>service.respondCrewRequest(requestId:d.id,fromUid:(m['fromUid']??'').toString(),toUid:profile.id,accept:true),icon:const Icon(Icons.check)),IconButton.outlined(onPressed:()=>service.respondCrewRequest(requestId:d.id,fromUid:(m['fromUid']??'').toString(),toUid:profile.id,accept:false),icon:const Icon(Icons.close))])));}).toList());});}
}
