import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jacksoft_mobile/core/format.dart';
import 'package:jacksoft_mobile/core/launch.dart';
import 'package:jacksoft_mobile/core/location.dart';
import 'package:jacksoft_mobile/core/map.dart';
import 'package:jacksoft_mobile/core/theme.dart';
import 'package:jacksoft_mobile/data/app_state.dart';
import 'package:jacksoft_mobile/data/models.dart';
import 'package:jacksoft_mobile/main.dart';

Future<void> _abrir(WidgetTester t, AppState st) async {
  t.view.physicalSize = const Size(390 * 3, 844 * 3);
  t.view.devicePixelRatio = 3;
  addTearDown(t.view.reset);
  await t.pumpWidget(JackSoftApp(state: st));
  await t.tap(find.text('La Coca de Jacks')); // salta el splash
  await t.pumpAndSettle();
}

void main() {
  setUp(() {
    JkText.googleFonts = false;
    RouteMap.tiles = false;
    UbicacionTracker.enabled = false;
  });

  group('reglas', () {
    test('pesos colombianos', () {
      expect(cop(300000), r'$300.000');
      expect(cop(75000), r'$75.000');
    });

    test('celular colombiano para llamar y WhatsApp', () {
      expect(celularCo('300 445 1287'), '573004451287');
      expect(celularCo('+57 300 445 1287'), '573004451287');
    });

    test('festivos que descuenta el plan activo', () {
      final st = AppState();
      expect(st.festivosDel(st.suscripcion), [DateTime(2026, 11, 16)]);
    });

    test('pausa hasta las 5:00 p. m. del día anterior', () {
      final st = AppState(); // ahora: lun 23 nov 2026, 10:20 a. m.
      expect(st.puedePausar(DateTime(2026, 11, 24)), isTrue);
      expect(st.puedePausar(DateTime(2026, 11, 23)), isFalse);
      expect(st.puedePausar(DateTime(2026, 12, 8)), isFalse); // festivo
    });

    test('la pausa no mueve el vencimiento y descuenta un almuerzo', () {
      final st = AppState();
      final antes = st.almuerzosRestantes;
      final vence = st.suscripcion.fechaVencimiento;
      st.alternarPausa(DateTime(2026, 11, 24));
      expect(st.almuerzosRestantes, antes - 1);
      expect(st.suscripcion.fechaVencimiento, vence);
    });

    test(
      'renovación con kit: no cobra cocas y suma el recargo de proteína',
      () {
        final st = AppState();
        st.solicitarPlan(
          plan: TipoPlan.mensual,
          preferencia: PreferenciaProteina.soloCerdo,
        );
        final s = st.solicitudEnCurso!;
        expect(s.tipoVenta, TipoVenta.renovacion);
        expect(s.cobroCocas, 0);
        expect(s.total, 310000);
        expect(s.fechaInicio, DateTime(2026, 12, 7));
      },
    );

    test('bloqueo tras 5 intentos fallidos', () {
      final st = AppState();
      for (var i = 0; i < 4; i++) {
        expect(
          st.iniciarSesion('laura.gomez@correo.com', 'x'),
          contains('intento'),
        );
      }
      expect(
        st.iniciarSesion('laura.gomez@correo.com', 'x'),
        contains('Bloqueamos'),
      );
      expect(
        st.iniciarSesion('laura.gomez@correo.com', '12345678'),
        contains('bloqueada'),
      );
    });
  });

  testWidgets('cliente: entra, ve su almuerzo y su plan', (t) async {
    final st = AppState();
    await _abrir(t, st);
    expect(find.text('Inicia sesión'), findsOneWidget);
    await t.tap(find.text('Ingresar'));
    await t.pumpAndSettle();
    expect(find.text('Hola, Laura'), findsOneWidget);
    expect(find.text('Tu almuerzo de hoy'), findsOneWidget);
    await t.tap(find.text('Mi plan').last);
    await t.pumpAndSettle();
    expect(find.text('Plan mensual'), findsOneWidget);
    expect(find.text('Renovar mi plan'), findsOneWidget);
  });

  testWidgets('domiciliario: confirma la entrega en curso', (t) async {
    final st = AppState();
    await _abrir(t, st);
    await t.tap(find.text('Domiciliario'));
    await t.pumpAndSettle();
    await t.tap(find.text('Ingresar'));
    await t.pumpAndSettle();
    expect(find.text('Hola, Julián'), findsOneWidget);
    final pendientes = st.pendientes.length;
    await t.tap(find.textContaining('Ir a la siguiente'));
    await t.pumpAndSettle();
    await t.tap(find.text('Confirmar entrega'));
    await t.pumpAndSettle();
    await t.tap(find.text('Entregado'));
    await t.pumpAndSettle();
    await t.tap(find.text('Confirmar'));
    await t.pumpAndSettle();
    expect(st.pendientes.length, pendientes - 1);
    expect(st.entregaHoy, EstadoEntrega.entregada); // era la entrega de Laura
  });
}
