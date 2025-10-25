// lib/widgets/glassmorphic_popup_menu.dart

import 'dart:ui';
import 'package:flutter/material.dart';

/// A simple data class for the menu items.
class GlassmorphicPopupMenuItem {
  final String value;
  final Widget child;
  const GlassmorphicPopupMenuItem({required this.value, required this.child});
}

/// A custom widget that displays a popup menu with a glassmorphism effect.
class GlassmorphicPopupMenu extends StatefulWidget {
  final Widget icon;
  final List<GlassmorphicPopupMenuItem> items;
  final Function(String) onItemSelected;

  const GlassmorphicPopupMenu({
    super.key,
    required this.icon,
    required this.items,
    required this.onItemSelected,
  });

  @override
  State<GlassmorphicPopupMenu> createState() => _GlassmorphicPopupMenuState();
}

class _GlassmorphicPopupMenuState extends State<GlassmorphicPopupMenu> {
  final GlobalKey _iconKey = GlobalKey();
  OverlayEntry? _overlayEntry;

  bool get _isMenuOpen => _overlayEntry != null;

  void _showMenu(BuildContext context) {
    final RenderBox renderBox = _iconKey.currentContext!.findRenderObject() as RenderBox;
    final size = renderBox.size;
    final offset = renderBox.localToGlobal(Offset.zero);

    _overlayEntry = OverlayEntry(
      builder: (context) => Stack(
        children: [
          // Full-screen GestureDetector to dismiss the menu when tapping outside
          GestureDetector(
            onTap: _hideMenu,
            behavior: HitTestBehavior.opaque,
            child: Container(color: Colors.transparent),
          ),
          // Positioned menu with the glassmorphism effect
          Positioned(
            top: offset.dy + size.height - 10, // Position it below the icon
            right: 16, // Align it to the right side of the screen
            child: Material(
              color: Colors.transparent,
              child: _buildGlassmorphicMenu(),
            ),
          ),
        ],
      ),
    );

    Overlay.of(context).insert(_overlayEntry!);
  }

  void _hideMenu() {
    _overlayEntry?.remove();
    _overlayEntry = null;
  }

  Widget _buildGlassmorphicMenu() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          width: 200, // A suitable width for your menu items
          decoration: BoxDecoration(
            color: const Color(0xFF1C1C1E).withOpacity(0.7),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: Colors.white.withOpacity(0.1),
              width: 1.5,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: widget.items.map((item) {
              return InkWell(
                onTap: () {
                  _hideMenu();
                  widget.onItemSelected(item.value);
                },
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  child: item.child,
                ),
              );
            }).toList(),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return IconButton(
      key: _iconKey,
      icon: widget.icon,
      onPressed: () {
        if (_isMenuOpen) {
          _hideMenu();
        } else {
          _showMenu(context);
        }
      },
    );
  }
}