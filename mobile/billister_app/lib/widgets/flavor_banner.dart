import 'package:flutter/material.dart';

import '../config/app_config.dart';

/// Wraps its [child] in a visible banner when running in the dev flavor.
/// In prod the child is returned unchanged.
class FlavorBanner extends StatelessWidget {
  const FlavorBanner({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    if (AppConfig.current.isProd) return child;

    return Stack(
      children: [
        child,
        _DevBanner(label: AppConfig.current.flavor.name.toUpperCase()),
      ],
    );
  }
}

class _DevBanner extends StatelessWidget {
  const _DevBanner({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: MediaQuery.of(context).padding.top + 4,
      right: 0,
      child: IgnorePointer(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          decoration: BoxDecoration(
            color: Colors.orange.shade700,
            borderRadius: const BorderRadius.horizontal(
              left: Radius.circular(6),
            ),
          ),
          child: Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 10,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.2,
            ),
          ),
        ),
      ),
    );
  }
}
