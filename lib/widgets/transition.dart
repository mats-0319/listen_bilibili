import 'package:flutter/material.dart';

RouteTransitionsBuilder transition() {
  var begin = Offset(1.0, 0.0); // 从右向左滑
  var end = Offset.zero;
  var tween = Tween(begin: begin, end: end);
  var tweenChain = tween.chain(CurveTween(curve: Curves.easeInOut));

  return (context, a, s, child) => SlideTransition(
    position: a.drive(tweenChain),
    child: FadeTransition(opacity: a, child: child),
  );
}
