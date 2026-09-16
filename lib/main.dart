import 'package:flutter/material.dart';

void main() {
  runApp(const TurmaC12ATApp());
}

class TurmaC12ATApp extends StatelessWidget {
  const TurmaC12ATApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Turma C12AT',
      theme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.light,
        colorSchemeSeed: const Color(0xFF355C7D),
        scaffoldBackgroundColor: const Color(0xFFF7F7F4),
      ),
      darkTheme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        colorSchemeSeed: const Color(0xFF8FB3CF),
      ),
      themeMode: ThemeMode.system,
      home: const HomeShell(),
    );
  }
}

class HomeShell extends StatefulWidget {
  const HomeShell({super.key});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int index = 0;

  static const pages = <Widget>[
    _HomePage(),
    _PlaceholderPage(title: 'Conversa', icon: Icons.forum_outlined),
    _PlaceholderPage(title: 'Materiais', icon: Icons.folder_outlined),
    _PlaceholderPage(title: 'Estudar', icon: Icons.school_outlined),
    _PlaceholderPage(title: 'Perfil', icon: Icons.person_outline),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(child: pages[index]),
      bottomNavigationBar: NavigationBar(
        selectedIndex: index,
        onDestinationSelected: (value) => setState(() => index = value),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.home_outlined), selectedIcon: Icon(Icons.home), label: 'Início'),
          NavigationDestination(icon: Icon(Icons.forum_outlined), selectedIcon: Icon(Icons.forum), label: 'Conversa'),
          NavigationDestination(icon: Icon(Icons.folder_outlined), selectedIcon: Icon(Icons.folder), label: 'Materiais'),
          NavigationDestination(icon: Icon(Icons.school_outlined), selectedIcon: Icon(Icons.school), label: 'Estudar'),
          NavigationDestination(icon: Icon(Icons.person_outline), selectedIcon: Icon(Icons.person), label: 'Perfil'),
        ],
      ),
    );
  }
}

class _HomePage extends StatelessWidget {
  const _HomePage();

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      slivers: [
        SliverAppBar.large(
          title: const Text('Turma C12AT'),
          actions: [
            IconButton(onPressed: () {}, icon: const Icon(Icons.notifications_none)),
          ],
        ),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
          sliver: SliverList(
            delegate: SliverChildListDelegate([
              _SectionCard(
                icon: Icons.campaign_outlined,
                title: 'Avisos importantes',
                child: const Text('Nenhum aviso fixado no momento.'),
              ),
              const SizedBox(height: 14),
              _SectionCard(
                icon: Icons.forum_outlined,
                title: 'Hoje na turma',
                child: const Text('A conversa coletiva e a atividade da turma aparecerão aqui.'),
              ),
              const SizedBox(height: 14),
              _SectionCard(
                icon: Icons.auto_stories_outlined,
                title: 'Materiais recentes',
                child: const Text('Os materiais compartilhados pela turma aparecerão aqui.'),
              ),
              const SizedBox(height: 14),
              FilledButton.icon(
                onPressed: () {},
                icon: const Icon(Icons.forum_outlined),
                label: const Text('Abrir conversa'),
              ),
              const SizedBox(height: 10),
              OutlinedButton.icon(
                onPressed: () {},
                icon: const Icon(Icons.auto_awesome_outlined),
                label: const Text('Estudar com IA'),
              ),
            ]),
          ),
        ),
      ],
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({required this.icon, required this.title, required this.child});

  final IconData icon;
  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [Icon(icon), const SizedBox(width: 10), Text(title, style: Theme.of(context).textTheme.titleMedium)]),
            const SizedBox(height: 12),
            child,
          ],
        ),
      ),
    );
  }
}

class _PlaceholderPage extends StatelessWidget {
  const _PlaceholderPage({required this.title, required this.icon});
  final String title;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [Icon(icon, size: 42), const SizedBox(height: 12), Text(title, style: Theme.of(context).textTheme.headlineSmall)],
      ),
    );
  }
}
