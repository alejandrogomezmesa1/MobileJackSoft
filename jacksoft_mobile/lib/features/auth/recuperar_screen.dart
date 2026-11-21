import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/theme.dart';
import '../../core/widgets.dart';
import 'login_screen.dart';

/// Recuperar contraseña en 3 pasos: correo → código de 6 dígitos → nueva contraseña.
class RecuperarScreen extends StatefulWidget {
  const RecuperarScreen({super.key});

  @override
  State<RecuperarScreen> createState() => _RecuperarScreenState();
}

class _RecuperarScreenState extends State<RecuperarScreen> {
  int _paso = 1;
  final _form = GlobalKey<FormState>();
  final _clave = TextEditingController();

  @override
  void dispose() {
    _clave.dispose();
    super.dispose();
  }

  void _siguiente() {
    if (!_form.currentState!.validate()) return;
    if (_paso < 3) {
      setState(() => _paso++);
      return;
    }
    showToast(context, 'Contraseña actualizada. Ya puedes iniciar sesión.');
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final (titulo, lead) = switch (_paso) {
      1 => (
        'Recuperar contraseña',
        'Escribe el correo o el celular de tu cuenta y te enviamos un código.',
      ),
      2 => (
        'Verifica tu código',
        'Te enviamos un código de 6 dígitos. Vence en 10 minutos y tienes 5 intentos.',
      ),
      _ => ('Nueva contraseña', 'Usa al menos 8 caracteres.'),
    };
    return AuthFrame(
      title: titulo,
      lead: lead,
      children: [
        _Pasos(actual: _paso),
        const SizedBox(height: 18),
        Form(
          key: _form,
          child: Column(
            children: [
              if (_paso == 1)
                JkField(
                  label: 'Correo o celular',
                  hint: 'tucorreo@ejemplo.com',
                  keyboard: TextInputType.emailAddress,
                  validator: (v) => (v ?? '').trim().isEmpty
                      ? 'Escribe tu correo o celular'
                      : null,
                ),
              if (_paso == 2) ...[
                CodigoField(label: 'Código de verificación'),
                Align(
                  alignment: Alignment.centerLeft,
                  child: TextButton(
                    onPressed: () =>
                        showToast(context, 'Te enviamos un código nuevo'),
                    style: TextButton.styleFrom(foregroundColor: JkColors.ink),
                    child: Text(
                      '¿No te llegó? Reenviar código',
                      style: JkText.body(
                        14,
                        w: FontWeight.w700,
                      ).copyWith(decoration: TextDecoration.underline),
                    ),
                  ),
                ),
              ],
              if (_paso == 3) ...[
                JkField(
                  label: 'Nueva contraseña',
                  controller: _clave,
                  password: true,
                  validator: (v) =>
                      (v ?? '').length < 8 ? 'Usa al menos 8 caracteres' : null,
                ),
                JkField(
                  label: 'Confirmar nueva contraseña',
                  password: true,
                  validator: (v) =>
                      v != _clave.text ? 'Las contraseñas no coinciden' : null,
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 4),
        JkButton(switch (_paso) {
          1 => 'Enviar código',
          2 => 'Verificar código',
          _ => 'Guardar contraseña',
        }, onPressed: _siguiente),
      ],
    );
  }
}

class _Pasos extends StatelessWidget {
  const _Pasos({required this.actual});
  final int actual;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      for (var i = 1; i <= 3; i++) ...[
        if (i > 1) const SizedBox(width: 6),
        Expanded(
          child: Container(
            height: 4,
            color: i <= actual ? JkColors.ink : JkColors.hairline,
          ),
        ),
      ],
      const SizedBox(width: 10),
      Text('Paso $actual de 3', style: JkText.body(13, c: JkColors.inkMuted)),
    ],
  );
}

/// Campo para el código de 6 dígitos (estilo de comanda, monoespaciado).
class CodigoField extends StatelessWidget {
  const CodigoField({super.key, required this.label, this.controller});
  final String label;
  final TextEditingController? controller;

  @override
  Widget build(BuildContext context) => JkField(
    label: label,
    controller: controller,
    hint: '000000',
    keyboard: TextInputType.number,
    textAlign: TextAlign.center,
    style: JkText.mono(22, c: JkColors.ink).copyWith(letterSpacing: 8),
    inputFormatters: [
      FilteringTextInputFormatter.digitsOnly,
      LengthLimitingTextInputFormatter(6),
    ],
    autofillHints: const [AutofillHints.oneTimeCode],
    validator: (v) =>
        (v ?? '').length != 6 ? 'El código tiene 6 dígitos' : null,
  );
}
