import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:geolocator/geolocator.dart';

import '../data/app_state.dart';

/// Transmite la ubicación del domiciliario mientras la ruta está iniciada y el
/// interruptor "Compartir mi ubicación" está encendido (HU07.2_06).
class UbicacionTracker extends StatefulWidget {
  const UbicacionTracker({super.key, required this.child});
  final Widget child;

  /// En las pruebas se apaga (no hay GPS).
  static bool enabled = true;

  @override
  State<UbicacionTracker> createState() => _UbicacionTrackerState();
}

class _UbicacionTrackerState extends State<UbicacionTracker> {
  StreamSubscription<Position>? _sub;
  AppState? _st;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final st = AppScope.of(context);
    if (!identical(st, _st)) {
      _st?.removeListener(_sync);
      _st = st..addListener(_sync);
    }
    _sync();
  }

  bool get _debe =>
      UbicacionTracker.enabled &&
      _st != null &&
      _st!.rutaIniciada &&
      _st!.compartiendoUbicacion;

  void _sync() {
    if (_debe && _sub == null) {
      _iniciar();
    } else if (!_debe && _sub != null) {
      _sub!.cancel();
      _sub = null;
    }
  }

  Future<void> _iniciar() async {
    final st = _st!;
    try {
      if (!await Geolocator.isLocationServiceEnabled()) {
        st.fallaUbicacion('El GPS del celular está apagado.');
        return;
      }
      var permiso = await Geolocator.checkPermission();
      if (permiso == LocationPermission.denied) {
        permiso = await Geolocator.requestPermission();
      }
      if (permiso == LocationPermission.denied ||
          permiso == LocationPermission.deniedForever) {
        st.fallaUbicacion('La app no tiene permiso de ubicación.');
        return;
      }
      if (!_debe || _sub != null) return;
      _sub =
          Geolocator.getPositionStream(
            locationSettings: const LocationSettings(
              accuracy: LocationAccuracy.high,
              distanceFilter: 25, // metros entre envíos
            ),
          ).listen(
            (p) => st.registrarUbicacion(p.latitude, p.longitude, p.accuracy),
            onError: (Object _) => st.fallaUbicacion('No pudimos leer el GPS.'),
          );
    } catch (_) {
      st.fallaUbicacion('Este dispositivo no permite leer la ubicación.');
    }
  }

  @override
  void dispose() {
    _sub?.cancel();
    _st?.removeListener(_sync);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
