import 'package:flutter/material.dart';

import '../../core/format.dart';
import '../../core/shell.dart';
import '../../core/theme.dart';
import '../../core/widgets.dart';
import '../../data/app_state.dart';
import '../../data/models.dart';

/// HU06.3_08: menú publicado de la semana (con la versión del seco según la proteína
/// y la alternativa según las alergias del cliente).
class MenuSemanaScreen extends StatelessWidget {
  const MenuSemanaScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final st = AppScope.of(context);
    final semana = st.semana;
    return JkPage(
      title: 'Menú de la semana',
      subtitle: '${fechaCorta(semana.first)} – ${fechaCorta(semana.last)}',
      children: [
        if (st.cliente.preferencia != PreferenciaProteina.normal ||
            st.cliente.alergias.isNotEmpty)
          Notice(
            [
              if (st.cliente.preferencia != PreferenciaProteina.normal)
                'Ves el seco en versión ${st.cliente.preferencia.label.toLowerCase()}.',
              if (st.cliente.alergias.isNotEmpty)
                'Por tus alergias (${st.cliente.alergias.map((a) => a.label.toLowerCase()).join(', ')}), te mostramos el plato que la cocina te cambia.',
            ].join(' '),
            icon: Icons.tune,
          ),
        for (final d in semana) _DiaMenu(st, d),
      ],
    );
  }
}

class _DiaMenu extends StatelessWidget {
  const _DiaMenu(this.st, this.d);
  final AppState st;
  final DateTime d;

  @override
  Widget build(BuildContext context) {
    final m = st.menuDe(d);
    final hoy = mismoDia(d, st.hoy);
    final alt = m == null ? null : _alternativa(m, st.cliente.alergias);
    return JkCard(
      onTap: m == null ? null : () => pushPage(context, MenuDiaScreen(m)),
      borderColor: hoy ? JkColors.ink : JkColors.line,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Fecha en bloque.
          Container(
            width: 52,
            padding: const EdgeInsets.symmetric(vertical: 6),
            decoration: BoxDecoration(
              color: hoy ? JkColors.ink : JkColors.beige,
              borderRadius: JkRadius.br,
            ),
            child: Column(
              children: [
                Text(
                  capitalizar(nombreDia(d)).substring(0, 3),
                  style: JkText.body(
                    12,
                    w: FontWeight.w600,
                    c: hoy ? JkColors.hairlineStrong : JkColors.inkMuted,
                  ),
                ),
                Text(
                  '${d.day}',
                  style: JkText.display(
                    22,
                    c: hoy ? JkColors.white : JkColors.ink,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (st.esFestivo(d))
                  Text(
                    'Festivo: no hay entrega',
                    style: JkText.body(
                      15,
                      w: FontWeight.w600,
                      c: JkColors.inkMuted,
                    ),
                  )
                else if (m == null)
                  Text(
                    'Menú por publicar',
                    style: JkText.body(
                      15,
                      w: FontWeight.w600,
                      c: JkColors.inkMuted,
                    ),
                  )
                else ...[
                  Text(
                    alt ?? m.secoPara(st.cliente.preferencia),
                    style: JkText.body(15.5, w: FontWeight.w700),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${m.sopa} · ${m.ensalada} · ${m.bebida}',
                    style: JkText.body(13.5, c: JkColors.inkSoft),
                  ),
                  if (alt != null) ...[
                    const SizedBox(height: 6),
                    StatusBadge('Cambiado por tu alergia', tone: Tone.warn),
                  ],
                  if (st.pausas.contains(d)) ...[
                    const SizedBox(height: 6),
                    StatusBadge.auto('Pausado'),
                  ],
                ],
              ],
            ),
          ),
          if (m != null)
            const Icon(Icons.chevron_right, color: JkColors.inkMuted),
        ],
      ),
    );
  }
}

String? _alternativa(MenuDia m, Set<Alergeno> alergias) {
  for (final a in alergias) {
    final alt = m.alternativas[a];
    if (alt != null) return alt;
  }
  return null;
}

/// HU06.3_09: detalle del almuerzo del día, coca por coca.
class MenuDiaScreen extends StatelessWidget {
  const MenuDiaScreen(this.m, {super.key});
  final MenuDia m;

  @override
  Widget build(BuildContext context) {
    final st = AppScope.of(context);
    final alt = _alternativa(m, st.cliente.alergias);
    final piezas = [
      (
        'Seco',
        alt ?? m.secoPara(st.cliente.preferencia),
        Icons.lunch_dining_outlined,
      ),
      ('Sopa', m.sopa, Icons.soup_kitchen_outlined),
      ('Ensalada', m.ensalada, Icons.eco_outlined),
      ('Bebida', m.bebida, Icons.local_drink_outlined),
    ];
    return JkPage(
      title: capitalizar(fechaLarga(m.fecha)),
      subtitle: 'Lo que llega en tus cocas',
      children: [
        for (final p in piezas)
          JkCard(
            child: Row(
              children: [
                IconTile(p.$3, size: 44),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Coca de ${p.$1.toLowerCase()}',
                        style: JkText.body(13, c: JkColors.inkMuted),
                      ),
                      Text(p.$2, style: JkText.body(16, w: FontWeight.w700)),
                    ],
                  ),
                ),
              ],
            ),
          ),
        if (alt != null)
          Notice(
            'El seco del menú es "${m.seco}". Por tu alergia la cocina te manda "$alt".',
            icon: Icons.health_and_safety_outlined,
            tone: Tone.warn,
          ),
        if (st.cliente.preferencia != PreferenciaProteina.normal && alt == null)
          Notice(
            'Tienes "${st.cliente.preferencia.label}": el seco del menú es "${m.seco}".',
            icon: Icons.tune,
          ),
      ],
    );
  }
}
