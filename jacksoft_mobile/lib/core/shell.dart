import 'package:flutter/material.dart';

import '../data/app_state.dart';
import 'theme.dart';
import 'widgets.dart';

// ============================================================ marca

/// Marca: la olla del prototipo HTML dibujada en un recuadro plano (sin gradiente).
class BrandMark extends StatelessWidget {
  const BrandMark({super.key, this.size = 56, this.onDark = false});
  final double size;
  final bool onDark;

  @override
  Widget build(BuildContext context) => Container(
    width: size,
    height: size,
    decoration: BoxDecoration(
      color: onDark ? JkColors.orange : JkColors.ink,
      borderRadius: JkRadius.br,
    ),
    padding: EdgeInsets.all(size * .22),
    child: CustomPaint(
      painter: _PotPainter(onDark ? JkColors.ink : JkColors.cream),
    ),
  );
}

class _PotPainter extends CustomPainter {
  _PotPainter(this.color);
  final Color color;

  @override
  void paint(Canvas canvas, Size s) {
    final k = s.width / 24;
    final p = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.2 * k
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    Offset o(double x, double y) => Offset(x * k, y * k);
    canvas.drawLine(o(12, 3), o(12, 5), p);
    canvas.drawLine(o(8, 4.5), o(8, 6), p);
    canvas.drawLine(o(16, 4.5), o(16, 6), p);
    canvas.drawLine(o(4, 10), o(20, 10), p);
    final bowl = Path()
      ..moveTo(5 * k, 10 * k)
      ..cubicTo(5 * k, 14.5 * k, 8.1 * k, 18 * k, 12 * k, 18 * k)
      ..cubicTo(15.9 * k, 18 * k, 19 * k, 14.5 * k, 19 * k, 10 * k);
    canvas.drawPath(bowl, p);
    canvas.drawLine(o(7, 20), o(17, 20), p);
  }

  @override
  bool shouldRepaint(covariant _PotPainter old) => old.color != color;
}

// ============================================================ barra superior

class JkTopBar extends StatelessWidget implements PreferredSizeWidget {
  const JkTopBar({
    super.key,
    required this.title,
    this.subtitle,
    this.showBell = false,
  });
  final String title;
  final String? subtitle;
  final bool showBell;

  @override
  Size get preferredSize => const Size.fromHeight(68);

  @override
  Widget build(BuildContext context) {
    final canPop = Navigator.of(context).canPop();
    return Material(
      color: JkColors.white,
      child: SafeArea(
        bottom: false,
        child: Container(
          height: 68,
          padding: const EdgeInsets.symmetric(horizontal: JkSpace.gutter),
          decoration: const BoxDecoration(
            border: Border(bottom: BorderSide(color: JkColors.line)),
          ),
          child: Row(
            children: [
              if (canPop) ...[
                SquareIconButton(
                  icon: Icons.arrow_back,
                  tooltip: 'Volver',
                  onTap: () => Navigator.of(context).maybePop(),
                ),
                const SizedBox(width: 12),
              ],
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: JkText.display(22),
                    ),
                    if (subtitle != null)
                      Text(
                        subtitle!,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: JkText.body(13, c: JkColors.inkMuted),
                      ),
                  ],
                ),
              ),
              if (showBell)
                SquareIconButton(
                  icon: Icons.notifications_none,
                  tooltip: 'Notificaciones',
                  dot: true,
                  onTap: () => showNotificaciones(context),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

void showNotificaciones(BuildContext context) {
  final st = AppScope.read(context);
  IconData icono(String k) => switch (k) {
    'truck' => Icons.delivery_dining_outlined,
    'check' => Icons.check_circle_outline,
    'reply' => Icons.mark_chat_read_outlined,
    'pay' => Icons.receipt_long_outlined,
    'route' => Icons.alt_route,
    'pause' => Icons.pause_circle_outline,
    _ => Icons.notifications_none,
  };
  showJkSheet(
    context,
    builder: (ctx) => Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Notificaciones', style: JkText.display(22)),
        const SizedBox(height: 8),
        for (final (i, n) in st.notificaciones.indexed)
          JkListItem(
            leading: IconTile(icono(n.icono), size: 38),
            title: n.titulo,
            subtitle: n.cuando,
            last: i == st.notificaciones.length - 1,
          ),
      ],
    ),
  );
}

// ============================================================ páginas internas

/// Pantalla apilada (con volver), sin barra de pestañas.
class JkPage extends StatelessWidget {
  const JkPage({
    super.key,
    required this.title,
    this.subtitle,
    required this.children,
    this.bottom,
  });
  final String title;
  final String? subtitle;
  final List<Widget> children;

  /// Acción fija abajo (por ejemplo el botón principal).
  final Widget? bottom;

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: JkTopBar(title: title, subtitle: subtitle),
    body: ListView(
      padding: const EdgeInsets.fromLTRB(
        JkSpace.gutter,
        JkSpace.gutter,
        JkSpace.gutter,
        32,
      ),
      children: children,
    ),
    bottomNavigationBar: bottom == null
        ? null
        : Container(
            decoration: const BoxDecoration(
              color: JkColors.white,
              border: Border(top: BorderSide(color: JkColors.line)),
            ),
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
            child: SafeArea(top: false, child: bottom!),
          ),
  );
}

Future<T?> pushPage<T>(BuildContext context, Widget page) =>
    Navigator.of(context).push<T>(MaterialPageRoute(builder: (_) => page));

// ============================================================ pestañas

class ShellTab {
  const ShellTab({
    required this.label,
    required this.icon,
    required this.title,
    required this.builder,
    this.subtitle,
    this.fab,
  });
  final String label;
  final IconData icon;
  final String Function(AppState) title;
  final String? Function(AppState)? subtitle;
  final WidgetBuilder builder;
  final ({IconData icon, String tooltip, void Function(BuildContext) onTap})?
  fab;
}

/// Marco con barra de pestañas abajo, al alcance del pulgar.
class RoleShell extends StatefulWidget {
  const RoleShell({super.key, required this.tabs});
  final List<ShellTab> tabs;

  static RoleShellState of(BuildContext context) =>
      context.findAncestorStateOfType<RoleShellState>()!;

  @override
  State<RoleShell> createState() => RoleShellState();
}

class RoleShellState extends State<RoleShell> {
  int index = 0;

  void goTab(int i) {
    Navigator.of(context).popUntil((r) => r.isFirst);
    setState(() => index = i);
  }

  @override
  Widget build(BuildContext context) {
    final st = AppScope.of(context);
    final tab = widget.tabs[index];
    return Scaffold(
      appBar: JkTopBar(
        title: tab.title(st),
        subtitle: tab.subtitle?.call(st),
        showBell: true,
      ),
      body: IndexedStack(
        index: index,
        children: [for (final t in widget.tabs) Builder(builder: t.builder)],
      ),
      floatingActionButton: tab.fab == null
          ? null
          : Builder(
              builder: (ctx) => FloatingActionButton(
                tooltip: tab.fab!.tooltip,
                backgroundColor: JkColors.ink,
                foregroundColor: JkColors.white,
                shape: const RoundedRectangleBorder(borderRadius: JkRadius.br),
                onPressed: () => tab.fab!.onTap(ctx),
                child: Icon(tab.fab!.icon),
              ),
            ),
      bottomNavigationBar: _BottomNav(
        tabs: widget.tabs,
        index: index,
        onTap: (i) => setState(() => index = i),
      ),
    );
  }
}

class _BottomNav extends StatelessWidget {
  const _BottomNav({
    required this.tabs,
    required this.index,
    required this.onTap,
  });
  final List<ShellTab> tabs;
  final int index;
  final ValueChanged<int> onTap;

  @override
  Widget build(BuildContext context) => Container(
    decoration: const BoxDecoration(
      color: JkColors.white,
      border: Border(top: BorderSide(color: JkColors.line)),
    ),
    child: SafeArea(
      top: false,
      child: SizedBox(
        height: 64,
        child: Row(
          children: [
            for (var i = 0; i < tabs.length; i++)
              Expanded(
                child: Semantics(
                  selected: i == index,
                  button: true,
                  label: tabs[i].label,
                  child: InkWell(
                    onTap: () => onTap(i),
                    child: Column(
                      children: [
                        // La línea de la pestaña activa crece en 200 ms (en carbón).
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          height: 2,
                          width: i == index ? 32 : 0,
                          color: JkColors.ink,
                        ),
                        const Spacer(),
                        Icon(
                          tabs[i].icon,
                          size: 23,
                          color: i == index ? JkColors.ink : JkColors.inkMuted,
                        ),
                        const SizedBox(height: 3),
                        Text(
                          tabs[i].label,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: JkText.body(
                            12,
                            w: i == index ? FontWeight.w700 : FontWeight.w500,
                            c: i == index ? JkColors.ink : JkColors.inkMuted,
                          ),
                        ),
                        const Spacer(),
                      ],
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    ),
  );
}

/// Contenido desplazable de una pestaña.
class TabBody extends StatelessWidget {
  const TabBody({super.key, required this.children});
  final List<Widget> children;

  @override
  Widget build(BuildContext context) => RefreshIndicator(
    color: JkColors.ink,
    backgroundColor: JkColors.white,
    onRefresh: AppScope.read(context).refrescar,
    child: ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(
        JkSpace.gutter,
        JkSpace.gutter,
        JkSpace.gutter,
        96,
      ),
      children: children,
    ),
  );
}
