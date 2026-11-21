import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/theme.dart';
import '../../core/widgets.dart';
import '../../data/app_state.dart';
import '../../data/models.dart';
import 'login_screen.dart';

/// HU06.1_08: registro del cliente desde la app (canal_registro = app_movil).
class RegistroScreen extends StatefulWidget {
  const RegistroScreen({super.key});

  @override
  State<RegistroScreen> createState() => _RegistroScreenState();
}

class _RegistroScreenState extends State<RegistroScreen> {
  final _form = GlobalKey<FormState>();
  final _nombre = TextEditingController();
  final _correo = TextEditingController();
  final _cel = TextEditingController();
  final _doc = TextEditingController();
  final _dir = TextEditingController();
  final _barrio = TextEditingController();
  final _notas = TextEditingController();
  final _clave = TextEditingController();
  String _tipoDoc = 'CC';
  String _municipio = municipios.first;
  final _alergias = <Alergeno>{};
  bool _terminos = false;
  bool _avisos = true;
  String? _error;

  @override
  void dispose() {
    for (final c in [
      _nombre,
      _correo,
      _cel,
      _doc,
      _dir,
      _barrio,
      _notas,
      _clave,
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  String? _req(String? v) =>
      (v ?? '').trim().isEmpty ? 'Este dato es obligatorio' : null;

  void _crear() {
    final ok = _form.currentState!.validate();
    if (!_terminos) {
      setState(
        () => _error =
            'Para crear la cuenta acepta los términos y la política de datos.',
      );
      return;
    }
    if (!ok) return;
    Navigator.of(context).popUntil((r) => r.isFirst);
    AppScope.read(context).registrar(
      nombre: _nombre.text.trim(),
      correo: _correo.text.trim(),
      celular: _cel.text.trim(),
      tipoDocumento: _tipoDoc,
      documento: _doc.text.trim(),
      direccion: Direccion(
        direccion: _dir.text.trim(),
        barrio: _barrio.text.trim(),
        municipio: _municipio,
        notas: _notas.text.trim(),
      ),
      alergias: {..._alergias},
    );
  }

  @override
  Widget build(BuildContext context) => AuthFrame(
    title: 'Crea tu cuenta',
    lead:
        'Con tu cuenta eliges el plan, subes el comprobante y sigues tus almuerzos.',
    children: [
      Form(
        key: _form,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            JkField(
              label: 'Nombre completo',
              controller: _nombre,
              hint: 'Laura Gómez',
              validator: _req,
            ),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  width: 104,
                  child: JkDropdown<String>(
                    label: 'Tipo',
                    value: _tipoDoc,
                    items: const ['CC', 'CE', 'PA', 'PPT', 'NIT'],
                    itemLabel: (s) => s,
                    onChanged: (v) => setState(() => _tipoDoc = v ?? 'CC'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: JkField(
                    label: 'Número de documento',
                    controller: _doc,
                    keyboard: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    validator: _req,
                  ),
                ),
              ],
            ),
            JkField(
              label: 'Celular (WhatsApp)',
              controller: _cel,
              hint: '300 000 0000',
              keyboard: TextInputType.phone,
              validator: (v) => (v ?? '').replaceAll(' ', '').length != 10
                  ? 'Escribe los 10 dígitos'
                  : null,
            ),
            JkField(
              label: 'Correo electrónico',
              controller: _correo,
              hint: 'tucorreo@ejemplo.com',
              keyboard: TextInputType.emailAddress,
              validator: (v) =>
                  (v ?? '').contains('@') ? null : 'Escribe un correo válido',
            ),
            const SectionTitle('Dirección de entrega'),
            JkField(
              label: 'Dirección',
              controller: _dir,
              hint: 'Cra 76 #33A-21, apto 502',
              validator: _req,
            ),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: JkField(
                    label: 'Barrio',
                    controller: _barrio,
                    validator: _req,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: JkDropdown<String>(
                    label: 'Municipio',
                    value: _municipio,
                    items: municipios,
                    itemLabel: (s) => s,
                    onChanged: (v) =>
                        setState(() => _municipio = v ?? municipios.first),
                  ),
                ),
              ],
            ),
            JkField(
              label: 'Indicaciones para el domiciliario',
              controller: _notas,
              maxLines: 2,
              hint: 'Torre, apartamento o portería',
              helper:
                  'Obligatorio si vives o trabajas en un edificio. Si recibes en dos direcciones, agrega la segunda desde tu perfil (modalidad híbrida).',
            ),
            const SectionTitle('Alergias'),
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Text(
                'Marca lo que no puedes comer. La cocina te cambia el plato ese día.',
                style: JkText.body(14, c: JkColors.inkSoft),
              ),
            ),
            ChipSelector<Alergeno>(
              options: Alergeno.values,
              selected: _alergias,
              label: (a) => a.label,
              onToggle: (a) => setState(
                () => _alergias.contains(a)
                    ? _alergias.remove(a)
                    : _alergias.add(a),
              ),
            ),
            const SizedBox(height: 18),
            JkField(
              label: 'Contraseña',
              controller: _clave,
              password: true,
              validator: (v) =>
                  (v ?? '').length < 8 ? 'Usa al menos 8 caracteres' : null,
            ),
            JkField(
              label: 'Confirmar contraseña',
              password: true,
              validator: (v) =>
                  v != _clave.text ? 'Las contraseñas no coinciden' : null,
            ),
          ],
        ),
      ),
      JkSwitchRow(
        title: 'Acepto los términos y la política de datos',
        value: _terminos,
        onChanged: (v) => setState(() {
          _terminos = v;
          _error = null;
        }),
      ),
      JkSwitchRow(
        title: 'Avisos de mis almuerzos por WhatsApp',
        subtitle: 'Te escribimos 5 minutos antes de llegar.',
        value: _avisos,
        onChanged: (v) => setState(() => _avisos = v),
      ),
      const SizedBox(height: 12),
      if (_error != null)
        Notice(_error!, tone: Tone.bad, icon: Icons.error_outline),
      JkButton('Crear cuenta', onPressed: _crear),
    ],
  );
}
