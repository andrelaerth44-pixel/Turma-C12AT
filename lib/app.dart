import 'dart:async';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'services/auth_service.dart';
import 'services/ai_service.dart';

final client = Supabase.instance.client;
final auth = AuthService(client);
final ai = SupabaseAIService(client);
final messengerKey = GlobalKey<ScaffoldMessengerState>();

class TurmaApp extends StatelessWidget {
  const TurmaApp({super.key});
  @override
  Widget build(BuildContext context) => MaterialApp(
        debugShowCheckedModeBanner: false,
        scaffoldMessengerKey: messengerKey,
        title: 'Turma C12AT',
        theme: ThemeData(useMaterial3: true, colorSchemeSeed: const Color(0xFF526B5A), brightness: Brightness.light),
        darkTheme: ThemeData(useMaterial3: true, colorSchemeSeed: const Color(0xFF8FAF98), brightness: Brightness.dark),
        themeMode: ThemeMode.system,
        home: const AuthGate(),
      );
}

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});
  @override
  Widget build(BuildContext context) => StreamBuilder<AuthState>(
        stream: client.auth.onAuthStateChange,
        builder: (_, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) return const LoadingPage();
          return client.auth.currentSession == null ? const LoginPage() : const MembershipGate();
        },
      );
}

class MembershipGate extends StatefulWidget {
  const MembershipGate({super.key});
  @override State<MembershipGate> createState() => _MembershipGateState();
}
class _MembershipGateState extends State<MembershipGate> {
  late Future<List<Map<String, dynamic>>> future;
  @override void initState() { super.initState(); future = auth.memberships(); }
  @override Widget build(BuildContext context) => FutureBuilder<List<Map<String, dynamic>>>(
        future: future,
        builder: (_, snap) {
          if (snap.connectionState != ConnectionState.done) return const LoadingPage();
          if (snap.hasError) return ErrorPage(message: errorText(snap.error!));
          if (snap.data!.isEmpty) return JoinClassPage(onChanged: () => setState(() => future = auth.memberships()));
          return AppShell(membership: snap.data!.first);
        },
      );
}

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});
  @override State<LoginPage> createState() => _LoginPageState();
}
class _LoginPageState extends State<LoginPage> {
  final email = TextEditingController(), password = TextEditingController(), name = TextEditingController();
  bool register = false, busy = false;
  Future<void> submit() async {
    if (email.text.trim().isEmpty || password.text.length < 6 || (register && name.text.trim().isEmpty)) { toast('Preencha os campos corretamente.'); return; }
    setState(() => busy = true);
    try {
      if (register) {
        final r = await auth.signUp(email.text, password.text, name.text);
        if (r.session == null) toast('Conta criada. Confirme o e-mail para continuar.');
      } else {
        await auth.signIn(email.text, password.text);
      }
    } catch (e) { toast(errorText(e)); }
    if (mounted) setState(() => busy = false);
  }
  @override void dispose() { email.dispose(); password.dispose(); name.dispose(); super.dispose(); }
  @override Widget build(BuildContext context) => Scaffold(
    body: SafeArea(child: Center(child: SingleChildScrollView(padding: const EdgeInsets.all(24), child: ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 460),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Brand(), const SizedBox(height: 38),
        Text(register ? 'Criar conta' : 'Entrar', style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w800)),
        const SizedBox(height: 8), Text(register ? 'Crie o seu acesso à turma.' : 'Entre para continuar.'), const SizedBox(height: 26),
        if (register) ...[TextField(controller: name, textInputAction: TextInputAction.next, decoration: const InputDecoration(labelText: 'Nome completo', prefixIcon: Icon(Icons.person_outline))), const SizedBox(height: 12)],
        TextField(controller: email, keyboardType: TextInputType.emailAddress, textInputAction: TextInputAction.next, decoration: const InputDecoration(labelText: 'E-mail', prefixIcon: Icon(Icons.mail_outline))),
        const SizedBox(height: 12), TextField(controller: password, obscureText: true, onSubmitted: (_) => submit(), decoration: const InputDecoration(labelText: 'Palavra-passe', prefixIcon: Icon(Icons.lock_outline))),
        const SizedBox(height: 18), SizedBox(width: double.infinity, child: FilledButton.icon(onPressed: busy ? null : submit, icon: busy ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2)) : const Icon(Icons.arrow_forward_rounded), label: Text(register ? 'Criar conta' : 'Entrar'))),
        const SizedBox(height: 10), SizedBox(width: double.infinity, child: OutlinedButton.icon(onPressed: busy ? null : () async { try { await auth.signInWithGoogle(); } catch (e) { toast(errorText(e)); } }, icon: const Icon(Icons.account_circle_outlined), label: const Text('Continuar com Google'))),
        const SizedBox(height: 12), Center(child: TextButton(onPressed: busy ? null : () => setState(() => register = !register), child: Text(register ? 'Já tenho uma conta' : 'Criar uma conta'))),
      ],
    )))),
  );
}

class JoinClassPage extends StatefulWidget {
  const JoinClassPage({super.key, required this.onChanged});
  final VoidCallback onChanged;
  @override State<JoinClassPage> createState() => _JoinClassPageState();
}
class _JoinClassPageState extends State<JoinClassPage> {
  final code = TextEditingController(), name = TextEditingController(), description = TextEditingController(), institution = TextEditingController(), year = TextEditingController();
  bool create = false, busy = false;
  Future<void> run() async {
    if ((!create && code.text.trim().isEmpty) || (create && name.text.trim().isEmpty)) { toast('Preencha os dados.'); return; }
    setState(() => busy = true);
    try {
      if (create) {
        final c = await auth.createClass(name: name.text, description: description.text, institution: institution.text, schoolYear: year.text);
        toast('Turma criada. Código: ${c['invite_code']}');
      } else {
        await auth.requestJoin(code.text); toast('Pedido enviado. Aguarde a aprovação.');
      }
      widget.onChanged();
    } catch (e) { toast(errorText(e)); }
    if (mounted) setState(() => busy = false);
  }
  @override void dispose() { code.dispose(); name.dispose(); description.dispose(); institution.dispose(); year.dispose(); super.dispose(); }
  @override Widget build(BuildContext context) => Scaffold(body: SafeArea(child: Center(child: SingleChildScrollView(padding: const EdgeInsets.all(24), child: ConstrainedBox(
    constraints: const BoxConstraints(maxWidth: 520), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Brand(), SizedBox(height: 36),
      Text('A sua turma', style: TextStyle(fontSize: 30, fontWeight: FontWeight.w800)), SizedBox(height: 8),
      Text('Entre com um código ou crie o espaço coletivo da turma.'), SizedBox(height: 26),
      if (create) ...[
        TextField(controller: name, decoration: const InputDecoration(labelText: 'Nome da turma', prefixIcon: Icon(Icons.groups_outlined))), SizedBox(height: 12),
        TextField(controller: description, decoration: const InputDecoration(labelText: 'Descrição')), SizedBox(height: 12),
        TextField(controller: institution, decoration: const InputDecoration(labelText: 'Instituição')), SizedBox(height: 12),
        TextField(controller: year, decoration: const InputDecoration(labelText: 'Ano letivo')),
      ] else TextField(controller: code, textCapitalization: TextCapitalization.characters, decoration: const InputDecoration(labelText: 'Código de convite', prefixIcon: Icon(Icons.key_outlined))),
      SizedBox(height: 18), SizedBox(width: double.infinity, child: FilledButton.icon(onPressed: busy ? null : run, icon: busy ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2)) : Icon(create ? Icons.add_rounded : Icons.login_rounded), label: Text(create ? 'Criar turma' : 'Pedir entrada'))),
      Center(child: TextButton(onPressed: busy ? null : () => setState(() => create = !create), child: Text(create ? 'Tenho um código de convite' : 'Sou administrador'))),
      Center(child: TextButton(onPressed: auth.signOut, child: const Text('Sair da conta'))),
    ],
  )))));
}

class AppShell extends StatefulWidget {
  const AppShell({super.key, required this.membership});
  final Map<String, dynamic> membership;
  @override State<AppShell> createState() => _AppShellState();
}
class _AppShellState extends State<AppShell> {
  int index = 0;
  late final String classId;
  late final Map<String, dynamic> cls;
  @override void initState() { super.initState(); classId = widget.membership['class_id'].toString(); cls = Map<String, dynamic>.from(widget.membership['classes'] as Map); }
  @override Widget build(BuildContext context) {
    final pages = [HomePage(classId: classId, cls: cls, open: (i) => setState(() => index = i)), ChatPage(classId: classId), MaterialsPage(classId: classId), StudyPage(classId: classId), ProfilePage(cls: cls)];
    return Scaffold(body: SafeArea(child: IndexedStack(index: index, children: pages)), bottomNavigationBar: NavigationBar(selectedIndex: index, onDestinationSelected: (i) => setState(() => index = i), destinations: const [
      NavigationDestination(icon: Icon(Icons.home_outlined), selectedIcon: Icon(Icons.home_rounded), label: 'Início'),
      NavigationDestination(icon: Icon(Icons.forum_outlined), selectedIcon: Icon(Icons.forum_rounded), label: 'Conversa'),
      NavigationDestination(icon: Icon(Icons.folder_outlined), selectedIcon: Icon(Icons.folder_rounded), label: 'Materiais'),
      NavigationDestination(icon: Icon(Icons.school_outlined), selectedIcon: Icon(Icons.school_rounded), label: 'Estudar'),
      NavigationDestination(icon: Icon(Icons.person_outline), selectedIcon: Icon(Icons.person_rounded), label: 'Perfil'),
    ]));
  }
}

class HomePage extends StatelessWidget {
  const HomePage({super.key, required this.classId, required this.cls, required this.open});
  final String classId; final Map<String, dynamic> cls; final ValueChanged<int> open;
  Future<Map<String, int>> stats() async {
    final m = await client.from('messages').select('id').eq('class_id', classId);
    final f = await client.from('materials').select('id').eq('class_id', classId);
    final u = await client.from('class_members').select('id').eq('class_id', classId).eq('status', 'approved');
    return {'messages': m.length, 'materials': f.length, 'members': u.length};
  }
  @override Widget build(BuildContext context) => FutureBuilder<Map<String, int>>(future: stats(), builder: (_, snap) {
    final s = snap.data ?? {};
    return ListView(padding: const EdgeInsets.fromLTRB(20, 18, 20, 30), children: [
      Row(children: [Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(cls['name']?.toString() ?? 'Turma C12AT', style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w800)), const SizedBox(height: 5), Text(cls['description']?.toString() ?? 'Tudo da turma, num só lugar')])), const Icon(Icons.groups_rounded, size: 34)]),
      const SizedBox(height: 22), Card(child: Padding(padding: const EdgeInsets.all(20), child: Row(children: [Icon(Icons.school_rounded, size: 32, color: Theme.of(context).colorScheme.primary), const SizedBox(width: 14), const Expanded(child: Text('Converse, partilhe materiais e estude juntos.', style: TextStyle(fontSize: 16, height: 1.35)))]))),
      const SizedBox(height: 22), Text('Hoje na turma', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800)), const SizedBox(height: 10),
      Row(children: [Expanded(child: Stat(icon: Icons.forum_outlined, value: '${s['messages'] ?? 0}', label: 'mensagens')), const SizedBox(width: 8), Expanded(child: Stat(icon: Icons.description_outlined, value: '${s['materials'] ?? 0}', label: 'materiais')), const SizedBox(width: 8), Expanded(child: Stat(icon: Icons.groups_outlined, value: '${s['members'] ?? 0}', label: 'membros'))]),
      const SizedBox(height: 18), SectionButton(icon: Icons.forum_outlined, title: 'Abrir conversa', subtitle: 'Fale com toda a turma', onTap: () => open(1)), const SizedBox(height: 10), SectionButton(icon: Icons.folder_outlined, title: 'Materiais', subtitle: 'Ficheiros e matérias da turma', onTap: () => open(2)), const SizedBox(height: 10), SectionButton(icon: Icons.school_outlined, title: 'Estudar', subtitle: 'Resumos, perguntas e mapas mentais', onTap: () => open(3)),
    ];
  });
}

class ChatPage extends StatefulWidget { const ChatPage({super.key, required this.classId}); final String classId; @override State<ChatPage> createState() => _ChatPageState(); }
class _ChatPageState extends State<ChatPage> {
  final input = TextEditingController(); final scroll = ScrollController(); List<Map<String, dynamic>> rows = []; bool loading = true, sending = false; RealtimeChannel? channel;
  @override void initState() { super.initState(); load(); channel = client.channel('turma-chat-${widget.classId}').onPostgresChanges(event: PostgresChangeEvent.all, schema: 'public', table: 'messages', filter: PostgresChangeFilter(type: PostgresChangeFilterType.eq, column: 'class_id', value: widget.classId), callback: (_) => load()).subscribe(); }
  Future<void> load() async { try { final r = await client.from('messages').select('*, profiles!messages_sender_id_fkey(id,full_name,avatar_url)').eq('class_id', widget.classId).isFilter('deleted_at', null).order('created_at'); if (mounted) setState(() => rows = List<Map<String, dynamic>>.from(r)); } catch (e) { toast(errorText(e)); } finally { if (mounted) setState(() => loading = false); } }
  Future<void> send() async { final text = input.text.trim(); if (text.isEmpty || sending) return; setState(() => sending = true); try { await client.from('messages').insert({'class_id': widget.classId, 'sender_id': client.auth.currentUser!.id, 'content': text, 'message_type': 'text'}); input.clear(); } catch (e) { toast(errorText(e)); } if (mounted) setState(() => sending = false); }
  @override void dispose() { channel?.unsubscribe(); input.dispose(); scroll.dispose(); super.dispose(); }
  @override Widget build(BuildContext context) => Column(children: [const PageHeader(title: 'Conversa'), Expanded(child: loading ? const LoadingPage() : rows.isEmpty ? const Empty(icon: Icons.forum_outlined, title: 'Ainda não há mensagens', body: 'Comece a conversa com a turma.') : ListView.builder(controller: scroll, padding: const EdgeInsets.fromLTRB(14, 4, 14, 14), itemCount: rows.length, itemBuilder: (_, i) => MessageTile(data: rows[i], own: rows[i]['sender_id'] == client.auth.currentUser?.id, onDelete: () async { await client.from('messages').update({'deleted_at': DateTime.now().toIso8601String()}).eq('id', rows[i]['id']); load(); }))), Container(padding: const EdgeInsets.fromLTRB(12, 7, 12, 12), decoration: BoxDecoration(color: Theme.of(context).colorScheme.surface, border: Border(top: BorderSide(color: Theme.of(context).dividerColor))), child: Row(crossAxisAlignment: CrossAxisAlignment.end, children: [Expanded(child: TextField(controller: input, minLines: 1, maxLines: 5, textInputAction: TextInputAction.newline, decoration: const InputDecoration(hintText: 'Escreva para a turma', border: OutlineInputBorder()))), const SizedBox(width: 8), IconButton.filled(onPressed: sending ? null : send, icon: const Icon(Icons.send_rounded))]))]);
}

class MaterialsPage extends StatefulWidget { const MaterialsPage({super.key, required this.classId}); final String classId; @override State<MaterialsPage> createState() => _MaterialsPageState(); }
class _MaterialsPageState extends State<MaterialsPage> {
  List<Map<String, dynamic>> rows = []; bool loading = true, uploading = false;
  @override void initState() { super.initState(); load(); }
  Future<void> load() async { try { final r = await client.from('materials').select().eq('class_id', widget.classId).order('created_at', ascending: false); if (mounted) setState(() => rows = List<Map<String, dynamic>>.from(r)); } catch (e) { toast(errorText(e)); } finally { if (mounted) setState(() => loading = false); } }
  Future<void> upload() async {
    final picked = await FilePicker.platform.pickFiles(withData: true); if (picked == null || picked.files.single.bytes == null) return;
    final file = picked.files.single; setState(() => uploading = true);
    try { final uid = client.auth.currentUser!.id; final path = '$uid/${DateTime.now().millisecondsSinceEpoch}_${file.name}'; await client.storage.from('materials').uploadBinary(path, file.bytes!); final row = await client.from('materials').insert({'class_id': widget.classId, 'uploaded_by': uid, 'title': file.name, 'processing_status': 'PENDING'}).select().single(); await client.from('attachments').insert({'message_id': null, 'file_name': file.name, 'file_url': path, 'file_type': 'material', 'file_size': file.size, 'mime_type': file.extension}); await client.functions.invoke('process-material', body: {'material_id': row['id']}); await load(); toast('Material enviado para processamento.'); } catch (e) { toast(errorText(e)); } if (mounted) setState(() => uploading = false);
  }
  @override Widget build(BuildContext context) => Column(children: [PageHeader(title: 'Materiais', action: IconButton(onPressed: uploading ? null : upload, icon: uploading ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2)) : const Icon(Icons.upload_file_rounded))), Expanded(child: loading ? const LoadingPage() : rows.isEmpty ? const Empty(icon: Icons.folder_outlined, title: 'Ainda não há materiais', body: 'Envie um PDF, documento ou ficheiro de estudo.') : ListView.builder(padding: const EdgeInsets.all(14), itemCount: rows.length, itemBuilder: (_, i) { final m = rows[i]; return Card(margin: const EdgeInsets.only(bottom: 10), child: ListTile(leading: const Icon(Icons.description_outlined), title: Text(m['title']?.toString() ?? 'Material'), subtitle: Text('${m['subject'] ?? 'Sem disciplina'} · ${m['processing_status'] ?? 'PENDING'}'), trailing: IconButton(icon: const Icon(Icons.auto_awesome_outlined), onPressed: () => showMaterialAI(context, m))); }))]);
}

class StudyPage extends StatefulWidget { const StudyPage({super.key, required this.classId}); final String classId; @override State<StudyPage> createState() => _StudyPageState(); }
class _StudyPageState extends State<StudyPage> {
  List<Map<String, dynamic>> materials = []; Map<String, dynamic>? selected; String output = ''; bool busy = false;
  @override void initState() { super.initState(); load(); }
  Future<void> load() async { try { final r = await client.from('materials').select().eq('class_id', widget.classId).order('created_at', ascending: false); if (mounted) setState(() => materials = List<Map<String, dynamic>>.from(r)); } catch (e) { toast(errorText(e)); } }
  Future<void> run(Future<Map<String, dynamic>> Function() action) async { setState(() => busy = true); try { final r = await action(); if (mounted) setState(() => output = r['result']?.toString() ?? ''); } catch (e) { toast(errorText(e)); } if (mounted) setState(() => busy = false); }
  @override Widget build(BuildContext context) => ListView(padding: const EdgeInsets.fromLTRB(18, 14, 18, 30), children: [Text('Estudar', style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800)), const SizedBox(height: 6), const Text('Use os materiais da turma como base para estudar.'), const SizedBox(height: 18), if (materials.isEmpty) const Empty(icon: Icons.school_outlined, title: 'Sem materiais', body: 'Quando houver materiais, eles aparecerão aqui.') else ...[
      DropdownButtonFormField<Map<String, dynamic>>(value: selected, isExpanded: true, decoration: const InputDecoration(labelText: 'Material'), items: materials.map((m) => DropdownMenuItem(value: m, child: Text(m['title']?.toString() ?? 'Material', overflow: TextOverflow.ellipsis))).toList(), onChanged: (v) => setState(() { selected = v; output = ''; })), const SizedBox(height: 12),
      Wrap(spacing: 8, runSpacing: 8, children: [ActionChip(avatar: const Icon(Icons.summarize_outlined), label: const Text('Resumo'), onPressed: selected == null || busy ? null : () => run(() => ai.summarize(selected!['id'].toString()))), ActionChip(avatar: const Icon(Icons.quiz_outlined), label: const Text('Perguntas'), onPressed: selected == null || busy ? null : () => run(() => ai.quiz(selected!['id'].toString()))), ActionChip(avatar: const Icon(Icons.account_tree_outlined), label: const Text('Mapa mental'), onPressed: selected == null || busy ? null : () => run(() => ai.mindMap(selected!['id'].toString()))) ]), const SizedBox(height: 18), if (busy) const LinearProgressIndicator(), if (output.isNotEmpty) Card(child: Padding(padding: const EdgeInsets.all(18), child: SelectableText(output, style: const TextStyle(height: 1.5)))),
    ]]);
}

class ProfilePage extends StatefulWidget { const ProfilePage({super.key, required this.cls}); final Map<String, dynamic> cls; @override State<ProfilePage> createState() => _ProfilePageState(); }
class _ProfilePageState extends State<ProfilePage> {
  Map<String, dynamic>? profile;
  @override void initState() { super.initState(); load(); }
  Future<void> load() async { final p = await auth.profile(); if (mounted) setState(() => profile = p); }
  @override Widget build(BuildContext context) => ListView(padding: const EdgeInsets.all(20), children: [Text('Perfil', style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800)), const SizedBox(height: 18), Card(child: ListTile(leading: CircleAvatar(child: Text((profile?['full_name']?.toString() ?? client.auth.currentUser?.email ?? 'U').characters.first.toUpperCase())), title: Text(profile?['full_name']?.toString() ?? 'Utilizador'), subtitle: Text(client.auth.currentUser?.email ?? ''))), const SizedBox(height: 12), Card(child: ListTile(leading: const Icon(Icons.groups_outlined), title: Text(widget.cls['name']?.toString() ?? 'Turma C12AT'), subtitle: const Text('Membro da turma'))), const SizedBox(height: 20), OutlinedButton.icon(onPressed: () => auth.signOut(), icon: const Icon(Icons.logout_rounded), label: const Text('Sair da conta'))]);
}

Future<void> showMaterialAI(BuildContext context, Map<String, dynamic> material) async {
  String output = ''; bool busy = false;
  await showModalBottomSheet(context: context, isScrollControlled: true, builder: (sheetContext) => StatefulBuilder(builder: (_, setModal) => Padding(padding: EdgeInsets.fromLTRB(18, 18, 18, MediaQuery.of(sheetContext).viewInsets.bottom + 24), child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [Text(material['title']?.toString() ?? 'Material', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800)), const SizedBox(height: 16), Wrap(spacing: 8, children: [ActionChip(label: const Text('Resumo'), onPressed: busy ? null : () async { setModal(() => busy = true); try { final r = await ai.summarize(material['id'].toString()); setModal(() => output = r['result']?.toString() ?? ''); } catch (e) { toast(errorText(e)); } setModal(() => busy = false); }), ActionChip(label: const Text('Mapa mental'), onPressed: busy ? null : () async { setModal(() => busy = true); try { final r = await ai.mindMap(material['id'].toString()); setModal(() => output = r['result']?.toString() ?? ''); } catch (e) { toast(errorText(e)); } setModal(() => busy = false); })]), const SizedBox(height: 12), if (busy) const LinearProgressIndicator(), if (output.isNotEmpty) Flexible(child: SingleChildScrollView(child: SelectableText(output, style: const TextStyle(height: 1.5))))])));
}

class MessageTile extends StatelessWidget { const MessageTile({super.key, required this.data, required this.own, required this.onDelete}); final Map<String, dynamic> data; final bool own; final VoidCallback onDelete;
  @override Widget build(BuildContext context) { final p = data['profiles'] is Map ? Map<String, dynamic>.from(data['profiles']) : <String, dynamic>{}; return Align(alignment: own ? Alignment.centerRight : Alignment.centerLeft, child: Container(constraints: const BoxConstraints(maxWidth: 520), margin: const EdgeInsets.only(bottom: 8), padding: const EdgeInsets.fromLTRB(14, 10, 10, 8), decoration: BoxDecoration(color: own ? Theme.of(context).colorScheme.primaryContainer : Theme.of(context).colorScheme.surfaceContainerHighest, borderRadius: BorderRadius.circular(18)), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [if (!own) Text(p['full_name']?.toString() ?? 'Aluno', style: const TextStyle(fontWeight: FontWeight.w700)), Text(data['content']?.toString() ?? '', style: const TextStyle(fontSize: 16, height: 1.3)), Row(mainAxisSize: MainAxisSize.min, children: [Text(_time(data['created_at']), style: Theme.of(context).textTheme.labelSmall), if (own) PopupMenuButton<String>(padding: EdgeInsets.zero, iconSize: 18, onSelected: (_) => onDelete(), itemBuilder: (_) => const [PopupMenuItem(value: 'delete', child: Text('Apagar'))])])]))); }
}

String _time(dynamic value) { if (value == null) return ''; final d = DateTime.tryParse(value.toString())?.toLocal(); if (d == null) return ''; return '${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}'; }

class Brand extends StatelessWidget { const Brand({super.key}); @override Widget build(BuildContext context) => Row(children: [Container(width: 44, height: 44, decoration: BoxDecoration(color: Theme.of(context).colorScheme.primaryContainer, borderRadius: BorderRadius.circular(14)), child: const Icon(Icons.school_rounded)), const SizedBox(width: 12), const Text('Turma C12AT', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800))]); }
class PageHeader extends StatelessWidget { const PageHeader({super.key, required this.title, this.action}); final String title; final Widget? action; @override Widget build(BuildContext context) => Padding(padding: const EdgeInsets.fromLTRB(18, 14, 12, 10), child: Row(children: [Text(title, style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800)), const Spacer(), if (action != null) action! ])); }
class SectionButton extends StatelessWidget { const SectionButton({super.key, required this.icon, required this.title, required this.subtitle, required this.onTap}); final IconData icon; final String title, subtitle; final VoidCallback onTap; @override Widget build(BuildContext context) => Card(child: ListTile(onTap: onTap, leading: Icon(icon), title: Text(title, style: const TextStyle(fontWeight: FontWeight.w700)), subtitle: Text(subtitle), trailing: const Icon(Icons.chevron_right_rounded))); }
class Stat extends StatelessWidget { const Stat({super.key, required this.icon, required this.value, required this.label}); final IconData icon; final String value, label; @override Widget build(BuildContext context) => Card(child: Padding(padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8), child: Column(children: [Icon(icon, size: 21), const SizedBox(height: 5), Text(value, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 17)), Text(label, style: Theme.of(context).textTheme.labelSmall)]))); }
class LoadingPage extends StatelessWidget { const LoadingPage({super.key}); @override Widget build(BuildContext context) => const Scaffold(body: Center(child: CircularProgressIndicator())); }
class Empty extends StatelessWidget { const Empty({super.key, required this.icon, required this.title, required this.body}); final IconData icon; final String title, body; @override Widget build(BuildContext context) => Center(child: Padding(padding: const EdgeInsets.all(32), child: Column(mainAxisSize: MainAxisSize.min, children: [Icon(icon, size: 42), const SizedBox(height: 12), Text(title, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 18)), const SizedBox(height: 6), Text(body, textAlign: TextAlign.center)]))); }
class ErrorPage extends StatelessWidget { const ErrorPage({super.key, required this.message}); final String message; @override Widget build(BuildContext context) => Scaffold(body: Center(child: Padding(padding: const EdgeInsets.all(24), child: Text(message, textAlign: TextAlign.center)))); }

void toast(String message) => messengerKey.currentState?.showSnackBar(SnackBar(content: Text(message)));
String errorText(Object error) { final text = error.toString(); if (text.contains('Invalid login credentials')) return 'E-mail ou palavra-passe incorretos.'; if (text.contains('User already registered')) return 'Este e-mail já está registado.'; return text.replaceFirst('Exception: ', ''); }
