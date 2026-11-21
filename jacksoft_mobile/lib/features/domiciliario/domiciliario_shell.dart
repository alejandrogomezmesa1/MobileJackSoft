import 'package:flutter/material.dart';

import 'package:jacksoft_mobile/core/format.dart';
import 'package:jacksoft_mobile/core/location.dart';
import 'package:jacksoft_mobile/core/shell.dart';
import 'package:jacksoft_mobile/core/theme.dart';
import 'package:jacksoft_mobile/core/widgets.dart';
import 'package:jacksoft_mobile/data/app_state.dart';
import 'package:jacksoft_mobile/data/models.dart';
import 'package:jacksoft_mobile/features/cliente/incidencias_screens.dart';
import 'package:jacksoft_mobile/features/cliente/perfil_screen.dart';
import 'package:jacksoft_mobile/features/domiciliario/entrega_screens.dart';

const tabRutas = 1;
const tabEntregas = 2;

/// Pestañas del domiciliario: las cinco del prototipo HTML.
class DomiciliarioShell extends StatelessWidget {
  const DomiciliarioShell({super.key});

  static void _novedad(BuildContext context) =>
      pushPage(context, const NovedadScreen());

  @override
  Widget build(BuildContext context) => UbicacionTracker(
    child: RoleShell(
      tabs: [
        ShellTab(
          label: 'Inicio',
          icon: Icons.home_outlined,
          title: (s) => 'Hola, ${s.domiciliario.nombre.split(' ').first}',
          subtitle: (s) => capitalizar(fechaLarga(s.hoy)),
          builder: (_) => const DomInicio(),
        ),
        ShellTab(
          label: 'Ruta',
          icon: Icons.alt_route,
          title: (s) => 'Mi ruta',
          subtitle: (s) => s.rutaNombre,
          builder: (_) => const RutaTab(),
          fab: (
            icon: Icons.add_a_photo_outlined,
            tooltip: 'Reportar novedad',
            onTap: _novedad,
          ),
        ),
        ShellTab(
          label: 'Entregas',
          icon: Icons.inventory_2_outlined,
          title: (_) => 'Entregas de hoy',
          builder: (_) => const EntregasTab(),
          fab: (
            icon: Icons.add_a_photo_outlined,
            tooltip: 'Reportar novedad',
            onTap: _novedad,
          ),
        ),
        ShellTab(
          label: 'Historial',
          icon: Icons.history,
          title: (_) => 'Historial',
          builder: (_) => const HistorialTab(),
        ),
        ShellTab(
          label: 'Perfil',
          icon: Icons.person_outline,
          title: (_) => 'Perfil',
          builder: (_) => const DomPerfil(),
        ),
      ],
    ),
  );
}

class DomInicio extends StatelessWidget {
  const DomInicio({super.key});

  @override
  Widget build(BuildContext context) {
    final st = AppScope.of(context);
    final total = st.paradas.length;
    final hechas = st.completadas.length;
    final sig = st.siguiente;
    final novedadesHoy = st.novedades
        .where((n) => mismoDia(n.fecha, st.hoy))
        .toList();

    return TabBody(
      children: [
        JkCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Tu ruta de hoy',
                style: JkText.body(
                  14,
                  w: FontWeight.w600,
                  c: JkColors.inkMuted,
                ),
              ),
              Text(
                sig == null
                    ? 'Terminaste la ruta'
                    : 'Tienes ${st.pendientes.length} entregas por hacer',
                style: JkText.display(26),
              ),
              Text(
                '${st.rutaNombre} · $total clientes · ${AppState.horario}',
                style: JkText.body(14, c: JkColors.inkSoft),
              ),
              const SizedBox(height: 12),
              ClipRRect(
                borderRadius: JkRadius.br,
                child: LinearProgressIndicator(
                  value: total == 0 ? 0 : hechas / total,
                  minHeight: 8,
                  color: JkColors.ink,
                  backgroundColor: JkColors.hairline,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '$hechas de $total listas',
                style: JkText.body(13, c: JkColors.inkMuted),
              ),
              const SizedBox(height: 6),
              JkSwitchRow(
                title: 'Compartir mi ubicación',
                subtitle: estadoUbicacion(st),
                value: st.compartiendoUbicacion,
                onChanged: (v) => st.alternarUbicacion(activa: v),
              ),
              if (st.compartiendoUbicacion && !st.enLinea)
                Notice(
                  'Sin conexión: guardamos '
                  '${st.colaUbicaciones.length} posiciones y las enviamos '
                  'cuando vuelva la señal.',
                  icon: Icons.wifi_off,
                  tone: Tone.warn,
                ),
              const SizedBox(height: 8),
              if (!st.rutaIniciada)
                JkButton(
                  'Iniciar ruta',
                  icon: Icons.navigation_outlined,
                  onPressed: () {
                    st.iniciarRuta();
                    showToast(
                      context,
                      'Ruta iniciada. ¡Buen viaje!',
                      icon: Icons.navigation_outlined,
                    );
                  },
                )
              else if (sig != null)
                JkButton(
                  'Ir a la siguiente: ${sig.cliente.split(' ').first}',
                  icon: Icons.navigation_outlined,
                  onPressed: () => pushPage(context, DetalleEntrega(sig)),
                ),
            ],
          ),
        ),
        StatGrid([
          StatTile(
            label: 'Pendientes',
            value: '${st.pendientes.length}',
            icon: Icons.inventory_2_outlined,
          ),
          StatTile(
            label: 'Entregadas',
            value: '${st.entregadasHoy}',
            icon: Icons.check_circle_outline,
          ),
          StatTile(
            label: 'Cocas por recoger',
            value: '${st.cocasPorRecoger}',
            icon: Icons.recycling,
          ),
          StatTile(
            label: 'Novedades hoy',
            value: '${novedadesHoy.length}',
            icon: Icons.report_gmailerrorred_outlined,
          ),
        ]),
        if (sig != null) ...[
          const SectionTitle('Siguiente entrega'),
          JkCard(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            child: ParadaItem(sig, last: true),
          ),
        ],
        const SectionTitle('Novedades de hoy'),
        if (novedadesHoy.isEmpty)
          Text(
            'Sin novedades por ahora.',
            style: JkText.body(15, c: JkColors.inkMuted),
          )
        else
          JkCard(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            child: Column(
              children: [
                for (final (i, n) in novedadesHoy.indexed)
                  JkListItem(
                    leading: const IconTile(
                      Icons.report_gmailerrorred_outlined,
                      size: 38,
                    ),
                    title: n.tipo.label,
                    subtitle: n.cliente ?? 'Ruta',
                    trailing: StatusBadge.auto(n.estado.label),
                    last: i == novedadesHoy.length - 1,
                    onTap: () => pushPage(context, IncidenciaDetalle(n)),
                  ),
              ],
            ),
          ),
      ],
    );
  }
}

/// Estado del envío de la ubicación, en una línea.
String estadoUbicacion(AppState st) {
  if (!st.compartiendoUbicacion) return 'Actívala mientras estés en ruta';
  if (st.problemaUbicacion != null) return st.problemaUbicacion!;
  final red = st.red == null ? 'sin conexión' : 'por ${st.red}';
  final u = st.ultimaUbicacion;
  if (u == null) return 'El administrador y tus clientes te ven · $red';
  return 'Última a las ${hora(u.hora)} · ${st.precisionGps} m · $red';
}

/// Fila de una parada de la ruta.
class ParadaItem extends StatelessWidget {
  const ParadaItem(this.p, {super.key, this.last = false});
  final Parada p;
  final bool last;

  @override
  Widget build(BuildContext context) => JkListItem(
    leading: Container(
      width: 38,
      height: 38,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: p.pendiente ? JkColors.white : JkColors.ink,
        borderRadius: JkRadius.br,
        border: Border.all(color: JkColors.ink),
      ),
      child: Text(
        '${p.orden}',
        style: JkText.mono(
          14,
          c: p.pendiente ? JkColors.ink : JkColors.white,
          w: FontWeight.w700,
        ),
      ),
    ),
    title: p.cliente,
    subtitle: '${p.direccion} · ${p.barrio}',
    trailing: StatusBadge.auto(p.resultado ?? p.estado.label),
    last: last,
    onTap: () => pushPage(context, DetalleEntrega(p)),
  );
}

/// HU07.1_09: rutas asignadas del día.
class RutaTab extends StatelessWidget {
  const RutaTab({super.key});

  @override
  Widget build(BuildContext context) {
    final st = AppScope.of(context);
    final ultima = st.completadas.isEmpty ? null : st.completadas.last;
    final sig = st.siguiente;
    final courier = ultima == null
        ? const Offset(.06, .1)
        : sig == null
        ? Offset(ultima.x, ultima.y)
        : Offset((ultima.x + sig.x) / 2, (ultima.y + sig.y) / 2);
    return TabBody(
      children: [
        RouteMap(
          height: 300,
          points: [
            for (final p in st.paradas)
              MapPoint(
                p.x,
                p.y,
                label: '${p.orden}',
                done: !p.pendiente,
                highlight: p == sig,
              ),
          ],
          courier: st.rutaIniciada ? courier : null,
          caption: Container(
            padding: const EdgeInsets.all(12),
            decoration: const BoxDecoration(
              color: JkColors.white,
              borderRadius: JkRadius.br,
              boxShadow: [
                BoxShadow(
                  color: Color(0x1F2B2118),
                  blurRadius: 16,
                  offset: Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        st.rutaNombre,
                        style: JkText.body(15, w: FontWeight.w700),
                      ),
                      Text(
                        '${st.paradas.length} clientes · '
                        '${st.pendientes.length} por entregar',
                        style: JkText.body(13, c: JkColors.inkMuted),
                      ),
                    ],
                  ),
                ),
                StatusBadge.auto(st.rutaIniciada ? 'En ruta' : 'Programada'),
              ],
            ),
          ),
        ),
        if (!st.rutaIniciada)
          JkButton(
            'Iniciar ruta',
            icon: Icons.navigation_outlined,
            onPressed: () {
              st.iniciarRuta();
              showToast(
                context,
                'Ruta iniciada. ¡Buen viaje!',
                icon: Icons.navigation_outlined,
              );
            },
          ),
        const SectionTitle('Orden de entrega'),
        JkCard(
          padding: const EdgeInsets.symmetric(horizontal: 14),
          child: Column(
            children: [
              for (final (i, p) in st.paradas.indexed)
                ParadaItem(p, last: i == st.paradas.length - 1),
            ],
          ),
        ),
      ],
    );
  }
}

class EntregasTab extends StatelessWidget {
  const EntregasTab({super.key});

  @override
  Widget build(BuildContext context) {
    final st = AppScope.of(context);
    return TabBody(
      children: [
        SectionTitle('Pendientes (${st.pendientes.length})'),
        if (st.pendientes.isEmpty)
          const Notice(
            '¡Terminaste! No te quedan entregas hoy.',
            tone: Tone.ok,
            icon: Icons.check_circle_outline,
          )
        else
          JkCard(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            child: Column(
              children: [
                for (final (i, p) in st.pendientes.indexed)
                  ParadaItem(p, last: i == st.pendientes.length - 1),
              ],
            ),
          ),
        SectionTitle('Completadas (${st.completadas.length})'),
        JkCard(
          padding: const EdgeInsets.symmetric(horizontal: 14),
          child: Column(
            children: [
              for (final (i, p) in st.completadas.indexed)
                JkListItem(
                  leading: const IconTile(Icons.check, size: 38),
                  title: p.cliente,
                  subtitle: '${p.barrio} · ${hora(p.horaEntrega!)}',
                  trailing: StatusBadge.auto(p.resultado!),
                  last: i == st.completadas.length - 1,
                  onTap: () => pushPage(context, DetalleEntrega(p)),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

/// HU07.2_10: historial por rango de fechas.
class HistorialTab extends StatefulWidget {
  const HistorialTab({super.key});

  @override
  State<HistorialTab> createState() => _HistorialTabState();
}

class _HistorialTabState extends State<HistorialTab> {
  int _dias = 7;

  @override
  Widget build(BuildContext context) {
    final st = AppScope.of(context);
    final desde = DateTime(st.hoy.year, st.hoy.month, st.hoy.day - (_dias - 1));
    final lista = st.historial.where((h) => !h.fecha.isBefore(desde)).toList();
    final ok = lista.where((h) => h.resultado == 'Entregado').length;
    final grupos = <DateTime, List<EntregaHistorial>>{};
    for (final h in lista) {
      grupos.putIfAbsent(soloFecha(h.fecha), () => []).add(h);
    }
    return TabBody(
      children: [
        Segmented<int>(
          options: const [1, 7, 30],
          selected: _dias,
          label: (d) => switch (d) {
            1 => 'Hoy',
            7 => '7 días',
            _ => '30 días',
          },
          onChanged: (d) => setState(() => _dias = d),
        ),
        const SizedBox(height: 12),
        StatGrid([
          StatTile(
            label: 'Entregadas',
            value: '$ok',
            icon: Icons.check_circle_outline,
          ),
          StatTile(
            label: 'Con novedad',
            value: '${lista.length - ok}',
            icon: Icons.report_gmailerrorred_outlined,
          ),
        ]),
        if (lista.isEmpty)
          Text(
            'No hay entregas en este rango.',
            style: JkText.body(15, c: JkColors.inkMuted),
          ),
        for (final e in grupos.entries) ...[
          SectionTitle(capitalizar(fechaLarga(e.key))),
          JkCard(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            child: Column(
              children: [
                for (final (i, h) in e.value.indexed)
                  JkListItem(
                    title: h.cliente,
                    subtitle: '${h.barrio} · ${hora(h.fecha)}',
                    trailing: StatusBadge.auto(h.resultado),
                    last: i == e.value.length - 1,
                  ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}

class DomPerfil extends StatelessWidget {
  const DomPerfil({super.key});

  @override
  Widget build(BuildContext context) {
    final st = AppScope.of(context);
    final d = st.domiciliario;
    return TabBody(
      children: [
        JkCard(
          child: Row(
            children: [
              Avatar(iniciales(d.nombre), size: 56),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(d.nombre, style: JkText.display(22)),
                    Text(
                      d.correo,
                      style: JkText.body(14, c: JkColors.inkMuted),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        JkCard(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          child: Column(
            children: [
              InfoRow('Documento', d.documento),
              InfoRow('Celular', d.celular),
              const InfoRow('Rol', 'Domiciliario'),
              InfoRow('Ruta de hoy', st.rutaNombre, last: true),
            ],
          ),
        ),
        JkCard(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          child: Column(
            children: [
              JkSwitchRow(
                title: 'Compartir mi ubicación',
                subtitle: estadoUbicacion(st),
                value: st.compartiendoUbicacion,
                onChanged: (v) => st.alternarUbicacion(activa: v),
              ),
              JkListItem(
                leading: const IconTile(Icons.lock_outline, size: 38),
                title: 'Cambiar contraseña',
                last: true,
                onTap: () => cambiarClaveSheet(context),
              ),
            ],
          ),
        ),
        const Notice(
          'Tus datos los actualiza el administrador. '
          'Si algo está mal, avísale.',
        ),
        const BotonCerrarSesion(mensaje: 'Dejarás de compartir tu ubicación.'),
      ],
    );
  }
}
