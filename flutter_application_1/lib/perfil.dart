import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;

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
    _func = funcs.firstWhere((f) => f['email'] == widget.emailLogado, orElse: () => {});
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
        body: Center(
          child: Text('Funcionário não encontrado', style: const TextStyle(color: Colors.white)),
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
                  const Icon(Icons.edit_note, color: Colors.white),
                ],
              ),
              const SizedBox(height: 16),
              const Icon(Icons.person, color: Colors.white, size: 70),
              const SizedBox(height: 8),
              Text('${_func!['nomeFunc']}, Souza',
                  style: const TextStyle(
                      color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
              const Text('MECÂNICO', style: TextStyle(color: Colors.grey)),
              const SizedBox(height: 24),

              _info('NOME COMPLETO', 'Marcos Silva de Andrade'),
              _info('DATA DE NASCIMENTO', '31/01/1997'),
              _info('TELEFONE/WHATSAPP', '(11) 91234-5678'),
              _info('E-MAIL', _func!['email']),
              _info('TEMPO DE ATUAÇÃO', '1 ano e 3 meses'),
              _info('PROJETOS CONCLUÍDOS', '6'),
              _info('PROJETOS APROVADOS', _func!['pedidosAprovados'].length.toString()),
              _info('PROJETOS REPROVADOS', '1'),
              const SizedBox(height: 20),

              const Align(
                alignment: Alignment.centerLeft,
                child: Text('AVALIAÇÕES',
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              ),
              const SizedBox(height: 6),
              const Row(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  Icon(Icons.star, color: Colors.white),
                  Icon(Icons.star, color: Colors.white),
                  Icon(Icons.star, color: Colors.white),
                  Icon(Icons.star_half, color: Colors.white),
                  Icon(Icons.star_border, color: Colors.white),
                ],
              ),
              const SizedBox(height: 20),

              const Align(
                alignment: Alignment.centerLeft,
                child: Text('REDES SOCIAIS',
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              ),
              const SizedBox(height: 6),
              const Row(
                children: [
                  Icon(Icons.camera_alt_outlined, color: Colors.white),
                  SizedBox(width: 12),
                  Icon(Icons.facebook, color: Colors.white),
                ],
              ),
              const SizedBox(height: 30),

              ElevatedButton(
                onPressed: () {},
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.black,
                  side: const BorderSide(color: Colors.white),
                  shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
                  padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 12),
                ),
                child: const Text('EDITAR INFORMAÇÕES',
                    style: TextStyle(color: Colors.white, letterSpacing: 0.5)),
              ),
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
          Text(titulo,
              style: const TextStyle(color: Colors.grey, fontWeight: FontWeight.bold, fontSize: 12)),
          Text(valor, style: const TextStyle(color: Colors.white, fontSize: 13)),
        ],
      ),
    );
  }
}
