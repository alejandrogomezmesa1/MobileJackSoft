import 'package:flutter/material.dart';

import '../../core/format.dart';
import '../../core/shell.dart';
import '../../core/theme.dart';
import '../../core/widgets.dart';
import '../../data/app_state.dart';

/// HU06.2_14: pausar (suspender) la entrega de un día.
/// Regla: hasta las 5:00 p. m. del día anterior; el día no se devuelve ni mueve el vencimiento.
class SuspenderScreen extends StatelessWidget {
  const SuspenderScreen({super.key});

  Future<void> _tocar(BuildContext context, AppState st, DateTime d) async {
    final pausado = st.pausas.contains(d);
    final ok = await confirmSheet(
      context,
      title: pausado ? '¿Quitar la pausa?' : '¿Pausar el ${fechaLarga(d)}?',
      message: pausado
          ? 'Te llevamos el almuerzo ese día como siempre.'
          : 'Ese día no te llevamos almuerzo. El día pausado no se devuelve y tu plan sigue venciendo el ${fechaLarga(st.suscripcion.fechaVencimiento)}.',
      confirmLabel: pausado ? 'Quitar pausa' : 'Pausar este día',
    );
    if (!ok || !context.mounted) return;
    st.alternarPausa(d);
    showToast(
      context,
      pausado
          ? 'Quitamos la pausa del ${fechaCorta(d)}'
          : 'Pausamos tu almuerzo del ${fechaCorta(d)}',
      icon: Icons.pause_circle_outline,
    );
  }

  @override
  Widget build(BuildContext context) {
    final st = AppScope.of(context);
    final dias = st.proximosHabiles(15);
    return JkPage(
      title: 'Pausar una entrega',
      subtitle: 'Toca el día que no vas a recibir',
      children: [
        JkCard(
          padding: const EdgeInsets.all(12),
          child: Column(
            children: [
              Row(
                children: [
                  for (final l in ['L', 'M', 'X', 'J', 'V'])
                    Expanded(
                      child: Center(
                        child: Text(
                          l,
                          style: JkText.body(
                            13,
                            w: FontWeight.w700,
                            c: JkColors.inkMuted,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 8),
              for (var w = 0; w < dias.length; w += 5)
                Row(
                  children: [
                    for (final d in dias.skip(w).take(5))
                      Expanded(
                        child: _Celda(st, d, () => _tocar(context, st, d)),
                      ),
                  ],
                ),
            ],
          ),
        ),
        const Wrap(
          spacing: 14,
          runSpacing: 6,
          children: [
            _Leyenda(JkColors.white, 'Puedes pausar'),
            _Leyenda(JkColors.amberWash, 'Pausado'),
            _Leyenda(JkColors.hairline, 'Festivo, pasado o fuera del plan'),
          ],
        ),
        const SizedBox(height: 14),
        Notice(
          'Puedes pausar hasta las 5:00 p. m. del día anterior. El día pausado no se devuelve y no mueve la fecha de vencimiento.',
          icon: Icons.schedule,
          tone: Tone.warn,
        ),
        if (st.pausas.isNotEmpty) ...[
          const SectionTitle('Días pausados'),
          JkCard(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            child: Column(
              children: [
                for (final (i, d) in (st.pausas.toList()..sort()).indexed)
                  JkListItem(
                    title: capitalizar(fechaLarga(d)),
                    subtitle: st.puedePausar(d)
                        ? 'Puedes quitarla hasta ${hora(st.limitePausa(d))} del ${fechaCorta(st.limitePausa(d))}'
                        : 'Ya no se puede cambiar',
                    trailing: StatusBadge.auto('Pausado'),
                    last: i == st.pausas.length - 1,
                    onTap: st.puedePausar(d)
                        ? () => _tocar(context, st, d)
                        : null,
                  ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}

class _Celda extends StatelessWidget {
  const _Celda(this.st, this.d, this.onTap);
  final AppState st;
  final DateTime d;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final pausado = st.pausas.contains(d);
    final activo = st.puedePausar(d);
    final hoy = mismoDia(d, st.hoy);
    final bg = pausado
        ? JkColors.amberWash
        : activo
        ? JkColors.white
        : JkColors.hairline;
    return Padding(
      padding: const EdgeInsets.all(3),
      child: Semantics(
        button: activo,
        selected: pausado,
        label:
            '${fechaLarga(d)}${pausado ? ', pausado' : ''}${st.esFestivo(d) ? ', festivo' : ''}',
        child: InkWell(
          onTap: activo ? onTap : null,
          borderRadius: JkRadius.br,
          child: Container(
            height: 58,
            decoration: BoxDecoration(
              color: bg,
              borderRadius: JkRadius.br,
              border: Border.all(
                color: hoy
                    ? JkColors.ink
                    : pausado
                    ? JkColors.amberInk.withValues(alpha: .4)
                    : JkColors.line,
                width: hoy ? 2 : 1,
              ),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  '${d.day}',
                  style: JkText.display(
                    20,
                    c: activo || pausado ? JkColors.ink : JkColors.inkMuted,
                  ),
                ),
                Text(
                  st.esFestivo(d)
                      ? 'Festivo'
                      : pausado
                      ? 'Pausado'
                      : hoy
                      ? 'Hoy'
                      : fechaCorta(d).split(' ').last,
                  style: JkText.body(
                    11,
                    w: FontWeight.w600,
                    c: pausado ? JkColors.amberInk : JkColors.inkMuted,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Leyenda extends StatelessWidget {
  const _Leyenda(this.c, this.t);
  final Color c;
  final String t;

  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Container(
        width: 14,
        height: 14,
        decoration: BoxDecoration(
          color: c,
          borderRadius: JkRadius.br,
          border: Border.all(color: JkColors.hairlineStrong),
        ),
      ),
      const SizedBox(width: 6),
      Text(t, style: JkText.body(12.5, c: JkColors.inkMuted)),
    ],
  );
}
