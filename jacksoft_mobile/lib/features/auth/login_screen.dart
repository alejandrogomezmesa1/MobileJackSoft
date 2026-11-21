import 'package:flutter/material.dart';

import '../../core/shell.dart';
import '../../core/theme.dart';
import '../../core/widgets.dart';
import '../../data/app_state.dart';
import '../../data/models.dart';
import 'recuperar_screen.dart';
import 'registro_screen.dart';
import 'whatsapp_screen.dart';

/// Marco común de las pantallas de acceso.
class AuthFrame extends StatelessWidget {
  const AuthFrame({
    super.key,
    required this.title,
    required this.lead,
    required this.children,
  });
  final String title;
  final String lead;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final canPop = Navigator.of(context).canPop();
    return Scaffold(
      backgroundColor: JkColors.bg,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
          children: [
            Row(
              children: [
                if (canPop)
                  SquareIconButton(
                    icon: Icons.arrow_back,
                    tooltip: 'Volver',
                    onTap: () => Navigator.of(context).maybePop(),
                  )
                else
                  const SizedBox(height: JkSpace.touch),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const BrandMark(size: 48),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('La Coca de Jacks', style: JkText.display(20)),
                      Text(
                        'Clientes y domiciliarios',
                        style: JkText.body(13, c: JkColors.inkMuted),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 28),
            Text(title, style: JkText.display(30)),
            const SizedBox(height: 4),
            Text(lead, style: JkText.body(15, c: JkColors.inkSoft)),
            const SizedBox(height: 22),
            ...children,
          ],
        ),
      ),
    );
  }
}

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  Rol _demo = Rol.cliente;
  final _id = TextEditingController(text: 'laura.gomez@correo.com');
  final _clave = TextEditingController(text: '12345678');
  bool _recordarme = true;
  String? _error;

  void _elegirDemo(Rol r) => setState(() {
    _demo = r;
    _error = null;
    _id.text = r == Rol.cliente
        ? 'laura.gomez@correo.com'
        : 'julian.ospina@lacocadejacks.co';
    _clave.text = '12345678';
  });

  void _ingresar() {
    final err = AppScope.read(context).iniciarSesion(_id.text, _clave.text);
    setState(() => _error = err);
  }

  @override
  void dispose() {
    _id.dispose();
    _clave.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AuthFrame(
    title: 'Inicia sesión',
    lead:
        'Entra con tu correo o tu celular. Te llevamos a tu cuenta de cliente o a tu ruta de domiciliario.',
    children: [
      Segmented<Rol>(
        options: Rol.values,
        selected: _demo,
        label: (r) => r == Rol.cliente ? 'Cliente' : 'Domiciliario',
        icons: const [Icons.person_outline, Icons.delivery_dining_outlined],
        onChanged: _elegirDemo,
      ),
      Padding(
        padding: const EdgeInsets.only(top: 6, bottom: 18),
        child: Text(
          'Modo demo: elige un rol para llenar una cuenta de prueba.',
          style: JkText.body(12.5, c: JkColors.inkMuted),
        ),
      ),
      AutofillGroup(
        child: Column(
          children: [
            JkField(
              label: 'Correo o celular',
              controller: _id,
              keyboard: TextInputType.emailAddress,
              autofillHints: const [
                AutofillHints.email,
                AutofillHints.telephoneNumber,
              ],
            ),
            JkField(
              label: 'Contraseña',
              controller: _clave,
              password: true,
              autofillHints: const [AutofillHints.password],
            ),
          ],
        ),
      ),
      Row(
        children: [
          Expanded(
            child: JkSwitchRow(
              title: 'Recordarme',
              value: _recordarme,
              onChanged: (v) => setState(() => _recordarme = v),
            ),
          ),
        ],
      ),
      Align(
        alignment: Alignment.centerRight,
        child: TextButton(
          onPressed: () => pushPage(context, const RecuperarScreen()),
          style: TextButton.styleFrom(
            foregroundColor: JkColors.ink,
            minimumSize: const Size(0, JkSpace.touch),
          ),
          child: Text(
            '¿Olvidaste tu contraseña?',
            style: JkText.body(
              14,
              w: FontWeight.w700,
            ).copyWith(decoration: TextDecoration.underline),
          ),
        ),
      ),
      const SizedBox(height: 8),
      if (_error != null)
        Notice(_error!, tone: Tone.bad, icon: Icons.error_outline),
      JkButton('Ingresar', onPressed: _ingresar),
      if (_demo == Rol.cliente) ...[
        const SizedBox(height: 22),
        Row(
          children: [
            const Expanded(child: Divider()),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10),
              child: Text(
                'o entra con',
                style: JkText.body(13, c: JkColors.inkMuted),
              ),
            ),
            const Expanded(child: Divider()),
          ],
        ),
        const SizedBox(height: 14),
        JkButton.ghost(
          'Código por WhatsApp',
          icon: Icons.chat_outlined,
          onPressed: () => pushPage(context, const WhatsappScreen()),
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: JkButton.ghost(
                'Google',
                icon: Icons.g_mobiledata,
                onPressed: () => AppScope.read(context).entrarComoCliente(),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: JkButton.ghost(
                'Apple',
                icon: Icons.apple,
                onPressed: () => AppScope.read(context).entrarComoCliente(),
              ),
            ),
          ],
        ),
      ],
      const SizedBox(height: 22),
      Center(
        child: Wrap(
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            Text(
              '¿No tienes cuenta? ',
              style: JkText.body(14, c: JkColors.inkSoft),
            ),
            TextButton(
              onPressed: () => pushPage(context, const RegistroScreen()),
              style: TextButton.styleFrom(
                foregroundColor: JkColors.ink,
                minimumSize: const Size(0, JkSpace.touch),
              ),
              child: Text(
                'Regístrate',
                style: JkText.body(
                  14,
                  w: FontWeight.w700,
                ).copyWith(decoration: TextDecoration.underline),
              ),
            ),
          ],
        ),
      ),
      Center(
        child: Text(
          'Los domiciliarios los crea el administrador.',
          style: JkText.body(12.5, c: JkColors.inkMuted),
        ),
      ),
    ],
  );
}
