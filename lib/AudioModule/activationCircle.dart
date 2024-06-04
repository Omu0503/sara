import 'package:flutter/material.dart';
import 'dart:ui' as ui;

import 'package:navapp2/utlilities/themes.dart';

class CustomShimmer extends StatefulWidget {
  final double size;
  final Duration duration;
  final Color color;
  final Curve curve;

  CustomShimmer({
    required this.size,
    required this.duration,
    required this.color,
    required this.curve,
  });

  @override
  _CustomShimmerState createState() => _CustomShimmerState();
}

class _CustomShimmerState extends State<CustomShimmer>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: widget.duration,
    )..repeat();
    _animation = CurvedAnimation(
      parent: _controller,
      curve: widget.curve,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return ShaderMask(
          shaderCallback: (rect) {
            return RadialGradient(
              center: const Alignment(0.0, 0.0), // Center of the circle
              radius: _animation.value,
              colors: [Colors.transparent, myThemes.green],
              stops: [0.0, 1.0],
            ).createShader(rect);
          },
          child: child,
        );
      },
      child: ClipRRect(

        borderRadius: BorderRadius.circular(widget.size),
        child: ImageFiltered(
          imageFilter: ui.ImageFilter.blur(
            sigmaX: 10,
            sigmaY: 10,
          ),
          child: Container(
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: Color.fromARGB(255, 255, 255, 255),
            ),
            height: widget.size,
            width: widget.size,
          ),
        ),
      ),
    );
  }
}
