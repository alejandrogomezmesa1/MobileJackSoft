/// Formatos en español de Colombia (pesos sin decimales, fechas y horas "a. m.").
library;

String cop(num valor) {
  final negativo = valor < 0;
  final s = valor.abs().round().toString();
  final b = StringBuffer();
  for (var i = 0; i < s.length; i++) {
    if (i > 0 && (s.length - i) % 3 == 0) b.write('.');
    b.write(s[i]);
  }
  return '${negativo ? '−' : ''}\$$b';
}

const _mesesCorto = [
  'ene',
  'feb',
  'mar',
  'abr',
  'may',
  'jun',
  'jul',
  'ago',
  'sep',
  'oct',
  'nov',
  'dic',
];
const _meses = [
  'enero',
  'febrero',
  'marzo',
  'abril',
  'mayo',
  'junio',
  'julio',
  'agosto',
  'septiembre',
  'octubre',
  'noviembre',
  'diciembre',
];
const _dias = [
  'lunes',
  'martes',
  'miércoles',
  'jueves',
  'viernes',
  'sábado',
  'domingo',
];
const _iniciales = ['L', 'M', 'X', 'J', 'V', 'S', 'D'];

/// "23 nov"
String fechaCorta(DateTime d) => '${d.day} ${_mesesCorto[d.month - 1]}';

/// "23 nov 2026"
String fechaMedia(DateTime d) => '${fechaCorta(d)} ${d.year}';

/// "lunes 23 de noviembre"
String fechaLarga(DateTime d) =>
    '${_dias[d.weekday - 1]} ${d.day} de ${_meses[d.month - 1]}';

String nombreDia(DateTime d) => _dias[d.weekday - 1];
String inicialDia(DateTime d) => _iniciales[d.weekday - 1];
String nombreMes(DateTime d) => _meses[d.month - 1];

/// "10:20 a. m.", "12:00 m.", "5:00 p. m."
String hora(DateTime d) {
  if (d.hour == 12 && d.minute == 0) return '12:00 m.';
  final h = d.hour % 12 == 0 ? 12 : d.hour % 12;
  final m = d.minute.toString().padLeft(2, '0');
  return '$h:$m ${d.hour < 12 ? 'a. m.' : 'p. m.'}';
}

String capitalizar(String s) =>
    s.isEmpty ? s : s[0].toUpperCase() + s.substring(1);

bool mismoDia(DateTime a, DateTime b) =>
    a.year == b.year && a.month == b.month && a.day == b.day;

DateTime soloFecha(DateTime d) => DateTime(d.year, d.month, d.day);

String iniciales(String nombre) {
  final partes = nombre.trim().split(RegExp(r'\s+'));
  return partes.take(2).map((p) => p[0].toUpperCase()).join();
}
