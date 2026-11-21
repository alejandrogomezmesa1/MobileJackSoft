import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import 'theme.dart';

/// Un punto de la ruta. Las paradas de prueba guardan una posición
/// normalizada (0–1) dentro de Laureles–Estadio; [latLng] la convierte.
/// Con la API, cada punto llega con la latitud y longitud de `direcciones_cliente`.
class MapPoint {
  const MapPoint(
    this.x,
    this.y, {
    this.label,
    this.done = false,
    this.highlight = false,
  });
  final double x;
  final double y;
  final String? label;
  final bool done;
  final bool highlight;

  LatLng get latLng => toLatLng(Offset(x, y));
}

/// Recuadro de Laureles–Estadio (Medellín) usado por los datos de prueba.
LatLng toLatLng(Offset p) =>
    LatLng(6.258 - p.dy * 0.026, -75.606 + p.dx * 0.028);

/// Mapa real (OpenStreetMap) con el recorrido, las paradas y el domiciliario.
/// Los mosaicos van en sepia apagado para que el naranja siga marcando la acción.
class RouteMap extends StatelessWidget {
  const RouteMap({
    super.key,
    required this.points,
    this.courier,
    this.height = 260,
    this.caption,
  });

  /// En las pruebas se apaga para no pedir mosaicos a la red.
  static bool tiles = true;

  final List<MapPoint> points;
  final Offset? courier;
  final double height;
  final Widget? caption;

  @override
  Widget build(BuildContext context) {
    final coords = [
      for (final p in points) p.latLng,
      if (courier != null) toLatLng(courier!),
    ];
    final done = [for (final p in points.where((p) => p.done)) p.latLng];
    final pendientes = points.where((p) => !p.done).toList();
    final todo = [
      if (done.isNotEmpty) done.last,
      for (final p in pendientes) p.latLng,
    ];

    return Container(
      height: height,
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFF4EFE7),
        borderRadius: JkRadius.br,
        border: Border.all(color: JkColors.line),
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          FlutterMap(
            options: MapOptions(
              initialCameraFit: coords.length > 1
                  ? CameraFit.coordinates(
                      coordinates: coords,
                      padding: EdgeInsets.fromLTRB(
                        36,
                        36,
                        36,
                        caption == null ? 36 : 96,
                      ),
                      maxZoom: 16.5,
                    )
                  : null,
              initialCenter: coords.isEmpty
                  ? toLatLng(const Offset(.5, .5))
                  : coords.first,
              initialZoom: 15,
              interactionOptions: const InteractionOptions(
                flags: InteractiveFlag.all & ~InteractiveFlag.rotate,
              ),
            ),
            children: [
              if (tiles)
                TileLayer(
                  urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  userAgentPackageName: 'co.lacocadejacks.jacksoft_mobile',
                  tileBuilder: (context, tile, _) =>
                      ColorFiltered(colorFilter: _sepia, child: tile),
                ),
              PolylineLayer(
                polylines: [
                  if (done.length > 1)
                    Polyline(points: done, color: JkColors.ink, strokeWidth: 4),
                  if (todo.length > 1)
                    Polyline(
                      points: todo,
                      color: JkColors.inkSoft,
                      strokeWidth: 3,
                      pattern: StrokePattern.dashed(segments: const [8, 7]),
                    ),
                ],
              ),
              MarkerLayer(
                markers: [
                  for (final p in points)
                    Marker(
                      point: p.latLng,
                      width: p.highlight ? 30 : 26,
                      height: p.highlight ? 30 : 26,
                      child: _Parada(p),
                    ),
                  if (courier != null)
                    Marker(
                      point: toLatLng(courier!),
                      width: 40,
                      height: 40,
                      child: const _Domiciliario(),
                    ),
                ],
              ),
              if (tiles)
                const Align(
                  alignment: Alignment.topRight,
                  child: Padding(
                    padding: EdgeInsets.all(4),
                    child: Text(
                      '© OpenStreetMap',
                      style: TextStyle(fontSize: 10, color: JkColors.inkSoft),
                    ),
                  ),
                ),
            ],
          ),
          if (caption != null)
            Positioned(left: 10, right: 10, bottom: 10, child: caption!),
        ],
      ),
    );
  }
}

const _sepia = ColorFilter.matrix(<double>[
  0.30, 0.50, 0.12, 0, 22, //
  0.28, 0.48, 0.11, 0, 18, //
  0.24, 0.42, 0.10, 0, 12, //
  0, 0, 0, 1, 0,
]);

class _Parada extends StatelessWidget {
  const _Parada(this.p);
  final MapPoint p;

  @override
  Widget build(BuildContext context) => Container(
    alignment: Alignment.center,
    decoration: BoxDecoration(
      color: p.done ? JkColors.ink : JkColors.white,
      borderRadius: JkRadius.br,
      border: Border.all(color: JkColors.ink, width: p.highlight ? 2.5 : 1.5),
    ),
    child: p.label == null
        ? null
        : Text(
            p.label!,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w800,
              color: p.done ? JkColors.white : JkColors.ink,
            ),
          ),
  );
}

class _Domiciliario extends StatelessWidget {
  const _Domiciliario();

  @override
  Widget build(BuildContext context) => Semantics(
    label: 'Domiciliario',
    child: Stack(
      alignment: Alignment.center,
      children: [
        Container(
          decoration: BoxDecoration(
            color: JkColors.orange.withValues(alpha: .2),
            shape: BoxShape.circle,
          ),
        ),
        Container(
          width: 18,
          height: 18,
          decoration: BoxDecoration(
            color: JkColors.orange,
            shape: BoxShape.circle,
            border: Border.all(color: JkColors.white, width: 3),
          ),
        ),
      ],
    ),
  );
}
