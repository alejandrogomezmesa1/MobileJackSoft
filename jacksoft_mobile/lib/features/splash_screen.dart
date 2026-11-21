import 'dart:async';

import 'package:flutter/material.dart';

import 'package:jacksoft_mobile/core/shell.dart';
import 'package:jacksoft_mobile/core/theme.dart';

/// Fondo "night-table" plano (sin gradiente ni brillo decorativo).
class SplashScreen extends StatefulWidget {
  const SplashScreen({required this.onDone, super.key});
  final VoidCallback onDone;

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  Timer? _t;

  @override
  void initState() {
    super.initState();
    _t = Timer(const Duration(milliseconds: 1900), widget.onDone);
  }

  @override
  void dispose() {
    _t?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: () {
      _t?.cancel();
      widget.onDone();
    },
    child: Scaffold(
      backgroundColor: JkColors.night,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const BrandMark(size: 88, onDark: true),
            const SizedBox(height: 20),
            Text(
              'La Coca de Jacks',
              style: JkText.display(34, c: JkColors.cream),
            ),
            const SizedBox(height: 2),
            Text(
              'Almuerzos caseros a domicilio',
              style: JkText.body(15, c: JkColors.hairlineStrong),
            ),
            const SizedBox(height: 36),
            const SizedBox(
              width: 22,
              height: 22,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: JkColors.cream,
              ),
            ),
          ],
        ),
      ),
    ),
  );
}
