import 'dart:async';
import 'package:flutter/material.dart';

import 'login.dart';
import 'a_fazer.dart';
import 'andamento.dart';
import 'homologacao.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      routes: {
        '/a_fazer': (context) => const AFazer(),
        '/andamento': (context) => const Andamento(),
        '/homologacao': (context) => const Homologacao(),
        '/login': (context) => const Login(),
      },
      home: const SplashScreen(),
    );
  }
}

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _larguraAnimada;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );

    _larguraAnimada = Tween<double>(begin: 25, end: 240).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeInOutCubic,
      ),
    );

    _controller.forward();

    WidgetsBinding.instance.addPostFrameCallback((_) {
  Future.delayed(const Duration(milliseconds: 2000), () { 
    if (mounted) {
      Navigator.pushReplacementNamed(context, '/login');
    }
  });
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
      backgroundColor: Colors.black,
      body: Center(
        child: AnimatedBuilder(
          animation: _larguraAnimada,
          builder: (context, _) {
            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // SZ FIXO
                Image.asset(
                  'img/szsem.png',
                  height: 85, 
                ),

                const SizedBox(height: 8),

                SizedBox(
                  height: 28,
                  width: _larguraAnimada.value,
                  child: Image.asset(
                    'img/barra.png',
                    fit: BoxFit.fill,
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
