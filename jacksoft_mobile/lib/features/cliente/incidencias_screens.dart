import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../core/format.dart';
import '../../core/shell.dart';
import '../../core/theme.dart';
import '../../core/widgets.dart';
import '../../data/app_state.dart';
import '../../data/models.dart';

/// HU07.3_07 (reportar con foto) y HU07.3_08 (ver la respuesta del administrador).
class IncidenciasTab extends StatefulWidget {
  const IncidenciasTab({super.key});

  @override
  State<IncidenciasTab> createState() => _IncidenciasTabState();
}

class _IncidenciasTabState extends State<IncidenciasTab> {
  TipoIncidencia? _tipo;
  final _desc = TextEditingController();
  XFile? _foto;
  final _form = GlobalKey<FormState>();
  bool _intento = false;

  @override
  void dispose() {
    _desc.dispose();
    super.dispose();
  }

  void _enviar() {
    setState(() => _intento = true);
    if (!_form.currentState!.validate() || _tipo == null) return;
    AppScope.read(
      context,
    ).reportarIncidencia(_tipo!, _desc.text.trim(), _foto != null);
    setState(() {
      _tipo = null;
      _desc.clear();
      _foto = null;
      _intento = false;
    });
    FocusScope.of(context).unfocus();
    showToast(context, 'Reporte enviado. Te avisamos cuando lo respondamos.');
  }

  @override
  Widget build(BuildContext context) {
    final st = AppScope.of(context);
    return TabBody(
      children: [
        JkCard(
          child: Form(
            key: _form,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Cuéntanos qué pasó', style: JkText.display(22)),
                const SizedBox(height: 12),
                JkDropdown<TipoIncidencia>(
                  label: 'Tipo',
                  value: _tipo,
                  hint: 'Elige una opción',
                  items: TipoIncidencia.delCliente,
                  itemLabel: (t) => t.label,
                  onChanged: (v) => setState(() => _tipo = v),
                ),
                if (_intento && _tipo == null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: Text(
                      'Elige el tipo de incidencia',
                      style: JkText.body(12.5, c: JkColors.red),
                    ),
                  ),
                JkField(
                  label: 'Descripción',
                  controller: _desc,
                  maxLines: 4,
                  hint: 'Qué pasó y con qué almuerzo',
                  validator: (v) => (v ?? '').trim().length < 10
                      ? 'Cuéntanos un poco más (mínimo 10 caracteres)'
                      : null,
                ),
                Text(
                  'Foto (opcional)',
                  style: JkText.body(
                    14,
                    w: FontWeight.w600,
                    c: JkColors.inkSoft,
                  ),
                ),
                const SizedBox(height: 6),
                PhotoField(
                  file: _foto,
                  onChanged: (f) => setState(() => _foto = f),
                ),
                JkButton('Enviar reporte', onPressed: _enviar),
              ],
            ),
          ),
        ),
        const SectionTitle('Tus reportes'),
        if (st.incidencias.isEmpty)
          Text(
            'Aún no has reportado nada.',
            style: JkText.body(15, c: JkColors.inkMuted),
          )
        else
          JkCard(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            child: Column(
              children: [
                for (final (i, inc) in st.incidencias.indexed)
                  JkListItem(
                    leading: const IconTile(
                      Icons.report_gmailerrorred_outlined,
                      size: 38,
                    ),
                    title: inc.tipo.label,
                    subtitle: '#${inc.id} · ${fechaCorta(inc.fecha)}',
                    monoSubtitle: true,
                    trailing: StatusBadge.auto(inc.estado.label),
                    last: i == st.incidencias.length - 1,
                    onTap: () => pushPage(context, IncidenciaDetalle(inc)),
                  ),
              ],
            ),
          ),
      ],
    );
  }
}

class IncidenciaDetalle extends StatelessWidget {
  const IncidenciaDetalle(this.inc, {super.key});
  final Incidencia inc;

  @override
  Widget build(BuildContext context) => JkPage(
    title: 'Incidencia #${inc.id}',
    subtitle: inc.tipo.label,
    children: [
      JkCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(inc.tipo.label, style: JkText.display(22)),
                ),
                StatusBadge.auto(inc.estado.label),
              ],
            ),
            const SizedBox(height: 8),
            Text(inc.descripcion, style: JkText.body(15)),
            const SizedBox(height: 10),
            InfoRow(
              'Reportada',
              '${fechaMedia(inc.fecha)}, ${hora(inc.fecha)}',
            ),
            if (inc.cliente != null) InfoRow('Cliente', inc.cliente!),
            InfoRow('Foto', inc.conFoto ? 'Adjunta' : 'Sin foto', last: true),
          ],
        ),
      ),
      const SectionTitle('Respuesta del administrador'),
      if (inc.respuesta == null)
        Notice(
          inc.estado == EstadoIncidencia.enRevision
              ? 'Estamos revisando tu caso. Te avisamos con una notificación cuando respondamos.'
              : 'Recibimos tu reporte. Pronto lo revisamos.',
          icon: Icons.hourglass_top,
          tone: Tone.warn,
        )
      else
        JkCard(
          color: JkColors.beige,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(inc.respuesta!, style: JkText.body(15)),
              if (inc.fechaResolucion != null) ...[
                const SizedBox(height: 8),
                Text(
                  'Resuelta el ${fechaMedia(inc.fechaResolucion!)}, ${hora(inc.fechaResolucion!)}',
                  style: JkText.body(13, c: JkColors.inkMuted),
                ),
              ],
            ],
          ),
        ),
    ],
  );
}
