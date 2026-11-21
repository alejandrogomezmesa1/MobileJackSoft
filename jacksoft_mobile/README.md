# JackSoft Mobile

App móvil de La Coca de Jacks para **clientes** y **domiciliarios**, hecha con Flutter y Dart.

## Cómo correrla

```bash
flutter pub get
flutter run                     # emulador o celular conectado
flutter run -d chrome           # en el navegador
flutter test                    # reglas de negocio y flujos principales
```

Cuentas de prueba (contraseña `12345678`). En el inicio de sesión, el selector **Cliente / Domiciliario** llena estos datos.

| Rol | Correo | Celular |
|---|---|---|
| Cliente | laura.gomez@correo.com | 300 445 1287 |
| Domiciliario | julian.ospina@lacocadejacks.co | 312 990 4471 |

La demo usa un reloj fijo: **lunes 23 de noviembre de 2026, 10:20 a. m.** ([AppState.ahora](lib/data/app_state.dart)). Así el almuerzo del día está en ruta y la semana tiene un día pausado.

## Fuentes que usa

- **Diseño:** el prototipo [`../jacksoft-mobile.html`](../jacksoft-mobile.html) define las pantallas, las pestañas y la navegación.
- **Estilo:** se ajustó a [`FrontedJackSoft/jacksoft/DESIGN.md`](../../FrontedJackSoft/jacksoft/DESIGN.md), en especial a su sección "Cuenta del cliente":
  - fondo `#faf8f5`, líneas `#e7e1d9` y esquinas de 2 px;
  - solo un botón naranja por pantalla, con texto carbón;
  - la pestaña activa, el día de hoy y la barra de avance van en carbón;
  - sin gradientes;
  - Baloo 2, Work Sans y monoespaciada solo en los recibos.
- **Datos:** los enums y las tablas siguen a `DocumentacionJackSoft/04_Modelado_DB/Modelo_Relacional/v15_2026-11-20/bd.uml`.
- **Reglas:** vienen de la ficha técnica v12 (alcance móvil) y de las HU de la Matriz HU (Kanban v12).

## Estructura

```
lib/
  main.dart                  splash → acceso → app según el rol
  core/theme.dart            tokens de DESIGN.md (colores, radio, tipografía)
  core/widgets.dart          tarjetas, botones, estados, campos, mapa, avisos
  core/shell.dart            barra superior, pestañas, páginas apiladas, marca
  core/format.dart           pesos, fechas y horas en español
  core/map.dart              mapa real (OpenStreetMap, flutter_map) con recorrido
  core/media.dart            foto o comprobante desde la cámara o la galería
  core/launch.dart           llamar, WhatsApp y navegación (Google Maps)
  core/location.dart         GPS del domiciliario mientras está en ruta
  data/models.dart           enums y entidades de bd.uml
  data/app_state.dart        estado con datos de prueba (reemplazar por la API)
  features/auth/             login, registro, recuperar, código por WhatsApp
  features/cliente/          inicio, plan/renovación, entrega/seguimiento,
                             incidencias, pausar, menú, perfil
  features/domiciliario/     inicio, ruta, entregas, detalle, confirmar,
                             cocas, novedades, historial, perfil
```

## HU cubiertas

- **Acceso:** 02.2_01–04, 02.2_11 y 02.2_12.
- **Clientes:** 06.1_08–12.
- **Suscripciones:** 06.2_11–14 y 06.2_16.
- **Menú:** 06.3_08 y 06.3_09.
- **Domiciliarios:** 07.1_09 y 07.2_06–10.
- **Incidencias:** 07.3_07–09.

## Qué ya es real y qué es de prueba

| Real en el celular | De prueba |
|---|---|
| Mapa de OpenStreetMap con las paradas y el recorrido | Datos de clientes, rutas, pagos y menú (`AppState`) |
| Cámara y galería para el comprobante y las fotos | La foto no se sube: falta el endpoint |
| Llamar, abrir WhatsApp y navegar con Google Maps | El seguimiento del cliente mueve al domiciliario solo |
| GPS del domiciliario cada 15 s o 25 m mientras está en ruta, también con la pantalla apagada | La posición queda en la app: falta enviarla a la API |
| Detecta Wi-Fi o datos; sin señal guarda las posiciones y las envía al volver | |
| Textos del sistema en español y deslizar para actualizar | Google, Apple y el código por WhatsApp entran directo |

Permisos ya configurados:
- **Android:**
  - ubicación precisa y aproximada;
  - servicio en primer plano de ubicación, con una notificación fija mientras comparte;
  - internet, estado de la red y del Wi-Fi;
  - notificaciones;
  - consultas para teléfono y enlaces.
- **iOS:**
  - cámara y fotos;
  - ubicación "al usar la app" y "siempre", con el modo de fondo `location`;
  - los esquemas `tel`, `https` y `whatsapp`.

Si Google Play Services no entrega la ubicación (por ejemplo, con la "Precisión de la ubicación de Google" apagada), la app usa el GPS del sistema.

## Calidad

- Reglas de [very_good_analysis](https://pub.dev/packages/very_good_analysis). `flutter analyze` no debe mostrar avisos.
- En VS Code, instala las extensiones **Flutter** y **Dart**.

## Pendiente para producción

- Conectar la API. Cada método de `AppState` corresponde a una llamada. `registrarUbicacion` debe enviar a `geolocalizacion_domiciliarios`.
- Subir las fotos (`incidencias.foto_url` y `pagos.comprobante_url`).
- Activar las notificaciones push (`dispositivos_push`).
- Implementar de verdad el inicio de sesión con Google, Apple y el código por WhatsApp.
- Cargar el WhatsApp de atención y la cuenta Bancolombia desde `configuraciones_sistema`. Hoy son datos de ejemplo.
- Agregar Gourmet (Estándar o Gourmet al cotizar y el menú de cada categoría) cuando cierre el grill G6.
