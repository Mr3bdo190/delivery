import 'dart:ui';
import 'package:flutter/material.dart';

class GlassBox extends StatelessWidget {
  final Widget child;
  final double width;
  final double? height;
  final EdgeInsetsGeometry padding;

  const GlassBox({
    super.key,
    required this.child,
    this.width = double.infinity,
    this.height,
    this.padding = const EdgeInsets.all(20),
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(25),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
        child: Container(
          width: width,
          height: height,
          padding: padding,
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.05),
            borderRadius: BorderRadius.circular(25),
            border: Border.all(color: Colors.white.withOpacity(0.2), width: 1.5),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.2),
                blurRadius: 20,
                spreadRadius: -5,
              )
            ],
          ),
          child: child,
        ),
      ),
    );
  }
}
