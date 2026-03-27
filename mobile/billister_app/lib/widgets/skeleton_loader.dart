import 'package:flutter/material.dart';

/// A pulsing shimmer wrapper. Wrap any skeleton placeholder inside this
/// to get an animated shimmer effect without external packages.
class _Shimmer extends StatefulWidget {
  const _Shimmer({required this.child});

  final Widget child;

  @override
  State<_Shimmer> createState() => _ShimmerState();
}

class _ShimmerState extends State<_Shimmer>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
    _anim = Tween<double>(begin: 0.35, end: 0.75).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _anim,
      builder: (_, child) => Opacity(opacity: _anim.value, child: child),
      child: widget.child,
    );
  }
}

/// A single grey placeholder box used as a building block for skeleton layouts.
class SkeletonBox extends StatelessWidget {
  const SkeletonBox({
    super.key,
    this.width,
    this.height = 14,
    this.borderRadius = 6,
  });

  final double? width;
  final double height;
  final double borderRadius;

  @override
  Widget build(BuildContext context) {
    final baseColor = Theme.of(context).brightness == Brightness.dark
        ? Colors.grey.shade700
        : Colors.grey.shade300;

    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: baseColor,
        borderRadius: BorderRadius.circular(borderRadius),
      ),
    );
  }
}

/// A skeleton placeholder that mimics a single car-listing `Card + ListTile`.
class SkeletonListTile extends StatelessWidget {
  const SkeletonListTile({super.key});

  @override
  Widget build(BuildContext context) {
    return _Shimmer(
      child: Card(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Row(
            children: [
              // Thumbnail placeholder
              const SkeletonBox(width: 64, height: 64, borderRadius: 8),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SkeletonBox(
                      width: MediaQuery.of(context).size.width * 0.45,
                      height: 14,
                    ),
                    const SizedBox(height: 8),
                    SkeletonBox(
                      width: MediaQuery.of(context).size.width * 0.3,
                      height: 12,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              // Price placeholder
              const SkeletonBox(width: 56, height: 14),
            ],
          ),
        ),
      ),
    );
  }
}

/// A skeleton placeholder for the listing-details screen.
class SkeletonDetailsView extends StatelessWidget {
  const SkeletonDetailsView({super.key});

  @override
  Widget build(BuildContext context) {
    return _Shimmer(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Hero image placeholder
            SkeletonBox(
              width: double.infinity,
              height: MediaQuery.of(context).size.width * (9 / 16),
              borderRadius: 12,
            ),
            const SizedBox(height: 16),
            const SkeletonBox(width: 240, height: 22),
            const SizedBox(height: 10),
            const SkeletonBox(width: 120, height: 18),
            const SizedBox(height: 16),
            ...List.generate(
              5,
              (_) => const Padding(
                padding: EdgeInsets.only(bottom: 10),
                child: Row(
                  children: [
                    SkeletonBox(width: 90, height: 13),
                    SizedBox(width: 16),
                    Expanded(child: SkeletonBox(height: 13)),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Convenience widget that shows [count] skeleton list-tile cards.
///
/// Set [shrinkWrap] to `true` when nesting inside another scrollable; leave
/// it `false` (the default) when using as the sole scrollable in a screen.
class SkeletonListView extends StatelessWidget {
  const SkeletonListView({super.key, this.count = 5, this.shrinkWrap = false});

  final int count;

  /// When `true` the list wraps its content height and disables scrolling so
  /// it can be embedded inside another scrollable widget.
  final bool shrinkWrap;

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      physics: shrinkWrap ? const NeverScrollableScrollPhysics() : null,
      shrinkWrap: shrinkWrap,
      itemCount: count,
      itemBuilder: (_, __) => const SkeletonListTile(),
    );
  }
}
