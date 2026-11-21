import 'dart:async';

import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart' show Distance, LengthUnit;

import '../../core/format.dart';
import '../../core/shell.dart';
import '../../core/theme.dart';
import '../../core/widgets.dart';
import '../../data/app_state.dart';
import '../../data/models.dart';
import 'cliente_shell.dart';
import 'suspender_screen.dart';

/// Seguimiento de la entrega: en preparación → en ruta → entregado.
class EntregaTab extends StatelessWidget {
  const EntregaTab({super.key});

  @override
  Widget build(BuildContext context) {
    final st = AppScope.of(context);
    if (!st.hayEntregaHoy) {
      final motivo =
          !st.tienePlan || st.suscripcion.estado != EstadoSuscripcion.activa
          ? 'Cuando tu plan esté activo, aquí ves tu almuerzo del día y al domiciliario en el mapa.'
          : st.pausas.contains(st.hoy)
          ? 'Pausaste el almuerzo de hoy.'
          : 'Hoy no hay entrega. Llegamos de lunes a viernes, ${AppState.horario}';
      return TabBody(
        children: [
          JkCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Sin almuerzo hoy', style: JkText.display(24)),
                const SizedBox(height: 4),
                Text(motivo, style: JkText.body(15, c: JkColors.inkSoft)),
              ],
            ),
          ),
        ],
      );
    }

    final entregado = st.entregaHoy == EstadoEntrega.entregada;
    final menu = st.menuDe(st.hoy);
    return TabBody(
      children: [
        JkCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      capitalizar(fechaLarga(st.hoy)),
                      style: JkText.display(22),
                    ),
                  ),
                  StatusBadge.auto(entregado ? 'Entregado' : 'En ruta'),
                ],
              ),
              if (menu != null)
                Padding(
                  padding: const EdgeInsets.only(top: 2, bottom: 14),
                  child: Text(
                    menu.secoPara(st.cliente.preferencia),
                    style: JkText.body(14, c: JkColors.inkSoft),
                  ),
                ),
              VTimeline([
                const TimelineStep(
                  'Programado',
                  'Confirmado a las 5:00 p. m. de ayer',
                  done: true,
                ),
                const TimelineStep(
                  'En preparación',
                  'La cocina empezó a las 6:30 a. m.',
                  done: true,
                ),
                TimelineStep(
                  'En ruta',
                  'Salió a las 9:05 a. m.',
                  done: entregado,
                  current: !entregado,
                ),
                TimelineStep(
                  'Entregado',
                  entregado
                      ? 'A las 10:41 a. m.'
                      : 'Llega entre 10:30 y 10:50 a. m.',
                  done: entregado,
                ),
              ]),
            ],
          ),
        ),
        JkCard(
          child: Row(
            children: [
              Avatar(iniciales(st.domiciliarioHoy), size: 46),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      st.domiciliarioHoy,
                      style: JkText.body(15, w: FontWeight.w700),
                    ),
                    Text(
                      'Tu domiciliario de hoy',
                      style: JkText.body(13, c: JkColors.inkMuted),
                    ),
                  ],
                ),
              ),
              SquareIconButton(
                icon: Icons.call_outlined,
                tooltip: 'Llamar',
                onTap: () => llamar(context, st.domiciliario.celular),
              ),
            ],
          ),
        ),
        JkCard(
          padding: const EdgeInsets.symmetric(horizontal: 14),
          child: Column(
            children: [
              InfoRow(
                'Dirección de hoy',
                st.cliente.direccionDelDia(st.hoy).resumen,
              ),
              InfoRow(
                'Juego de cocas',
                'Entregan el juego 2 y recogen el 1',
                last: true,
              ),
            ],
          ),
        ),
        if (!entregado) ...[
          const Notice(
            'Te escribimos por WhatsApp 5 minutos antes de llegar. El domiciliario te espera hasta 10 minutos.',
            icon: Icons.notifications_active_outlined,
          ),
          JkButton(
            'Ver ubicación en tiempo real',
            icon: Icons.place_outlined,
            onPressed: () => pushPage(context, const SeguimientoScreen()),
          ),
          const SizedBox(height: 10),
        ],
        JkButton.ghost(
          'Pausar otro día',
          icon: Icons.pause_circle_outline,
          onPressed: () => pushPage(context, const SuspenderScreen()),
        ),
        const SizedBox(height: 10),
        JkButton.ghost(
          'Algo salió mal: reportar',
          icon: Icons.report_gmailerrorred_outlined,
          onPressed: () => RoleShell.of(context).goTab(tabIncidencias),
        ),
      ],
    );
  }
}

/// Mapa con la ubicación del domiciliario (geolocalizacion_domiciliarios).
/// En la demo el domiciliario avanza solo desde la parada anterior; con la API
/// la posición llega cada pocos segundos desde el celular del domiciliario.
class SeguimientoScreen extends StatefulWidget {
  const SeguimientoScreen({super.key});

  @override
  State<SeguimientoScreen> createState() => _SeguimientoScreenState();
}

class _SeguimientoScreenState extends State<SeguimientoScreen> {
  static const _desde = Offset(.46, .30); // parada anterior
  static const _velocidadKmH = 18.0;
  double _t = 0;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(milliseconds: 900), (t) {
      if (_t >= 1) {
        t.cancel();
        return;
      }
      setState(() => _t = (_t + 0.04).clamp(0, 1));
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final st = AppScope.of(context);
    final mia = st.paradas.where((p) => p.cliente == st.cliente.nombre);
    final destino = mia.isEmpty
        ? const Offset(.58, .48)
        : Offset(mia.first.x, mia.first.y);
    final pos = Offset.lerp(_desde, destino, _t)!;
    final metros = const Distance().as(
      LengthUnit.Meter,
      toLatLng(pos),
      toLatLng(destino),
    );
    final minutos = (metros / 1000 / _velocidadKmH * 60).ceil();
    final llego = metros < 30;
    final cerca = metros < 400;
    final distancia = metros >= 1000
        ? '${(metros / 1000).toStringAsFixed(1).replaceAll('.', ',')} km'
        : '${metros.round()} m';

    return JkPage(
      title: 'Tu domiciliario',
      subtitle: 'Ubicación en tiempo real',
      children: [
        RouteMap(
          height: 340,
          // Al cliente solo se le muestra su parada y el domiciliario (no la zona interna).
          points: [
            MapPoint(destino.dx, destino.dy, label: '•', highlight: true),
          ],
          courier: pos,
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
                        st.domiciliarioHoy,
                        style: JkText.body(15, w: FontWeight.w700),
                      ),
                      Text(
                        llego
                            ? 'Llegó a tu dirección'
                            : 'Va a tu dirección · $distancia',
                        style: JkText.body(13, c: JkColors.inkMuted),
                      ),
                    ],
                  ),
                ),
                Text(llego ? 'Ya' : '$minutos min', style: JkText.display(22)),
              ],
            ),
          ),
        ),
        Semantics(
          liveRegion: true,
          child: StatGrid([
            StatTile(
              label: 'Distancia',
              value: llego ? '0 m' : distancia,
              icon: Icons.straighten,
            ),
            StatTile(
              label: 'Llega en',
              value: llego ? 'Ya llegó' : '$minutos min',
              icon: Icons.schedule,
            ),
          ]),
        ),
        if (llego)
          const Notice(
            'Tu domiciliario llegó. Te espera hasta 10 minutos.',
            icon: Icons.where_to_vote_outlined,
            tone: Tone.ok,
          )
        else if (cerca)
          const Notice(
            'Está llegando: ten listo el juego de cocas vacío.',
            icon: Icons.notifications_active_outlined,
            tone: Tone.warn,
          )
        else
          const Notice(
            'Te avisamos por WhatsApp 5 minutos antes de llegar y cuando entregue.',
            icon: Icons.notifications_none,
          ),
        JkButton.ghost(
          'Llamar a ${st.domiciliarioHoy.split(' ').first}',
          icon: Icons.call_outlined,
          onPressed: () => llamar(context, st.domiciliario.celular),
        ),
      ],
    );
  }
}
