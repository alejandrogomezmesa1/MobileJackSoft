import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter/services.dart';

import '../../core/format.dart';
import '../../core/shell.dart';
import '../../core/theme.dart';
import '../../core/widgets.dart';
import '../../data/app_state.dart';
import '../../data/models.dart';

/// HU06.2_13: estado de la suscripción, contador en vivo e historial de pagos.
class PlanTab extends StatelessWidget {
  const PlanTab({super.key});

  @override
  Widget build(BuildContext context) {
    final st = AppScope.of(context);
    if (!st.tienePlan) {
      return TabBody(
        children: [
          JkCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Aún no tienes plan', style: JkText.display(24)),
                const SizedBox(height: 4),
                Text(
                  'Semanal, quincenal o mensual. Pagas por transferencia a Bancolombia y subes el comprobante aquí.',
                  style: JkText.body(15, c: JkColors.inkSoft),
                ),
                const SizedBox(height: 14),
                JkButton(
                  'Cotizar mi plan',
                  onPressed: () => pushPage(context, const RenovacionScreen()),
                ),
              ],
            ),
          ),
        ],
      );
    }
    final s = st.suscripcion;
    final consumidos = (s.plan.almuerzos - st.almuerzosRestantes).clamp(
      0,
      s.plan.almuerzos,
    );
    final avance = s.estado == EstadoSuscripcion.activa
        ? consumidos / s.plan.almuerzos
        : 0.0;

    return TabBody(
      children: [
        JkCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Plan ${s.plan.label.toLowerCase()}',
                          style: JkText.display(26),
                        ),
                        Text(
                          '${s.plan.almuerzos} almuerzos · lunes a viernes',
                          style: JkText.body(14, c: JkColors.inkMuted),
                        ),
                      ],
                    ),
                  ),
                  StatusBadge.auto(s.estado.label),
                ],
              ),
              if (s.estado == EstadoSuscripcion.activa) ...[
                const SizedBox(height: 14),
                Row(
                  children: [
                    Text('${st.almuerzosRestantes}', style: JkText.display(34)),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'almuerzos por recibir\nhasta el ${fechaLarga(s.fechaVencimiento)}',
                        style: JkText.body(14, c: JkColors.inkSoft),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                // Barra de avance en carbón.
                ClipRRect(
                  borderRadius: JkRadius.br,
                  child: LinearProgressIndicator(
                    value: avance,
                    minHeight: 8,
                    color: JkColors.ink,
                    backgroundColor: JkColors.hairline,
                  ),
                ),
              ],
              const SizedBox(height: 12),
              InfoRow('Referencia', s.referencia, mono: true),
              InfoRow('Empezó', capitalizar(fechaLarga(s.fechaInicio))),
              InfoRow('Vence', capitalizar(fechaLarga(s.fechaVencimiento))),
              if (s.descuentoFestivos > 0)
                InfoRow(
                  'Festivos descontados',
                  '${st.festivosDel(s).map(fechaCorta).join(', ')} · ${cop(s.descuentoFestivos)}',
                ),
              InfoRow('Proteína', s.preferencia.label),
              InfoRow('Valor pagado', cop(s.total), mono: true, last: true),
              const SizedBox(height: 14),
              if (st.solicitudEnCurso == null)
                // Botón dinámico: renovar (activa) o volver (finalizada / cancelada).
                JkButton(
                  s.estado.permiteReingreso
                      ? 'Volver a suscribirme'
                      : 'Renovar mi plan',
                  icon: Icons.event_repeat,
                  onPressed: () => pushPage(context, const RenovacionScreen()),
                )
              else
                _QueSigue(st.solicitudEnCurso!),
            ],
          ),
        ),
        if (st.pagos.isNotEmpty) ...[
          const SectionTitle('Historial de pagos'),
          JkCard(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            child: Column(
              children: [
                for (final (i, p) in st.pagos.indexed)
                  JkListItem(
                    leading: const IconTile(Icons.payments_outlined, size: 38),
                    title: p.concepto,
                    subtitle:
                        '${fechaMedia(p.fecha)} · ${cop(p.valor)} · ${p.referencia}',
                    monoSubtitle: true,
                    trailing: StatusBadge.auto(p.estado),
                    last: i == st.pagos.length - 1,
                  ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}

/// Pasos de activación (solo mientras se verifica el pago).
class _QueSigue extends StatelessWidget {
  const _QueSigue(this.s);
  final Suscripcion s;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: JkColors.amberWash,
      borderRadius: JkRadius.br,
      border: Border.all(color: JkColors.amberInk.withValues(alpha: .2)),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '${s.tipoVenta.label} en verificación',
          style: JkText.body(15, w: FontWeight.w700, c: JkColors.amberInk),
        ),
        const SizedBox(height: 10),
        VTimeline([
          const TimelineStep('Comprobante recibido', 'Ahora mismo', done: true),
          const TimelineStep(
            'Validamos el pago',
            'Te avisamos por WhatsApp',
            current: true,
          ),
          TimelineStep(
            'Empieza tu plan ${s.plan.label.toLowerCase()}',
            '${capitalizar(fechaLarga(s.fechaInicio))} · ${AppState.horario}',
          ),
        ]),
      ],
    ),
  );
}

/// HU06.2_11 / HU06.2_12 / HU06.2_16: cotizar, elegir proteína y subir el comprobante
/// (nueva, renovación o reingreso). Todo en la página, sin ventanas emergentes.
class RenovacionScreen extends StatefulWidget {
  const RenovacionScreen({super.key});

  @override
  State<RenovacionScreen> createState() => _RenovacionScreenState();
}

class _RenovacionScreenState extends State<RenovacionScreen> {
  TipoPlan _plan = TipoPlan.mensual;
  late PreferenciaProteina _pref = AppScope.read(context).cliente.preferencia;
  XFile? _comprobante;

  @override
  Widget build(BuildContext context) {
    final st = AppScope.of(context);
    final tipo = !st.tienePlan
        ? TipoVenta.nueva
        : st.suscripcion.estado.permiteReingreso
        ? TipoVenta.reingreso
        : TipoVenta.renovacion;
    final recargo = _pref == PreferenciaProteina.normal
        ? 0
        : AppState.recargoPreferencia;
    final cocas = st.cliente.tieneKitCocas ? 0 : AppState.cobroCocas;
    final total = _plan.valor + recargo + cocas;
    final ref = 'SUS-${2611 + st.pagos.length}';

    return JkPage(
      title: switch (tipo) {
        TipoVenta.nueva => 'Cotiza tu plan',
        TipoVenta.renovacion => 'Renovar mi plan',
        TipoVenta.reingreso => 'Volver a suscribirme',
      },
      subtitle: 'Empieza el ${fechaLarga(st.inicioSiguienteCiclo)}',
      bottom: JkButton(
        _comprobante != null
            ? 'Enviar comprobante'
            : 'Sube el comprobante para enviar',
        onPressed: _comprobante == null
            ? null
            : () {
                st.solicitarPlan(plan: _plan, preferencia: _pref);
                showToast(
                  context,
                  '¡Listo, ${st.cliente.primerNombre}! Estamos verificando tu pago.',
                );
                Navigator.pop(context);
              },
      ),
      children: [
        const SectionTitle('Plan'),
        for (final p in TipoPlan.values)
          OptionCard(
            title: p.label,
            subtitle: '${p.almuerzos} almuerzos',
            trailing: cop(p.valor),
            selected: _plan == p,
            onTap: () => setState(() => _plan = p),
          ),
        const SectionTitle('Proteína del seco'),
        for (final p in PreferenciaProteina.values)
          OptionCard(
            title: p.label,
            subtitle: p.detalle,
            trailing: p == PreferenciaProteina.normal
                ? 'Incluido'
                : '+${cop(AppState.recargoPreferencia)}',
            selected: _pref == p,
            onTap: () => setState(() => _pref = p),
          ),
        const SizedBox(height: 4),
        Notice(
          st.cliente.tieneKitCocas
              ? 'Ya tienes tu kit de cocas: no lo pagas de nuevo.'
              : 'El kit de 2 juegos de cocas (${cop(AppState.cobroCocas)}) se paga una sola vez.',
          icon: Icons.inventory_2_outlined,
          tone: st.cliente.tieneKitCocas ? Tone.ok : Tone.neutral,
        ),

        const SectionTitle('Transfiere a Bancolombia'),
        JkCard(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
          child: Column(
            children: [
              // Datos de ejemplo: el administrador los configura en el panel.
              _Copiable('Cuenta de ahorros', '000-000000-00'),
              _Copiable('Titular', 'La Coca de Jacks S.A.S.'),
              _Copiable('Referencia', ref, last: true),
            ],
          ),
        ),

        const SectionTitle('Resumen'),
        // Elemento tipo recibo: aquí sí va la monoespaciada.
        JkCard(
          color: JkColors.paper,
          dashed: true,
          child: Column(
            children: [
              _Linea('Plan ${_plan.label.toLowerCase()}', cop(_plan.valor)),
              if (recargo > 0) _Linea(_pref.label, '+${cop(recargo)}'),
              _Linea('Kit de cocas', cocas == 0 ? cop(0) : cop(cocas)),
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 6),
                child: Divider(height: 1, color: JkColors.dash),
              ),
              _Linea('Total', cop(total), bold: true),
              const SizedBox(height: 6),
              Text(
                'Si hay festivos en tu ciclo, el descuento se aplica al validar el pago.',
                style: JkText.body(12.5, c: JkColors.inkMuted),
              ),
            ],
          ),
        ),

        const SectionTitle('Comprobante'),
        PhotoField(
          file: _comprobante,
          label: 'Toca para subir la foto o captura del comprobante',
          onChanged: (f) => setState(() => _comprobante = f),
        ),
        Text(
          'Si envías antes del sábado a las 12:00 m., empiezas el lunes siguiente.',
          style: JkText.body(13, c: JkColors.inkMuted),
        ),
      ],
    );
  }
}

class _Linea extends StatelessWidget {
  const _Linea(this.l, this.v, {this.bold = false});
  final String l;
  final String v;
  final bool bold;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 3),
    child: Row(
      children: [
        Expanded(
          child: Text(
            l,
            style: JkText.mono(
              bold ? 15 : 13.5,
              c: JkColors.ink,
              w: bold ? FontWeight.w800 : FontWeight.w500,
            ),
          ),
        ),
        Text(
          v,
          style: JkText.mono(
            bold ? 15 : 13.5,
            c: JkColors.ink,
            w: bold ? FontWeight.w800 : FontWeight.w600,
          ),
        ),
      ],
    ),
  );
}

class _Copiable extends StatelessWidget {
  const _Copiable(this.l, this.v, {this.last = false});
  final String l;
  final String v;
  final bool last;

  @override
  Widget build(BuildContext context) => JkListItem(
    title: v,
    subtitle: l,
    last: last,
    trailing: TextButton.icon(
      style: TextButton.styleFrom(
        foregroundColor: JkColors.ink,
        minimumSize: const Size(0, JkSpace.touch),
      ),
      onPressed: () {
        Clipboard.setData(ClipboardData(text: v));
        showToast(context, '$l copiado', icon: Icons.copy);
      },
      icon: const Icon(Icons.copy, size: 17),
      label: const Text('Copiar'),
    ),
  );
}
