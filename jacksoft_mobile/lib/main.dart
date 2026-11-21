import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'package:jacksoft_mobile/core/theme.dart';
import 'package:jacksoft_mobile/data/app_state.dart';
import 'package:jacksoft_mobile/data/models.dart';
import 'package:jacksoft_mobile/features/auth/login_screen.dart';
import 'package:jacksoft_mobile/features/cliente/cliente_shell.dart';
import 'package:jacksoft_mobile/features/domiciliario/domiciliario_shell.dart';
import 'package:jacksoft_mobile/features/splash_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle.dark);
  runApp(JackSoftApp(state: AppState()));
}

class JackSoftApp extends StatelessWidget {
  const JackSoftApp({required this.state, super.key});
  final AppState state;

  @override
  Widget build(BuildContext context) => AppScope(
    state: state,
    child: MaterialApp(
      title: 'La Coca de Jacks',
      debugShowCheckedModeBanner: false,
      theme: buildJkTheme(),
      locale: const Locale('es', 'CO'),
      supportedLocales: const [Locale('es', 'CO'), Locale('es')],
      localizationsDelegates: GlobalMaterialLocalizations.delegates,
      home: const _Root(),
    ),
  );
}

/// splash → acceso → app según el rol (redirección por rol).
class _Root extends StatefulWidget {
  const _Root();

  @override
  State<_Root> createState() => _RootState();
}

class _RootState extends State<_Root> {
  bool _splash = true;

  @override
  Widget build(BuildContext context) {
    final st = AppScope.of(context);
    final child = _splash
        ? SplashScreen(onDone: () => setState(() => _splash = false))
        : switch (st.rol) {
            null => const LoginScreen(),
            Rol.cliente => const ClienteShell(),
            Rol.domiciliario => const DomiciliarioShell(),
          };
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 220),
      child: KeyedSubtree(key: ValueKey('${_splash}_${st.rol}'), child: child),
    );
  }
}
