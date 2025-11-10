// ignore_for_file: use_super_parameters

import 'dart:async';
import 'package:flutter/material.dart';

class LoginScreen extends StatefulWidget {
  final VoidCallback onFinishSplash;
  const LoginScreen({Key? key, required this.onFinishSplash}) : super(key: key);

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000), // Reduced from 2 seconds to 1 second
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeIn),
    );

    _scaleAnimation = Tween<double>(begin: 0.9, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );

    _controller.forward();

    // Reduced total waiting time to 1.7 seconds (from 3 seconds)
    Timer(const Duration(milliseconds: 1700), () {
      widget.onFinishSplash();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 255, 240, 218), // Beige background
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: ScaleTransition(
          scale: _scaleAnimation,
          child: Center(
            child: Image.asset(
              'images/moneyhive_logo.jpg',
              width: MediaQuery.of(context).size.width * 0.9, // Covers 90% width
              height: MediaQuery.of(context).size.height * 0.9, // Covers 90% height
              fit: BoxFit.contain, // Keeps aspect ratio without cropping
            ),
          ),
        ),
      ),
    );
  }
}