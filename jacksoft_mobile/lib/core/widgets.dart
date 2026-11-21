import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'theme.dart';

export 'launch.dart';
export 'map.dart';
export 'media.dart';

// ============================================================ superficies

/// Tarjeta blanca con línea fina (sin sombra: Float Only Rule).
class JkCard extends StatelessWidget {
  const JkCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.color = JkColors.white,
    this.borderColor = JkColors.line,
    this.onTap,
    this.margin = const EdgeInsets.only(bottom: 12),
    this.dashed = false,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final Color color;
  final Color borderColor;
  final VoidCallback? onTap;
  final EdgeInsetsGeometry margin;
  final bool dashed;

  @override
  Widget build(BuildContext context) {
    Widget body = Padding(padding: padding, child: child);
    if (onTap != null) {
      body = InkWell(onTap: onTap, borderRadius: JkRadius.br, child: body);
    }
    return Padding(
      padding: margin,
      child: Material(
        color: color,
        shape: RoundedRectangleBorder(
          borderRadius: JkRadius.br,
          side: BorderSide(
            color: dashed ? JkColors.dash : borderColor,
            width: dashed ? 1.5 : 1,
          ),
        ),
        clipBehavior: Clip.antiAlias,
        child: body,
      ),
    );
  }
}

/// Título de sección en frase normal (sin etiqueta pequeña en mayúsculas).
class SectionTitle extends StatelessWidget {
  const SectionTitle(this.text, {super.key, this.trailing});
  final String text;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(top: 10, bottom: 8),
    child: Row(
      children: [
        Expanded(child: Text(text, style: JkText.display(18))),
        ?trailing,
      ],
    ),
  );
}

class InfoRow extends StatelessWidget {
  const InfoRow(
    this.label,
    this.value, {
    super.key,
    this.last = false,
    this.mono = false,
  });
  final String label;
  final String value;
  final bool last;
  final bool mono;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(vertical: 10),
    decoration: BoxDecoration(
      border: last
          ? null
          : const Border(bottom: BorderSide(color: JkColors.hairline)),
    ),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          flex: 4,
          child: Text(label, style: JkText.body(14, c: JkColors.inkMuted)),
        ),
        const SizedBox(width: 12),
        Expanded(
          flex: 7,
          child: Text(
            value,
            textAlign: TextAlign.right,
            style: mono
                ? JkText.mono(14, c: JkColors.ink)
                : JkText.body(14, w: FontWeight.w600),
          ),
        ),
      ],
    ),
  );
}

// ============================================================ estados

enum Tone { ok, warn, bad, neutral, info }

/// Estado con su tono y siempre con texto.
class StatusBadge extends StatelessWidget {
  const StatusBadge(this.text, {super.key, required this.tone});
  final String text;
  final Tone tone;

  static Tone toneFor(String s) => switch (s) {
    'Activa' ||
    'Entregado' ||
    'Entregada' ||
    'Aprobado' ||
    'Resuelta' ||
    'Al día' ||
    'Llega' ||
    'Bueno' => Tone.ok,
    'Verificando pago' ||
    'En verificación' ||
    'Pendiente de pago' ||
    'En revisión' ||
    'Pausada' ||
    'Pausado' ||
    'Por recoger' ||
    'En espera' => Tone.warn,
    'Rechazada' ||
    'Rechazado' ||
    'Cancelada' ||
    'Con novedad' ||
    'Cliente ausente' ||
    'Dirección incorrecta' ||
    'Entrega fallida' ||
    'Dañado' ||
    'Perdido' => Tone.bad,
    'En ruta' || 'Abierta' || 'Hoy' => Tone.info,
    _ => Tone.neutral,
  };

  factory StatusBadge.auto(String text, {Key? key}) =>
      StatusBadge(text, key: key, tone: toneFor(text));

  @override
  Widget build(BuildContext context) {
    final (bg, fg) = switch (tone) {
      Tone.ok => (JkColors.greenWash, JkColors.greenInk),
      Tone.warn => (JkColors.amberWash, JkColors.amberInk),
      Tone.bad => (JkColors.redWash, JkColors.red),
      Tone.info => (JkColors.cream, JkColors.ink),
      Tone.neutral => (JkColors.beige, JkColors.inkSoft),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: JkRadius.br,
        border: tone == Tone.info
            ? Border.all(color: JkColors.hairlineStrong)
            : null,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(color: fg, shape: BoxShape.circle),
          ),
          const SizedBox(width: 6),
          Text(
            text,
            style: JkText.body(12.5, w: FontWeight.w600, c: fg),
          ),
        ],
      ),
    );
  }
}

/// Recuadro de ícono (tono neutro; el color lo pone el estado, no el ícono).
class IconTile extends StatelessWidget {
  const IconTile(
    this.icon, {
    super.key,
    this.size = 40,
    this.tone = Tone.neutral,
  });
  final IconData icon;
  final double size;
  final Tone tone;

  @override
  Widget build(BuildContext context) {
    final (bg, fg) = switch (tone) {
      Tone.ok => (JkColors.greenWash, JkColors.greenInk),
      Tone.warn => (JkColors.amberWash, JkColors.amberInk),
      Tone.bad => (JkColors.redWash, JkColors.red),
      _ => (JkColors.beige, JkColors.ink),
    };
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: bg,
        borderRadius: JkRadius.br,
        border: Border.all(color: JkColors.hairline),
      ),
      child: Icon(icon, size: size * .48, color: fg),
    );
  }
}

class Avatar extends StatelessWidget {
  const Avatar(this.initials, {super.key, this.size = 48});
  final String initials;
  final double size;

  @override
  Widget build(BuildContext context) => Container(
    width: size,
    height: size,
    alignment: Alignment.center,
    decoration: const BoxDecoration(
      color: JkColors.cream,
      borderRadius: JkRadius.br,
      border: Border.fromBorderSide(BorderSide(color: JkColors.orangeLine)),
    ),
    child: Text(
      initials,
      style: JkText.display(size * .4, c: JkColors.orangeDeep),
    ),
  );
}

class JkListItem extends StatelessWidget {
  const JkListItem({
    super.key,
    this.leading,
    required this.title,
    this.subtitle,
    this.trailing,
    this.onTap,
    this.last = false,
    this.monoSubtitle = false,
  });
  final Widget? leading;
  final String title;
  final String? subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;
  final bool last;
  final bool monoSubtitle;

  @override
  Widget build(BuildContext context) => InkWell(
    onTap: onTap,
    child: Container(
      constraints: const BoxConstraints(minHeight: JkSpace.touch + 12),
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: BoxDecoration(
        border: last
            ? null
            : const Border(bottom: BorderSide(color: JkColors.hairline)),
      ),
      child: Row(
        children: [
          if (leading != null) ...[leading!, const SizedBox(width: 12)],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: JkText.body(15, w: FontWeight.w600)),
                if (subtitle != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Text(
                      subtitle!,
                      style: monoSubtitle
                          ? JkText.mono(12.5)
                          : JkText.body(13, c: JkColors.inkMuted),
                    ),
                  ),
              ],
            ),
          ),
          if (trailing != null) ...[const SizedBox(width: 8), trailing!],
          if (onTap != null && trailing == null)
            const Icon(Icons.chevron_right, color: JkColors.inkMuted),
        ],
      ),
    ),
  );
}

class StatTile extends StatelessWidget {
  const StatTile({
    super.key,
    required this.label,
    required this.value,
    this.icon,
    this.valueWidget,
  });
  final String label;
  final String value;
  final IconData? icon;
  final Widget? valueWidget;

  @override
  Widget build(BuildContext context) => JkCard(
    margin: EdgeInsets.zero,
    padding: const EdgeInsets.all(14),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            if (icon != null) ...[
              Icon(icon, size: 18, color: JkColors.inkSoft),
              const SizedBox(width: 6),
            ],
            Expanded(
              child: Text(
                label,
                style: JkText.body(13, c: JkColors.inkMuted),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        valueWidget ?? Text(value, style: JkText.display(22)),
      ],
    ),
  );
}

/// Rejilla de 2 columnas para [StatTile].
class StatGrid extends StatelessWidget {
  const StatGrid(this.children, {super.key});
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final rows = <Widget>[];
    for (var i = 0; i < children.length; i += 2) {
      rows.add(
        Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(child: children[i]),
                const SizedBox(width: 10),
                Expanded(
                  child: i + 1 < children.length
                      ? children[i + 1]
                      : const SizedBox(),
                ),
              ],
            ),
          ),
        ),
      );
    }
    return Padding(
      padding: const EdgeInsets.only(bottom: 2),
      child: Column(children: rows),
    );
  }
}

class Notice extends StatelessWidget {
  const Notice(
    this.text, {
    super.key,
    this.icon = Icons.info_outline,
    this.tone = Tone.neutral,
  });
  final String text;
  final IconData icon;
  final Tone tone;

  @override
  Widget build(BuildContext context) {
    final (bg, fg) = switch (tone) {
      Tone.warn => (JkColors.amberWash, JkColors.amberInk),
      Tone.bad => (JkColors.redWash, JkColors.red),
      Tone.ok => (JkColors.greenWash, JkColors.greenInk),
      _ => (JkColors.beige, JkColors.inkSoft),
    };
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: JkRadius.br,
        border: Border.all(color: fg.withValues(alpha: .18)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: fg),
          const SizedBox(width: 10),
          Expanded(
            child: Text(text, style: JkText.body(13.5, c: fg)),
          ),
        ],
      ),
    );
  }
}

// ============================================================ botones

enum BtnKind { primary, ghost, danger, dark }

/// Primario: naranja con texto carbón, Baloo 2 700, uno por pantalla.
class JkButton extends StatelessWidget {
  const JkButton(
    this.label, {
    super.key,
    this.onPressed,
    this.icon,
    this.kind = BtnKind.primary,
    this.small = false,
    this.expand = true,
  });

  const JkButton.ghost(
    this.label, {
    super.key,
    this.onPressed,
    this.icon,
    this.small = false,
    this.expand = true,
  }) : kind = BtnKind.ghost;
  const JkButton.danger(
    this.label, {
    super.key,
    this.onPressed,
    this.icon,
    this.small = false,
    this.expand = true,
  }) : kind = BtnKind.danger;
  const JkButton.dark(
    this.label, {
    super.key,
    this.onPressed,
    this.icon,
    this.small = false,
    this.expand = true,
  }) : kind = BtnKind.dark;

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final BtnKind kind;
  final bool small;
  final bool expand;

  @override
  Widget build(BuildContext context) {
    final (bg, fg, side) = switch (kind) {
      BtnKind.primary => (JkColors.orange, JkColors.ink, BorderSide.none),
      BtnKind.ghost => (
        JkColors.white,
        JkColors.ink,
        const BorderSide(color: JkColors.hairlineStrong),
      ),
      BtnKind.danger => (
        JkColors.white,
        JkColors.red,
        const BorderSide(color: Color(0x55B42318)),
      ),
      BtnKind.dark => (JkColors.ink, JkColors.white, BorderSide.none),
    };
    final h = small ? 40.0 : JkSpace.field;
    final style = ButtonStyle(
      minimumSize: WidgetStatePropertyAll(
        Size(expand ? double.infinity : 0, h),
      ),
      padding: WidgetStatePropertyAll(
        EdgeInsets.symmetric(horizontal: small ? 14 : 20),
      ),
      backgroundColor: WidgetStateProperty.resolveWith((s) {
        if (s.contains(WidgetState.disabled)) return JkColors.hairline;
        if (kind == BtnKind.primary &&
            (s.contains(WidgetState.pressed) ||
                s.contains(WidgetState.hovered))) {
          return JkColors.orangeHover;
        }
        return bg;
      }),
      foregroundColor: WidgetStateProperty.resolveWith(
        (s) => s.contains(WidgetState.disabled) ? JkColors.inkMuted : fg,
      ),
      overlayColor: WidgetStatePropertyAll(fg.withValues(alpha: .06)),
      shape: WidgetStatePropertyAll(
        RoundedRectangleBorder(borderRadius: JkRadius.br, side: side),
      ),
      elevation: const WidgetStatePropertyAll(0),
      textStyle: WidgetStatePropertyAll(
        kind == BtnKind.primary
            ? JkText.display(small ? 15 : 17)
            : JkText.body(small ? 14 : 15, w: FontWeight.w600),
      ),
    );
    final child = Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (icon != null) ...[
          Icon(icon, size: small ? 17 : 19),
          const SizedBox(width: 8),
        ],
        Flexible(child: Text(label, overflow: TextOverflow.ellipsis)),
      ],
    );
    return TextButton(onPressed: onPressed, style: style, child: child);
  }
}

/// Botón cuadrado de ícono para la barra superior.
class SquareIconButton extends StatelessWidget {
  const SquareIconButton({
    super.key,
    required this.icon,
    required this.onTap,
    this.dot = false,
    this.tooltip,
  });
  final IconData icon;
  final VoidCallback onTap;
  final bool dot;
  final String? tooltip;

  @override
  Widget build(BuildContext context) => Tooltip(
    message: tooltip ?? '',
    child: InkWell(
      onTap: onTap,
      borderRadius: JkRadius.br,
      child: Container(
        width: JkSpace.touch,
        height: JkSpace.touch,
        decoration: BoxDecoration(
          borderRadius: JkRadius.br,
          border: Border.all(color: JkColors.line),
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            Icon(icon, size: 21, color: JkColors.ink),
            if (dot)
              Positioned(
                top: 10,
                right: 11,
                child: Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    color: JkColors.red,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
          ],
        ),
      ),
    ),
  );
}

// ============================================================ formularios

class JkField extends StatefulWidget {
  const JkField({
    super.key,
    required this.label,
    this.controller,
    this.hint,
    this.keyboard,
    this.password = false,
    this.maxLines = 1,
    this.helper,
    this.validator,
    this.initialValue,
    this.inputFormatters,
    this.textAlign = TextAlign.start,
    this.style,
    this.autofillHints,
  });

  final String label;
  final TextEditingController? controller;
  final String? hint;
  final TextInputType? keyboard;
  final bool password;
  final int maxLines;
  final String? helper;
  final String? Function(String?)? validator;
  final String? initialValue;
  final List<TextInputFormatter>? inputFormatters;
  final TextAlign textAlign;
  final TextStyle? style;
  final Iterable<String>? autofillHints;

  @override
  State<JkField> createState() => _JkFieldState();
}

class _JkFieldState extends State<JkField> {
  bool _oculto = true;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 14),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          widget.label,
          style: JkText.body(14, w: FontWeight.w600, c: JkColors.inkSoft),
        ),
        const SizedBox(height: 6),
        TextFormField(
          controller: widget.controller,
          initialValue: widget.controller == null ? widget.initialValue : null,
          keyboardType: widget.keyboard,
          obscureText: widget.password && _oculto,
          maxLines: widget.password ? 1 : widget.maxLines,
          validator: widget.validator,
          inputFormatters: widget.inputFormatters,
          textAlign: widget.textAlign,
          autofillHints: widget.autofillHints,
          // 16 px para que iOS no acerque la página.
          style: widget.style ?? JkText.body(16),
          decoration: InputDecoration(
            hintText: widget.hint,
            helperText: widget.helper,
            helperMaxLines: 3,
            helperStyle: JkText.body(12.5, c: JkColors.inkMuted),
            suffixIcon: widget.password
                ? IconButton(
                    tooltip: _oculto
                        ? 'Mostrar contraseña'
                        : 'Ocultar contraseña',
                    icon: Icon(
                      _oculto
                          ? Icons.visibility_outlined
                          : Icons.visibility_off_outlined,
                      color: JkColors.inkMuted,
                    ),
                    onPressed: () => setState(() => _oculto = !_oculto),
                  )
                : null,
          ),
        ),
      ],
    ),
  );
}

class JkDropdown<T> extends StatelessWidget {
  const JkDropdown({
    super.key,
    required this.label,
    required this.value,
    required this.items,
    required this.itemLabel,
    required this.onChanged,
    this.hint,
  });
  final String label;
  final T? value;
  final List<T> items;
  final String Function(T) itemLabel;
  final ValueChanged<T?> onChanged;
  final String? hint;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 14),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: JkText.body(14, w: FontWeight.w600, c: JkColors.inkSoft),
        ),
        const SizedBox(height: 6),
        DropdownButtonFormField<T>(
          initialValue: value,
          isExpanded: true,
          hint: hint == null
              ? null
              : Text(hint!, style: JkText.body(16, c: JkColors.inkMuted)),
          icon: const Icon(Icons.expand_more, color: JkColors.inkMuted),
          style: JkText.body(16),
          borderRadius: JkRadius.br,
          dropdownColor: JkColors.white,
          items: [
            for (final it in items)
              DropdownMenuItem(value: it, child: Text(itemLabel(it))),
          ],
          onChanged: onChanged,
        ),
      ],
    ),
  );
}

/// Interruptor cuadrado del panel, en una fila de 44 px o más.
class JkSwitchRow extends StatelessWidget {
  const JkSwitchRow({
    super.key,
    required this.title,
    this.subtitle,
    required this.value,
    required this.onChanged,
  });
  final String title;
  final String? subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) => Semantics(
    toggled: value,
    label: title,
    child: InkWell(
      onTap: () => onChanged(!value),
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: JkSpace.touch + 8),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(title, style: JkText.body(15, w: FontWeight.w600)),
                  if (subtitle != null)
                    Text(
                      subtitle!,
                      style: JkText.body(13, c: JkColors.inkMuted),
                    ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              width: 48,
              height: 28,
              padding: const EdgeInsets.all(3),
              alignment: value ? Alignment.centerRight : Alignment.centerLeft,
              decoration: BoxDecoration(
                color: value ? JkColors.ink : JkColors.hairline,
                borderRadius: JkRadius.br,
                border: Border.all(
                  color: value ? JkColors.ink : JkColors.hairlineStrong,
                ),
              ),
              child: Container(
                width: 22,
                height: 22,
                decoration: const BoxDecoration(
                  color: JkColors.white,
                  borderRadius: JkRadius.br,
                ),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

/// Selector de opciones en bloque (equivale al `.radio2` del prototipo).
class Segmented<T> extends StatelessWidget {
  const Segmented({
    super.key,
    required this.options,
    required this.selected,
    required this.label,
    required this.onChanged,
    this.icons,
  });
  final List<T> options;
  final T selected;
  final String Function(T) label;
  final ValueChanged<T> onChanged;
  final List<IconData>? icons;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      for (var i = 0; i < options.length; i++) ...[
        if (i > 0) const SizedBox(width: 8),
        Expanded(
          child: Semantics(
            selected: options[i] == selected,
            button: true,
            child: InkWell(
              onTap: () => onChanged(options[i]),
              borderRadius: JkRadius.br,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 160),
                height: JkSpace.touch + 4,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: options[i] == selected
                      ? JkColors.cream
                      : JkColors.white,
                  borderRadius: JkRadius.br,
                  border: Border.all(
                    color: options[i] == selected
                        ? JkColors.ink
                        : JkColors.hairlineStrong,
                    width: options[i] == selected ? 1.5 : 1,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (icons != null) ...[
                      Icon(icons![i], size: 17, color: JkColors.ink),
                      const SizedBox(width: 6),
                    ],
                    Flexible(
                      child: Text(
                        label(options[i]),
                        overflow: TextOverflow.ellipsis,
                        style: JkText.body(
                          14.5,
                          w: options[i] == selected
                              ? FontWeight.w700
                              : FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    ],
  );
}

/// Opción grande seleccionable (planes, proteína).
class OptionCard extends StatelessWidget {
  const OptionCard({
    super.key,
    required this.title,
    this.subtitle,
    this.trailing,
    required this.selected,
    required this.onTap,
  });
  final String title;
  final String? subtitle;
  final String? trailing;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Semantics(
      selected: selected,
      button: true,
      child: InkWell(
        onTap: onTap,
        borderRadius: JkRadius.br,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: selected ? JkColors.cream : JkColors.white,
            borderRadius: JkRadius.br,
            border: Border.all(
              color: selected ? JkColors.ink : JkColors.line,
              width: selected ? 1.5 : 1,
            ),
          ),
          child: Row(
            children: [
              Icon(
                selected ? Icons.radio_button_checked : Icons.radio_button_off,
                size: 20,
                color: selected ? JkColors.ink : JkColors.inkMuted,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: JkText.body(15, w: FontWeight.w700)),
                    if (subtitle != null)
                      Text(
                        subtitle!,
                        style: JkText.body(13, c: JkColors.inkMuted),
                      ),
                  ],
                ),
              ),
              if (trailing != null)
                Text(trailing!, style: JkText.mono(14, c: JkColors.ink)),
            ],
          ),
        ),
      ),
    ),
  );
}

/// Chips de selección múltiple (las 7 alergias de la lista cerrada).
class ChipSelector<T> extends StatelessWidget {
  const ChipSelector({
    super.key,
    required this.options,
    required this.selected,
    required this.label,
    required this.onToggle,
  });
  final List<T> options;
  final Set<T> selected;
  final String Function(T) label;
  final ValueChanged<T> onToggle;

  @override
  Widget build(BuildContext context) => Wrap(
    spacing: 8,
    runSpacing: 8,
    children: [
      for (final o in options)
        Semantics(
          selected: selected.contains(o),
          button: true,
          child: InkWell(
            onTap: () => onToggle(o),
            borderRadius: JkRadius.br,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 140),
              constraints: const BoxConstraints(minHeight: JkSpace.touch),
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                color: selected.contains(o) ? JkColors.ink : JkColors.white,
                borderRadius: JkRadius.br,
                border: Border.all(
                  color: selected.contains(o)
                      ? JkColors.ink
                      : JkColors.hairlineStrong,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (selected.contains(o)) ...[
                    const Icon(Icons.check, size: 16, color: JkColors.white),
                    const SizedBox(width: 6),
                  ],
                  Text(
                    label(o),
                    style: JkText.body(
                      14,
                      w: FontWeight.w600,
                      c: selected.contains(o) ? JkColors.white : JkColors.ink,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
    ],
  );
}

/// Zona para adjuntar una foto o el comprobante.
// ============================================================ línea de tiempo

class TimelineStep {
  const TimelineStep(
    this.title,
    this.subtitle, {
    this.done = false,
    this.current = false,
  });
  final String title;
  final String subtitle;
  final bool done;
  final bool current;
}

class VTimeline extends StatelessWidget {
  const VTimeline(this.steps, {super.key});
  final List<TimelineStep> steps;

  @override
  Widget build(BuildContext context) => Column(
    children: [
      for (var i = 0; i < steps.length; i++)
        IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SizedBox(
                width: 28,
                child: Column(
                  children: [
                    Container(
                      width: 24,
                      height: 24,
                      decoration: BoxDecoration(
                        color: steps[i].done
                            ? JkColors.ink
                            : steps[i].current
                            ? JkColors.cream
                            : JkColors.white,
                        borderRadius: JkRadius.br,
                        border: Border.all(
                          color: steps[i].done || steps[i].current
                              ? JkColors.ink
                              : JkColors.hairlineStrong,
                          width: steps[i].current ? 2 : 1,
                        ),
                      ),
                      child: steps[i].done
                          ? const Icon(
                              Icons.check,
                              size: 15,
                              color: JkColors.white,
                            )
                          : steps[i].current
                          ? const Icon(
                              Icons.delivery_dining_outlined,
                              size: 15,
                              color: JkColors.ink,
                            )
                          : null,
                    ),
                    if (i < steps.length - 1)
                      Expanded(
                        child: Container(
                          width: 2,
                          color: steps[i].done
                              ? JkColors.ink
                              : JkColors.hairline,
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Padding(
                  padding: EdgeInsets.only(
                    bottom: i < steps.length - 1 ? 18 : 0,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        steps[i].title,
                        style: JkText.body(
                          15,
                          w: steps[i].current
                              ? FontWeight.w700
                              : FontWeight.w600,
                          c: steps[i].done || steps[i].current
                              ? JkColors.ink
                              : JkColors.inkMuted,
                        ),
                      ),
                      Text(
                        steps[i].subtitle,
                        style: JkText.body(13, c: JkColors.inkMuted),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
    ],
  );
}

// ============================================================ avisos

void showToast(
  BuildContext context,
  String msg, {
  IconData icon = Icons.check,
}) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(
        duration: const Duration(milliseconds: 2600),
        content: Row(
          children: [
            Icon(icon, size: 18, color: JkColors.white),
            const SizedBox(width: 10),
            Expanded(child: Text(msg)),
          ],
        ),
      ),
    );
}

Future<T?> showJkSheet<T>(
  BuildContext context, {
  required WidgetBuilder builder,
}) => showModalBottomSheet<T>(
  context: context,
  isScrollControlled: true,
  useSafeArea: true,
  builder: (ctx) => Padding(
    padding: EdgeInsets.fromLTRB(
      20,
      0,
      20,
      20 + MediaQuery.viewInsetsOf(ctx).bottom,
    ),
    child: builder(ctx),
  ),
);

/// Confirmación en hoja inferior con dos botones.
Future<bool> confirmSheet(
  BuildContext context, {
  required String title,
  required String message,
  required String confirmLabel,
  bool danger = false,
}) async {
  final r = await showJkSheet<bool>(
    context,
    builder: (ctx) => Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: JkText.display(22)),
        const SizedBox(height: 6),
        Text(message, style: JkText.body(15, c: JkColors.inkSoft)),
        const SizedBox(height: 20),
        Row(
          children: [
            Expanded(
              child: JkButton.ghost(
                'Cancelar',
                onPressed: () => Navigator.pop(ctx, false),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: danger
                  ? JkButton.danger(
                      confirmLabel,
                      onPressed: () => Navigator.pop(ctx, true),
                    )
                  : JkButton(
                      confirmLabel,
                      onPressed: () => Navigator.pop(ctx, true),
                    ),
            ),
          ],
        ),
      ],
    ),
  );
  return r ?? false;
}
