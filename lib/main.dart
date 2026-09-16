import 'package:flutter/material.dart';

void main() => runApp(const TurmaC12ATApp());

class TurmaC12ATApp extends StatelessWidget {
  const TurmaC12ATApp({super.key});
  @override
  Widget build(BuildContext context) {
    const accent = Color(0xFF315E68);
    final light = ThemeData(useMaterial3: true, brightness: Brightness.light, scaffoldBackgroundColor: const Color(0xFFF4F7F6), colorScheme: ColorScheme.fromSeed(seedColor: accent, brightness: Brightness.light));
    final dark = ThemeData(useMaterial3: true, brightness: Brightness.dark, scaffoldBackgroundColor: const Color(0xFF101617), colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF8CB8B8), brightness: Brightness.dark));
    return MaterialApp(debugShowCheckedModeBanner: false, title: 'Turma C12AT', theme: light, darkTheme: dark, themeMode: ThemeMode.system, home: const HomeShell());
  }
}

class HomeShell extends StatefulWidget { const HomeShell({super.key}); @override State<HomeShell> createState() => _HomeShellState(); }
class _HomeShellState extends State<HomeShell> {
  int index = 0;
  static const pages = <Widget>[_HomePage(), _PlaceholderPage('Conversa', Icons.forum_outlined), _PlaceholderPage('Materiais', Icons.folder_outlined), _PlaceholderPage('Estudar', Icons.school_outlined), _PlaceholderPage('Perfil', Icons.person_outline)];
  @override Widget build(BuildContext context) => Scaffold(body: SafeArea(child: AnimatedSwitcher(duration: const Duration(milliseconds: 220), child: pages[index])), bottomNavigationBar: NavigationBar(selectedIndex: index, onDestinationSelected: (v) => setState(() => index = v), destinations: const [NavigationDestination(icon: Icon(Icons.home_outlined), selectedIcon: Icon(Icons.home_rounded), label: 'Início'), NavigationDestination(icon: Icon(Icons.forum_outlined), selectedIcon: Icon(Icons.forum_rounded), label: 'Conversa'), NavigationDestination(icon: Icon(Icons.folder_outlined), selectedIcon: Icon(Icons.folder_rounded), label: 'Materiais'), NavigationDestination(icon: Icon(Icons.school_outlined), selectedIcon: Icon(Icons.school_rounded), label: 'Estudar'), NavigationDestination(icon: Icon(Icons.person_outline), selectedIcon: Icon(Icons.person_rounded), label: 'Perfil')]);
}

class _HomePage extends StatelessWidget {
  const _HomePage();
  @override Widget build(BuildContext context) => CustomScrollView(physics: const BouncingScrollPhysics(), slivers: [
    SliverPadding(padding: const EdgeInsets.fromLTRB(20, 18, 20, 0), sliver: SliverToBoxAdapter(child: Row(children: [Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text('Turma C12AT', style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w800, letterSpacing: -1)), const SizedBox(height: 4), Text('Tudo da turma, num só lugar', style: Theme.of(context).textTheme.bodyMedium)])), _IconGlassButton(icon: Icons.notifications_none_rounded)]))),
    SliverPadding(padding: const EdgeInsets.fromLTRB(20, 22, 20, 28), sliver: SliverList(delegate: SliverChildListDelegate([
      const _HeroCard(), const SizedBox(height: 20),
      Text('Hoje na turma', style: TextStyle(fontSize: 21, fontWeight: FontWeight.w750, color: Theme.of(context).colorScheme.onSurface)), const SizedBox(height: 10),
      const Row(children: [Expanded(child: _Metric(icon: Icons.forum_outlined, value: '0', label: 'mensagens')), SizedBox(width: 10), Expanded(child: _Metric(icon: Icons.description_outlined, value: '0', label: 'materiais'))]),
      const SizedBox(height: 18), const _GlassPanel(icon: Icons.campaign_outlined, title: 'Avisos importantes', body: 'Nenhum aviso fixado no momento.'), const SizedBox(height: 12), const _GlassPanel(icon: Icons.auto_stories_outlined, title: 'Materiais recentes', body: 'Os materiais compartilhados pela turma aparecerão aqui.'), const SizedBox(height: 20),
      Row(children: [Expanded(child: _Action(icon: Icons.forum_outlined, text: 'Abrir conversa', filled: true)), const SizedBox(width: 10), Expanded(child: _Action(icon: Icons.auto_awesome_outlined, text: 'Estudar'))])
    ])))
  ]);
}

class _HeroCard extends StatelessWidget {
  const _HeroCard();
  @override Widget build(BuildContext context) => Container(padding: const EdgeInsets.all(22), decoration: BoxDecoration(borderRadius: BorderRadius.circular(30), gradient: const LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [Color(0xFFE8F1EF), Color(0xFFD5E5E2)]), border: Border.all(color: Colors.white.withValues(alpha: .85)), boxShadow: const [BoxShadow(offset: Offset(7, 8), blurRadius: 18, color: Color(0x220E2529)), BoxShadow(offset: Offset(-5, -5), blurRadius: 14, color: Color(0xAAFFFFFF))]), child: const Row(children: [CircleAvatar(radius: 29, backgroundColor: Color(0x99FFFFFF), child: Icon(Icons.groups_rounded, size: 29)), SizedBox(width: 16), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text('A turma inteira dentro de um único app', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800)), SizedBox(height: 6), Text('Converse, partilhe materiais e estude juntos.', style: TextStyle(height: 1.3))]))]));
}

class _Metric extends StatelessWidget { const _Metric({required this.icon, required this.value, required this.label}); final IconData icon; final String value, label; @override Widget build(BuildContext context) => Container(padding: const EdgeInsets.all(17), decoration: BoxDecoration(color: Theme.of(context).colorScheme.surface, borderRadius: BorderRadius.circular(22), border: Border.all(color: Theme.of(context).dividerColor.withValues(alpha: .35)), boxShadow: [BoxShadow(offset: const Offset(4, 5), blurRadius: 11, color: Colors.black.withValues(alpha: .07)), BoxShadow(offset: const Offset(-3, -3), blurRadius: 8, color: Colors.white.withValues(alpha: .7))]), child: Row(children: [Icon(icon, size: 22), const SizedBox(width: 12), Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(value, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800)), Text(label, style: Theme.of(context).textTheme.bodySmall)])])); }

class _GlassPanel extends StatelessWidget { const _GlassPanel({required this.icon, required this.title, required this.body}); final IconData icon; final String title, body; @override Widget build(BuildContext context) { final dark = Theme.of(context).brightness == Brightness.dark; return Container(padding: const EdgeInsets.all(18), decoration: BoxDecoration(color: dark ? const Color(0xCC1A2224) : const Color(0x99FFFFFF), borderRadius: BorderRadius.circular(24), border: Border.all(color: Colors.white.withValues(alpha: dark ? .1 : .75)), boxShadow: [BoxShadow(offset: const Offset(5, 6), blurRadius: 14, color: Colors.black.withValues(alpha: .07)), BoxShadow(offset: const Offset(-4, -4), blurRadius: 10, color: Colors.white.withValues(alpha: dark ? .02 : .75))]), child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [Container(width: 42, height: 42, decoration: BoxDecoration(shape: BoxShape.circle, color: dark ? const Color(0xFF263436) : const Color(0xFFE7EFED)), child: Icon(icon, size: 20)), const SizedBox(width: 13), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(title, style: Theme.of(context).textTheme.titleMedium), const SizedBox(height: 6), Text(body, style: Theme.of(context).textTheme.bodyMedium?.copyWith(height: 1.35))]))])); } }

class _Action extends StatelessWidget { const _Action({required this.icon, required this.text, this.filled = false}); final IconData icon; final String text; final bool filled; @override Widget build(BuildContext context) => Container(height: 54, decoration: BoxDecoration(color: filled ? Theme.of(context).colorScheme.primary : Colors.transparent, borderRadius: BorderRadius.circular(19), border: Border.all(color: filled ? Colors.transparent : Theme.of(context).dividerColor), boxShadow: filled ? const [BoxShadow(offset: Offset(3, 4), blurRadius: 9, color: Color(0x22000000))] : null), child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(icon, size: 19, color: filled ? Colors.white : null), const SizedBox(width: 8), Text(text, style: TextStyle(fontWeight: FontWeight.w700, color: filled ? Colors.white : null))])); }

class _IconGlassButton extends StatelessWidget { const _IconGlassButton({required this.icon}); final IconData icon; @override Widget build(BuildContext context) => Container(width: 48, height: 48, decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.white.withValues(alpha: .58), border: Border.all(color: Colors.white.withValues(alpha: .82)), boxShadow: const [BoxShadow(offset: Offset(3, 4), blurRadius: 9, color: Color(0x18000000)), BoxShadow(offset: Offset(-3, -3), blurRadius: 8, color: Color(0x66FFFFFF))]), child: Icon(icon)); }

class _PlaceholderPage extends StatelessWidget { const _PlaceholderPage(this.title, this.icon); final String title; final IconData icon; @override Widget build(BuildContext context) => Center(child: Column(mainAxisSize: MainAxisSize.min, children: [Icon(icon, size: 42), const SizedBox(height: 12), Text(title, style: Theme.of(context).textTheme.headlineSmall)])); }
