import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/widgets.dart';
import '../../data/app_state.dart';
import 'login_screen.dart';
import 'recuperar_screen.dart';

/// HU02.2_12: entrar con un código que llega por WhatsApp (solo clientes).
class WhatsappScreen extends StatefulWidget {
  const WhatsappScreen({super.key});

  @override
  State<WhatsappScreen> createState() => _WhatsappScreenState();
}

class _WhatsappScreenState extends State<WhatsappScreen> {
  final _form = GlobalKey<FormState>();
  final _cel = TextEditingController(text: '300 445 1287');
  bool _enviado = false;

  @override
  void dispose() {
    _cel.dispose();
    super.dispose();
  }

  void _accion() {
    if (!_form.currentState!.validate()) return;
    if (!_enviado) {
      setState(() => _enviado = true);
      return;
    }
    Navigator.of(context).popUntil((r) => r.isFirst);
    AppScope.read(context).entrarComoCliente();
  }

  @override
  Widget build(BuildContext context) => AuthFrame(
    title: _enviado ? 'Escribe el código' : 'Entra con WhatsApp',
    lead: _enviado
        ? 'Te lo enviamos por WhatsApp al ${_cel.text}. Vence en 10 minutos.'
        : 'Te enviamos un código de 6 dígitos al celular de tu cuenta.',
    children: [
      Form(
        key: _form,
        child: _enviado
            ? const CodigoField(label: 'Código de WhatsApp')
            : JkField(
                label: 'Celular',
                controller: _cel,
                keyboard: TextInputType.phone,
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'[0-9 ]')),
                ],
                validator: (v) => (v ?? '').replaceAll(' ', '').length != 10
                    ? 'Escribe los 10 dígitos de tu celular'
                    : null,
              ),
      ),
      JkButton(_enviado ? 'Entrar' : 'Enviar código', onPressed: _accion),
      if (_enviado) ...[
        const SizedBox(height: 10),
        JkButton.ghost(
          'Cambiar el celular',
          onPressed: () => setState(() => _enviado = false),
        ),
      ],
    ],
  );
}
