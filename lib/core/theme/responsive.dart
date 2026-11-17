import 'package:material_ui/material_ui.dart';

/// Centralized responsiveness system shared across every screen.
///
/// This does NOT introduce a new design language — it only removes the
/// hardcoded pixel values scattered across screens and replaces them with a
/// single source of truth for breakpoints, spacing and adaptive sizing.
/// Adopting these helpers is purely a layout change; no business logic,
/// navigation, data or functionality is altered.

// ───────────────────────── SPACING ─────────────────────────
/// Centralized spacing scale. Use these instead of magic numbers like 8 / 16.
class Spacing {
  const Spacing._();

  static const double xs = 4;
  static const double s = 8;
  static const double m = 16;
  static const double l = 24;
  static const double xl = 32;

  static EdgeInsets all(double v) => EdgeInsets.all(v);
  static EdgeInsets horizontal(double v) => EdgeInsets.symmetric(horizontal: v);
  static EdgeInsets vertical(double v) => EdgeInsets.symmetric(vertical: v);
  static EdgeInsets symmetric({double horizontal = 0, double vertical = 0}) =>
      EdgeInsets.symmetric(horizontal: horizontal, vertical: vertical);
}

// ───────────────────────── SCREEN SIZE ─────────────────────────
/// Material-style breakpoints:
///   Compact   < 600      (small / large phones)
///   Medium    600–899    (large phones, unfolded foldables)
///   Expanded  900–1199   (tablets, chromebooks)
///   Large     ≥ 1200     (desktop windows)
enum ScreenSize { compact, medium, expanded, large }

extension ScreenSizeX on ScreenSize {
  bool get isCompact => this == ScreenSize.compact;
  bool get isMedium => this == ScreenSize.medium;
  bool get isExpanded => this == ScreenSize.expanded;
  bool get isLarge => this == ScreenSize.large;

  /// Index order: compact(0) … large(3).
  int get rank => switch (this) {
        ScreenSize.compact => 0,
        ScreenSize.medium => 1,
        ScreenSize.expanded => 2,
        ScreenSize.large => 3,
      };
}

class ResponsiveBreakpoints {
  ResponsiveBreakpoints._();

  static const double compactMax = 600;
  static const double mediumMax = 900;
  static const double expandedMax = 1200;

  /// Maximum width for centered single-column reading / form content.
  static const double maxFormWidth = 480;

  /// Maximum width for centered two-pane / dashboard content on large screens.
  static const double maxContentWidth = 1400;

  /// Minimum touch-target size (Material accessibility guideline).
  static const double minTouchTarget = 48;

  static ScreenSize of(double width) {
    if (width < compactMax) return ScreenSize.compact;
    if (width < mediumMax) return ScreenSize.medium;
    if (width < expandedMax) return ScreenSize.expanded;
    return ScreenSize.large;
  }

  static ScreenSize sizeOf(BuildContext context) => of(Responsive.widthOf(context));

  static bool isCompact(BuildContext context) =>
      sizeOf(context) == ScreenSize.compact;
  static bool isMedium(BuildContext context) =>
      sizeOf(context) == ScreenSize.medium;
  static bool isExpanded(BuildContext context) =>
      sizeOf(context) == ScreenSize.expanded;
  static bool isLarge(BuildContext context) =>
      sizeOf(context) == ScreenSize.large;

  /// Returns the value produced by the matching breakpoint builder, falling
  /// back to [orElse] when a specific breakpoint is not provided.
  static T when<T>(
    BuildContext context, {
    T Function()? compact,
    T Function()? medium,
    T Function()? expanded,
    T Function()? large,
    required T Function() orElse,
  }) {
    final size = sizeOf(context);
    switch (size) {
      case ScreenSize.compact:
        return compact?.call() ?? orElse();
      case ScreenSize.medium:
        return medium?.call() ?? orElse();
      case ScreenSize.expanded:
        return expanded?.call() ?? orElse();
      case ScreenSize.large:
        return large?.call() ?? orElse();
    }
  }

  /// Number of grid columns for a given width, based on a desired minimum
  /// tile width. Always returns at least 1 and at most [maxColumns].
  static int columns(
    double width, {
    double minTileWidth = 220,
    int maxColumns = 6,
  }) {
    final columns = (width / minTileWidth).floor();
    return columns.clamp(1, maxColumns);
  }

  /// Sidebar width used by the desktop shell layout.
  static double sidebarWidth(double width) =>
      width >= expandedMax ? 264 : 220;
}

// ───────────────────────── RESPONSIVE LAYOUT ─────────────────────────
/// Builds a different subtree per breakpoint. Use the [builder] overload when
/// the widget tree differs substantially between sizes.
class ResponsiveLayout extends StatelessWidget {
  final Widget Function(BuildContext context, ScreenSize size) builder;

  const ResponsiveLayout({super.key, required this.builder});

  @override
  Widget build(BuildContext context) =>
      builder(context, ResponsiveBreakpoints.sizeOf(context));
}

/// Builds one of four explicitly-provided subtrees based on the breakpoint.
class ResponsiveBuilder extends StatelessWidget {
  final Widget Function(BuildContext context)? compact;
  final Widget Function(BuildContext context)? medium;
  final Widget Function(BuildContext context)? expanded;
  final Widget Function(BuildContext context)? large;
  final Widget Function(BuildContext context) fallback;

  const ResponsiveBuilder({
    super.key,
    this.compact,
    this.medium,
    this.expanded,
    this.large,
    required this.fallback,
  });

  @override
  Widget build(BuildContext context) {
    final size = ResponsiveBreakpoints.sizeOf(context);
    switch (size) {
      case ScreenSize.compact:
        return (compact ?? fallback)(context);
      case ScreenSize.medium:
        return (medium ?? fallback)(context);
      case ScreenSize.expanded:
        return (expanded ?? fallback)(context);
      case ScreenSize.large:
        return (large ?? fallback)(context);
    }
  }
}

// ───────────────────────── RESPONSIVE PADDING ─────────────────────────
/// Page padding that gently shrinks on the smallest phones so content keeps
/// breathing room, without changing the look on normal phones / tablets.
class ResponsivePadding extends StatelessWidget {
  final Widget child;
  final bool horizontalOnly;
  final double? base;

  const ResponsivePadding({
    super.key,
    required this.child,
    this.horizontalOnly = false,
    this.base,
  });

  @override
  Widget build(BuildContext context) {
    final size = ResponsiveBreakpoints.sizeOf(context);
    final value = base ??
        (size.isCompact
            ? Spacing.m - 4 // 12
            : size.isMedium
                ? Spacing.m // 16
                : Spacing.l); // 24
    return Padding(
      padding: horizontalOnly
          ? EdgeInsets.symmetric(horizontal: value)
          : EdgeInsets.all(value),
      child: child,
    );
  }
}

// ───────────────────────── RESPONSIVE SPACING ─────────────────────────
/// A gap that scales with the breakpoint. Use instead of fixed SizedBoxes.
class ResponsiveSpacing extends StatelessWidget {
  final double size;
  final Axis direction;

  const ResponsiveSpacing({
    super.key,
    required this.size,
    this.direction = Axis.vertical,
  });

  /// Vertical gap of [size].
  const ResponsiveSpacing.vertical({super.key, required this.size})
      : direction = Axis.vertical;

  /// Horizontal gap of [size].
  const ResponsiveSpacing.horizontal({super.key, required this.size})
      : direction = Axis.horizontal;

  @override
  Widget build(BuildContext context) {
    final size = ResponsiveBreakpoints.sizeOf(context);
    // Compact phones get slightly tighter spacing; expanded/large get more.
    final scaled = size.isCompact
        ? this.size * 0.85
        : size.isLarge
            ? this.size * 1.15
            : this.size;
    return SizedBox(
      width: direction == Axis.horizontal ? scaled : null,
      height: direction == Axis.vertical ? scaled : null,
    );
  }
}

// ───────────────────────── RESPONSIVE TEXT ─────────────────────────
/// Text whose font size scales with screen width. Accessibility text
/// scaling is handled automatically by Flutter (it multiplies any explicit
/// fontSize by the system text-scale factor), so no manual scaling is needed
/// here — we only adjust for screen width.
class ResponsiveText extends StatelessWidget {
  final String text;
  final TextStyle? style;
  final TextAlign? textAlign;
  final int? maxLines;
  final double baseFontSize;
  final double? minFontSize;
  final double? maxFontSize;

  const ResponsiveText(
    this.text, {
    super.key,
    required this.baseFontSize,
    this.style,
    this.textAlign,
    this.maxLines,
    this.minFontSize,
    this.maxFontSize,
  });

  @override
  Widget build(BuildContext context) {
    final width = Responsive.widthOf(context);
    // Scale the base size up gently with width, clamped to sane bounds.
    final factor = (width / ResponsiveBreakpoints.compactMax).clamp(0.85, 1.35);
    var fontSize = baseFontSize * factor;
    if (minFontSize != null) fontSize = fontSize.clamp(minFontSize!, fontSize);
    if (maxFontSize != null) fontSize = fontSize.clamp(0.0, maxFontSize!);

    return Text(
      text,
      style: style?.copyWith(fontSize: fontSize) ?? TextStyle(fontSize: fontSize),
      textAlign: textAlign,
      maxLines: maxLines,
      overflow: maxLines != null ? TextOverflow.ellipsis : null,
    );
  }
}

// ───────────────────────── ADAPTIVE GRID ─────────────────────────
/// A responsive grid whose column count derives from the available width.
/// Wrap children that should resize naturally (no fixed widths).
class AdaptiveGrid extends StatelessWidget {
  final List<Widget> children;
  final double minTileWidth;
  final int maxColumns;
  final double spacing;
  final double? childAspectRatio;
  final EdgeInsetsGeometry? padding;
  final bool shrinkWrap;

  const AdaptiveGrid({
    super.key,
    required this.children,
    this.minTileWidth = 220,
    this.maxColumns = 6,
    this.spacing = Spacing.m,
    this.childAspectRatio,
    this.padding,
    this.shrinkWrap = true,
  });

  @override
  Widget build(BuildContext context) {
    final width = Responsive.widthOf(context);
    final columns = ResponsiveBreakpoints.columns(
      width,
      minTileWidth: minTileWidth,
      maxColumns: maxColumns,
    );

    return GridView.builder(
      shrinkWrap: shrinkWrap,
      physics: shrinkWrap ? const NeverScrollableScrollPhysics() : null,
      padding: padding,
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: columns,
        crossAxisSpacing: spacing,
        mainAxisSpacing: spacing,
        childAspectRatio: childAspectRatio ?? 1.0,
      ),
      itemCount: children.length,
      itemBuilder: (context, index) => children[index],
    );
  }
}

// ───────────────────────── RESPONSIVE (legacy + additions) ─────────────────────────
class Responsive {
  Responsive._();

  /// Below this width we're on a small phone (e.g. older 320-360dp devices).
  static const double smallPhone = 360;

  /// Below this width we're on a "normal" phone (390-430dp covers the vast
  /// majority of modern Android phones).
  static const double mediumPhone = 430;

  /// Below this width we're still considered a phone (large phones /
  /// phones in a slightly scaled-up display setting).
  static const double largePhone = 600;

  /// At/above this width we treat the device as a tablet or unfolded
  /// foldable. This matches the breakpoint already used by
  /// [DashboardScreen] to switch between mobile and desktop chrome.
  static const double tablet = 840;

  /// At/above this width the app shows the desktop (sidebar) chrome.
  static const double desktop = 840;

  static double widthOf(BuildContext context) =>
      MediaQuery.sizeOf(context).width;

  static double heightOf(BuildContext context) =>
      MediaQuery.sizeOf(context).height;

  static bool isSmallPhone(BuildContext context) =>
      widthOf(context) < smallPhone;

  static bool isTablet(BuildContext context) => widthOf(context) >= tablet;

  static bool isDesktop(BuildContext context) => widthOf(context) >= desktop;

  /// Horizontal padding that gently shrinks on the smallest phones so
  /// content has more breathing room, without changing the look on normal
  /// phones/tablets.
  static double pagePadding(BuildContext context) {
    final width = widthOf(context);
    if (width < smallPhone) return 12;
    if (width < largePhone) return 16;
    return 20;
  }

  /// A general-purpose helper for turning a fixed pixel dimension into one
  /// that scales down slightly on small phones. Use sparingly — most
  /// layouts should prefer Expanded/Flexible instead of scaled constants.
  static double scale(BuildContext context, double base, {double min = 0.8}) {
    final width = widthOf(context);
    if (width >= mediumPhone) return base;
    final factor = (width / mediumPhone).clamp(min, 1.0);
    return base * factor;
  }

  /// Number of grid columns for a given available [width], based on a
  /// desired minimum tile width. Always returns at least 1 and at most
  /// [maxColumns].
  static int gridColumns(
    double width, {
    double minTileWidth = 160,
    int maxColumns = 4,
  }) {
    final columns = (width / minTileWidth).floor();
    return columns.clamp(1, maxColumns);
  }

  /// Constrains [child] to [maxFormWidth] when the screen is wide enough,
  /// centering it. Used by login / form screens on tablets and desktop.
  static Widget centeredForm(Widget child, {double? maxWidth}) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final w = maxWidth ?? ResponsiveBreakpoints.maxFormWidth;
        if (constraints.maxWidth <= w) return child;
        return Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: w),
            child: child,
          ),
        );
      },
    );
  }
}
