import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/theme.dart';

/// Widget con comportamento focus TV-friendly.
/// Evidenzia il bordo quando ha il focus, gestisce OK/Enter come tap.
class TvFocusable extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final bool autofocus;
  final FocusNode? focusNode;
  final Color focusColor;
  final double borderRadius;

  const TvFocusable({
    super.key,
    required this.child,
    this.onTap,
    this.onLongPress,
    this.autofocus = false,
    this.focusNode,
    this.focusColor = AppTheme.accent,
    this.borderRadius = 8,
  });

  @override
  State<TvFocusable> createState() => _TvFocusableState();
}

class _TvFocusableState extends State<TvFocusable> {
  late final FocusNode _node;
  bool _focused = false;

  @override
  void initState() {
    super.initState();
    _node = widget.focusNode ?? FocusNode();
    _node.addListener(() {
      if (mounted) setState(() => _focused = _node.hasFocus);
    });
  }

  @override
  void dispose() {
    if (widget.focusNode == null) _node.dispose();
    super.dispose();
  }

  KeyEventResult _onKey(FocusNode node, KeyEvent event) {
    if (event is KeyDownEvent &&
        (event.logicalKey == LogicalKeyboardKey.select ||
            event.logicalKey == LogicalKeyboardKey.enter ||
            event.logicalKey == LogicalKeyboardKey.space)) {
      widget.onTap?.call();
      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }

  @override
  Widget build(BuildContext context) {
    return Focus(
      focusNode: _node,
      autofocus: widget.autofocus,
      onKeyEvent: _onKey,
      child: GestureDetector(
        onTap: () {
          _node.requestFocus();
          widget.onTap?.call();
        },
        onLongPress: widget.onLongPress,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(widget.borderRadius),
            border: Border.all(
              color: _focused ? widget.focusColor : Colors.transparent,
              width: 2.5,
            ),
            boxShadow: _focused
                ? [
                    BoxShadow(
                      color: widget.focusColor.withOpacity(0.4),
                      blurRadius: 8,
                      spreadRadius: 1,
                    )
                  ]
                : null,
          ),
          child: widget.child,
        ),
      ),
    );
  }
}

/// Item di lista con focus TV tracciato via StatefulWidget
class _TvFocusItem extends StatefulWidget {
  final Widget Function(BuildContext context, bool hasFocus) builder;
  final VoidCallback? onSelect;

  const _TvFocusItem({required this.builder, this.onSelect});

  @override
  State<_TvFocusItem> createState() => _TvFocusItemState();
}

class _TvFocusItemState extends State<_TvFocusItem> {
  final _node = FocusNode();
  bool _focused = false;

  @override
  void initState() {
    super.initState();
    _node.addListener(() {
      if (mounted) setState(() => _focused = _node.hasFocus);
    });
  }

  @override
  void dispose() {
    _node.dispose();
    super.dispose();
  }

  KeyEventResult _onKey(FocusNode node, KeyEvent event) {
    if (event is KeyDownEvent &&
        (event.logicalKey == LogicalKeyboardKey.select ||
            event.logicalKey == LogicalKeyboardKey.enter)) {
      widget.onSelect?.call();
      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }

  @override
  Widget build(BuildContext context) {
    return Focus(
      focusNode: _node,
      onKeyEvent: _onKey,
      child: widget.builder(context, _focused),
    );
  }
}

/// Lista con navigazione D-pad ottimizzata per TV
class TvFocusList extends StatelessWidget {
  final int itemCount;
  final Widget Function(BuildContext, int, bool hasFocus) itemBuilder;
  final Axis scrollDirection;
  final void Function(int)? onItemSelected;

  const TvFocusList({
    super.key,
    required this.itemCount,
    required this.itemBuilder,
    this.scrollDirection = Axis.vertical,
    this.onItemSelected,
  });

  @override
  Widget build(BuildContext context) {
    return FocusTraversalGroup(
      policy: OrderedTraversalPolicy(),
      child: ListView.builder(
        scrollDirection: scrollDirection,
        itemCount: itemCount,
        itemBuilder: (context, i) => _TvFocusItem(
          onSelect: () => onItemSelected?.call(i),
          builder: (ctx, focused) => itemBuilder(ctx, i, focused),
        ),
      ),
    );
  }
}

/// Griglia con navigazione D-pad per TV (es. VOD grid)
class TvFocusGrid extends StatelessWidget {
  final int itemCount;
  final int crossAxisCount;
  final Widget Function(BuildContext, int, bool hasFocus) itemBuilder;
  final void Function(int)? onItemSelected;
  final double spacing;

  const TvFocusGrid({
    super.key,
    required this.itemCount,
    required this.crossAxisCount,
    required this.itemBuilder,
    this.onItemSelected,
    this.spacing = 8,
  });

  @override
  Widget build(BuildContext context) {
    return FocusTraversalGroup(
      policy: OrderedTraversalPolicy(),
      child: GridView.builder(
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: crossAxisCount,
          crossAxisSpacing: spacing,
          mainAxisSpacing: spacing,
          childAspectRatio: 0.65,
        ),
        itemCount: itemCount,
        itemBuilder: (context, i) => _TvFocusItem(
          onSelect: () => onItemSelected?.call(i),
          builder: (ctx, focused) => itemBuilder(ctx, i, focused),
        ),
      ),
    );
  }
}
