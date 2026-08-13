import 'package:flutter/widgets.dart';

import '../models/enums.dart';
import '../models/node_config.dart';

class AnimationModifier extends StatefulWidget {
  final NDAnimation animation;
  final Widget child;

  const AnimationModifier({
    super.key,
    required this.animation,
    required this.child,
  });

  @override
  State<AnimationModifier> createState() => _AnimationModifierState();
}

class _AnimationModifierState extends State<AnimationModifier>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _opacity;
  late Animation<Offset> _slide;
  late Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    final anim = widget.animation;
    _controller = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: anim.duration),
    );

    final curve = _resolveCurve(anim.easing);
    final curved = CurvedAnimation(parent: _controller, curve: curve);

    _opacity = Tween<double>(begin: 0, end: 1).animate(curved);
    _slide = Tween<Offset>(begin: _slideBegin(anim.type), end: Offset.zero).animate(curved);
    _scale = Tween<double>(begin: 0.8, end: 1).animate(curved);

    if (anim.delay > 0) {
      Future.delayed(Duration(milliseconds: anim.delay), () {
        if (mounted) _controller.forward();
      });
    } else {
      _controller.forward();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Curve _resolveCurve(Easing easing) => switch (easing) {
        Easing.linear => Curves.linear,
        Easing.easeIn => Curves.easeIn,
        Easing.easeOut => Curves.easeOut,
        Easing.easeInOut => Curves.easeInOut,
        Easing.easeInBack => Curves.easeInBack,
        Easing.easeOutBack => Curves.easeOutBack,
        Easing.spring => Curves.elasticOut,
      };

  Offset _slideBegin(AnimationType type) => switch (type) {
        AnimationType.slideInLeft => const Offset(-1, 0),
        AnimationType.slideInRight => const Offset(1, 0),
        AnimationType.slideInTop => const Offset(0, -1),
        AnimationType.slideInBottom => const Offset(0, 1),
        AnimationType.fadeSlideIn => const Offset(0, 0.2),
        _ => Offset.zero,
      };

  bool get _hasFade => switch (widget.animation.type) {
        AnimationType.none => false,
        AnimationType.fadeIn => true,
        AnimationType.slideInLeft => false,
        AnimationType.slideInRight => false,
        AnimationType.slideInTop => false,
        AnimationType.slideInBottom => false,
        AnimationType.scaleIn => false,
        AnimationType.fadeScaleIn => true,
        AnimationType.fadeSlideIn => true,
      };

  bool get _hasSlide => switch (widget.animation.type) {
        AnimationType.slideInLeft => true,
        AnimationType.slideInRight => true,
        AnimationType.slideInTop => true,
        AnimationType.slideInBottom => true,
        AnimationType.fadeSlideIn => true,
        _ => false,
      };

  bool get _hasScale => switch (widget.animation.type) {
        AnimationType.scaleIn => true,
        AnimationType.fadeScaleIn => true,
        _ => false,
      };

  @override
  Widget build(BuildContext context) {
    if (widget.animation.type == AnimationType.none) return widget.child;

    Widget result = widget.child;

    if (_hasSlide) {
      result = SlideTransition(position: _slide, child: result);
    }
    if (_hasScale) {
      result = ScaleTransition(scale: _scale, child: result);
    }
    if (_hasFade) {
      result = FadeTransition(opacity: _opacity, child: result);
    }

    return result;
  }
}
