import 'package:flutter/material.dart';
import 'dart:math';

class AppVersion extends StatefulWidget {
  const AppVersion({Key? key}) : super(key: key);

  @override
  State<AppVersion> createState() => _AppVersionState();
}

class _AppVersionState extends State<AppVersion>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;
  final List<_Glitter> _glitters = [];
  final Random _random = Random();

  @override
  void initState() {
    super.initState();
    // Animation controller in 0..1 range
    _controller = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );

    // Tween from 1.0 -> 1.2 for bounce
    _animation = Tween<double>(begin: 1.0, end: 1.2)
        .chain(CurveTween(curve: Curves.elasticOut))
        .animate(_controller);

    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        _controller.reverse();
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onTextTap() {
    _controller.forward(from: 0);
  }

  void _onScreenTap(TapDownDetails details) {
    final renderBox = context.findRenderObject() as RenderBox;
    final localPos = renderBox.globalToLocal(details.globalPosition);

    // Generate multiple sparkles
    setState(() {
      for (int i = 0; i < 8; i++) {
        _glitters.add(_Glitter(
          position: localPos +
              Offset(_random.nextDouble() * 30 - 15, _random.nextDouble() * 30 - 15),
          size: _random.nextDouble() * 8 + 4,
          color: Colors.white.withOpacity(0.8),
        ));
      }
    });

    // Remove after animation
    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) {
        setState(() {
          if (_glitters.length >= 8) {
            _glitters.removeRange(0, 8);
          }
        });
      }
    });
  }

  Widget _buildGlitters() {
    return Stack(
      children: _glitters
          .map((g) => Positioned(
                left: g.position.dx,
                top: g.position.dy,
                child: Icon(
                  Icons.star,
                  color: g.color,
                  size: g.size,
                ),
              ))
          .toList(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: _onScreenTap,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Version'),
          backgroundColor: Colors.blue[900],
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        body: Stack(
          children: [
            Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Color(0xFF0D47A1), // Dark Blue
                    Colors.black,
                  ],
                ),
              ),
            ),
            Center(
  child: Column(
    mainAxisSize: MainAxisSize.min,
    children: [
      const Text(
        'UniFind',
        style: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: Colors.white,
          shadows: [
            Shadow(
              blurRadius: 5,
              color: Colors.white70,
              offset: Offset(0, 0),
            ),
          ],
        ),
      ),
      const SizedBox(height: 16),
      ScaleTransition(
        scale: _animation,
        child: GestureDetector(
          onTap: _onTextTap,
          child: const Text(
            'Version 1.0',
            style: TextStyle(
              fontSize: 48,
              fontWeight: FontWeight.bold,
              color: Colors.white,
              shadows: [
                Shadow(
                  blurRadius: 10,
                  color: Colors.white70,
                  offset: Offset(0, 0),
                ),
              ],
            ),
          ),
        ),
      ),
      const SizedBox(height: 16),
      const Text(
        'Release Date: 1 Dec 2025',
        style: TextStyle(
          fontSize: 12,
          color: Colors.white70,
        ),
      ),
    ],
  ),
),
            _buildGlitters(),
          ],
        ),
      ),
    );
  }
}

class _Glitter {
  final Offset position;
  final double size;
  final Color color;

  _Glitter({required this.position, required this.size, required this.color});
}
