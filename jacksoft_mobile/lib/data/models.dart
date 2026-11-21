/// Modelos del dominio. Los enums siguen al modelo relacional
/// DocumentacionJackSoft/04_Modelado_DB/Modelo_Relacional/v15_2026-11-20/bd.uml
/// (DBML v4.8). El campo [db] es el valor que viaja a la API.
library;

enum Rol { cliente, domiciliario }

enum EstadoSuscripcion {
  enEspera('en_espera', 'En espera'),
  pendientePago('pendiente_pago', 'Pendiente de pago'),
  verificando('verificando', 'Verificando pago'),
  activa('activa', 'Activa'),
  finalizada('finalizada', 'Finalizada'),
  rechazada('rechazada', 'Rechazada'),
  cancelada('cancelada', 'Cancelada');

  const EstadoSuscripcion(this.db, this.label);
  final String db;
  final String label;

  /// Con estos estados el botón dinámico ofrece "Volver" (reingreso).
  bool get permiteReingreso =>
      this == finalizada || this == cancelada || this == rechazada;
}

/// Planes y precios de PRODUCT.md (los define el administrador en Servicios).
enum TipoPlan {
  semanal('semanal', 'Semanal', 5, 75000),
  quincenal('quincenal', 'Quincenal', 10, 150000),
  mensual('mensual', 'Mensual', 20, 300000);

  const TipoPlan(this.db, this.label, this.almuerzos, this.valor);
  final String db;
  final String label;
  final int almuerzos;
  final int valor;
}

/// `clientes.preferencia_proteina`: vacío = menú normal.
enum PreferenciaProteina {
  normal(null, 'Menú normal', 'El seco del menú de cada día'),
  soloPollo('solo_pollo', 'Solo pollo', 'El seco siempre en versión de pollo'),
  soloCerdo('solo_cerdo', 'Solo cerdo', 'El seco siempre en versión de cerdo');

  const PreferenciaProteina(this.db, this.label, this.detalle);
  final String? db;
  final String label;
  final String detalle;
}

enum TipoVenta {
  nueva('nueva', 'Suscripción nueva'),
  renovacion('renovacion', 'Renovación'),
  reingreso('reingreso', 'Reingreso');

  const TipoVenta(this.db, this.label);
  final String db;
  final String label;
}

enum EstadoEntrega {
  programada('programada', 'Programada'),
  enRuta('en_ruta', 'En ruta'),
  entregada('entregada', 'Entregada'),
  suspendida('suspendida', 'Pausada'),
  incidencia('incidencia', 'Con novedad');

  const EstadoEntrega(this.db, this.label);
  final String db;
  final String label;
}

enum EstadoIncidencia {
  abierta('abierta', 'Abierta'),
  enRevision('en_revision', 'En revisión'),
  resuelta('resuelta', 'Resuelta');

  const EstadoIncidencia(this.db, this.label);
  final String db;
  final String label;
}

enum TipoIncidencia {
  cocaDefectuosa('coca_defectuosa', 'Coca defectuosa'),
  ausenciaCliente('ausencia_cliente', 'Cliente ausente'),
  direccionIncorrecta('direccion_incorrecta', 'Dirección incorrecta'),
  calidadAlmuerzo('calidad_almuerzo', 'Calidad del almuerzo'),
  cocaNoDevuelta('coca_no_devuelta', 'Coca no devuelta'),
  retraso('retraso', 'Retraso'),
  alergiaNoAtendida('alergia_no_atendida', 'Alergia no atendida'),
  otro('otro', 'Otro');

  const TipoIncidencia(this.db, this.label);
  final String db;
  final String label;

  static const delCliente = [
    calidadAlmuerzo,
    cocaDefectuosa,
    retraso,
    alergiaNoAtendida,
    otro,
  ];
  static const deRuta = [
    ausenciaCliente,
    direccionIncorrecta,
    cocaDefectuosa,
    cocaNoDevuelta,
    retraso,
    otro,
  ];
}

/// `componente_alimento`: lista cerrada de 7 alergias (acuerdo G1–G3, sin texto libre).
enum Alergeno {
  carne('carne', 'Carne'),
  cerdo('cerdo', 'Cerdo'),
  mariscos('mariscos', 'Mariscos'),
  gluten('gluten', 'Gluten'),
  lacteos('lacteos', 'Lácteos'),
  frutosSecos('frutos_secos', 'Frutos secos'),
  huevo('huevo', 'Huevo');

  const Alergeno(this.db, this.label);
  final String db;
  final String label;
}

enum EstadoFisicoRecipiente {
  bueno('bueno', 'Bueno'),
  danado('danado', 'Dañado'),
  perdido('perdido', 'Perdido');

  const EstadoFisicoRecipiente(this.db, this.label);
  final String db;
  final String label;
}

/// Piezas de un juego de cocas = categorías de producto.
const piezasCoca = ['Seco', 'Sopa', 'Ensalada', 'Bebida'];

const municipios = ['Medellín', 'Bello', 'Envigado', 'Itagüí', 'Sabaneta'];

class Direccion {
  Direccion({
    required this.direccion,
    required this.barrio,
    required this.municipio,
    this.notas = '',
    Set<int>? dias,
  }) : dias = dias ?? {1, 2, 3, 4, 5};

  String direccion;
  String barrio;
  String municipio;
  String notas;

  /// `direccion_dias`: días hábiles (1 = lunes) en que se usa esta dirección.
  Set<int> dias;

  String get resumen => '$direccion, $barrio';
}

class Cliente {
  Cliente({
    required this.nombre,
    required this.correo,
    required this.celular,
    required this.tipoDocumento,
    required this.documento,
    required this.direcciones,
    Set<Alergeno>? alergias,
    this.preferencia = PreferenciaProteina.normal,
    this.tieneKitCocas = false,
    this.avisosWhatsapp = true,
  }) : alergias = alergias ?? {};

  String nombre;
  String correo;
  String celular;
  String tipoDocumento;
  String documento;
  List<Direccion> direcciones;
  Set<Alergeno> alergias;
  PreferenciaProteina preferencia;

  /// HU06.1_12: el sistema sabe si ya tiene el kit y no lo cobra de nuevo.
  bool tieneKitCocas;
  bool avisosWhatsapp;

  /// La modalidad se calcula con las direcciones (bd.uml): una = Fija, dos = Híbrida.
  bool get esHibrida => direcciones.length > 1;
  String get primerNombre => nombre.split(' ').first;

  Direccion direccionDelDia(DateTime d) => direcciones.firstWhere(
    (x) => x.dias.contains(d.weekday),
    orElse: () => direcciones.first,
  );
}

class Suscripcion {
  Suscripcion({
    required this.referencia,
    required this.plan,
    required this.tipoVenta,
    required this.preferencia,
    required this.fechaSolicitud,
    required this.fechaInicio,
    required this.fechaVencimiento,
    required this.valorPlan,
    required this.estado,
    this.descuentoFestivos = 0,
    this.cobroCocas = 0,
  });

  final String referencia;
  final TipoPlan plan;
  final TipoVenta tipoVenta;
  final PreferenciaProteina preferencia;
  final DateTime fechaSolicitud;
  final DateTime fechaInicio;
  final DateTime fechaVencimiento;
  final int valorPlan;
  final int descuentoFestivos;
  final int cobroCocas;
  EstadoSuscripcion estado;

  int get total => valorPlan - descuentoFestivos + cobroCocas;
}

class Pago {
  Pago({
    required this.fecha,
    required this.concepto,
    required this.valor,
    required this.estado,
    required this.referencia,
  });
  final DateTime fecha;
  final String concepto;
  final int valor;
  final String estado; // Aprobado · En verificación · Rechazado
  final String referencia;
}

class MenuDia {
  const MenuDia({
    required this.fecha,
    required this.seco,
    required this.sopa,
    required this.ensalada,
    required this.bebida,
    this.alternativas = const {},
    this.secoPollo,
    this.secoCerdo,
  });
  final DateTime fecha;
  final String seco;
  final String sopa;
  final String ensalada;
  final String bebida;

  /// `menu_alternativas`: plato que reemplaza al del menú según la alergia.
  final Map<Alergeno, String> alternativas;
  final String? secoPollo;
  final String? secoCerdo;

  String secoPara(PreferenciaProteina p) => switch (p) {
    PreferenciaProteina.soloPollo => secoPollo ?? seco,
    PreferenciaProteina.soloCerdo => secoCerdo ?? seco,
    PreferenciaProteina.normal => seco,
  };
}

class Incidencia {
  Incidencia({
    required this.id,
    required this.tipo,
    required this.descripcion,
    required this.fecha,
    this.estado = EstadoIncidencia.abierta,
    this.conFoto = false,
    this.respuesta,
    this.fechaResolucion,
    this.cliente,
  });
  final int id;
  final TipoIncidencia tipo;
  final String descripcion;
  final DateTime fecha;
  EstadoIncidencia estado;
  final bool conFoto;
  String? respuesta;
  DateTime? fechaResolucion;

  /// Solo en las novedades de ruta del domiciliario.
  final String? cliente;
}

/// Una fila de `ruta_clientes` vista por el domiciliario.
class Parada {
  Parada({
    required this.id,
    required this.orden,
    required this.cliente,
    required this.celular,
    required this.direccion,
    required this.barrio,
    required this.notas,
    required this.x,
    required this.y,
    this.alergias = const {},
    this.preferencia = PreferenciaProteina.normal,
    required this.juegoEntregar,
    this.juegoRecoger,
    this.estado = EstadoEntrega.programada,
    this.horaEntrega,
    this.resultado,
  });
  final int id;
  final int orden;
  final String cliente;
  final String celular;
  final String direccion;
  final String barrio;
  final String notas;

  /// Posición normalizada (0–1) en el mapa de la ruta.
  final double x;
  final double y;
  final Set<Alergeno> alergias;
  final PreferenciaProteina preferencia;
  final int juegoEntregar;
  final int? juegoRecoger;
  EstadoEntrega estado;
  DateTime? horaEntrega;
  String? resultado;
  bool cocasRegistradas = false;

  bool get pendiente =>
      estado == EstadoEntrega.programada || estado == EstadoEntrega.enRuta;
}

class EntregaHistorial {
  const EntregaHistorial(this.fecha, this.cliente, this.barrio, this.resultado);
  final DateTime fecha;
  final String cliente;
  final String barrio;
  final String resultado; // Entregado · Cliente ausente · Dirección incorrecta
}

class Notificacion {
  const Notificacion(this.icono, this.titulo, this.cuando);
  final String icono;
  final String titulo;
  final String cuando;
}
