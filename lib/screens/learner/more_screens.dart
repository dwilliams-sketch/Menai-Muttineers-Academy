import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../../i18n.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../models.dart';
import '../../services/firestore_service.dart';
import '../../widgets/language_toggle.dart';
import '../../services/media_service.dart';
import 'account_screen.dart';
import 'games_screen.dart';
import 'support_screen.dart';

class MoreScreen extends StatelessWidget {
  final AppUser profile; final DogProfile dog;
  const MoreScreen({super.key,required this.profile,required this.dog});
  @override Widget build(BuildContext context){final active=dog.isActive(profile);return ListView(padding:const EdgeInsets.all(16),children:[
    I18nText('More From the Academy',style:Theme.of(context).textTheme.headlineSmall),const SizedBox(height:8),
    if(active)_tile(context,Icons.support_agent,'Training Support','Questions, 1-to-1 sessions and diary',SupportScreen(profile:profile,dog:dog)),
    if(active)_tile(context,Icons.traffic,'Games & Practice','Start Lights and short training timer',GamesScreen(profile:profile,dog:dog)),
    if(!active)Card(child:ListTile(leading:const Icon(Icons.anchor),title:I18nText('${dog.name}’s training tools are anchored'),subtitle:const I18nText('Official training tools stay locked while this dog is paused. Restart the adventure or use the 1-to-1 button on the anchored screen.'))),
    _tile(context,Icons.account_balance_wallet,'Payments & Access','Doubloons, dog access, pause and payment details',AccountScreen(profile:profile,dog:dog)),
    _tile(context,Icons.link,'Follow & Support the Crew','Socials, Easyfundraising, GoFundMe and club links',LinksScreen(profile:profile,dog:dog)),
    _tile(context,Icons.inventory_2,'Muttineers Treasure Chest','Merchandise coming soon',TreasureChestScreen(profile:profile)),
    _tile(context,Icons.manage_accounts,'Profile & Settings','Photos, backgrounds, music and privacy',ProfileSettingsScreen(profile:profile,dog:dog)),
    _tile(context,Icons.feedback_outlined,'Suggest an Improvement','Send feedback or report a problem',FeedbackScreen(profile:profile)),
  ]);}
  Widget _tile(BuildContext context,IconData icon,String title,String subtitle,Widget screen)=>Card(child:ListTile(leading:Icon(icon),title:I18nText(title),subtitle:I18nText(subtitle),trailing:const Icon(Icons.chevron_right),onTap:()=>Navigator.push(context,MaterialPageRoute(builder:(_)=>Scaffold(appBar:AppBar(title:I18nText(title),actions:[LanguageToggle(userId:profile.id)]),body:screen)))));
}

class LinksScreen extends StatelessWidget{
  final AppUser profile;final DogProfile dog;LinksScreen({super.key,required this.profile,required this.dog});final service=FirestoreService();
  Future<void> launch(String url)async{final u=Uri.tryParse(url);if(u!=null&&url.isNotEmpty)await launchUrl(u,mode:LaunchMode.platformDefault);}
  @override Widget build(BuildContext context)=>StreamBuilder<DocumentSnapshot<Map<String,dynamic>>>(
    stream:service.academySettings(),
    builder:(context,academySnap){
      final config=AcademyConfig.fromMap(academySnap.data?.data()??{});
      return StreamBuilder<DocumentSnapshot<Map<String,dynamic>>>(stream:service.linkSettings(),builder:(context,snap){
        final links=AppLinks.fromMap(snap.data?.data()??{});
        final ref=service.paymentReference(dogName:dog.name,memberName:profile.name,suffix:config.paymentReferenceSuffix);
        return ListView(padding:const EdgeInsets.all(16),children:[
          I18nText('Follow the Crew',style:Theme.of(context).textTheme.headlineSmall),
          const I18nText('Keep up with the Muttineers and help support the Academy.'),
          const SizedBox(height:10),
          _link('Facebook',Icons.facebook,links.facebook),_link('Instagram',Icons.camera_alt,links.instagram),_link('TikTok',Icons.music_note,links.tiktok),_link('YouTube',Icons.play_circle,links.youtube),_link('Website',Icons.language,links.website),
          const SizedBox(height:12),I18nText('Support the Crew',style:Theme.of(context).textTheme.titleLarge),_link('Easyfundraising',Icons.volunteer_activism,links.easyfundraising),_link('GoFundMe',Icons.favorite,links.gofundme),
          const SizedBox(height:12),
          Card(child:Padding(padding:const EdgeInsets.all(16),child:Column(crossAxisAlignment:CrossAxisAlignment.stretch,children:[
            I18nText('Bank Transfer / Standing Order',style:Theme.of(context).textTheme.titleLarge),
            const I18nText('Payments happen outside the app. The Academy does not collect your bank or card details.'),
            const SizedBox(height:6),
            const I18nText('1 Doubloon (£5) gives one dog 30 days of Academy access.'),
            const SizedBox(height:8),
            if(links.accountName.isNotEmpty)I18nText('Account: ${links.accountName}'),
            if(links.bankName.isNotEmpty)I18nText('Bank: ${links.bankName}'),
            if(links.sortCode.isNotEmpty)I18nText('Sort code: ${links.sortCode}'),
            if(links.accountNumber.isNotEmpty)I18nText('Account number: ${links.accountNumber}'),
            const SizedBox(height:8),const I18nText('Your reference:',style:TextStyle(fontWeight:FontWeight.bold)),
            Row(children:[Expanded(child:SelectableText(ref,style:Theme.of(context).textTheme.titleLarge)),IconButton(onPressed:(){Clipboard.setData(ClipboardData(text:ref));ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content:I18nText('Reference copied.')));},icon:const Icon(Icons.copy))]),
            if(links.paymentNote.isNotEmpty)I18nText(links.paymentNote),
            if(links.directDebitInfo.isNotEmpty)...[const Divider(),I18nText('Standing order / Direct Debit information',style:Theme.of(context).textTheme.titleMedium),I18nText(links.directDebitInfo)],
          ]))),
        ]);
      });
    },
  );
  Widget _link(String name,IconData icon,String url)=>Card(child:ListTile(leading:Icon(icon),title:I18nText(name),trailing:Icon(url.isEmpty?Icons.hourglass_empty:Icons.open_in_new),subtitle:url.isEmpty?const I18nText('Link coming soon'):null,onTap:url.isEmpty?null:()=>launch(url)));
}

class ProfileSettingsScreen extends StatefulWidget{final AppUser profile;final DogProfile dog;const ProfileSettingsScreen({super.key,required this.profile,required this.dog});@override State<ProfileSettingsScreen> createState()=>_ProfileSettingsScreenState();}
class _ProfileSettingsScreenState extends State<ProfileSettingsScreen>{
  final service=FirestoreService();final media=MediaService();bool uploading=false;
  Future<void> _personPhoto(bool enabled)async{setState(()=>uploading=true);try{final url=await media.pickAndUploadProfile(uid:widget.profile.id,enabled:enabled);if(url!=null)await service.updateUserPreferences(widget.profile.id,{'photoUrl':url});}catch(_){if(mounted)ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content:I18nText('Photo upload is not available yet. Admin may need to enable Firebase Storage.')));}finally{if(mounted)setState(()=>uploading=false);}}
  Future<void> _dogPhoto(bool enabled)async{setState(()=>uploading=true);try{final url=await media.pickAndUploadDog(dogId:widget.dog.id,enabled:enabled);if(url!=null)await service.updateDog(widget.dog.id,{'photoUrl':url});}catch(_){if(mounted)ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content:I18nText('Photo upload is not available yet. Admin may need to enable Firebase Storage.')));}finally{if(mounted)setState(()=>uploading=false);}}
  @override Widget build(BuildContext context)=>StreamBuilder<DocumentSnapshot<Map<String,dynamic>>>(stream:service.featureSettings(),builder:(context,snap){final photoEnabled=snap.data?.data()?['photoUploadsEnabled']==true;return ListView(padding:const EdgeInsets.all(16),children:[
    I18nText('Profile Photos',style:Theme.of(context).textTheme.titleLarge),Card(child:Padding(padding:const EdgeInsets.all(14),child:Column(children:[Row(mainAxisAlignment:MainAxisAlignment.spaceEvenly,children:[_photo(widget.profile.photoUrl,Icons.person),_photo(widget.dog.photoUrl,Icons.pets)]),const SizedBox(height:8),Wrap(spacing:8,children:[OutlinedButton.icon(onPressed:uploading?null:()=>_personPhoto(photoEnabled),icon:const Icon(Icons.person),label:const I18nText('My Photo')),OutlinedButton.icon(onPressed:uploading?null:()=>_dogPhoto(photoEnabled),icon:const Icon(Icons.pets),label:I18nText('${widget.dog.name}’s Photo'))]),if(!photoEnabled)const Padding(padding:EdgeInsets.only(top:8),child:I18nText('Photo upload is currently disabled by Admin. This keeps the Academy on the low-cost setup until cloud photo storage is enabled.'))]))),
    I18nText('Appearance & Sound',style:Theme.of(context).textTheme.titleLarge),
    SwitchListTile(title:const I18nText('Pirate backgrounds'),subtitle:const I18nText('Light pirate scenes behind the app. Turn off for a plain view.'),value:widget.profile.pirateBackgrounds,onChanged:(v)=>service.updateUserPreferences(widget.profile.id,{'pirateBackgrounds':v})),
    ListTile(title:const I18nText('Background style'),trailing:DropdownButton<String>(value:widget.profile.backgroundMode,items:const [DropdownMenuItem(value:'rotate',child:I18nText('Change each visit')),DropdownMenuItem(value:'fixed',child:I18nText('My favourite'))],onChanged:(v){if(v!=null)service.updateUserPreferences(widget.profile.id,{'backgroundMode':v});})),
    if(widget.profile.backgroundMode=='fixed')DropdownButtonFormField<String>(initialValue:widget.profile.backgroundChoice,decoration:const InputDecoration(label: I18nText('Favourite scene')),items:const ['cove','deck','island','parrot','cannon','harbour'].map((e)=>DropdownMenuItem(value:e,child:I18nText(e.toUpperCase()))).toList(),onChanged:(v){if(v!=null)service.updateUserPreferences(widget.profile.id,{'backgroundChoice':v});}),
    SwitchListTile(title:const I18nText('Background shanty music'),subtitle:const I18nText('Loops between Academy tracks. Off by default.'),value:widget.profile.musicEnabled,onChanged:(v)=>service.updateUserPreferences(widget.profile.id,{'musicEnabled':v})),
    ListTile(title:const I18nText('Music volume'),subtitle:Slider(value:widget.profile.musicVolume,min:0,max:.7,divisions:14,onChanged:(v)=>service.updateUserPreferences(widget.profile.id,{'musicVolume':v}))),
    SwitchListTile(title:const I18nText('Trophy celebration sounds'),value:widget.profile.celebrationSound,onChanged:(v)=>service.updateUserPreferences(widget.profile.id,{'celebrationSound':v})),
    SwitchListTile(title:const I18nText('Reduced animation'),subtitle:const I18nText('Use gentler movement and transitions.'),value:widget.profile.reducedMotion,onChanged:(v)=>service.updateUserPreferences(widget.profile.id,{'reducedMotion':v})),
    DropdownButtonFormField<String>(initialValue:widget.profile.timerSound,decoration:const InputDecoration(label: I18nText('Training timer sound')),items:const [DropdownMenuItem(value:'parrot',child:I18nText('🦜 Parrot Squawk')),DropdownMenuItem(value:'bell',child:I18nText('🔔 Ship’s Bell')),DropdownMenuItem(value:'cannon',child:I18nText('💥 Tiny Cannon')),DropdownMenuItem(value:'none',child:I18nText('🔇 None'))],onChanged:(v){if(v!=null)service.updateUserPreferences(widget.profile.id,{'timerSound':v});}),
    const SizedBox(height:16),I18nText('Crew Privacy',style:Theme.of(context).textTheme.titleLarge),SwitchListTile(title:const I18nText('Let other learners find me'),subtitle:const I18nText('They only see your display name and dog name.'),value:widget.profile.discoverable,onChanged:(v)=>service.updateUserPreferences(widget.profile.id,{'discoverable':v})),SwitchListTile(title:const I18nText('Share achievements with my Crew'),value:widget.profile.shareAchievements,onChanged:(v)=>service.updateUserPreferences(widget.profile.id,{'shareAchievements':v})),SwitchListTile(title:const I18nText('Push notifications'),subtitle:const I18nText('Android push works when the Firebase push service is enabled; the in-app bell always works.'),value:widget.profile.pushEnabled,onChanged:(v)=>service.updateUserPreferences(widget.profile.id,{'pushEnabled':v})),
    const SizedBox(height:16),
    _AccountClosureCard(profile:widget.profile),
  ]);});
  Widget _photo(String url,IconData fallback)=>CircleAvatar(radius:48,backgroundImage:url.startsWith('http')?NetworkImage(url):null,child:url.isEmpty?Icon(fallback,size:40):null);
}


class _AccountClosureCard extends StatefulWidget {
  final AppUser profile;
  const _AccountClosureCard({required this.profile});
  @override State<_AccountClosureCard> createState()=>_AccountClosureCardState();
}
class _AccountClosureCardState extends State<_AccountClosureCard>{
  final service=FirestoreService();
  Future<void> _request(AcademyConfig config)async{
    final reason=TextEditingController();
    final confirmed=await showDialog<bool>(context:context,builder:(ctx)=>AlertDialog(
      title:const I18nText('Set Sail on a New Adventure?'),
      content:SizedBox(width:520,child:Column(mainAxisSize:MainAxisSize.min,crossAxisAlignment:CrossAxisAlignment.stretch,children:[
        const I18nText('Are you sure you want to leave this adventure?'),
        const SizedBox(height:8),
        I18nText(config.accountClosureWording),
        const SizedBox(height:10),
        const I18nText('If you only want a break from payments, cancel this and pause your dog instead.'),
        const SizedBox(height:10),
        TextField(controller:reason,maxLines:3,decoration:const InputDecoration(label: I18nText('Optional reason / message to Admin'))),
      ])),
      actions:[TextButton(onPressed:()=>Navigator.pop(ctx,false),child:const I18nText('STAY ABOARD')),FilledButton.tonal(onPressed:()=>Navigator.pop(ctx,true),child:const I18nText('REQUEST TO LEAVE'))],
    ));
    if(confirmed==true){await service.requestAccountClosure(uid:widget.profile.id,name:widget.profile.name,reason:reason.text);if(mounted)ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content:I18nText('Your request has been sent to Captain/Admin. You can cancel it until it is processed.')));}
    reason.dispose();
  }
  @override Widget build(BuildContext context)=>StreamBuilder<DocumentSnapshot<Map<String,dynamic>>>(stream:service.academySettings(),builder:(context,aSnap){final config=AcademyConfig.fromMap(aSnap.data?.data()??{});return StreamBuilder<DocumentSnapshot<Map<String,dynamic>>>(stream:service.accountDeletionRequest(widget.profile.id),builder:(context,snap){final m=snap.data?.data()??{};final status=(m['status']??'').toString();return Card(child:Padding(padding:const EdgeInsets.all(16),child:Column(crossAxisAlignment:CrossAxisAlignment.stretch,children:[
    I18nText('My Academy Account',style:Theme.of(context).textTheme.titleLarge),
    const I18nText('If you need a break, pause a dog from Payments & Access. If you want to leave completely, you can ask us to close your Academy account.'),
    const SizedBox(height:10),
    if(status=='requested'||status=='processing')...[
      I18nText(status=='processing'?'Your account closure request is being processed.':'Your request to leave is waiting for Captain/Admin.',style:const TextStyle(fontWeight:FontWeight.bold)),
      if(status=='requested')OutlinedButton(onPressed:()=>service.cancelAccountClosure(widget.profile.id),child:const I18nText('CANCEL LEAVING REQUEST')),
    ] else FilledButton.tonalIcon(onPressed:()=>_request(config),icon:const Icon(Icons.sailing),label:const I18nText('SET SAIL ON A NEW ADVENTURE')),
  ])));});});
}

class TreasureChestScreen extends StatefulWidget{final AppUser profile;const TreasureChestScreen({super.key,required this.profile});@override State<TreasureChestScreen> createState()=>_TreasureChestScreenState();}
class _TreasureChestScreenState extends State<TreasureChestScreen>{final service=FirestoreService();final selected=<String>{};static const products={'Mugs':Icons.coffee,'Pens':Icons.edit,'Dog Bandanas':Icons.pets,'Real Trophies':Icons.emoji_events,'Stickers':Icons.stars,'Magnets':Icons.push_pin,'Keyrings':Icons.key,'T-shirts & Hoodies':Icons.checkroom};
  @override Widget build(BuildContext context)=>ListView(padding:const EdgeInsets.all(16),children:[I18nText('Menai Muttineers Treasure Chest',style:Theme.of(context).textTheme.headlineSmall),const I18nText('COMING SOON — tell us what treasure you’d actually like to buy.'),const SizedBox(height:12),Wrap(spacing:10,runSpacing:10,children:products.entries.map((e){final picked=selected.contains(e.key);return SizedBox(width:190,child:Card(child:InkWell(onTap:()=>setState(()=>picked?selected.remove(e.key):selected.add(e.key)),child:Padding(padding:const EdgeInsets.all(16),child:Column(children:[Icon(e.value,size:50),I18nText(e.key,textAlign:TextAlign.center,style:const TextStyle(fontWeight:FontWeight.bold)),const I18nText('Coming soon'),Icon(picked?Icons.check_circle:Icons.add_circle_outline)])))));}).toList()),const SizedBox(height:12),FilledButton.icon(onPressed:()=>service.registerMerchInterest(uid:widget.profile.id,name:widget.profile.name,items:selected.toList()),icon:const Icon(Icons.inventory_2),label:const I18nText('REGISTER MY INTEREST'))]);}

class FeedbackScreen extends StatefulWidget{final AppUser profile;const FeedbackScreen({super.key,required this.profile});@override State<FeedbackScreen> createState()=>_FeedbackScreenState();}
class _FeedbackScreenState extends State<FeedbackScreen>{final service=FirestoreService();final msg=TextEditingController();String type='Suggestion';@override void dispose(){msg.dispose();super.dispose();}@override Widget build(BuildContext context)=>ListView(padding:const EdgeInsets.all(16),children:[I18nText('Help us improve the ship',style:Theme.of(context).textTheme.headlineSmall),DropdownButtonFormField<String>(initialValue:type,items:['Suggestion','Problem / bug','Something confusing','Course idea','Other'].map((e)=>DropdownMenuItem(value:e,child:I18nText(e))).toList(),onChanged:(v)=>setState(()=>type=v??type),decoration:const InputDecoration(label: I18nText('Type'))),const SizedBox(height:8),TextField(controller:msg,maxLines:6,decoration:const InputDecoration(label: I18nText('Tell us about it'))),const SizedBox(height:8),FilledButton.icon(onPressed:()async{if(msg.text.trim().isEmpty)return;await service.submitFeedback(uid:widget.profile.id,name:widget.profile.name,type:type,message:msg.text);msg.clear();if(mounted)ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content:I18nText('Thank you — feedback sent to the Captain.')));},icon:const Icon(Icons.send),label:const I18nText('SEND FEEDBACK'))]);}
