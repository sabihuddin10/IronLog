import 'dart:ui';
import 'package:flutter/material.dart';
import 'premium_theme.dart';

/// Base card shell used everywhere in the premium spec: diagonal
/// surface2->surface gradient, hairline border, soft drop shadow, rounded
/// corners. `linear-gradient(165deg, var(--surface-2), var(--surface))`.
class PremiumCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final double radius;
  final LinearGradient? gradient;
  final Color? borderColor;
  final VoidCallback? onTap;

  const PremiumCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(17),
    this.radius = Premium.radiusLg,
    this.gradient,
    this.borderColor,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final card = Container(
      padding: padding,
      decoration: BoxDecoration(
        gradient: gradient ?? Premium.cardGradient,
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(color: borderColor ?? Premium.border),
        boxShadow: Premium.cardShadow,
      ),
      child: child,
    );
    if (onTap == null) return card;
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(radius),
      child: InkWell(
        borderRadius: BorderRadius.circular(radius),
        onTap: onTap,
        child: card,
      ),
    );
  }
}

/// A pill-shaped chip filled with [Premium.accentGradient] — the spec's
/// primary-action styling (Finish button, Start Run, active tab, etc).
class PremiumGradientButton extends StatelessWidget {
  final String label;
  final VoidCallback? onTap;
  final IconData? icon;
  final EdgeInsetsGeometry padding;
  final double radius;

  const PremiumGradientButton({
    super.key,
    required this.label,
    this.onTap,
    this.icon,
    this.padding = const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
    this.radius = 20,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(radius),
      child: InkWell(
        borderRadius: BorderRadius.circular(radius),
        onTap: onTap,
        child: Container(
          padding: padding,
          decoration: BoxDecoration(
            gradient: Premium.accentGradient,
            borderRadius: BorderRadius.circular(radius),
            boxShadow: Premium.accentGlowShadow(),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null) ...[
                Icon(icon, size: 15, color: Premium.ink),
                const SizedBox(width: 6),
              ],
              Text(
                label,
                style: Premium.heading(13, weight: FontWeight.w700, color: Premium.ink),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Small icon chip used for card/exercise/tool icons:
/// `background: linear-gradient(150deg, var(--accent-dim), rgba(79,255,174,0.05))`.
class PremiumIconChip extends StatelessWidget {
  final IconData icon;
  final double size;

  const PremiumIconChip({super.key, required this.icon, this.size = 32});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Premium.accentDim, Premium.accent.withValues(alpha: 0.05)],
        ),
        borderRadius: BorderRadius.circular(size * 0.31),
        border: Border.all(color: Premium.accent.withValues(alpha: 0.18)),
      ),
      child: Icon(icon, size: size * 0.5, color: Premium.accent),
    );
  }
}

class NavEntry {
  final IconData icon;
  final IconData selectedIcon;
  final String label;

  const NavEntry({required this.icon, required this.selectedIcon, required this.label});
}

/// Floating glass pill nav bar with a sliding gradient indicator behind the
/// active tab — replicates the spec's `.navwrap`/`.navbar`/`.nav-indicator`.
class PillNavBar extends StatelessWidget {
  final int index;
  final ValueChanged<int> onSelect;
  final List<NavEntry> entries;

  const PillNavBar({super.key, required this.index, required this.onSelect, required this.entries});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 0, 18, 18),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
          child: Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: Premium.surface2.withValues(alpha: 0.72),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: Premium.borderStrong),
            ),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final itemWidth = constraints.maxWidth / entries.length;
                return Stack(
                  children: [
                    AnimatedPositioned(
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeOutCubic,
                      left: itemWidth * index,
                      width: itemWidth,
                      top: 0,
                      bottom: 0,
                      child: Container(
                        margin: const EdgeInsets.symmetric(horizontal: 2),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [Premium.accent.withValues(alpha: 0.18), Premium.accent.withValues(alpha: 0.06)],
                          ),
                          border: Border.all(color: Premium.accent.withValues(alpha: 0.22)),
                          borderRadius: BorderRadius.circular(18),
                        ),
                      ),
                    ),
                    Row(
                      children: [
                        for (var i = 0; i < entries.length; i++)
                          Expanded(
                            child: InkWell(
                              borderRadius: BorderRadius.circular(18),
                              onTap: () => onSelect(i),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(vertical: 9),
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      i == index ? entries[i].selectedIcon : entries[i].icon,
                                      size: 19,
                                      color: i == index ? Premium.accent : Premium.textFaint,
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      entries[i].label,
                                      style: Premium.body(
                                        10,
                                        weight: i == index ? FontWeight.w600 : FontWeight.w500,
                                        color: i == index ? Premium.accent : Premium.textFaint,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}

/// A small live-pulsing dot — `.live-dot` — used next to a workout-in-progress
/// title.
class LivePulseDot extends StatefulWidget {
  const LivePulseDot({super.key});

  @override
  State<LivePulseDot> createState() => _LivePulseDotState();
}

class _LivePulseDotState extends State<LivePulseDot> with SingleTickerProviderStateMixin {
  late final AnimationController _controller =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 1400))..repeat(reverse: true);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final t = _controller.value;
        return Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Premium.liveRed.withValues(alpha: 1 - t * 0.5),
            boxShadow: [
              BoxShadow(color: Premium.liveRed.withValues(alpha: (1 - t) * 0.5), blurRadius: 5 * t, spreadRadius: 5 * t),
            ],
          ),
        );
      },
    );
  }
}
