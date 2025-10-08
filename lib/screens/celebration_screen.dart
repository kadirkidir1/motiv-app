import 'package:flutter/material.dart';
import 'dart:math';

class CelebrationScreen extends StatefulWidget {
  final String message;
  final VoidCallback onComplete;

  const CelebrationScreen({
    super.key,
    required this.message,
    required this.onComplete,
  });

  @override
  State<CelebrationScreen> createState() => _CelebrationScreenState();
}

class _CelebrationScreenState extends State<CelebrationScreen>
    with TickerProviderStateMixin {
  late AnimationController _controller;
  late AnimationController _textController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;
  late Animation<double> _textAnimation;

  final List<String> _motivationalMessages = [
    "🎉 Aslansın! 🦁",
    "🔥 Kaplansın! 🐅", 
    "⭐ Süpersin! ⭐",
    "💪 Harikasın! 💪",
    "🚀 İmkansızı başardın! 🚀",
    "👑 Kralsın! 👑",
    "🎯 Hedefine odaklandın! 🎯",
    "💎 Değerlisin! 💎",
  ];

  @override
  void initState() {
    super.initState();
    
    _controller = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );
    
    _textController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.elasticOut,
    ));

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.0, 0.6, curve: Curves.easeIn),
    ));

    _textAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _textController,
      curve: Curves.bounceOut,
    ));

    _startAnimation();
  }

  void _startAnimation() async {
    await Future.delayed(const Duration(milliseconds: 300));
    if (mounted) _controller.forward();
    await Future.delayed(const Duration(milliseconds: 500));
    if (mounted) _textController.forward();
    
    await Future.delayed(const Duration(milliseconds: 2500));
    if (mounted) widget.onComplete();
  }

  @override
  void dispose() {
    _controller.stop();
    _textController.stop();
    _controller.dispose();
    _textController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black87,
      body: Stack(
        children: [
          // Havai fişek efekti
          ...List.generate(20, (index) => _buildFirework(index)),
          
          // Ana içerik
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                AnimatedBuilder(
                  animation: _scaleAnimation,
                  builder: (context, child) {
                    if (!mounted) return const SizedBox.shrink();
                    return Transform.scale(
                      scale: _scaleAnimation.value,
                      child: Container(
                        padding: const EdgeInsets.all(32),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              Colors.yellow.shade400,
                              Colors.orange.shade500,
                              Colors.red.shade400,
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.yellow.withValues(alpha: 0.5),
                              blurRadius: 20,
                              spreadRadius: 5,
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.star,
                          size: 80,
                          color: Colors.white,
                        ),
                      ),
                    );
                  },
                ),
                
                const SizedBox(height: 40),
                
                AnimatedBuilder(
                  animation: _textAnimation,
                  builder: (context, child) {
                    if (!mounted) return const SizedBox.shrink();
                    return Transform.scale(
                      scale: _textAnimation.value,
                      child: Text(
                        _motivationalMessages[Random().nextInt(_motivationalMessages.length)],
                        style: const TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    );
                  },
                ),
                
                const SizedBox(height: 20),
                
                AnimatedBuilder(
                  animation: _fadeAnimation,
                  builder: (context, child) {
                    if (!mounted) return const SizedBox.shrink();
                    return Opacity(
                      opacity: _fadeAnimation.value,
                      child: Text(
                        widget.message,
                        style: const TextStyle(
                          fontSize: 18,
                          color: Colors.white70,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFirework(int index) {
    final random = Random(index);
    final left = random.nextDouble() * MediaQuery.of(context).size.width;
    final top = random.nextDouble() * MediaQuery.of(context).size.height;
    final delay = random.nextInt(1000);
    
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        if (!mounted) return const SizedBox.shrink();
        return Positioned(
          left: left,
          top: top,
          child: AnimatedOpacity(
            duration: Duration(milliseconds: 500 + delay),
            opacity: _controller.value > 0.3 ? 1.0 : 0.0,
            child: Transform.scale(
              scale: _controller.value,
              child: Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: _getRandomColor(),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: _getRandomColor().withValues(alpha: 0.8),
                      blurRadius: 10,
                      spreadRadius: 2,
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Color _getRandomColor() {
    final colors = [
      Colors.red,
      Colors.blue,
      Colors.green,
      Colors.yellow,
      Colors.purple,
      Colors.orange,
      Colors.pink,
      Colors.cyan,
    ];
    return colors[Random().nextInt(colors.length)];
  }
}