import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import 'widgets.dart';

/// Celular colombiano a formato internacional: "300 445 1287" → "573004451287".
String celularCo(String celular) {
  final d = celular.replaceAll(RegExp(r'\D'), '');
  return d.startsWith('57') && d.length == 12 ? d : '57$d';
}

Future<void> _abrir(BuildContext context, Uri uri, String falla) async {
  var ok = false;
  try {
    ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
  } catch (_) {
    ok = false;
  }
  if (!ok && context.mounted) {
    showToast(context, falla, icon: Icons.error_outline);
  }
}

Future<void> llamar(BuildContext context, String celular) => _abrir(
  context,
  Uri(scheme: 'tel', path: '+${celularCo(celular)}'),
  'No pudimos abrir el teléfono. Marca al $celular.',
);

Future<void> abrirWhatsapp(
  BuildContext context,
  String celular, {
  String mensaje = '',
}) => _abrir(
  context,
  Uri.https('wa.me', '/${celularCo(celular)}', {
    if (mensaje.isNotEmpty) 'text': mensaje,
  }),
  'No pudimos abrir WhatsApp.',
);

/// Abre Google Maps (o el navegador) con la ruta hasta la dirección.
Future<void> navegarA(
  BuildContext context,
  String direccion, {
  String municipio = 'Medellín',
}) => _abrir(
  context,
  Uri.https('www.google.com', '/maps/dir/', {
    'api': '1',
    'destination': '$direccion, $municipio, Antioquia, Colombia',
    'travelmode': 'driving',
  }),
  'No pudimos abrir la navegación.',
);
