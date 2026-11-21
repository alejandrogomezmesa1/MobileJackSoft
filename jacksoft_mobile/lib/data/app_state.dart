import 'package:flutter/widgets.dart';

import '../core/format.dart';
import 'models.dart';

/// Estado de la app con datos de prueba. Cada método corresponde a una
/// llamada de la API; al conectar el backend se reemplaza el cuerpo sin
/// tocar las pantallas.
class AppState extends ChangeNotifier {
  AppState() {
    _sembrar();
  }

  // ---------------------------------------------------------------- reglas
  /// Reloj de la demo: lunes 23 de noviembre de 2026, 10:20 a. m.
  DateTime get ahora => DateTime(2026, 11, 23, 10, 20);
  DateTime get hoy => soloFecha(ahora);

  /// configuraciones_sistema (bd.uml v15)
  static const horaLimiteSuspension = 17; // 17:00 del día anterior
  static const recargoPreferencia = 10000; // por plan
  static const cobroCocas = 80000; // una sola vez
  static const intentosMaximos = 5;
  static const minutosBloqueo = 15;
  static const horario = '8:00 a. m. – 12:00 m.';

  /// WhatsApp de atención (dato de ejemplo: sale de configuraciones_sistema).
  static const whatsappLaCoca = '300 000 0000';

  /// Festivos de Colombia del periodo de la demo (tabla calendario).
  final festivos = <DateTime>{
    DateTime(2026, 11, 2),
    DateTime(2026, 11, 16),
    DateTime(2026, 12, 8),
    DateTime(2026, 12, 25),
  };

  /// Festivos hábiles (lunes a viernes) dentro del ciclo de una suscripción.
  List<DateTime> festivosDel(Suscripcion s) =>
      festivos
          .where(
            (f) =>
                f.weekday <= DateTime.friday &&
                !f.isBefore(s.fechaInicio) &&
                !f.isAfter(s.fechaVencimiento),
          )
          .toList()
        ..sort();

  /// Deslizar para actualizar: con la API, vuelve a pedir los datos.
  Future<void> refrescar() async {
    await Future<void>.delayed(const Duration(milliseconds: 700));
    notifyListeners();
  }

  bool esFestivo(DateTime d) => festivos.contains(soloFecha(d));
  bool esHabil(DateTime d) => d.weekday <= DateTime.friday && !esFestivo(d);

  /// Límite para pausar el día [d]: las 5:00 p. m. del día anterior.
  DateTime limitePausa(DateTime d) =>
      DateTime(d.year, d.month, d.day - 1, horaLimiteSuspension);
  bool puedePausar(DateTime d) =>
      esHabil(d) && ahora.isBefore(limitePausa(d)) && !esFuera(d);
  bool esFuera(DateTime d) =>
      soloFecha(d).isAfter(suscripcion.fechaVencimiento) ||
      soloFecha(d).isBefore(suscripcion.fechaInicio);

  // ---------------------------------------------------------------- sesión
  Rol? rol;
  int intentosFallidos = 0;
  DateTime? bloqueadoHasta;

  static const _cuentas = {
    'laura.gomez@correo.com': Rol.cliente,
    '3004451287': Rol.cliente,
    'julian.ospina@lacocadejacks.co': Rol.domiciliario,
    '3129904471': Rol.domiciliario,
  };
  static const _claveDemo = '12345678';

  /// Devuelve null si entra; si no, el mensaje que se muestra.
  String? iniciarSesion(String identificador, String clave) {
    if (bloqueadoHasta != null && ahora.isBefore(bloqueadoHasta!)) {
      return 'Tu cuenta está bloqueada por intentos fallidos. Intenta de nuevo a las ${hora(bloqueadoHasta!)} o recupera tu contraseña.';
    }
    final id = identificador.trim().toLowerCase().replaceAll(' ', '');
    final r = _cuentas[id];
    if (r == null || clave != _claveDemo) {
      intentosFallidos++;
      if (intentosFallidos >= intentosMaximos) {
        bloqueadoHasta = ahora.add(const Duration(minutes: minutosBloqueo));
        notifyListeners();
        return 'Bloqueamos tu cuenta por $minutosBloqueo minutos después de $intentosMaximos intentos fallidos.';
      }
      final quedan = intentosMaximos - intentosFallidos;
      return 'El correo, el celular o la contraseña no coinciden. Te ${quedan == 1 ? 'queda 1 intento' : 'quedan $quedan intentos'}.';
    }
    _entrar(r);
    return null;
  }

  /// Google, Apple o código por WhatsApp: solo para clientes.
  void entrarComoCliente() => _entrar(Rol.cliente);

  void _entrar(Rol r) {
    intentosFallidos = 0;
    bloqueadoHasta = null;
    rol = r;
    notifyListeners();
  }

  void cerrarSesion() {
    rol = null;
    notifyListeners();
  }

  void registrar({
    required String nombre,
    required String correo,
    required String celular,
    required String tipoDocumento,
    required String documento,
    required Direccion direccion,
    required Set<Alergeno> alergias,
  }) {
    cliente = Cliente(
      nombre: nombre,
      correo: correo,
      celular: celular,
      tipoDocumento: tipoDocumento,
      documento: documento,
      direcciones: [direccion],
      alergias: alergias,
    );
    tienePlan = false;
    solicitudEnCurso = null;
    pagos.clear();
    pausas.clear();
    incidencias.clear();
    _entrar(Rol.cliente);
  }

  // ---------------------------------------------------------------- cliente
  late Cliente cliente;
  late Suscripcion suscripcion;

  /// Falso para un cliente recién registrado: aún no compra su primer plan.
  bool tienePlan = true;
  Suscripcion? solicitudEnCurso;
  final pagos = <Pago>[];
  final pausas = <DateTime>{};
  final menu = <MenuDia>[];
  final incidencias = <Incidencia>[];
  EstadoEntrega entregaHoy = EstadoEntrega.enRuta;
  final domiciliarioHoy = 'Julián Ospina';

  /// Contador en vivo: almuerzos que faltan por recibir (sin festivos ni pausas).
  int get almuerzosRestantes {
    if (!tienePlan || suscripcion.estado != EstadoSuscripcion.activa) return 0;
    var n = 0;
    for (
      var d = hoy;
      !d.isAfter(suscripcion.fechaVencimiento);
      d = DateTime(d.year, d.month, d.day + 1)
    ) {
      if (!esHabil(d) || pausas.contains(d)) continue;
      if (mismoDia(d, hoy) && entregaHoy == EstadoEntrega.entregada) continue;
      n++;
    }
    return n;
  }

  /// Semana de lunes a viernes para el resumen.
  List<DateTime> get semana {
    final lunes = DateTime(hoy.year, hoy.month, hoy.day - (hoy.weekday - 1));
    return List.generate(
      5,
      (i) => DateTime(lunes.year, lunes.month, lunes.day + i),
    );
  }

  List<DateTime> proximosHabiles(int cuantos) {
    final out = <DateTime>[];
    var d = hoy;
    while (out.length < cuantos) {
      if (d.weekday <= DateTime.friday) out.add(d);
      d = DateTime(d.year, d.month, d.day + 1);
    }
    return out;
  }

  MenuDia? menuDe(DateTime d) {
    for (final m in menu) {
      if (mismoDia(m.fecha, d)) return m;
    }
    return null;
  }

  void alternarPausa(DateTime d) {
    final f = soloFecha(d);
    pausas.contains(f) ? pausas.remove(f) : pausas.add(f);
    notifyListeners();
  }

  /// Renovación (o reingreso) con el comprobante: queda "Verificando".
  void solicitarPlan({
    required TipoPlan plan,
    required PreferenciaProteina preferencia,
  }) {
    final tipo = !tienePlan
        ? TipoVenta.nueva
        : suscripcion.estado.permiteReingreso
        ? TipoVenta.reingreso
        : TipoVenta.renovacion;
    final inicio = inicioSiguienteCiclo;
    final valor =
        plan.valor +
        (preferencia == PreferenciaProteina.normal ? 0 : recargoPreferencia);
    solicitudEnCurso = Suscripcion(
      referencia: 'SUS-${2611 + pagos.length}',
      plan: plan,
      tipoVenta: tipo,
      preferencia: preferencia,
      fechaSolicitud: ahora,
      fechaInicio: inicio,
      fechaVencimiento: _vencimiento(inicio, plan),
      valorPlan: valor,
      cobroCocas: cliente.tieneKitCocas ? 0 : cobroCocas,
      estado: EstadoSuscripcion.verificando,
    );
    pagos.insert(
      0,
      Pago(
        fecha: ahora,
        concepto: '${tipo.label} · Plan ${plan.label.toLowerCase()}',
        valor: solicitudEnCurso!.total,
        estado: 'En verificación',
        referencia: solicitudEnCurso!.referencia,
      ),
    );
    cliente.preferencia = preferencia;
    if (!tienePlan) {
      suscripcion = solicitudEnCurso!;
      tienePlan = true;
    }
    notifyListeners();
  }

  /// Lunes siguiente al vencimiento (renovación) o al corte del sábado 12:00 m.
  DateTime get inicioSiguienteCiclo {
    var d = !tienePlan || suscripcion.estado.permiteReingreso
        ? hoy
        : suscripcion.fechaVencimiento;
    d = DateTime(d.year, d.month, d.day + 1);
    while (d.weekday != DateTime.monday) {
      d = DateTime(d.year, d.month, d.day + 1);
    }
    return d;
  }

  DateTime _vencimiento(DateTime inicio, TipoPlan plan) {
    final semanas = plan.almuerzos ~/ 5;
    return DateTime(inicio.year, inicio.month, inicio.day + semanas * 7 - 3);
  }

  void reportarIncidencia(TipoIncidencia tipo, String descripcion, bool foto) {
    incidencias.insert(
      0,
      Incidencia(
        id: 400 + incidencias.length + novedades.length,
        tipo: tipo,
        descripcion: descripcion,
        fecha: ahora,
        conFoto: foto,
      ),
    );
    notifyListeners();
  }

  void guardarPerfil() => notifyListeners();

  // ---------------------------------------------------------------- domiciliario
  final domiciliario = (
    nombre: 'Julián Ospina',
    correo: 'julian.ospina@lacocadejacks.co',
    celular: '312 990 4471',
    documento: 'CC 1.007.221.998',
  );
  final rutaNombre = 'Laureles – Estadio';
  final paradas = <Parada>[];
  final novedades = <Incidencia>[];
  final historial = <EntregaHistorial>[];
  bool rutaIniciada = true;
  bool compartiendoUbicacion = true;

  List<Parada> get pendientes => paradas.where((p) => p.pendiente).toList();
  List<Parada> get completadas => paradas.where((p) => !p.pendiente).toList();
  Parada? get siguiente => pendientes.isEmpty ? null : pendientes.first;
  int get cocasPorRecoger => paradas
      .where((p) => p.juegoRecoger != null && !p.cocasRegistradas)
      .length;

  void iniciarRuta() {
    rutaIniciada = true;
    compartiendoUbicacion = true;
    final s = siguiente;
    if (s != null) s.estado = EstadoEntrega.enRuta;
    notifyListeners();
  }

  void alternarUbicacion(bool v) {
    compartiendoUbicacion = v;
    notifyListeners();
  }

  /// Última posición enviada (POST a geolocalizacion_domiciliarios).
  ({double lat, double lng, double precision, DateTime hora})? ultimaUbicacion;

  /// Motivo por el que no se pudo leer el GPS (permiso negado, GPS apagado).
  String? problemaUbicacion;

  void registrarUbicacion(double lat, double lng, double precision) {
    ultimaUbicacion = (
      lat: lat,
      lng: lng,
      precision: precision,
      hora: DateTime.now(),
    );
    problemaUbicacion = null;
    notifyListeners();
  }

  void fallaUbicacion(String motivo) {
    problemaUbicacion = motivo;
    notifyListeners();
  }

  /// Confirmar la entrega o registrar por qué no se pudo.
  void cerrarParada(Parada p, String resultado) {
    p.resultado = resultado;
    p.horaEntrega = ahora;
    p.estado = resultado == 'Entregado'
        ? EstadoEntrega.entregada
        : EstadoEntrega.incidencia;
    if (resultado != 'Entregado') {
      final tipo = switch (resultado) {
        'Cliente ausente' => TipoIncidencia.ausenciaCliente,
        'Dirección incorrecta' => TipoIncidencia.direccionIncorrecta,
        _ => TipoIncidencia.otro,
      };
      novedades.insert(
        0,
        Incidencia(
          id: 500 + novedades.length,
          tipo: tipo,
          descripcion: '$resultado al entregar.',
          fecha: ahora,
          cliente: p.cliente,
        ),
      );
    }
    historial.insert(
      0,
      EntregaHistorial(ahora, p.cliente, p.barrio, resultado),
    );
    final s = siguiente;
    if (s != null && rutaIniciada) s.estado = EstadoEntrega.enRuta;
    if (p.cliente == cliente.nombre && resultado == 'Entregado') {
      entregaHoy = EstadoEntrega.entregada;
    }
    notifyListeners();
  }

  void registrarCocas(Parada p) {
    p.cocasRegistradas = true;
    notifyListeners();
  }

  void reportarNovedad(
    TipoIncidencia tipo,
    String descripcion,
    String? clienteNombre,
    bool foto,
  ) {
    novedades.insert(
      0,
      Incidencia(
        id: 500 + novedades.length,
        tipo: tipo,
        descripcion: descripcion,
        fecha: ahora,
        conFoto: foto,
        cliente: clienteNombre,
      ),
    );
    notifyListeners();
  }

  // ---------------------------------------------------------------- avisos
  List<Notificacion> get notificaciones => rol == Rol.domiciliario
      ? const [
          Notificacion(
            'route',
            'Tu ruta de hoy está lista: 8 entregas',
            '6:45 a. m.',
          ),
          Notificacion(
            'pause',
            'Sofía Marín pausó su almuerzo de mañana',
            'Ayer, 4:10 p. m.',
          ),
          Notificacion(
            'reply',
            'El administrador respondió tu novedad #498',
            'Ayer, 2:30 p. m.',
          ),
        ]
      : const [
          Notificacion('truck', 'Tu almuerzo va en camino', 'Hace 15 min'),
          Notificacion(
            'check',
            'Tu almuerzo del viernes fue entregado',
            'Vie 20 nov, 10:42 a. m.',
          ),
          Notificacion(
            'reply',
            'Respondimos tu incidencia #397',
            '18 nov, 3:15 p. m.',
          ),
          Notificacion(
            'pay',
            'Aprobamos tu pago del plan mensual',
            '6 nov, 9:10 a. m.',
          ),
        ];

  // ---------------------------------------------------------------- datos de prueba
  void _sembrar() {
    cliente = Cliente(
      nombre: 'Laura Gómez',
      correo: 'laura.gomez@correo.com',
      celular: '300 445 1287',
      tipoDocumento: 'CC',
      documento: '43.221.887',
      direcciones: [
        Direccion(
          direccion: 'Cra 76 #33A-21, apto 502',
          barrio: 'Laureles',
          municipio: 'Medellín',
          notas: 'Torre 2. Si no respondo, dejar en portería.',
          dias: {1, 2, 3},
        ),
        Direccion(
          direccion: 'Cl 10 #43C-55, piso 4',
          barrio: 'El Poblado',
          municipio: 'Medellín',
          notas: 'Oficina 402, preguntar en recepción.',
          dias: {4, 5},
        ),
      ],
      alergias: {Alergeno.mariscos},
      preferencia: PreferenciaProteina.soloPollo,
      tieneKitCocas: true,
    );

    suscripcion = Suscripcion(
      referencia: 'SUS-2584',
      plan: TipoPlan.mensual,
      tipoVenta: TipoVenta.renovacion,
      preferencia: PreferenciaProteina.soloPollo,
      fechaSolicitud: DateTime(2026, 11, 5, 18, 40),
      fechaInicio: DateTime(2026, 11, 9),
      fechaVencimiento: DateTime(2026, 12, 4),
      valorPlan: 310000,
      descuentoFestivos: 15500,
      estado: EstadoSuscripcion.activa,
    );

    pagos.addAll([
      Pago(
        fecha: DateTime(2026, 11, 6, 9, 10),
        concepto: 'Renovación · Plan mensual',
        valor: 294500,
        estado: 'Aprobado',
        referencia: 'SUS-2584',
      ),
      Pago(
        fecha: DateTime(2026, 10, 9, 11, 2),
        concepto: 'Suscripción nueva · Plan quincenal',
        valor: 230000,
        estado: 'Aprobado',
        referencia: 'SUS-2391',
      ),
    ]);

    pausas.add(DateTime(2026, 11, 27));

    final semana = this.semana;
    const secos = [
      (
        'Bandeja de frijoles con chicharrón',
        'Frijoles con pollo desmechado',
        null,
      ),
      ('Pollo sudado con papa criolla', null, 'Cerdo sudado con papa criolla'),
      ('Cerdo en salsa de ciruela', 'Pollo en salsa de ciruela', null),
      (
        'Sobrebarriga en salsa criolla',
        'Pechuga en salsa criolla',
        'Lomo de cerdo en salsa criolla',
      ),
      (
        'Cazuela de mariscos con arroz blanco',
        'Arroz con pollo',
        'Arroz con cerdo',
      ),
    ];
    const sopas = [
      'Sopa de arroz',
      'Crema de ahuyama',
      'Sancocho trifásico',
      'Sopa de lentejas',
      'Crema de espinaca',
    ];
    const ensaladas = [
      'Ensalada de repollo y zanahoria',
      'Tomate, cebolla y cilantro',
      'Ensalada verde con aguacate',
      'Remolacha y zanahoria',
      'Pepino con limón',
    ];
    const bebidas = [
      'Jugo de mora',
      'Limonada de panela',
      'Jugo de guayaba',
      'Jugo de maracuyá',
      'Agua de panela con limón',
    ];
    for (var i = 0; i < 5; i++) {
      menu.add(
        MenuDia(
          fecha: semana[i],
          seco: secos[i].$1,
          secoPollo: secos[i].$2,
          secoCerdo: secos[i].$3,
          sopa: sopas[i],
          ensalada: ensaladas[i],
          bebida: bebidas[i],
          alternativas: i == 4
              ? const {Alergeno.mariscos: 'Arroz con pollo y verduras'}
              : i == 3
              ? const {Alergeno.lacteos: 'Crema de espinaca sin leche'}
              : const {},
        ),
      );
    }

    incidencias.addAll([
      Incidencia(
        id: 397,
        tipo: TipoIncidencia.cocaDefectuosa,
        descripcion: 'La tapa de la sopa llegó partida y se regó un poco.',
        fecha: DateTime(2026, 11, 17, 12, 5),
        estado: EstadoIncidencia.resuelta,
        conFoto: true,
        respuesta:
            'Laura, ya cambiamos esa pieza de tu juego de cocas. Gracias por avisarnos.',
        fechaResolucion: DateTime(2026, 11, 18, 15, 15),
      ),
      Incidencia(
        id: 412,
        tipo: TipoIncidencia.retraso,
        descripcion: 'El almuerzo del jueves llegó después de las 12.',
        fecha: DateTime(2026, 11, 19, 12, 20),
        estado: EstadoIncidencia.enRevision,
      ),
    ]);

    paradas.addAll([
      Parada(
        id: 1,
        orden: 1,
        cliente: 'Carlos Mejía',
        celular: '301 220 1144',
        direccion: 'Cl 44 #74-30',
        barrio: 'Laureles',
        notas: 'Casa esquinera de rejas verdes.',
        x: .14,
        y: .22,
        juegoEntregar: 2,
        juegoRecoger: 1,
        estado: EstadoEntrega.entregada,
        horaEntrega: DateTime(2026, 11, 23, 9, 18),
        resultado: 'Entregado',
      ),
      Parada(
        id: 2,
        orden: 2,
        cliente: 'Daniela Zapata',
        celular: '310 554 0921',
        direccion: 'Cra 70 #45E-12, apto 301',
        barrio: 'Estadio',
        notas: 'Timbre 301.',
        x: .30,
        y: .14,
        alergias: const {Alergeno.gluten},
        juegoEntregar: 1,
        juegoRecoger: 2,
        estado: EstadoEntrega.entregada,
        horaEntrega: DateTime(2026, 11, 23, 9, 41),
        resultado: 'Entregado',
      ),
      Parada(
        id: 3,
        orden: 3,
        cliente: 'Andrés Ruiz',
        celular: '304 118 7760',
        direccion: 'Cl 33 #70-12',
        barrio: 'Laureles',
        notas: 'Local de mascotas, primer piso.',
        x: .46,
        y: .30,
        juegoEntregar: 1,
        estado: EstadoEntrega.entregada,
        horaEntrega: DateTime(2026, 11, 23, 10, 2),
        resultado: 'Entregado',
      ),
      Parada(
        id: 4,
        orden: 4,
        cliente: 'Laura Gómez',
        celular: '300 445 1287',
        direccion: 'Cra 76 #33A-21, apto 502',
        barrio: 'Laureles',
        notas: 'Torre 2. Si no responde, dejar en portería.',
        x: .58,
        y: .48,
        alergias: const {Alergeno.mariscos},
        preferencia: PreferenciaProteina.soloPollo,
        juegoEntregar: 2,
        juegoRecoger: 1,
        estado: EstadoEntrega.enRuta,
      ),
      Parada(
        id: 5,
        orden: 5,
        cliente: 'Sofía Marín',
        celular: '315 660 2290',
        direccion: 'Cra 81 #30-44',
        barrio: 'Belén',
        notas: 'Portería del conjunto Altos de Belén.',
        x: .72,
        y: .38,
        preferencia: PreferenciaProteina.soloCerdo,
        juegoEntregar: 1,
        juegoRecoger: 2,
      ),
      Parada(
        id: 6,
        orden: 6,
        cliente: 'Mateo Restrepo',
        celular: '300 912 3381',
        direccion: 'Cl 30A #82-15',
        barrio: 'Belén',
        notas: '',
        x: .82,
        y: .58,
        alergias: const {Alergeno.lacteos, Alergeno.huevo},
        juegoEntregar: 2,
        juegoRecoger: 1,
      ),
      Parada(
        id: 7,
        orden: 7,
        cliente: 'Valentina Ochoa',
        celular: '318 223 4471',
        direccion: 'Cra 65 #32-08, of. 210',
        barrio: 'Conquistadores',
        notas: 'Recepción del edificio.',
        x: .62,
        y: .76,
        juegoEntregar: 1,
        juegoRecoger: 2,
      ),
      Parada(
        id: 8,
        orden: 8,
        cliente: 'Juan Pablo Arango',
        celular: '302 771 0055',
        direccion: 'Cl 37 #66B-40',
        barrio: 'Conquistadores',
        notas: '',
        x: .40,
        y: .84,
        juegoEntregar: 2,
      ),
    ]);

    novedades.add(
      Incidencia(
        id: 498,
        tipo: TipoIncidencia.cocaNoDevuelta,
        descripcion: 'El cliente no tenía listo el juego vacío.',
        fecha: DateTime(2026, 11, 20, 10, 50),
        estado: EstadoIncidencia.resuelta,
        cliente: 'Mateo Restrepo',
        respuesta: 'Lo recoges mañana con el siguiente almuerzo.',
        fechaResolucion: DateTime(2026, 11, 20, 14, 30),
      ),
    );

    for (final p in paradas.where((p) => !p.pendiente)) {
      historial.add(
        EntregaHistorial(p.horaEntrega!, p.cliente, p.barrio, p.resultado!),
      );
    }
    final previos = [
      (DateTime(2026, 11, 20, 9, 12), 'Carlos Mejía', 'Laureles', 'Entregado'),
      (DateTime(2026, 11, 20, 9, 40), 'Daniela Zapata', 'Estadio', 'Entregado'),
      (
        DateTime(2026, 11, 20, 10, 20),
        'Laura Gómez',
        'El Poblado',
        'Entregado',
      ),
      (DateTime(2026, 11, 20, 10, 50), 'Mateo Restrepo', 'Belén', 'Entregado'),
      (
        DateTime(2026, 11, 19, 9, 30),
        'Sofía Marín',
        'Belén',
        'Cliente ausente',
      ),
      (DateTime(2026, 11, 19, 10, 5), 'Andrés Ruiz', 'Laureles', 'Entregado'),
      (
        DateTime(2026, 11, 18, 9, 22),
        'Valentina Ochoa',
        'Conquistadores',
        'Entregado',
      ),
      (
        DateTime(2026, 11, 13, 11, 10),
        'Juan Pablo Arango',
        'Conquistadores',
        'Dirección incorrecta',
      ),
    ];
    historial.insertAll(
      0,
      previos.map((e) => EntregaHistorial(e.$1, e.$2, e.$3, e.$4)),
    );
    historial.sort((a, b) => b.fecha.compareTo(a.fecha));
  }
}

/// Acceso al estado desde cualquier pantalla: `AppScope.of(context)`.
class AppScope extends InheritedNotifier<AppState> {
  const AppScope({super.key, required AppState state, required super.child})
    : super(notifier: state);

  static AppState of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<AppScope>()!.notifier!;

  static AppState read(BuildContext context) =>
      context.getInheritedWidgetOfExactType<AppScope>()!.notifier!;
}
