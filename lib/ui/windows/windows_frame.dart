import 'package:flutter/material.dart';
import 'package:window_manager/window_manager.dart';

class WindowsFrame extends StatelessWidget {
  const WindowsFrame({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bg = theme.colorScheme.surface;
    final iconColor = theme.colorScheme.onSurface;

    return Column(
      children: [
        SizedBox(
          height: 36,
          child: Container(
            color: bg,
            child: Row(
              children: [
                Expanded(
                  child: DragToMoveArea(
                    child: const SizedBox.expand(),
                  ),
                ),
                _CaptionButton(
                  icon: Icons.remove,
                  tooltip: 'Minimize',
                  onPressed: () => windowManager.minimize(),
                ),
                _CaptionButton(
                  icon: Icons.crop_square,
                  tooltip: 'Maximize/Restore',
                  onPressed: () async {
                    final isMax = await windowManager.isMaximized();
                    if (isMax) {
                      await windowManager.restore();
                    } else {
                      await windowManager.maximize();
                    }
                  },
                ),
                _CaptionButton(
                  icon: Icons.close,
                  tooltip: 'Close',
                  hoverColor: Colors.red.withOpacity(0.8),
                  iconHoverColor: Colors.white,
                  onPressed: () async {
                    // If minimized already, close; otherwise minimize first.
                    final isMin = await windowManager.isMinimized();
                    if (isMin) {
                      await windowManager.close();
                    } else {
                      await windowManager.minimize();
                    }
                  },
                ),
              ],
            ),
          ),
        ),
        Expanded(child: child),
      ],
    );
  }
}

class _CaptionButton extends StatefulWidget {
  const _CaptionButton({
    required this.icon,
    required this.onPressed,
    this.tooltip,
    this.hoverColor,
    this.iconHoverColor,
  });

  final IconData icon;
  final VoidCallback onPressed;
  final String? tooltip;
  final Color? hoverColor;
  final Color? iconHoverColor;

  @override
  State<_CaptionButton> createState() => _CaptionButtonState();
}

class _CaptionButtonState extends State<_CaptionButton> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final baseBg = theme.colorScheme.surface;
    final baseIconColor = theme.colorScheme.onSurface;
    final bg = _hover ? (widget.hoverColor ?? baseBg.withOpacity(0.9)) : baseBg;
    final iconColor = _hover ? (widget.iconHoverColor ?? baseIconColor) : baseIconColor;

    final button = SizedBox(
      width: 46,
      height: double.infinity,
      child: IconButton(
        padding: EdgeInsets.zero,
        icon: Icon(widget.icon, size: 18, color: iconColor),
        onPressed: widget.onPressed,
        tooltip: widget.tooltip,
      ),
    );

    return MouseRegion(
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: ColoredBox(color: bg, child: button),
    );
  }
}
