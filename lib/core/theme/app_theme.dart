import 'package:flutter/material.dart';

class AppTheme {
  static const accent = Color(0xFF315E68);
  static const lightBg = Color(0xFFF2F6F4);
  static const darkBg = Color(0xFF101617);

  static ThemeData light() => ThemeData(
        useMaterial3: true,
        brightness: Brightness.light,
        scaffoldBackgroundColor: lightBg,
        colorScheme: ColorScheme.fromSeed(seedColor: accent, brightness: Brightness.light).copyWith(primary: accent),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: const Color(0xFFEAF0EE),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(20), borderSide: BorderSide.none),
          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(20), borderSide: BorderSide.none),
          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(20), borderSide: const BorderSide(color: accent, width: 1.3)),
        ),
        navigationBarTheme: NavigationBarThemeData(
          backgroundColor: const Color(0xFFEAF0EE),
          indicatorColor: const Color(0xFFD1E2DF),
          elevation: 0,
          labelTextStyle: WidgetStatePropertyAll(TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
        ),
      );

  static ThemeData dark() => ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        scaffoldBackgroundColor: darkBg,
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF8DB9B8), brightness: Brightness.dark).copyWith(primary: const Color(0xFF8DB9B8)),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: const Color(0xFF1B2426),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(20), borderSide: BorderSide.none),
          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(20), borderSide: BorderSide.none),
          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(20), borderSide: const BorderSide(color: Color(0xFF8DB9B8), width: 1.3)),
        ),
        navigationBarTheme: const NavigationBarThemeData(backgroundColor: Color(0xFF182022), indicatorColor: Color(0xFF29383A), elevation: 0),
      );
}

class Surface extends StatelessWidget {
  const Surface({super.key, required this.child, this.padding, this.radius = 24, this.tint});
  final Widget child;
  final EdgeInsets? padding;
  final double radius;
  final Color? tint;

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final base = tint ?? (dark ? const Color(0xFF192224) : const Color(0xFFEAF0EE));
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: base,
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(color: dark ? Colors.white.withValues(alpha: .06) : Colors.white.withValues(alpha: .82)),
        boxShadow: [
          BoxShadow(offset: const Offset(6, 7), blurRadius: 15, color: Colors.black.withValues(alpha: dark ? .28 : .075)),
          BoxShadow(offset: const Offset(-5, -5), blurRadius: 13, color: dark ? Colors.white.withValues(alpha: .025) : Colors.white.withValues(alpha: .8)),
        ],
      ),
      child: child,
    );
  }
}

class Glass extends StatelessWidget {
  const Glass({super.key, required this.child, this.padding, this.radius = 24});
  final Widget child;
  final EdgeInsets? padding;
  final double radius;

  @override
  Widget build(BuildContext context) => Surface(
        radius: radius,
        padding: padding,
        tint: Theme.of(context).brightness == Brightness.dark ? const Color(0xFF182224) : const Color(0xFFEFF5F3),
        child: child,
      );
}
