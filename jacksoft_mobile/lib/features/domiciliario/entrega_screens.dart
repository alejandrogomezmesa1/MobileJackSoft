import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import 'package:jacksoft_mobile/core/format.dart';
import 'package:jacksoft_mobile/core/shell.dart';
import 'package:jacksoft_mobile/core/theme.dart';
import 'package:jacksoft_mobile/core/widgets.dart';
import 'package:jacksoft_mobile/data/app_state.dart';
import 'package:jacksoft_mobile/data/models.dart';
import 'package:jacksoft_mobile/features/cliente/incidencias_screens.dart';

/// Detalle de la entrega: dirección, indicaciones, alergias y cocas.
class DetalleEntrega extends StatelessWidget {
  const DetalleEntrega(this.p, {super.key});
  final Parada p;

  @override
  Widget build(BuildContext context) {
    AppScope.of(context); // se redibuja al cambiar la parada
    return JkPage(
      title: 'Entrega ${p.orden}',
      subtitle: p.cliente,
      bottom: p.pendiente
          ? JkButton(
              'Confirmar entrega',
              onPressed: () => pushPage(context, ConfirmarEntrega(p)),
            )
          : null,
      children: [
        JkCard(
          child: Row(
            children: [
              Avatar(iniciales(p.cliente), size: 52),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(p.cliente, style: JkText.display(22)),
                    Text(
                      p.celular,
                      style: JkText.body(14, c: JkColors.inkMuted),
                    ),
                  ],
                ),
              ),
              StatusBadge.auto(p.resultado ?? p.estado.label),
            ],
          ),
        ),
        JkCard(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          child: Column(
            children: [
              InfoRow('Dirección', '${p.direccion}, ${p.barrio}'),
              InfoRow(
                'Indicaciones',
                p.notas.isEmpty ? 'Sin indicaciones' : p.notas,
              ),
              InfoRow('Proteína', p.preferencia.label, last: true),
            ],
          ),
        ),
        if (p.alergias.isNotEmpty)
          Notice(
            'Alergias: '
            '${p.alergias.map((a) => a.label.toLowerCase()).join(', ')}. '
            'Verifica que la coca diga su nombre.',
            tone: Tone.warn,
            icon: Icons.health_and_safety_outlined,
          ),
        const SectionTitle('Cocas'),
        JkCard(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          child: Column(
            children: [
              InfoRow('Entregas lleno', 'Juego ${p.juegoEntregar}'),
              InfoRow(
                'Recoges vacío',
                p.juegoRecoger == null
                    ? 'Nada (primera entrega)'
                    : 'Juego ${p.juegoRecoger}',
              ),
              InfoRow(
                'Registro',
                p.cocasRegistradas ? 'Registradas' : 'Sin registrar',
                last: true,
              ),
            ],
          ),
        ),
        Row(
          children: [
            Expanded(
              child: JkButton.ghost(
                'Navegar',
                icon: Icons.navigation_outlined,
                onPressed: () =>
                    navegarA(context, '${p.direccion}, ${p.barrio}'),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: JkButton.ghost(
                'Llamar',
                icon: Icons.call_outlined,
                onPressed: () => llamar(context, p.celular),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        JkButton.ghost(
          p.cocasRegistradas ? 'Ver registro de cocas' : 'Registrar cocas',
          icon: Icons.recycling,
          onPressed: () => pushPage(context, CocasScreen(p)),
        ),
        if (!p.pendiente) ...[
          const SizedBox(height: 14),
          Notice(
            '${p.resultado} a las ${hora(p.horaEntrega!)}. Ya se le avisó '
            'al cliente y al administrador.',
            tone: p.estado == EstadoEntrega.entregada ? Tone.ok : Tone.bad,
            icon: p.estado == EstadoEntrega.entregada
                ? Icons.check_circle_outline
                : Icons.report_gmailerrorred_outlined,
          ),
        ],
      ],
    );
  }
}

/// HU07.2_07: confirmar la entrega o decir por qué no se pudo.
class ConfirmarEntrega extends StatelessWidget {
  const ConfirmarEntrega(this.p, {super.key});
  final Parada p;

  static const List<(String, String, IconData, Tone)> _opciones = [
    (
      'Entregado',
      'El cliente o la portería recibió',
      Icons.check_circle_outline,
      Tone.ok,
    ),
    (
      'Cliente ausente',
      'Esperaste 10 minutos y nadie recibió',
      Icons.person_off_outlined,
      Tone.warn,
    ),
    (
      'Dirección incorrecta',
      'La dirección no existe o no corresponde',
      Icons.wrong_location_outlined,
      Tone.warn,
    ),
    (
      'Entrega fallida',
      'Otro motivo: lo cuentas en la novedad',
      Icons.cancel_outlined,
      Tone.bad,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final st = AppScope.of(context);
    return JkPage(
      title: 'Confirmar entrega',
      subtitle: '${p.cliente} · ${p.direccion}',
      children: [
        for (final o in _opciones)
          JkCard(
            onTap: () async {
              final ok = await confirmSheet(
                context,
                title: o.$1,
                message:
                    'Se registra a las ${hora(st.ahora)} y se le avisa a '
                    '${p.cliente.split(' ').first} y al administrador.',
                confirmLabel: 'Confirmar',
              );
              if (!ok || !context.mounted) return;
              st.cerrarParada(p, o.$1);
              showToast(
                context,
                o.$1 == 'Entregado'
                    ? 'Entrega confirmada'
                    : 'Novedad registrada: ${o.$1.toLowerCase()}',
              );
              Navigator.of(context).popUntil((r) => r.isFirst);
            },
            child: Row(
              children: [
                IconTile(o.$3, size: 44, tone: o.$4),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(o.$1, style: JkText.body(16, w: FontWeight.w700)),
                      Text(
                        o.$2,
                        style: JkText.body(13.5, c: JkColors.inkMuted),
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right, color: JkColors.inkMuted),
              ],
            ),
          ),
        JkCard(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          child: InfoRow('Hora de registro', hora(st.ahora), last: true),
        ),
      ],
    );
  }
}

/// HU07.2_08: cocas entregadas y recogidas, con el estado físico de cada pieza.
class CocasScreen extends StatefulWidget {
  const CocasScreen(this.p, {super.key});
  final Parada p;

  @override
  State<CocasScreen> createState() => _CocasScreenState();
}

class _CocasScreenState extends State<CocasScreen> {
  bool _entregado = true;
  late bool _recogido = widget.p.juegoRecoger != null;
  final Map<String, EstadoFisicoRecipiente> _estado = {
    for (final pz in piezasCoca) pz: EstadoFisicoRecipiente.bueno,
  };

  @override
  Widget build(BuildContext context) {
    final p = widget.p;
    final hayDano = _estado.values.any(
      (e) => e != EstadoFisicoRecipiente.bueno,
    );
    return JkPage(
      title: 'Registrar cocas',
      subtitle: p.cliente,
      bottom: JkButton(
        'Guardar registro',
        onPressed: () {
          final st = AppScope.read(context)..registrarCocas(p);
          if (hayDano) {
            final malas = _estado.entries.where(
              (e) => e.value != EstadoFisicoRecipiente.bueno,
            );
            st.reportarNovedad(
              _recogido
                  ? TipoIncidencia.cocaDefectuosa
                  : TipoIncidencia.cocaNoDevuelta,
              malas
                  .map((e) => '${e.key}: ${e.value.label.toLowerCase()}')
                  .join(', '),
              p.cliente,
              foto: false,
            );
          } else if (p.juegoRecoger != null && !_recogido) {
            st.reportarNovedad(
              TipoIncidencia.cocaNoDevuelta,
              'No entregó el juego ${p.juegoRecoger} vacío.',
              p.cliente,
              foto: false,
            );
          }
          showToast(context, 'Cocas registradas');
          Navigator.pop(context);
        },
      ),
      children: [
        JkCard(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          child: Column(
            children: [
              JkSwitchRow(
                title: 'Entregué el juego ${p.juegoEntregar} lleno',
                value: _entregado,
                onChanged: (v) => setState(() => _entregado = v),
              ),
              if (p.juegoRecoger != null)
                JkSwitchRow(
                  title: 'Recogí el juego ${p.juegoRecoger} vacío',
                  subtitle: _recogido
                      ? null
                      : 'Se reporta como coca no devuelta',
                  value: _recogido,
                  onChanged: (v) => setState(() => _recogido = v),
                ),
            ],
          ),
        ),
        if (_recogido) ...[
          SectionTitle('Estado del juego ${p.juegoRecoger}'),
          for (final pz in piezasCoca)
            JkCard(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Coca de ${pz.toLowerCase()}',
                    style: JkText.body(15, w: FontWeight.w700),
                  ),
                  const SizedBox(height: 8),
                  Segmented<EstadoFisicoRecipiente>(
                    options: EstadoFisicoRecipiente.values,
                    selected: _estado[pz]!,
                    label: (e) => e.label,
                    onChanged: (e) => setState(() => _estado[pz] = e),
                  ),
                ],
              ),
            ),
          if (hayDano)
            const Notice(
              'Al guardar se crea una novedad de coca defectuosa para el '
              'administrador.',
              tone: Tone.warn,
              icon: Icons.report_gmailerrorred_outlined,
            ),
        ],
      ],
    );
  }
}

/// HU07.2_09 / HU07.3_09: novedad o incidencia de ruta, con foto.
class NovedadScreen extends StatefulWidget {
  const NovedadScreen({super.key, this.parada});
  final Parada? parada;

  @override
  State<NovedadScreen> createState() => _NovedadScreenState();
}

class _NovedadScreenState extends State<NovedadScreen> {
  TipoIncidencia _tipo = TipoIncidencia.ausenciaCliente;
  late String? _cliente = widget.parada?.cliente;
  final _desc = TextEditingController();
  XFile? _foto;
  final _form = GlobalKey<FormState>();

  @override
  void dispose() {
    _desc.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final st = AppScope.of(context);
    final mias = st.novedades;
    return JkPage(
      title: 'Reportar novedad',
      subtitle: st.rutaNombre,
      children: [
        JkCard(
          child: Form(
            key: _form,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                JkDropdown<TipoIncidencia>(
                  label: 'Tipo',
                  value: _tipo,
                  items: TipoIncidencia.deRuta,
                  itemLabel: (t) => t.label,
                  onChanged: (v) => setState(() => _tipo = v ?? _tipo),
                ),
                JkDropdown<String?>(
                  label: 'Cliente (opcional)',
                  value: _cliente,
                  items: [null, ...st.paradas.map((p) => p.cliente)],
                  itemLabel: (c) => c ?? 'Toda la ruta',
                  onChanged: (v) => setState(() => _cliente = v),
                ),
                JkField(
                  label: 'Descripción',
                  controller: _desc,
                  maxLines: 4,
                  hint: 'Qué pasó',
                  validator: (v) => (v ?? '').trim().length < 5
                      ? 'Cuéntalo en pocas palabras'
                      : null,
                ),
                Text(
                  'Foto de evidencia',
                  style: JkText.body(
                    14,
                    w: FontWeight.w600,
                    c: JkColors.inkSoft,
                  ),
                ),
                const SizedBox(height: 6),
                PhotoField(
                  file: _foto,
                  label: 'Toca para tomar la foto de evidencia',
                  onChanged: (f) => setState(() => _foto = f),
                ),
                JkButton(
                  'Enviar novedad',
                  onPressed: () {
                    if (!_form.currentState!.validate()) return;
                    st.reportarNovedad(
                      _tipo,
                      _desc.text.trim(),
                      _cliente,
                      foto: _foto != null,
                    );
                    showToast(context, 'Novedad enviada al administrador');
                    Navigator.pop(context);
                  },
                ),
              ],
            ),
          ),
        ),
        if (mias.isNotEmpty) ...[
          const SectionTitle('Tus novedades'),
          JkCard(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            child: Column(
              children: [
                for (final (i, n) in mias.indexed)
                  JkListItem(
                    title: n.tipo.label,
                    subtitle:
                        '#${n.id} · ${n.cliente ?? 'Ruta'} · '
                        '${fechaCorta(n.fecha)}',
                    trailing: StatusBadge.auto(n.estado.label),
                    last: i == mias.length - 1,
                    onTap: () => pushPage(context, IncidenciaDetalle(n)),
                  ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}
