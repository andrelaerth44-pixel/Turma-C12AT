import 'dart:async';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'core/theme/app_theme.dart';
import 'services/auth_service.dart';
import 'services/ai_service.dart';

const supabaseUrl = 'https://fmqdyaoqttvubynmjbxt.supabase.co';
const supabaseKey = 'sb_publishable_cQwCwWG9t7NncfJXpF6tcg_AsKPktmL';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Supabase.initialize(url: supabaseUrl, anonKey: supabaseKey);
  runApp(const TurmaC12ATApp());
}

final client = Supabase.instance.client;
final auth = AuthService(client);
final ai = SupabaseAIService(client);

class TurmaC12ATApp extends StatelessWidget {
  const TurmaC12ATApp({super.key});
  @override
  Widget build(BuildContext context) => MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'Turma C12AT',
        theme: AppTheme.light(),
        darkTheme: AppTheme.dark(),
        themeMode: ThemeMode.system,
        home: const AuthGate(),
      );
}

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});
  @override
  Widget build(BuildContext context) => StreamBuilder<AuthState>(
        stream: client.auth.onAuthStateChange,
        builder: (_, snap) {
          if (snap.connectionState == ConnectionState.waiting) return const _Loading();
          if (client.auth.currentSession == null) return const LoginPage();
          return const ClassGate();
        },
      );
}

class ClassGate extends StatefulWidget { const ClassGate({super.key}); @override State<ClassGate> createState() => _ClassGateState(); }
class _ClassGateState extends State<ClassGate> {
  late Future<List<Map<String, dynamic>>> future;
  @override void initState() { super.initState(); future = auth.memberships(); }
  void refresh() => setState(() => future = auth.memberships());
  @override Widget build(BuildContext context) => FutureBuilder<List<Map<String, dynamic>>>(
        future: future,
        builder: (_, s) {
          if (!s.hasData) return const _Loading();
          final memberships = s.data!;
          if (memberships.isEmpty) return JoinClassPage(onChanged: refresh);
          return AppShell(membership: memberships.first);
        },
      );
}

class LoginPage extends StatefulWidget { const LoginPage({super.key}); @override State<LoginPage> createState() => _LoginPageState(); }
class _LoginPageState extends State<LoginPage> {
  final email = TextEditingController(); final password = TextEditingController(); final name = TextEditingController();
  bool register = false, busy = false;
  Future<void> submit() async {
    if (email.text.trim().isEmpty || password.text.length < 6 || (register && name.text.trim().isEmpty)) { _toast('Preencha os campos corretamente.'); return; }
    setState(() => busy = true);
    try { if (register) { final r = await auth.signUp(email.text, password.text, name.text); if (r.session == null && mounted) _toast('Conta criada. Confirme o e-mail para continuar.'); } else { await auth.signIn(email.text, password.text); } }
    catch (e) { if (mounted) _toast(_error(e)); }
    finally { if (mounted) setState(() => busy = false); }
  }
  @override Widget build(BuildContext context) => Scaffold(body: SafeArea(child: Center(child: SingleChildScrollView(padding: const EdgeInsets.all(24), child: ConstrainedBox(constraints: const BoxConstraints(maxWidth: 460), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
    const _Brand(), const SizedBox(height: 32), Text(register ? 'Criar conta' : 'Entrar', style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w800)), const SizedBox(height: 8), Text(register ? 'Crie o seu acesso à turma.' : 'Entre para continuar na sua turma.'), const SizedBox(height: 26),
    if (register) ...[TextField(controller: name, textInputAction: TextInputAction.next, decoration: const InputDecoration(labelText: 'Nome completo', prefixIcon: Icon(Icons.person_outline))), const SizedBox(height: 12)],
    TextField(controller: email, keyboardType: TextInputType.emailAddress, decoration: const InputDecoration(labelText: 'E-mail', prefixIcon: Icon(Icons.mail_outline))), const SizedBox(height: 12), TextField(controller: password, obscureText: true, decoration: const InputDecoration(labelText: 'Palavra-passe', prefixIcon: Icon(Icons.lock_outline))), const SizedBox(height: 18),
    SizedBox(width: double.infinity, child: FilledButton.icon(onPressed: busy ? null : submit, icon: busy ? const SizedBox(width: 18,height:18,child:CircularProgressIndicator(strokeWidth:2)) : const Icon(Icons.arrow_forward_rounded), label: Text(register ? 'Criar conta' : 'Entrar'))), const SizedBox(height: 10),
    SizedBox(width: double.infinity, child: OutlinedButton.icon(onPressed: busy ? null : () async { try { await auth.signInWithGoogle(); } catch(e) { _toast(_error(e)); } }, icon: const Icon(Icons.account_circle_outlined), label: const Text('Continuar com Google'))), const SizedBox(height: 14),
    Center(child: TextButton(onPressed: () => setState(() => register = !register), child: Text(register ? 'Já tenho uma conta' : 'Criar uma conta'))),
  ]))))));
}

class JoinClassPage extends StatefulWidget { const JoinClassPage({super.key, required this.onChanged}); final VoidCallback onChanged; @override State<JoinClassPage> createState()=>_JoinClassPageState(); }
class _JoinClassPageState extends State<JoinClassPage> {
  final code=TextEditingController(); final name=TextEditingController(); final description=TextEditingController(); final institution=TextEditingController(); final year=TextEditingController(); bool create=false,busy=false;
  Future<void> run() async { setState(()=>busy=true); try { if(create){ await auth.createClass(name:name.text,description:description.text,institution:institution.text,schoolYear:year.text); } else { await auth.requestJoin(code.text); _toast('Pedido enviado. Aguarde a aprovação do administrador.'); } widget.onChanged(); } catch(e){_toast(_error(e));} finally{if(mounted)setState(()=>busy=false);} }
  @override Widget build(BuildContext context)=>Scaffold(body:SafeArea(child:Center(child:SingleChildScrollView(padding:const EdgeInsets.all(24),child:ConstrainedBox(constraints:const BoxConstraints(maxWidth:520),child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
    const _Brand(),const SizedBox(height:32),Text(create?'Criar turma':'Entrar na turma',style:Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight:FontWeight.w800)),const SizedBox(height:8),Text(create?'Crie o espaço coletivo da sua turma.':'Use o código fornecido pelo administrador.'),const SizedBox(height:24),
    if(create)...[TextField(controller:name,decoration:const InputDecoration(labelText:'Nome da turma',prefixIcon:Icon(Icons.groups_outlined))),const SizedBox(height:12),TextField(controller:description,decoration:const InputDecoration(labelText:'Descrição opcional')),const SizedBox(height:12),TextField(controller:institution,decoration:const InputDecoration(labelText:'Instituição opcional')),const SizedBox(height:12),TextField(controller:year,decoration:const InputDecoration(labelText:'Ano letivo',prefixIcon:Icon(Icons.calendar_today_outlined))),] else TextField(controller:code,textCapitalization:TextCapitalization.characters,decoration:const InputDecoration(labelText:'Código de convite',prefixIcon:Icon(Icons.key_outlined))),
    const SizedBox(height:18),SizedBox(width:double.infinity,child:FilledButton.icon(onPressed:busy?null:run,icon:busy?const SizedBox(width:18,height:18,child:CircularProgressIndicator(strokeWidth:2)):Icon(create?Icons.add_rounded:Icons.login_rounded),label:Text(create?'Criar turma':'Pedir entrada'))),const SizedBox(height:8),Center(child:TextButton(onPressed:busy?null:()=>setState(()=>create=!create),child:Text(create?'Tenho um código de convite':'Sou administrador e quero criar a turma'))),Center(child:TextButton(onPressed:auth.signOut,child:const Text('Sair da conta'))),
  ]))))));
}

class AppShell extends StatefulWidget { const AppShell({super.key,required this.membership}); final Map<String,dynamic> membership; @override State<AppShell> createState()=>_AppShellState(); }
class _AppShellState extends State<AppShell> {
  int index=0; late String classId; late Map<String,dynamic> cls;
  @override void initState(){super.initState();classId=widget.membership['class_id'].toString();cls=Map<String,dynamic>.from(widget.membership['classes'] as Map);}
  @override Widget build(BuildContext context){final pages=[HomePage(classId:classId,cls:cls,onOpen:(i)=>setState(()=>index=i)),ChatPage(classId:classId),MaterialsPage(classId:classId),StudyPage(classId:classId),ProfilePage(cls:cls)];return Scaffold(body:SafeArea(child:AnimatedSwitcher(duration:const Duration(milliseconds:220),child:pages[index])),bottomNavigationBar:NavigationBar(selectedIndex:index,onDestinationSelected:(v)=>setState(()=>index=v),destinations:const[NavigationDestination(icon:Icon(Icons.home_outlined),selectedIcon:Icon(Icons.home_rounded),label:'Início'),NavigationDestination(icon:Icon(Icons.forum_outlined),selectedIcon:Icon(Icons.forum_rounded),label:'Conversa'),NavigationDestination(icon:Icon(Icons.folder_outlined),selectedIcon:Icon(Icons.folder_rounded),label:'Materiais'),NavigationDestination(icon:Icon(Icons.school_outlined),selectedIcon:Icon(Icons.school_rounded),label:'Estudar'),NavigationDestination(icon:Icon(Icons.person_outline),selectedIcon:Icon(Icons.person_rounded),label:'Perfil')]));}
}

class HomePage extends StatelessWidget { const HomePage({super.key,required this.classId,required this.cls,required this.onOpen}); final String classId; final Map<String,dynamic> cls; final ValueChanged<int> onOpen;
  Future<Map<String,int>> stats() async {final m=await client.from('messages').select('id').eq('class_id',classId);final f=await client.from('materials').select('id').eq('class_id',classId);final u=await client.from('class_members').select('id').eq('class_id',classId).eq('status','approved');return {'messages':m.length,'materials':f.length,'members':u.length};}
  @override Widget build(BuildContext context)=>FutureBuilder<Map<String,int>>(future:stats(),builder:(_,s){final x=s.data??{};return CustomScrollView(physics:const BouncingScrollPhysics(),slivers:[SliverPadding(padding:const EdgeInsets.fromLTRB(20,18,20,28),sliver:SliverList(delegate:SliverChildListDelegate([
    Row(children:[Expanded(child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[Text(cls['name']??'Turma C12AT',style:Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight:FontWeight.w800,letterSpacing:-1)),const SizedBox(height:5),Text(cls['description']??'Tudo da turma, num só lugar')])) ,IconButton(onPressed:(){},icon:const Icon(Icons.notifications_none_rounded))]),const SizedBox(height:22),
    Surface(padding:const EdgeInsets.all(22),child:Row(children:[Container(width:56,height:56,decoration:BoxDecoration(shape:BoxShape.circle,color:Theme.of(context).colorScheme.primaryContainer),child:const Icon(Icons.groups_rounded,size:28)),const SizedBox(width:16),Expanded(child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[Text('A turma inteira dentro de um único app',style:Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight:FontWeight.w800)),const SizedBox(height:6),const Text('Converse, partilhe materiais e estude juntos.',style:TextStyle(height:1.35))]))])),const SizedBox(height:20),Text('Hoje na turma',style:Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight:FontWeight.w800)),const SizedBox(height:10),Row(children:[Expanded(child:_Stat(icon:Icons.forum_outlined,value:'${x['messages']??0}',label:'mensagens')),const SizedBox(width:10),Expanded(child:_Stat(icon:Icons.description_outlined,value:'${x['materials']??0}',label:'materiais')),const SizedBox(width:10),Expanded(child:_Stat(icon:Icons.groups_outlined,value:'${x['members']??0}',label:'membros'))]),const SizedBox(height:16),
    _SectionButton(icon:Icons.forum_outlined,title:'Abrir conversa',subtitle:'Fale com toda a turma',onTap:()=>onOpen(1)),const SizedBox(height:10),_SectionButton(icon:Icons.folder_outlined,title:'Materiais',subtitle:'Aceda aos ficheiros da turma',onTap:()=>onOpen(2)),const SizedBox(height:10),_SectionButton(icon:Icons.auto_awesome_outlined,title:'Estudar com IA',subtitle:'Resumos, perguntas e mapas mentais',onTap:()=>onOpen(3)),
  ]))) ]);});}
}

class ChatPage extends StatefulWidget { const ChatPage({super.key,required this.classId}); final String classId; @override State<ChatPage> createState()=>_ChatPageState(); }
class _ChatPageState extends State<ChatPage>{final input=TextEditingController();final scroll=ScrollController();List<Map<String,dynamic>> items=[];bool loading=true,sending=false;RealtimeChannel? channel;
  @override void initState(){super.initState();load();channel=client.channel('messages-${widget.classId}').onPostgresChanges(event:PostgresChangeEvent.all,schema:'public',table:'messages',filter:PostgresChangeFilter(type:PostgresChangeFilterType.eq,column:'class_id',value:widget.classId),callback:(_){load()}).subscribe();}
  Future<void> load()async{try{final rows=await client.from('messages').select('*, profiles!messages_sender_id_fkey(id,full_name,avatar_url)').eq('class_id',widget.classId).isFilter('deleted_at',null).order('created_at');if(mounted)setState(()=>items=List<Map<String,dynamic>>.from(rows));}catch(e){if(mounted)_toast(_error(e));}finally{if(mounted)setState(()=>loading=false);}}
  Future<void> send()async{final text=input.text.trim();if(text.isEmpty||sending)return;setState(()=>sending=true);try{await client.from('messages').insert({'class_id':widget.classId,'sender_id':client.auth.currentUser!.id,'content':text,'message_type':'text'});input.clear();await load();}catch(e){_toast(_error(e));}finally{if(mounted)setState(()=>sending=false);}}
  @override void dispose(){channel?.unsubscribe();input.dispose();scroll.dispose();super.dispose();}
  @override Widget build(BuildContext context)=>Column(children:[Padding(padding:const EdgeInsets.fromLTRB(18,14,18,10),child:Row(children:[Text('Conversa',style:Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight:FontWeight.w800)),const Spacer(),IconButton(onPressed:load,icon:const Icon(Icons.refresh_rounded))])),Expanded(child:loading?const _Loading():items.isEmpty?const _Empty(icon:Icons.forum_outlined,title:'Ainda não há mensagens',body:'Comece a conversa com a turma.'):ListView.builder(controller:scroll,padding:const EdgeInsets.fromLTRB(16,4,16,18),itemCount:items.length,itemBuilder:(_,i)=>_Message(data:items[i],own:items[i]['sender_id']==client.auth.currentUser!.id,onDelete:()=>client.from('messages').update({'deleted_at':DateTime.now().toIso8601String()}).eq('id',items[i]['id']).then((_)=>load())))),Padding(padding:const EdgeInsets.fromLTRB(12,8,12,12),child:Surface(padding:const EdgeInsets.symmetric(horizontal:8,vertical:4),radius:24,child:Row(children:[IconButton(onPressed:()async{final r=await FilePicker.platform.pickFiles();if(r!=null)_toast('Ficheiro selecionado: ${r.files.single.name}. Envio de anexos será ligado ao Storage nesta conversa.');},icon:const Icon(Icons.attach_file_rounded)),Expanded(child:TextField(controller:input,minLines:1,maxLines:5,decoration:const InputDecoration(hintText:'Escreva para a turma',filled:false,border:InputBorder.none))),IconButton(onPressed:sending?null:send,icon:Icon(sending?Icons.hourglass_top_rounded:Icons.send_rounded))])))]);
}

class MaterialsPage extends StatefulWidget { const MaterialsPage({super.key,required this.classId}); final String classId; @override State<MaterialsPage> createState()=>_MaterialsPageState(); }
class _MaterialsPageState extends State<MaterialsPage>{List<Map<String,dynamic>> rows=[];bool loading=true;@override void initState(){super.initState();load();}Future<void>load()async{try{final r=await client.from('materials').select('*, profiles!materials_uploaded_by_fkey(id,full_name)').eq('class_id',widget.classId).order('created_at',ascending:false);if(mounted)setState(()=>rows=List<Map<String,dynamic>>.from(r));}catch(e){_toast(_error(e));}finally{if(mounted)setState(()=>loading=false);}}Future<void>add()async{final p=await FilePicker.platform.pickFiles(withData:true);if(p==null||p.files.single.bytes==null)return;final f=p.files.single;try{final u=client.auth.currentUser!;final path='${u.id}/${DateTime.now().millisecondsSinceEpoch}_${f.name}';final mime=f.extension=='pdf'?'application/pdf':'application/octet-stream';final bucket=f.extension=='pdf'?'documents':'materials';await client.storage.from(bucket).uploadBinary(path,f.bytes!,fileOptions:FileOptions(contentType:mime));final a=await client.from('attachments').insert({'file_name':f.name,'file_url':path,'file_type':'material','file_size':f.size,'mime_type':mime}).select().single();await client.from('materials').insert({'class_id':widget.classId,'uploaded_by':u.id,'attachment_id':a['id'],'title':f.name,'processing_status':'PENDING'});await load();}catch(e){_toast(_error(e));}}
@override Widget build(BuildContext context)=>Column(children:[Padding(padding:const EdgeInsets.fromLTRB(18,14,18,10),child:Row(children:[Text('Materiais',style:Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight:FontWeight.w800)),const Spacer(),FilledButton.tonalIcon(onPressed:add,icon:const Icon(Icons.upload_file_rounded),label:const Text('Adicionar'))])),Expanded(child:loading?const _Loading():rows.isEmpty?const _Empty(icon:Icons.folder_outlined,title:'Nenhum material ainda',body:'Envie PDFs, documentos ou apontamentos da turma.'):ListView.separated(padding:const EdgeInsets.all(16),itemCount:rows.length,separatorBuilder:(_,__)=>const SizedBox(height:10),itemBuilder:(_,i){final r=rows[i];return Surface(padding:const EdgeInsets.all(16),child:ListTile(contentPadding:EdgeInsets.zero,leading:Container(width:48,height:48,decoration:BoxDecoration(color:Theme.of(context).colorScheme.primaryContainer,borderRadius:16),child:Icon(r['title'].toString().toLowerCase().endsWith('.pdf')?Icons.picture_as_pdf_outlined:Icons.description_outlined)),title:Text(r['title']??'Material',style:const TextStyle(fontWeight:FontWeight.w750)),subtitle:Text('${r['processing_status']??'PENDING'} · ${r['created_at']!=null?DateFormat('dd/MM HH:mm').format(DateTime.parse(r['created_at'])):''}'),trailing:IconButton(onPressed:()=>showStudyActions(context,r),icon:const Icon(Icons.auto_awesome_outlined))));})]);
}

void showStudyActions(BuildContext context,Map<String,dynamic> material){showModalBottomSheet(context:context,builder:(_)=>SafeArea(child:Padding(padding:const EdgeInsets.all(20),child:Wrap(children:[ListTile(leading:const Icon(Icons.summarize_outlined),title:const Text('Gerar resumo'),onTap:()async{Navigator.pop(context);try{final r=await ai.summarize(material['id']);_showResult(context,'Resumo',r['result']??r['content']??r);}catch(e){_toast(_error(e));}}),ListTile(leading:const Icon(Icons.quiz_outlined),title:const Text('Criar quiz'),onTap:()async{Navigator.pop(context);try{final r=await ai.quiz(material['id']);_showResult(context,'Quiz',r['result']??r['content']??r);}catch(e){_toast(_error(e));}}),ListTile(leading:const Icon(Icons.account_tree_outlined),title:const Text('Mapa mental'),onTap:()async{Navigator.pop(context);try{final r=await ai.mindMap(material['id']);_showResult(context,'Mapa mental',r['result']??r['content']??r);}catch(e){_toast(_error(e));}})]))));}

class StudyPage extends StatefulWidget { const StudyPage({super.key,required this.classId}); final String classId; @override State<StudyPage> createState()=>_StudyPageState(); }
class _StudyPageState extends State<StudyPage>{final q=TextEditingController();bool busy=false;String result='';Future<void>ask()async{if(q.text.trim().isEmpty)return;setState(()=>busy=true);try{final r=await ai.ask(prompt:q.text.trim(),context:'Responda como assistente de estudo da turma C12AT. Priorize explicações claras em português e não invente conteúdo que não esteja no material fornecido.');setState(()=>result=(r['result']??r['content']??r).toString());}catch(e){_toast(_error(e));}finally{if(mounted)setState(()=>busy=false);}}@override Widget build(BuildContext context)=>SingleChildScrollView(padding:const EdgeInsets.fromLTRB(18,18,18,28),child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[Text('Estudar',style:Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight:FontWeight.w800)),const SizedBox(height:6),const Text('Transforme as matérias em estudo ativo.'),const SizedBox(height:20),Surface(padding:const EdgeInsets.all(16),child:Column(children:[TextField(controller:q,minLines:2,maxLines:6,decoration:const InputDecoration(hintText:'Pergunte algo sobre uma matéria…',prefixIcon:Icon(Icons.auto_awesome_outlined))),const SizedBox(height:12),SizedBox(width:double.infinity,child:FilledButton.icon(onPressed:busy?null:ask,icon:busy?const SizedBox(width:18,height:18,child:CircularProgressIndicator(strokeWidth:2)):const Icon(Icons.arrow_upward_rounded),label:const Text('Perguntar à IA')))])),if(result.isNotEmpty)...[const SizedBox(height:16),Surface(padding:const EdgeInsets.all(18),child:SelectableText(result,style:const TextStyle(height:1.45)))],const SizedBox(height:20),Text('Ferramentas',style:Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight:FontWeight.w800)),const SizedBox(height:10),Wrap(spacing:10,runSpacing:10,children:[ActionChip(avatar:const Icon(Icons.summarize_outlined,size:18),label:const Text('Resumo'),onPressed:()=>q.text='Faz um resumo desta matéria'),ActionChip(avatar:const Icon(Icons.quiz_outlined,size:18),label:const Text('Perguntas'),onPressed:()=>q.text='Cria 10 perguntas de revisão'),ActionChip(avatar:const Icon(Icons.account_tree_outlined,size:18),label:const Text('Mapa mental'),onPressed:()=>q.text='Cria um mapa mental'),ActionChip(avatar:const Icon(Icons.school_outlined,size:18),label:const Text('Explicar simples'),onPressed:()=>q.text='Explica este conteúdo de forma simples')]) ]);
}

class ProfilePage extends StatelessWidget { const ProfilePage({super.key,required this.cls}); final Map<String,dynamic> cls; @override Widget build(BuildContext context)=>FutureBuilder<Map<String,dynamic>?>(future:auth.profile(),builder:(_,s){final p=s.data??{};return ListView(padding:const EdgeInsets.all(20),children:[Text('Perfil',style:Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight:FontWeight.w800)),const SizedBox(height:20),Surface(padding:const EdgeInsets.all(20),child:Row(children:[CircleAvatar(radius:30,child:Text(((p['full_name']??'?') as String).substring(0,1).toUpperCase())),const SizedBox(width:15),Expanded(child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[Text(p['full_name']??'Utilizador',style:Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight:FontWeight.w800)),Text(client.auth.currentUser?.email??'')]))])),const SizedBox(height:14),Surface(padding:const EdgeInsets.all(18),child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[const Text('Turma',style:TextStyle(fontWeight:FontWeight.w800)),const SizedBox(height:6),Text(cls['name']??'Turma C12AT'),if(cls['invite_code']!=null)...[const SizedBox(height:12),Text('Código de convite',style:TextStyle(fontWeight:FontWeight.w700)),SelectableText(cls['invite_code'].toString())]])),const SizedBox(height:18),ListTile(leading:const Icon(Icons.logout_rounded),title:const Text('Sair da conta'),onTap:auth.signOut) ]);});}

class _Message extends StatelessWidget{const _Message({required this.data,required this.own,required this.onDelete});final Map<String,dynamic>data;final bool own;final VoidCallback onDelete;@override Widget build(BuildContext context){final p=data['profiles'] as Map?;return Align(alignment:own?Alignment.centerRight:Alignment.centerLeft,child:GestureDetector(onLongPress:own?()=>showModalBottomSheet(context:context,builder:(_)=>ListTile(leading:const Icon(Icons.delete_outline),title:const Text('Apagar mensagem'),onTap:(){Navigator.pop(context);onDelete();})):null,child:Container(constraints:const BoxConstraints(maxWidth:380),margin:const EdgeInsets.only(bottom:8),padding:const EdgeInsets.symmetric(horizontal:14,vertical:10),decoration:BoxDecoration(color:own?Theme.of(context).colorScheme.primaryContainer:Theme.of(context).colorScheme.surface,borderRadius:BorderRadius.circular(19),boxShadow:[BoxShadow(offset:const Offset(3,4),blurRadius:9,color:Colors.black12)]),child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[if(!own)Text(p?['full_name']??'Aluno',style:TextStyle(fontWeight:FontWeight.w800,color:Theme.of(context).colorScheme.primary)),Text(data['content']??'',style:const TextStyle(height:1.35)),const SizedBox(height:4),Text(data['created_at']!=null?DateFormat('HH:mm').format(DateTime.parse(data['created_at'])):'',style:Theme.of(context).textTheme.labelSmall)]))));}}

class _Stat extends StatelessWidget{const _Stat({required this.icon,required this.value,required this.label});final IconData icon;final String value,label;@override Widget build(BuildContext context)=>Surface(padding:const EdgeInsets.all(13),radius:20,child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[Icon(icon,size:20),const SizedBox(height:8),Text(value,style:const TextStyle(fontSize:20,fontWeight:FontWeight.w800)),Text(label,style:Theme.of(context).textTheme.bodySmall)]));}
class _SectionButton extends StatelessWidget{const _SectionButton({required this.icon,required this.title,required this.subtitle,required this.onTap});final IconData icon;final String title,subtitle;final VoidCallback onTap;@override Widget build(BuildContext context)=>InkWell(borderRadius:BorderRadius.circular(24),onTap:onTap,child:Surface(padding:const EdgeInsets.all(15),child:Row(children:[Container(width:46,height:46,decoration:BoxDecoration(color:Theme.of(context).colorScheme.primaryContainer,borderRadius:16),child:Icon(icon)),const SizedBox(width:14),Expanded(child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[Text(title,style:const TextStyle(fontWeight:FontWeight.w800)),const SizedBox(height:3),Text(subtitle)])),const Icon(Icons.chevron_right_rounded)])));}
class _Brand extends StatelessWidget{const _Brand();@override Widget build(BuildContext context)=>Row(children:[Container(width:46,height:46,decoration:BoxDecoration(color:Theme.of(context).colorScheme.primaryContainer,borderRadius:15),child:const Icon(Icons.school_rounded)),const SizedBox(width:12),const Text('Turma C12AT',style:TextStyle(fontSize:22,fontWeight:FontWeight.w800))]);}
class _Empty extends StatelessWidget{const _Empty({required this.icon,required this.title,required this.body});final IconData icon;final String title,body;@override Widget build(BuildContext context)=>Center(child:Padding(padding:const EdgeInsets.all(30),child:Column(mainAxisSize:MainAxisSize.min,children:[Icon(icon,size:44),const SizedBox(height:12),Text(title,style:Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight:FontWeight.w800)),const SizedBox(height:5),Text(body,textAlign:TextAlign.center)])));}
class _Loading extends StatelessWidget{const _Loading();@override Widget build(BuildContext context)=>const Scaffold(body:Center(child:CircularProgressIndicator()));}
void _toast(String text){final ctx=_navigatorKey.currentContext;if(ctx!=null)ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(content:Text(text)));}
final GlobalKey<NavigatorState> _navigatorKey=GlobalKey<NavigatorState>();
String _error(Object e)=>e.toString().replaceFirst('Exception: ','').replaceFirst('PostgrestException(message: ','').replaceFirst(RegExp(r', code:.*'),'');
void _showResult(BuildContext context,String title,Object result){showModalBottomSheet(context:context,isScrollControlled:true,builder:(_)=>DraggableScrollableSheet(expand:false,builder:(_,c)=>SafeArea(child:ListView(controller:c,padding:const EdgeInsets.all(22),children:[Text(title,style:Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight:FontWeight.w800)),const SizedBox(height:16),SelectableText(result.toString(),style:const TextStyle(height:1.45))]))));}
