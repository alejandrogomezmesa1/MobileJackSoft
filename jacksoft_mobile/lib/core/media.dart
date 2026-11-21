import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';

import 'package:jacksoft_mobile/core/theme.dart';
import 'package:jacksoft_mobile/core/widgets.dart';

/// Foto o comprobante desde la cámara o la galería, con vista previa.
/// Controlado: el dueño guarda el [file] y lo recibe en [onChanged].
class PhotoField extends StatefulWidget {
  const PhotoField({
    required this.file,
    required this.onChanged,
    super.key,
    this.label = 'Toca para tomar o subir una foto',
    this.error,
  });
  final XFile? file;
  final ValueChanged<XFile?> onChanged;
  final String label;
  final String? error;

  @override
  State<PhotoField> createState() => _PhotoFieldState();
}

class _PhotoFieldState extends State<PhotoField> {
  Uint8List? _bytes;
  String? _path;

  @override
  void didUpdateWidget(covariant PhotoField old) {
    super.didUpdateWidget(old);
    if (widget.file == null) {
      _bytes = null;
      _path = null;
    } else if (widget.file!.path != _path) {
      unawaited(_cargar(widget.file!));
    }
  }

  Future<void> _cargar(XFile f) async {
    _path = f.path;
    final b = await f.readAsBytes();
    if (mounted && _path == f.path) setState(() => _bytes = b);
  }

  Future<void> _elegir() async {
    final origen = await showJkSheet<ImageSource?>(
      context,
      builder: (ctx) => Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Agregar foto', style: JkText.display(22)),
          const SizedBox(height: 8),
          JkListItem(
            leading: const IconTile(Icons.photo_camera_outlined, size: 38),
            title: 'Tomar foto',
            onTap: () => Navigator.pop(ctx, ImageSource.camera),
          ),
          JkListItem(
            leading: const IconTile(Icons.photo_library_outlined, size: 38),
            title: 'Elegir de la galería',
            last: widget.file == null,
            onTap: () => Navigator.pop(ctx, ImageSource.gallery),
          ),
          if (widget.file != null)
            JkListItem(
              leading: const IconTile(
                Icons.delete_outline,
                size: 38,
                tone: Tone.bad,
              ),
              title: 'Quitar la foto',
              last: true,
              onTap: () {
                Navigator.pop(ctx);
                widget.onChanged(null);
              },
            ),
        ],
      ),
    );
    if (origen == null || !mounted) return;
    try {
      final f = await ImagePicker().pickImage(
        source: origen,
        maxWidth: 1600,
        imageQuality: 75,
      );
      if (f != null) {
        await _cargar(f);
        widget.onChanged(f);
      }
    } on PlatformException {
      if (mounted) {
        showToast(
          context,
          'No pudimos abrir la '
          '${origen == ImageSource.camera ? 'cámara' : 'galería'}. Revisa '
          'los permisos de la app.',
          icon: Icons.error_outline,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final hay = widget.file != null;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Semantics(
            button: true,
            label: hay ? 'Cambiar o quitar la foto' : widget.label,
            child: InkWell(
              onTap: _elegir,
              borderRadius: JkRadius.br,
              child: Container(
                constraints: const BoxConstraints(minHeight: 64),
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: hay ? JkColors.greenWash : JkColors.paper,
                  borderRadius: JkRadius.br,
                  border: Border.all(
                    color: widget.error != null
                        ? JkColors.red
                        : hay
                        ? JkColors.green
                        : JkColors.dash,
                    width: 1.5,
                  ),
                ),
                child: Row(
                  children: [
                    if (hay && _bytes != null)
                      ClipRRect(
                        borderRadius: JkRadius.br,
                        child: Image.memory(
                          _bytes!,
                          width: 56,
                          height: 56,
                          fit: BoxFit.cover,
                        ),
                      )
                    else
                      Icon(
                        hay
                            ? Icons.check_circle_outline
                            : Icons.photo_camera_outlined,
                        size: 24,
                        color: hay ? JkColors.greenInk : JkColors.inkSoft,
                      ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        hay
                            ? '${widget.file!.name}\nToca para cambiarla o '
                                  'quitarla'
                            : widget.label,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: JkText.body(
                          14,
                          w: FontWeight.w600,
                          c: hay ? JkColors.greenInk : JkColors.inkSoft,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          if (widget.error != null)
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Text(
                widget.error!,
                style: JkText.body(12.5, c: JkColors.red),
              ),
            ),
        ],
      ),
    );
  }
}
