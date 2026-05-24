import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:window_manager/window_manager.dart';

/// Custom title bar shown only on desktop platforms.
/// Replaces the native OS title bar when [TitleBarStyle.hidden] is used.
class AppTitleBar extends StatelessWidget {
  const AppTitleBar({super.key});

  @override
  Widget build(BuildContext context) {
    final isDesktop =
        !kIsWeb && (Platform.isWindows || Platform.isMacOS || Platform.isLinux);
    if (!isDesktop) return const SizedBox.shrink();

    return Container(
      height: 30,
      color: Colors.white,
      child: Row(
        children: [
          const SizedBox(width: 14),
          const Icon(Icons.school, size: 18, color: Color(0xFF1E6AF9)),
          const SizedBox(width: 8),
          const Text(
            'ClassPulse',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: Color(0xFF334155),
            ),
          ),
          Expanded(
            child: DragToMoveArea(
              child: Container(color: Colors.transparent),
            ),
          ),
          const WindowButtons(),
        ],
      ),
    );
  }
}

// ─── Window control buttons ────────────────────────────────────────────────

class WindowButtons extends StatelessWidget {
  const WindowButtons({super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _WindowButton(
          customIconBuilder: (color) =>
              Container(width: 12, height: 1.5, color: color),
          onTap: () => windowManager.minimize(),
          hoverColor: Colors.black.withValues(alpha: 0.1),
        ),
        _WindowButton(
          icon: Icons.crop_square,
          iconSize: 15,
          onTap: () async {
            if (await windowManager.isMaximized()) {
              windowManager.unmaximize();
            } else {
              windowManager.maximize();
            }
          },
          hoverColor: Colors.black.withValues(alpha: 0.1),
        ),
        _WindowButton(
          icon: Icons.close,
          onTap: () => windowManager.close(),
          hoverColor: Colors.red,
          hoverIconColor: Colors.white,
        ),
      ],
    );
  }
}

// ─── Single window button ─────────────────────────────────────────────────

class _WindowButton extends StatefulWidget {
  final IconData? icon;
  final Widget Function(Color color)? customIconBuilder;
  final double iconSize;
  final VoidCallback onTap;
  final Color hoverColor;
  final Color? hoverIconColor;

  const _WindowButton({
    this.icon,
    this.customIconBuilder,
    this.iconSize = 18,
    required this.onTap,
    required this.hoverColor,
    this.hoverIconColor,
  });

  @override
  State<_WindowButton> createState() => _WindowButtonState();
}

class _WindowButtonState extends State<_WindowButton> {
  bool _isHovering = false;

  @override
  Widget build(BuildContext context) {
    const defaultColor = Color(0xFF64748B);
    final activeColor =
        _isHovering ? (widget.hoverIconColor ?? defaultColor) : defaultColor;

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovering = true),
      onExit: (_) => setState(() => _isHovering = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: Container(
          width: 46,
          height: 30,
          color: _isHovering ? widget.hoverColor : Colors.transparent,
          alignment: Alignment.center,
          child: widget.customIconBuilder != null
              ? widget.customIconBuilder!(activeColor)
              : Icon(widget.icon, size: widget.iconSize, color: activeColor),
        ),
      ),
    );
  }
}
