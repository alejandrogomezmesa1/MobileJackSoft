import 'package:flutter/material.dart';

import '../../core/format.dart';
import '../../core/shell.dart';
import '../../core/theme.dart';
import '../../core/widgets.dart';
import '../../data/app_state.dart';
import '../../data/models.dart';
import 'entrega_screens.dart';
import 'incidencias_screens.dart';
import 'menu_screens.dart';
import 'perfil_screen.dart';
import 'plan_screens.dart';
import 'suspender_screen.dart';

/// Pestañas del cliente: las cinco del prototipo HTML.
class ClienteShell extends StatelessWidget {
  const ClienteShell({super.key});

  @override
  Widget build(BuildContext context) => RoleShell(
    tabs: [
      ShellTab(
        label: 'Inicio',
        icon: Icons.home_outlined,
        title: (s) => 'Hola, ${s.cliente.primerNombre}',
        builder: (_) => const ClienteInicio(),
      ),
      ShellTab(
        label: 'Mi plan',
        icon: Icons.receipt_long_outlined,
        title: (_) => 'Mi plan',
        builder: (_) => const PlanTab(),
      ),
      ShellTab(
        label: 'Entrega',
        icon: Icons.delivery_dining_outlined,
        title: (_) => 'Mi almuerzo de hoy',
        builder: (_) => const EntregaTab(),
      ),
      ShellTab(
        label: 'Incidencias',
        icon: Icons.report_gmailerrorred_outlined,
        title: (_) => 'Incidencias',
        builder: (_) => const IncidenciasTab(),
      ),
      ShellTab(
        label: 'Perfil',
        icon: Icons.person_outline,
        title: (_) => 'Mi perfil',
        builder: (_) => const PerfilTab(),
      ),
    ],
  );
}

const tabPlan = 1, tabEntrega = 2, tabIncidencias = 3;

extension EntregaHoyX on AppState {
  bool get hayEntregaHoy =>
      tienePlan &&
      suscripcion.estado == EstadoSuscripcion.activa &&
      esHabil(hoy) &&
      !pausas.contains(hoy) &&
      !esFuera(hoy);

  String estadoDia(DateTime d) {
    if (esFestivo(d)) return 'Festivo';
    if (pausas.contains(d)) return 'Pausado';
    if (!tienePlan || esFuera(d)) return 'Sin plan';
    if (mismoDia(d, hoy)) {
      return entregaHoy == EstadoEntrega.entregada ? 'Entregado' : 'Hoy';
    }
    return d.isBefore(hoy) ? 'Entregado' : 'Llega';
  }
}

class ClienteInicio extends StatelessWidget {
  const ClienteInicio({super.key});

  @override
  Widget build(BuildContext context) {
    final st = AppScope.of(context);
    final sus = st.suscripcion;
    final menuHoy = st.menuDe(st.hoy);
    final shell = RoleShell.of(context);

    return TabBody(
      children: [
        // 1. Primero lo que hay que hacer ahora (solo si hay algo).
        if (!st.tienePlan)
          JkCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Elige tu plan', style: JkText.display(24)),
                const SizedBox(height: 4),
                Text(
                  'Cotiza el plan, sube el comprobante y te avisamos por WhatsApp cuando quede activo.',
                  style: JkText.body(15, c: JkColors.inkSoft),
                ),
                const SizedBox(height: 14),
                JkButton(
                  'Cotizar mi plan',
                  onPressed: () => pushPage(context, const RenovacionScreen()),
                ),
              ],
            ),
          )
        else if (sus.estado == EstadoSuscripcion.verificando)
          Notice(
            'Estamos verificando tu pago del plan ${sus.plan.label.toLowerCase()}. Te avisamos por WhatsApp cuando quede activo.',
            tone: Tone.warn,
            icon: Icons.hourglass_top,
          )
        else if (st.solicitudEnCurso != null)
          Notice(
            'Recibimos tu comprobante de ${st.solicitudEnCurso!.tipoVenta.label.toLowerCase()}. Lo estamos verificando.',
            tone: Tone.warn,
            icon: Icons.hourglass_top,
          )
        else if (st.almuerzosRestantes > 0 && st.almuerzosRestantes <= 10)
          Notice(
            'Te quedan ${st.almuerzosRestantes} almuerzos. Renueva antes del sábado a las 12:00 m. para seguir sin pausa.',
            icon: Icons.event_repeat,
          ),

        // 2. Tu próximo almuerzo
        if (st.hayEntregaHoy)
          JkCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Tu almuerzo de hoy',
                        style: JkText.body(
                          14,
                          c: JkColors.inkMuted,
                          w: FontWeight.w600,
                        ),
                      ),
                    ),
                    StatusBadge.auto(
                      st.entregaHoy == EstadoEntrega.entregada
                          ? 'Entregado'
                          : 'En ruta',
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  capitalizar(fechaLarga(st.hoy)),
                  style: JkText.display(26),
                ),
                if (menuHoy != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    menuHoy.secoPara(st.cliente.preferencia),
                    style: JkText.body(16, w: FontWeight.w700),
                  ),
                  Text(
                    '${menuHoy.sopa} · ${menuHoy.ensalada} · ${menuHoy.bebida}',
                    style: JkText.body(14, c: JkColors.inkSoft),
                  ),
                ],
                const SizedBox(height: 12),
                _Dato(
                  Icons.place_outlined,
                  st.cliente.direccionDelDia(st.hoy).resumen,
                ),
                _Dato(
                  Icons.schedule,
                  st.entregaHoy == EstadoEntrega.entregada
                      ? 'Entregado a las 10:41 a. m.'
                      : 'Llega entre 10:30 y 10:50 a. m. · horario ${AppState.horario}',
                ),
                const SizedBox(height: 14),
                JkButton(
                  'Ver estado del almuerzo',
                  onPressed: () => shell.goTab(tabEntrega),
                ),
              ],
            ),
          ),

        // 3. La semana, de lunes a viernes
        if (st.tienePlan) ...[
          const SectionTitle('Tu semana'),
          JkCard(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
            child: Row(
              children: [
                for (final d in st.semana)
                  Expanded(
                    child: _DiaSemana(d, st.estadoDia(d), mismoDia(d, st.hoy)),
                  ),
              ],
            ),
          ),
          StatGrid([
            StatTile(
              label: 'Suscripción',
              value: '',
              icon: Icons.receipt_long_outlined,
              valueWidget: Padding(
                padding: const EdgeInsets.only(top: 4),
                child: StatusBadge.auto(sus.estado.label),
              ),
            ),
            StatTile(
              label: 'Por recibir',
              value: '${st.almuerzosRestantes}',
              icon: Icons.lunch_dining_outlined,
            ),
            StatTile(
              label: 'Vence',
              value: fechaCorta(sus.fechaVencimiento),
              icon: Icons.event_outlined,
            ),
            StatTile(
              label: 'Último pago',
              value: st.pagos.isEmpty ? '—' : cop(st.pagos.first.valor),
              icon: Icons.payments_outlined,
            ),
          ]),
        ],

        // 4. Accesos
        const SectionTitle('¿Qué quieres hacer?'),
        JkCard(
          padding: const EdgeInsets.symmetric(horizontal: 14),
          child: Column(
            children: [
              JkListItem(
                leading: const IconTile(Icons.restaurant_menu, size: 38),
                title: 'Ver el menú de la semana',
                onTap: () => pushPage(context, const MenuSemanaScreen()),
              ),
              if (st.tienePlan)
                JkListItem(
                  leading: const IconTile(Icons.event_repeat, size: 38),
                  title: sus.estado.permiteReingreso
                      ? 'Volver a suscribirme'
                      : 'Renovar mi plan',
                  onTap: () => shell.goTab(tabPlan),
                ),
              if (st.tienePlan)
                JkListItem(
                  leading: const IconTile(Icons.pause_circle_outline, size: 38),
                  title: 'Pausar una entrega',
                  subtitle: 'Hasta las 5:00 p. m. del día anterior',
                  onTap: () => pushPage(context, const SuspenderScreen()),
                ),
              JkListItem(
                leading: const IconTile(
                  Icons.report_gmailerrorred_outlined,
                  size: 38,
                ),
                title: 'Reportar una incidencia',
                onTap: () => shell.goTab(tabIncidencias),
              ),
              JkListItem(
                leading: const IconTile(Icons.chat_outlined, size: 38),
                title: 'Ayuda por WhatsApp',
                subtitle: 'Te responde el equipo de La Coca',
                last: true,
                onTap: () => abrirWhatsapp(
                  context,
                  AppState.whatsappLaCoca,
                  mensaje: 'Hola, soy ${st.cliente.nombre}. ',
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _Dato extends StatelessWidget {
  const _Dato(this.icon, this.text);
  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(top: 6),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: JkColors.inkSoft),
        const SizedBox(width: 8),
        Expanded(
          child: Text(text, style: JkText.body(14, c: JkColors.inkSoft)),
        ),
      ],
    ),
  );
}

class _DiaSemana extends StatelessWidget {
  const _DiaSemana(this.d, this.estado, this.esHoy);
  final DateTime d;
  final String estado;
  final bool esHoy;

  @override
  Widget build(BuildContext context) {
    final apagado =
        estado == 'Festivo' || estado == 'Pausado' || estado == 'Sin plan';
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 3),
      padding: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        // El día de hoy en carbón.
        color: esHoy ? JkColors.ink : null,
        borderRadius: JkRadius.br,
      ),
      child: Column(
        children: [
          Text(
            inicialDia(d),
            style: JkText.body(
              12.5,
              w: FontWeight.w600,
              c: esHoy ? JkColors.hairlineStrong : JkColors.inkMuted,
            ),
          ),
          Text(
            '${d.day}',
            style: JkText.display(
              22,
              c: esHoy
                  ? JkColors.white
                  : apagado
                  ? JkColors.inkMuted
                  : JkColors.ink,
            ),
          ),
          const SizedBox(height: 2),
          FittedBox(
            child: Text(
              estado,
              style: JkText.body(
                11.5,
                w: FontWeight.w600,
                c: esHoy
                    ? JkColors.white
                    : switch (estado) {
                        'Entregado' => JkColors.greenInk,
                        'Pausado' => JkColors.amberInk,
                        _ => JkColors.inkMuted,
                      },
              ),
            ),
          ),
        ],
      ),
    );
  }
}
