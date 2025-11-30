import 'dart:convert';
import 'dart:html' as html;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'login.dart';

class Perfil extends StatefulWidget {
  final String emailLogado;
  const Perfil({super.key, required this.emailLogado});

  @override
  State<Perfil> createState() => _PerfilState();
}

class _PerfilState extends State<Perfil> {
  Map<String, dynamic>? _func;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadFuncionario();
  }

  Future<void> _loadFuncionario() async {
    final raw = await rootBundle.loadString('assets/logins.json');
    final data = json.decode(raw) as Map<String, dynamic>;

    final funcs = (data['funcionarios'] as List).cast<Map<String, dynamic>>();

    _func = funcs.firstWhere(
      (f) => f['email'] == widget.emailLogado,
      orElse: () => {},
    );

    setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        backgroundColor: Colors.black,
        body: Center(child: CircularProgressIndicator(color: Colors.white)),
      );
    }

    if (_func == null || _func!.isEmpty) {
      return Scaffold(
        backgroundColor: Colors.black,
        body: const Center(
          child: Text(
            'Funcionário não encontrado',
            style: TextStyle(color: Colors.white),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white),
                    onPressed: () => Navigator.pop(context),
                  ),
                  IconButton(
                    icon: const Icon(Icons.logout, color: Colors.white),
                    onPressed: () {
                      html.window.localStorage.remove('emailLogado');
                      html.window.localStorage.remove('cargo');

                      Navigator.pushAndRemoveUntil(
                        context,
                        MaterialPageRoute(builder: (_) => const Login()),
                        (_) => false,
                      );
                    },
                  ),
                ],
              ),

              const SizedBox(height: 16),

              const Icon(Icons.person, color: Colors.white, size: 70),
              const SizedBox(height: 8),

              Text(
                _func!['nomeFunc'],
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 20,
                ),
              ),

              Text(
                _func!['cargo'].toString().toUpperCase(),
                style: const TextStyle(color: Colors.grey),
              ),

              const SizedBox(height: 24),

              _info('NOME COMPLETO', _func!['nomeFunc']),
              _info('DATA DE NASCIMENTO', _func!['dataNasc']),
              _info('TELEFONE/WHATSAPP', _func!['telefone']),
              _info('E-MAIL', _func!['email']),
              _info('TEMPO DE ATUAÇÃO', _func!['tempoAtuacao']),
              _info('PROJETOS CONCLUÍDOS', _func!['projetosConcluidos'].toString()),
              _info('PROJETOS REPROVADOS', _func!['projetosReprovados'].toString()),

              const SizedBox(height: 20),

              const Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'AVALIAÇÕES',
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(height: 6),

              Row(
                children: _buildStars(_func!['avaliacao']),
              ),

              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _info(String titulo, String valor) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            titulo,
            style: const TextStyle(
              color: Colors.grey,
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
          Text(
            valor,
            style: const TextStyle(color: Colors.white, fontSize: 13),
          ),
        ],
      ),
    );
  }


  List<Widget> _buildStars(double rating) {
    List<Widget> stars = [];

    for (int i = 1; i <= 5; i++) {
      if (rating >= i) {
        stars.add(const Icon(Icons.star, color: Colors.white));
      } else if (rating >= i - 0.5) {
        stars.add(const Icon(Icons.star_half, color: Colors.white));
      } else {
        stars.add(const Icon(Icons.star_border, color: Colors.white));
      }
    }

    return stars;
  }
}
