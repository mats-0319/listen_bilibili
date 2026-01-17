import 'package:flutter/material.dart';

var transition = (context, animation, secondaryAnimation, child) {
  return SlideTransition(
    position: animation.drive(Tween(begin: Offset(1.0, 0.0), end: Offset.zero)),
    child: child,
  );
};
