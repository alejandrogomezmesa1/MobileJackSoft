import 'package:flutter/material.dart';

import 'package:jacksoft_mobile/core/shell.dart';
import 'package:jacksoft_mobile/core/theme.dart';
import 'package:jacksoft_mobile/core/widgets.dart';
import 'package:jacksoft_mobile/data/app_state.dart';
import 'package:jacksoft_mobile/data/models.dart';

/// HU06.1_09 / 06.1_10 / 06.1_11: datos, direcciones (Fija o Híbrida) y alergias.
/// Secciones que se leen como lista y se editan en el mismo lugar, una a la
/// vez.
class PerfilTab extends StatefulWidget {
  const PerfilTab({super.key});

  @override
  State<PerfilTab> createState() => _PerfilTabState();
}

enum _Seccion { datos, direcciones, alergias }

class _PerfilTabState extends State<PerfilTab> {
  _Seccion? _editando;

  void _editar(_Seccion? s) => setState(() => _editando = s);

  void _guardar(String msg) {
    AppScope.read(context).guardarPerfil();
    _editar(null);
    showToast(context, msg);
  }

  @override
  Widget build(BuildContext context) {
    final st = AppScope.of(context);
    final c = st.cliente;
    return TabBody(
      children: [
        JkCard(
          child: Row(
            children: [
              Avatar(
                c.nombre.split(' ').take(2).map((p) => p[0]).join(),
                size: 56,
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(c.nombre, style: JkText.display(22)),
                    Text(
                      c.correo,
                      style: JkText.body(14, c: JkColors.inkMuted),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        _SeccionCard(
          titulo: 'Datos personales',
          editando: _editando == _Seccion.datos,
          onEditar: () => _editar(_Seccion.datos),
          onCancelar: () => _editar(null),
          onGuardar: () => _guardar('Datos actualizados'),
          lectura: Column(
            children: [
              InfoRow('Documento', '${c.tipoDocumento} ${c.documento}'),
              InfoRow('Celular', c.celular),
              InfoRow('Correo', c.correo, last: true),
            ],
          ),
          edicion: Column(
            children: [
              JkField(label: 'Nombre completo', initialValue: c.nombre),
              JkField(
                label: 'Celular',
                initialValue: c.celular,
                keyboard: TextInputType.phone,
              ),
              JkField(
                label: 'Correo',
                initialValue: c.correo,
                keyboard: TextInputType.emailAddress,
              ),
            ],
          ),
        ),

        _SeccionCard(
          titulo: 'Direcciones',
          editando: _editando == _Seccion.direcciones,
          onEditar: () => _editar(_Seccion.direcciones),
          onCancelar: () => _editar(null),
          onGuardar: () => _guardar('Direcciones actualizadas'),
          lectura: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              InfoRow(
                'Modalidad',
                c.esHibrida ? 'Híbrida (dos direcciones)' : 'Fija',
              ),
              for (final (i, d) in c.direcciones.indexed)
                JkListItem(
                  leading: IconTile(
                    i == 0 ? Icons.home_outlined : Icons.work_outline,
                    size: 38,
                  ),
                  title: d.resumen,
                  subtitle:
                      '${_dias(d.dias)} · '
                      '${d.municipio}${d.notas.isEmpty ? '' : '\n${d.notas}'}',
                  last: i == c.direcciones.length - 1,
                ),
            ],
          ),
          edicion: _EditorDirecciones(
            cliente: c,
            onChanged: () => setState(() {}),
          ),
        ),

        _SeccionCard(
          titulo: 'Alergias',
          editando: _editando == _Seccion.alergias,
          onEditar: () => _editar(_Seccion.alergias),
          onCancelar: () => _editar(null),
          onGuardar: () =>
              _guardar('Alergias actualizadas. La cocina ya lo sabe.'),
          lectura: Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: c.alergias.isEmpty
                ? Text('Ninguna', style: JkText.body(15, c: JkColors.inkMuted))
                : Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      for (final a in c.alergias)
                        StatusBadge(a.label, tone: Tone.warn),
                    ],
                  ),
          ),
          edicion: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Marca lo que no puedes comer.',
                style: JkText.body(14, c: JkColors.inkSoft),
              ),
              const SizedBox(height: 10),
              ChipSelector<Alergeno>(
                options: Alergeno.values,
                selected: c.alergias,
                label: (a) => a.label,
                onToggle: (a) => setState(
                  () => c.alergias.contains(a)
                      ? c.alergias.remove(a)
                      : c.alergias.add(a),
                ),
              ),
              const SizedBox(height: 14),
            ],
          ),
        ),

        JkCard(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SectionTitle('Avisos'),
              JkSwitchRow(
                title: 'Avisos por WhatsApp',
                subtitle: '5 minutos antes de llegar, pagos y respuestas',
                value: c.avisosWhatsapp,
                onChanged: (v) {
                  c.avisosWhatsapp = v;
                  st.guardarPerfil();
                  showToast(
                    context,
                    v
                        ? 'Avisos por WhatsApp activados'
                        : 'Avisos por WhatsApp desactivados',
                  );
                },
              ),
              const SizedBox(height: 6),
            ],
          ),
        ),

        JkCard(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SectionTitle('Seguridad'),
              JkListItem(
                leading: const IconTile(Icons.lock_outline, size: 38),
                title: 'Cambiar contraseña',
                last: true,
                onTap: () => cambiarClaveSheet(context),
              ),
            ],
          ),
        ),
        const SizedBox(height: 4),
        const BotonCerrarSesion(
          mensaje: 'Tendrás que entrar de nuevo para ver tu plan.',
        ),
      ],
    );
  }
}

String _dias(Set<int> dias) {
  const n = ['', 'Lun', 'Mar', 'Mié', 'Jue', 'Vie'];
  final l = dias.toList()..sort();
  if (l.length == 5) return 'Lunes a viernes';
  return l.map((d) => n[d]).join(', ');
}

class _SeccionCard extends StatelessWidget {
  const _SeccionCard({
    required this.titulo,
    required this.editando,
    required this.onEditar,
    required this.onCancelar,
    required this.onGuardar,
    required this.lectura,
    required this.edicion,
  });
  final String titulo;
  final bool editando;
  final VoidCallback onEditar;
  final VoidCallback onCancelar;
  final VoidCallback onGuardar;
  final Widget lectura;
  final Widget edicion;

  @override
  Widget build(BuildContext context) => JkCard(
    padding: const EdgeInsets.fromLTRB(16, 4, 16, 14),
    borderColor: editando ? JkColors.ink : JkColors.line,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionTitle(
          titulo,
          trailing: editando
              ? null
              : TextButton.icon(
                  onPressed: onEditar,
                  style: TextButton.styleFrom(
                    foregroundColor: JkColors.ink,
                    minimumSize: const Size(0, JkSpace.touch),
                  ),
                  icon: const Icon(Icons.edit_outlined, size: 17),
                  label: const Text('Editar'),
                ),
        ),
        AnimatedSize(
          duration: const Duration(milliseconds: 160),
          alignment: Alignment.topCenter,
          child: editando
              ? Column(
                  children: [
                    edicion,
                    Row(
                      children: [
                        Expanded(
                          child: JkButton.ghost(
                            'Cancelar',
                            onPressed: onCancelar,
                          ),
                        ),
                        const SizedBox(width: 10),
                        // Solo se edita una sección a la vez: un único botón
                        // naranja.
                        Expanded(
                          child: JkButton(
                            'Guardar cambios',
                            onPressed: onGuardar,
                          ),
                        ),
                      ],
                    ),
                  ],
                )
              : lectura,
        ),
      ],
    ),
  );
}

class _EditorDirecciones extends StatelessWidget {
  const _EditorDirecciones({required this.cliente, required this.onChanged});
  final Cliente cliente;
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context) {
    final c = cliente;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Segmented<bool>(
          options: const [false, true],
          selected: c.esHibrida,
          label: (h) => h ? 'Híbrida' : 'Fija',
          icons: const [Icons.home_outlined, Icons.swap_horiz],
          onChanged: (h) {
            if (h && !c.esHibrida) {
              c.direcciones.first.dias = {1, 2, 3};
              c.direcciones.add(
                Direccion(
                  direccion: '',
                  barrio: '',
                  municipio: municipios.first,
                  dias: {4, 5},
                ),
              );
            } else if (!h && c.esHibrida) {
              c.direcciones.removeRange(1, c.direcciones.length);
              c.direcciones.first.dias = {1, 2, 3, 4, 5};
            }
            onChanged();
          },
        ),
        Padding(
          padding: const EdgeInsets.only(top: 8, bottom: 12),
          child: Text(
            c.esHibrida
                ? 'Recibe en dos direcciones según el día (por ejemplo, '
                      'casa y oficina).'
                : 'Recibe siempre en la misma dirección.',
            style: JkText.body(13.5, c: JkColors.inkMuted),
          ),
        ),
        for (final (i, d) in c.direcciones.indexed) ...[
          if (c.esHibrida)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Text(
                'Dirección ${i + 1}',
                style: JkText.body(15, w: FontWeight.w700),
              ),
            ),
          JkField(
            label: 'Dirección',
            initialValue: d.direccion,
            hint: 'Cra 76 #33A-21',
          ),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: JkField(label: 'Barrio', initialValue: d.barrio),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: JkDropdown<String>(
                  label: 'Municipio',
                  value: d.municipio,
                  items: municipios,
                  itemLabel: (s) => s,
                  onChanged: (v) => d.municipio = v ?? d.municipio,
                ),
              ),
            ],
          ),
          JkField(label: 'Indicaciones', initialValue: d.notas, maxLines: 2),
          if (c.esHibrida) ...[
            Text(
              'Días en esta dirección',
              style: JkText.body(14, w: FontWeight.w600, c: JkColors.inkSoft),
            ),
            const SizedBox(height: 6),
            ChipSelector<int>(
              options: const [1, 2, 3, 4, 5],
              selected: d.dias,
              label: (x) => const ['', 'Lun', 'Mar', 'Mié', 'Jue', 'Vie'][x],
              onToggle: (x) {
                // Cada día va a una sola dirección.
                for (final o in c.direcciones) {
                  o.dias.remove(x);
                }
                d.dias.add(x);
                onChanged();
              },
            ),
            const SizedBox(height: 18),
          ],
        ],
      ],
    );
  }
}

Future<void> cambiarClaveSheet(BuildContext context) {
  return showJkSheet<void>(
    context,
    builder: (ctx) => Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Cambiar contraseña', style: JkText.display(22)),
        const SizedBox(height: 14),
        const JkField(label: 'Contraseña actual', password: true),
        const JkField(
          label: 'Nueva contraseña',
          password: true,
          helper: 'Al menos 8 caracteres',
        ),
        JkButton(
          'Actualizar contraseña',
          onPressed: () {
            Navigator.pop(ctx);
            showToast(context, 'Contraseña actualizada');
          },
        ),
      ],
    ),
  );
}

class BotonCerrarSesion extends StatelessWidget {
  const BotonCerrarSesion({required this.mensaje, super.key});
  final String mensaje;

  @override
  Widget build(BuildContext context) => JkButton.danger(
    'Cerrar sesión',
    icon: Icons.logout,
    onPressed: () async {
      final ok = await confirmSheet(
        context,
        title: '¿Cerrar sesión?',
        message: mensaje,
        confirmLabel: 'Cerrar sesión',
        danger: true,
      );
      if (ok && context.mounted) AppScope.read(context).cerrarSesion();
    },
  );
}
