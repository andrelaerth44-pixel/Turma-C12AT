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
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) return const LoadingPage();
          if (client.auth.currentSession == null) return const LoginPage();
          return const MembershipGate();
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
  void reload() => setState(() => future = auth.memberships());
  @override Widget build(BuildContext context) => FutureBuilder<List<Map<String, dynamic>>>(
        future: future,
        builder: (context, snap) {
          if (!snap.hasData) return const LoadingPage();
          if (snap.data!.isEmpty) return JoinClassPage(onChanged: reload);
          return AppShell(membership: snap.data!.first);
        },
      );
}

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});
  @override State<LoginPage> createState() => _LoginPageState();
}
class _LoginPageState extends State<LoginPage> {
  final email = TextEditingController();
  final password = TextEditingController();
  final name = TextEditingController();
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
    } catch (e) { toast(errorText(e)); } finally { if (mounted) setState(() => busy = false); }
  }
  @override Widget build(BuildContext context) => Scaffold(
    body: SafeArea(child: Center(child: SingleChildScrollView(padding: const EdgeInsets.all(24), child: ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 470),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Brand(), const SizedBox(height: 34),
        Text(register ? 'Criar conta' : 'Entrar', style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w800)),
        const SizedBox(height: 7), Text(register ? 'Crie o seu acesso à turma.' : 'Entre para continuar.'), const SizedBox(height: 25),
        if (register) ...[TextField(controller: name, decoration: const InputDecoration(labelText: 'Nome completo', prefixIcon: Icon(Icons.person_outline))), const SizedBox(height: 12)],
        TextField(controller: email, keyboardType: TextInputType.emailAddress, decoration: const InputDecoration(labelText: 'E-mail', prefixIcon: Icon(Icons.mail_outline))), const SizedBox(height: 12),
        TextField(controller: password, obscureText: true, decoration: const InputDecoration(labelText: 'Palavra-passe', prefixIcon: Icon(Icons.lock_outline))), const SizedBox(height: 18),
        SizedBox(width: double.infinity, child: FilledButton.icon(onPressed: busy ? null : submit, icon: busy ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2)) : const Icon(Icons.arrow_forward_rounded), label: Text(register ? 'Criar conta' : 'Entrar'))),
        const SizedBox(height: 10), SizedBox(width: double.infinity, child: OutlinedButton.icon(onPressed: busy ? null : () async { try { await auth.signInWithGoogle(); } catch (e) { toast(errorText(e)); } }, icon: const Icon(Icons.account_circle_outlined), label: const Text('Continuar com Google'))),
        const SizedBox(height: 12), Center(child: TextButton(onPressed: () => setState(() => register = !register), child: Text(register ? 'Já tenho uma conta' : 'Criar uma conta'))),
      ],
    )))
  ));
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
    } catch (e) { toast(errorText(e)); } finally { if (mounted) setState(() => busy = false); }
  }
  @override Widget build(BuildContext context) => Scaffold(body: SafeArea(child: Center(child: SingleChildScrollView(padding: const EdgeInsets.all(24), child: ConstrainedBox(constraints: const BoxConstraints(maxWidth: 520), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
    const Brand(), const SizedBox(height: 34), Text(create ? 'Criar turma' : 'Entrar na turma', style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w800)), const SizedBox(height: 7), Text(create ? 'Crie o espaço coletivo da turma.' : 'Use o código fornecido pelo administrador.'), const SizedBox(height: 24),
    if (create) ...[
      TextField(controller: name, decoration: const InputDecoration(labelText: 'Nome da turma', prefixIcon: Icon(Icons.groups_outlined))), const SizedBox(height: 12),
      TextField(controller: description, decoration: const InputDecoration(labelText: 'Descrição opcional')), const SizedBox(height: 12),
      TextField(controller: institution, decoration: const InputDecoration(labelText: 'Instituição opcional')), const SizedBox(height: 12),
      TextField(controller: year, decoration: const InputDecoration(labelText: 'Ano letivo')),
    ] else TextField(controller: code, textCapitalization: TextCapitalization.characters, decoration: const InputDecoration(labelText: 'Código de convite', prefixIcon: Icon(Icons.key_outlined))),
    const SizedBox(height: 18), SizedBox(width: double.infinity, child: FilledButton.icon(onPressed: busy ? null : run, icon: busy ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2)) : Icon(create ? Icons.add_rounded : Icons.login_rounded), label: Text(create ? 'Criar turma' : 'Pedir entrada'))),
    Center(child: TextButton(onPressed: busy ? null : () => setState(() => create = !create), child: Text(create ? 'Tenho um código de convite' : 'Sou administrador e quero criar a turma'))),
    Center(child: TextButton(onPressed: auth.signOut, child: const Text('Sair da conta'))),
  ]))))));
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
    final pages = <Widget>[
      HomePage(classId: classId, cls: cls, open: (v) => setState(() => index = v)),
      ChatPage(classId: classId), MaterialsPage(classId: classId), StudyPage(classId: classId), ProfilePage(cls: cls),
    ];
    return Scaffold(body: SafeArea(child: AnimatedSwitcher(duration: const Duration(milliseconds: 220), child: pages[index])), bottomNavigationBar: NavigationBar(selectedIndex: index, onDestinationSelected: (v) => setState(() => index = v), destinations: const [
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
    final a = await client.from('messages').select('id').eq('class_id', classId);
    final b = await client.from('materials').select('id').eq('class_id', classId);
    final c = await client.from('class_members').select('id').eq('class_id', classId).eq('status', 'approved');
    return {'messages': a.length, 'materials': b.length, 'members': c.length};
  }
  @override Widget build(BuildContext context) => FutureBuilder<Map<String, int>>(future: stats(), builder: (context, snap) {
    final s = snap.data ?? const <String, int>{};
    return CustomScrollView(physics: const BouncingScrollPhysics(), slivers: [SliverPadding(padding: const EdgeInsets.fromLTRB(20, 18, 20, 28), sliver: SliverList(delegate: SliverChildListDelegate([
      Row(children: [Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(cls['name'] ?? 'Turma C12AT', style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w800, letterSpacing: -1)), const SizedBox(height: 4), Text(cls['description'] ?? 'Tudo da turma, num só lugar')])), IconButton(onPressed: () {}, icon: const Icon(Icons.notifications_none_rounded))]),
      const SizedBox(height: 22), Surface(padding: const EdgeInsets.all(22), child: Row(children: [Container(width: 56, height: 56, decoration: BoxDecoration(color: Theme.of(context).colorScheme.primaryContainer, borderRadius: BorderRadius.circular(18)), child: const Icon(Icons.groups_rounded, size: 29)), const SizedBox(width: 16), const Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text('A turma inteira dentro de um único app', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800)), SizedBox(height: 6), Text('Converse, partilhe materiais e estude juntos.', style: TextStyle(height: 1.35))]))])),
      const SizedBox(height: 20), Text('Hoje na turma', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800)), const SizedBox(height: 10), Row(children: [Expanded(child: Stat(icon: Icons.forum_outlined, value: '${s['messages'] ?? 0}', label: 'mensagens')), const SizedBox(width: 8), Expanded(child: Stat(icon: Icons.description_outlined, value: '${s['materials'] ?? 0}', label: 'materiais')), const SizedBox(width: 8), Expanded(child: Stat(icon: Icons.groups_outlined, value: '${s['members'] ?? 0}', label: 'membros'))]),
      const SizedBox(height: 16), SectionButton(icon: Icons.forum_outlined, title: 'Abrir conversa', subtitle: 'Fale com toda a turma', onTap: () => open(1)), const SizedBox(height: 10), SectionButton(icon: Icons.folder_outlined, title: 'Materiais', subtitle: 'Ficheiros e matérias da turma', onTap: () => open(2)), const SizedBox(height: 10), SectionButton(icon: Icons.auto_awesome_outlined, title: 'Estudar com IA', subtitle: 'Resumos, perguntas e mapas mentais', onTap: () => open(3)),
    ]))) ]);
  });
}

class ChatPage extends StatefulWidget { const ChatPage({super.key, required this.classId}); final String classId; @override State<ChatPage> createState() => _ChatPageState(); }
class _ChatPageState extends State<ChatPage> {
  final input = TextEditingController(); List<Map<String, dynamic>> rows = []; bool loading = true, sending = false; RealtimeChannel? channel;
  @override void initState() { super.initState(); load(); channel = client.channel('chat-${widget.classId}').onPostgresChanges(event: PostgresChangeEvent.all, schema: 'public', table: 'messages', filter: PostgresChangeFilter(type: PostgresChangeFilterType.eq, column: 'class_id', value: widget.classId), callback: (_) => load()).subscribe(); }
  Future<void> load() async { try { final r = await client.from('messages').select('*, profiles!messages_sender_id_fkey(id,full_name,avatar_url)').eq('class_id', widget.classId).isFilter('deleted_at', null).order('created_at'); if (mounted) setState(() => rows = List<Map<String, dynamic>>.from(r)); } catch (e) { toast(errorText(e)); } finally { if (mounted) setState(() => loading = false); } }
  Future<void> send() async { final text = input.text.trim(); if (text.isEmpty || sending) return; setState(() => sending = true); try { await client.from('messages').insert({'class_id': widget.classId, 'sender_id': client.auth.currentUser!.id, 'content': text, 'message_type': 'text'}); input.clear(); } catch (e) { toast(errorText(e)); } finally { if (mounted) setState(() => sending = false); } }
  @override void dispose() { channel?.unsubscribe(); input.dispose(); super.dispose(); }
  @override Widget build(BuildContext context) => Column(children: [Padding(padding: const EdgeInsets.fromLTRB(18, 14, 18, 10), child: Row(children: [Text('Conversa', style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800)), const Spacer(), IconButton(onPressed: load, icon: const Icon(Icons.refresh_rounded))])), Expanded(child: loading ? const LoadingPage() : rows.isEmpty ? const Empty(icon: Icons.forum_outlined, title: 'Ainda não há mensagens', body: 'Comece a conversa com a turma.') : ListView.builder(padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4), itemCount: rows.length, itemBuilder: (context, i) => MessageTile(data: rows[i], own: rows[i]['sender_id'] == client.auth.currentUser!.id, onDelete: () async { await client.from('messages').update({'deleted_at': DateTime.now().toIso8601String()}).eq('id', rows[i]['id']); load(); }))), Padding(padding: const EdgeInsets.fromLTRB(12, 7, 12, 12), child: Surface(radius: 24, padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3), child: Row(children: [IconButton(onPressed: () async { final p = await FilePicker.platform.pickFiles(); if (p != null) toast('Anexo selecionado: ${p.files.single.name}'); }, icon: const Icon(Icons.attach_file_rounded)), Expanded(child: TextField(controller: input, maxLines: 5, minLines: 1, decoration: const InputDecoration(hintText: 'Escreva para a turma', filled: false, border: InputBorder.none))), IconButton(onPressed: sending ? null : send, icon: Icon(sending ? Icons.hourglass_top_rounded : Icons.send_rounded))])))]);
}

class MaterialsPage extends StatefulWidget { const MaterialsPage({super.key, required this.classId}); final String classId; @override State<MaterialsPage> createState() => _MaterialsPageState(); }
class _MaterialsPageState extends State<MaterialsPage> {
  List<Map<String, dynamic>> rows = []; bool loading = true;
  @override void initState() { super.initState(); load(); }
  Future<void> load() async { try { final r = await client.from('materials').select('*, profiles!materials_uploaded_by_fkey(id,full_name)').eq('class_id', widget.classId).order('created_at', ascending: false); if (mounted) setState(() => rows = List<Map<String, dynamic>>.from(r)); } catch (e) { toast(errorText(e)); } finally { if (mounted) setState(() => loading = false); } }
  Future<void> upload() async {
    final pick = await FilePicker.platform.pickFiles(withData: true); if (pick == null || pick.files.single.bytes == null) return; final f = pick.files.single;
    try { final u = client.auth.currentUser!; final path = '${u.id}/${DateTime.now().millisecondsSinceEpoch}_${f.name}'; final isPdf = f.extension?.toLowerCase() == 'pdf'; final bucket = isPdf ? 'documents' : 'materials'; final mime = isPdf ? 'application/pdf' : 'application/octet-stream'; await client.storage.from(bucket).uploadBinary(path, f.bytes!, fileOptions: FileOptions(contentType: mime)); final a = await client.from('attachments').insert({'file_name': f.name, 'file_url': path, 'file_type': 'material', 'file_size': f.size, 'mime_type': mime}).select().single(); await client.from('materials').insert({'class_id': widget.classId, 'uploaded_by': u.id, 'attachment_id': a['id'], 'title': f.name, 'processing_status': 'PENDING'}); await load(); } catch (e) { toast(errorText(e)); }
  }
  @override Widget build(BuildContext context) => Column(children: [Padding(padding: const EdgeInsets.fromLTRB(18, 14, 18, 10), child: Row(children: [Text('Materiais', style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800)), const Spacer(), FilledButton.tonalIcon(onPressed: upload, icon: const Icon(Icons.upload_file_rounded), label: const Text('Adicionar'))])), Expanded(child: loading ? const LoadingPage() : rows.isEmpty ? const Empty(icon: Icons.folder_outlined, title: 'Nenhum material ainda', body: 'Envie PDFs, documentos ou apontamentos da turma.') : ListView.separated(padding: const EdgeInsets.all(15), itemCount: rows.length, separatorBuilder: (_, __) => const SizedBox(height: 10), itemBuilder: (context, i) { final m = rows[i]; final title = m['title'] ?? 'Material'; return Surface(padding: const EdgeInsets.all(14), child: ListTile(contentPadding: EdgeInsets.zero, leading: Icon(title.toString().toLowerCase().endsWith('.pdf') ? Icons.picture_as_pdf_outlined : Icons.description_outlined, size: 30), title: Text(title, style: const TextStyle(fontWeight: FontWeight.w700)), subtitle: Text('${m['processing_status'] ?? 'PENDING'} · ${m['created_at'] == null ? '' : DateFormat('dd/MM HH:mm').format(DateTime.parse(m['created_at']))}'), trailing: IconButton(onPressed: () => studyActions(context, m), icon: const Icon(Icons.auto_awesome_outlined)))); })]);
}

Future<void> studyActions(BuildContext context, Map<String, dynamic> material) async { showModalBottomSheet(context: context, builder: (_) => SafeArea(child: Wrap(children: [ListTile(leading: const Icon(Icons.summarize_outlined), title: const Text('Gerar resumo'), onTap: () async { Navigator.pop(context); try { final r = await ai.summarize(material['id']); showResult(context, 'Resumo', r); } catch (e) { toast(errorText(e)); } }), ListTile(leading: const Icon(Icons.quiz_outlined), title: const Text('Criar quiz'), onTap: () async { Navigator.pop(context); try { final r = await ai.quiz(material['id']); showResult(context, 'Quiz', r); } catch (e) { toast(errorText(e)); } }), ListTile(leading: const Icon(Icons.account_tree_outlined), title: const Text('Mapa mental'), onTap: () async { Navigator.pop(context); try { final r = await ai.mindMap(material['id']); showResult(context, 'Mapa mental', r); } catch (e) { toast(errorText(e)); } })])); }

class StudyPage extends StatefulWidget { const StudyPage({super.key, required this.classId}); final String classId; @override State<StudyPage> createState() => _StudyPageState(); }
class _StudyPageState extends State<StudyPage> {
  final prompt = TextEditingController(); bool busy = false; String answer = '';
  Future<void> ask() async { if (prompt.text.trim().isEmpty) return; setState(() => busy = true); try { final r = await ai.ask(prompt: prompt.text.trim(), context: 'És o assistente de estudo da Turma C12AT. Responde em português, explica com clareza e não inventa dados de materiais que não foram fornecidos.'); setState(() => answer = (r['result'] ?? r['content'] ?? r).toString()); } catch (e) { toast(errorText(e)); } finally { if (mounted) setState(() => busy = false); } }
  @override Widget build(BuildContext context) => ListView(padding: const EdgeInsets.fromLTRB(18, 18, 18, 28), children: [Text('Estudar', style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800)), const SizedBox(height: 5), const Text('Transforme as matérias em estudo ativo.'), const SizedBox(height: 18), Surface(padding: const EdgeInsets.all(16), child: Column(children: [TextField(controller: prompt, minLines: 2, maxLines: 6, decoration: const InputDecoration(hintText: 'Pergunte algo sobre uma matéria…', prefixIcon: Icon(Icons.auto_awesome_outlined))), const SizedBox(height: 11), SizedBox(width: double.infinity, child: FilledButton.icon(onPressed: busy ? null : ask, icon: busy ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2)) : const Icon(Icons.arrow_upward_rounded), label: const Text('Perguntar à IA')))])), if (answer.isNotEmpty) ...[const SizedBox(height: 14), Surface(padding: const EdgeInsets.all(18), child: SelectableText(answer, style: const TextStyle(height: 1.45)))], const SizedBox(height: 20), Text('Atalhos', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800)), const SizedBox(height: 10), Wrap(spacing: 8, runSpacing: 8, children: [ActionChip(avatar: const Icon(Icons.summarize_outlined, size: 18), label: const Text('Resumo'), onPressed: () => setState(() => prompt.text = 'Faz um resumo desta matéria')), ActionChip(avatar: const Icon(Icons.quiz_outlined, size: 18), label: const Text('Perguntas'), onPressed: () => setState(() => prompt.text = 'Cria 10 perguntas de revisão')), ActionChip(avatar: const Icon(Icons.account_tree_outlined, size: 18), label: const Text('Mapa mental'), onPressed: () => setState(() => prompt.text = 'Cria um mapa mental')), ActionChip(avatar: const Icon(Icons.school_outlined, size: 18), label: const Text('Explicar simples'), onPressed: () => setState(() => prompt.text = 'Explica este conteúdo de forma simples'))])]);
}

class ProfilePage extends StatelessWidget { const ProfilePage({super.key, required this.cls}); final Map<String, dynamic> cls; @override Widget build(BuildContext context) => FutureBuilder<Map<String, dynamic>?>(future: auth.profile(), builder: (context, snap) { final p = snap.data ?? {}; final full = (p['full_name'] ?? 'Utilizador').toString(); final initial = full.isEmpty ? '?' : full.substring(0, 1).toUpperCase(); return ListView(padding: const EdgeInsets.all(20), children: [Text('Perfil', style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800)), const SizedBox(height: 18), Surface(padding: const EdgeInsets.all(20), child: Row(children: [CircleAvatar(radius: 30, child: Text(initial)), const SizedBox(width: 15), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(full, style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800)), Text(client.auth.currentUser?.email ?? '')]))])), const SizedBox(height: 14), Surface(padding: const EdgeInsets.all(18), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [const Text('Turma', style: TextStyle(fontWeight: FontWeight.w800)), const SizedBox(height: 6), Text(cls['name'] ?? 'Turma C12AT'), if (cls['invite_code'] != null) ...[const SizedBox(height: 12), const Text('Código de convite', style: TextStyle(fontWeight: FontWeight.w700)), SelectableText(cls['invite_code'].toString())]])), const SizedBox(height: 16), ListTile(leading: const Icon(Icons.logout_rounded), title: const Text('Sair da conta'), onTap: auth.signOut)]; }); }

class Brand extends StatelessWidget { const Brand({super.key}); @override Widget build(BuildContext context) => Row(children: [Container(width: 46, height: 46, decoration: BoxDecoration(color: Theme.of(context).colorScheme.primaryContainer, borderRadius: BorderRadius.circular(15)), child: const Icon(Icons.school_rounded)), const SizedBox(width: 12), const Text('Turma C12AT', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800))]); }
class Stat extends StatelessWidget { const Stat({super.key, required this.icon, required this.value, required this.label}); final IconData icon; final String value, label; @override Widget build(BuildContext context) => Surface(radius: 20, padding: const EdgeInsets.all(13), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Icon(icon, size: 20), const SizedBox(height: 7), Text(value, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800)), Text(label, style: Theme.of(context).textTheme.bodySmall)])); }
class SectionButton extends StatelessWidget { const SectionButton({super.key, required this.icon, required this.title, required this.subtitle, required this.onTap}); final IconData icon; final String title, subtitle; final VoidCallback onTap; @override Widget build(BuildContext context) => InkWell(borderRadius: BorderRadius.circular(24), onTap: onTap, child: Surface(padding: const EdgeInsets.all(15), child: Row(children: [Container(width: 46, height: 46, decoration: BoxDecoration(color: Theme.of(context).colorScheme.primaryContainer, borderRadius: BorderRadius.circular(16)), child: Icon(icon)), const SizedBox(width: 14), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(title, style: const TextStyle(fontWeight: FontWeight.w800)), const SizedBox(height: 3), Text(subtitle)])), const Icon(Icons.chevron_right_rounded)]))); }
class MessageTile extends StatelessWidget { const MessageTile({super.key, required this.data, required this.own, required this.onDelete}); final Map<String, dynamic> data; final bool own; final VoidCallback onDelete; @override Widget build(BuildContext context) { final p = data['profiles'] is Map ? Map<String, dynamic>.from(data['profiles']) : <String, dynamic>{}; return Align(alignment: own ? Alignment.centerRight : Alignment.centerLeft, child: GestureDetector(onLongPress: own ? () => showModalBottomSheet(context: context, builder: (_) => ListTile(leading: const Icon(Icons.delete_outline), title: const Text('Apagar mensagem'), onTap: () { Navigator.pop(context); onDelete(); })) : null, child: Container(constraints: const BoxConstraints(maxWidth: 390), margin: const EdgeInsets.only(bottom: 8), padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10), decoration: BoxDecoration(color: own ? Theme.of(context).colorScheme.primaryContainer : Theme.of(context).colorScheme.surface, borderRadius: BorderRadius.circular(19), boxShadow: const [BoxShadow(offset: Offset(2, 3), blurRadius: 8, color: Color(0x14000000))]), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [if (!own) Text(p['full_name'] ?? 'Aluno', style: TextStyle(fontWeight: FontWeight.w800, color: Theme.of(context).colorScheme.primary)), Text(data['content'] ?? '', style: const TextStyle(height: 1.35)), const SizedBox(height: 4), Text(data['created_at'] == null ? '' : DateFormat('HH:mm').format(DateTime.parse(data['created_at'])), style: Theme.of(context).textTheme.labelSmall)])))); } }
class Empty extends StatelessWidget { const Empty({super.key, required this.icon, required this.title, required this.body}); final IconData icon; final String title, body; @override Widget build(BuildContext context) => Center(child: Padding(padding: const EdgeInsets.all(30), child: Column(mainAxisSize: MainAxisSize.min, children: [Icon(icon, size: 44), const SizedBox(height: 12), Text(title, style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800)), const SizedBox(height: 5), Text(body, textAlign: TextAlign.center)]))); }
class LoadingPage extends StatelessWidget { const LoadingPage({super.key}); @override Widget build(BuildContext context) => const Scaffold(body: Center(child: CircularProgressIndicator())); }

void toast(String text) => messengerKey.currentState?.showSnackBar(SnackBar(content: Text(text)));
String errorText(Object e) => e.toString().replaceFirst('Exception: ', '');
void showResult(BuildContext context, String title, Object result) => showModalBottomSheet(context: context, isScrollControlled: true, builder: (_) => DraggableScrollableSheet(expand: false, builder: (_, controller) => SafeArea(child: ListView(controller: controller, padding: const EdgeInsets.all(22), children: [Text(title, style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800)), const SizedBox(height: 15), SelectableText(result.toString(), style: const TextStyle(height: 1.45))]))));
