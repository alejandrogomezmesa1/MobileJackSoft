import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:geolocator/geolocator.dart';
import 'package:jacksoft_mobile/data/app_state.dart';

/// Transmite la ubicación del domiciliario mientras la ruta está iniciada y el
/// interruptor "Compartir mi ubicación" está encendido (HU07.2_06).
///
/// - Sigue enviando con la app en segundo plano: en Android con una
///   notificación fija (servicio en primer plano) y en iOS con el modo de
///   fondo "location".
/// - Vigila la red (Wi-Fi o datos). Sin conexión, las posiciones quedan en
///   cola y se envían al volver la señal.
class UbicacionTracker extends StatefulWidget {
  const UbicacionTracker({required this.child, super.key});
  final Widget child;

  /// En las pruebas se apaga (no hay GPS ni red).
  static bool enabled = true;

  @override
  State<UbicacionTracker> createState() => _UbicacionTrackerState();
}

class _UbicacionTrackerState extends State<UbicacionTracker> {
  StreamSubscription<Position>? _gps;
  bool _iniciando = false;

  /// Si el proveedor de Google Play Services falla (por ejemplo, con la
  /// "Precisión de la ubicación de Google" apagada), se usa el GPS del
  /// sistema (LocationManager).
  bool _gpsDelSistema = false;
  StreamSubscription<List<ConnectivityResult>>? _redSub;
  AppState? _st;

  @override
  void initState() {
    super.initState();
    if (UbicacionTracker.enabled) unawaited(_vigilarRed());
  }

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

  Future<void> _vigilarRed() async {
    final conn = Connectivity();
    try {
      _aplicarRed(await conn.checkConnectivity());
      _redSub = conn.onConnectivityChanged.listen(_aplicarRed);
    } on Exception {
      // Sin el plugin de red (por ejemplo, en pruebas): se asume en línea.
    }
  }

  void _aplicarRed(List<ConnectivityResult> r) {
    final red = r.contains(ConnectivityResult.wifi)
        ? 'Wi-Fi'
        : r.contains(ConnectivityResult.mobile)
        ? 'datos móviles'
        : r.contains(ConnectivityResult.ethernet) ||
              r.contains(ConnectivityResult.vpn)
        ? 'red'
        : null;
    _st?.cambioDeRed(red);
  }

  bool get _debe =>
      UbicacionTracker.enabled &&
      _st != null &&
      _st!.rutaIniciada &&
      _st!.compartiendoUbicacion;

  void _sync() {
    if (_debe && _gps == null && !_iniciando) {
      unawaited(_iniciar());
    } else if (!_debe && _gps != null) {
      unawaited(_gps!.cancel());
      _gps = null;
    }
  }

  LocationSettings get _ajustes {
    const distancia = 25; // metros entre posiciones
    if (kIsWeb) {
      return const LocationSettings(distanceFilter: distancia);
    }
    return switch (defaultTargetPlatform) {
      TargetPlatform.android => AndroidSettings(
        distanceFilter: distancia,
        forceLocationManager: _gpsDelSistema,
        intervalDuration: const Duration(seconds: 15),
        foregroundNotificationConfig: const ForegroundNotificationConfig(
          notificationTitle: 'Compartiendo tu ubicación',
          notificationText:
              'La Coca de Jacks envía tu ubicación mientras estás en ruta.',
          enableWakeLock: true,
        ),
      ),
      TargetPlatform.iOS => AppleSettings(
        distanceFilter: distancia,
        activityType: ActivityType.automotiveNavigation,
        pauseLocationUpdatesAutomatically: true,
        showBackgroundLocationIndicator: true,
      ),
      _ => const LocationSettings(distanceFilter: distancia),
    };
  }

  Future<void> _iniciar() async {
    final st = _st!;
    _iniciando = true;
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
        st.fallaUbicacion(
          'La app no tiene permiso de ubicación. Actívalo en Ajustes.',
        );
        return;
      }
      if (!_debe || _gps != null) return;
      st.fallaUbicacion(null);
      _gps = Geolocator.getPositionStream(locationSettings: _ajustes).listen(
        (p) => st.registrarUbicacion(p.latitude, p.longitude, p.accuracy),
        onError: (Object e) {
          if (e is LocationServiceDisabledException &&
              !_gpsDelSistema &&
              !kIsWeb &&
              defaultTargetPlatform == TargetPlatform.android) {
            _gpsDelSistema = true;
            unawaited(_gps?.cancel());
            _gps = null;
            _sync();
            return;
          }
          st.fallaUbicacion('No pudimos leer el GPS.');
        },
      );
    } on Exception {
      st.fallaUbicacion('Este dispositivo no permite leer la ubicación.');
    } finally {
      _iniciando = false;
    }
  }

  @override
  void dispose() {
    unawaited(_gps?.cancel());
    unawaited(_redSub?.cancel());
    _st?.removeListener(_sync);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
