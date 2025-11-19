import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:carousel_slider/carousel_slider.dart';

class Detalhes extends StatefulWidget {
  final String idProjeto;
  final String modelo;
  final double borderRadius; 

  const Detalhes({
    super.key,
    required this.idProjeto,
    required this.modelo,
    this.borderRadius = 0, 
  });

  @override
  State<Detalhes> createState() => _DetalhesState();
}

class _DetalhesState extends State<Detalhes> {
  Map<String, dynamic>? _projeto;
  bool _loading = true;

  List<String> imagensExteriores = [];
  List<String> imagensInteriores = [];

  @override
  void initState() {
    super.initState();
    _loadProjeto();
    _carregarImagens();
  }

  Future<void> _loadProjeto() async {
    final raw = await rootBundle.loadString('assets/projeto.json');
    final data = json.decode(raw) as Map<String, dynamic>;
    final projetos = (data['projetos'] as List).cast<Map<String, dynamic>>();
    _projeto =
        projetos.firstWhere((p) => p['idProjeto'] == widget.idProjeto, orElse: () => {});
    setState(() => _loading = false);
  }

  void _carregarImagens() {
    final todas = [
      'img/final_exterior_cinco.png',
      'img/final_exterior_dez.png',
      'img/final_exterior_dois.png',
      'img/final_exterior_nove.png',
      'img/final_exterior_oito.png',
      'img/final_exterior_onze.png',
      'img/final_exterior_quatro.png',
      'img/final_exterior_seis.png',
      'img/final_exterior_sete.png',
      'img/final_exterior_tres.png',
      'img/final_interior_cinco.png',
      'img/final_interior_quatro.png',
      'img/final_interior_seis.png',
      'img/final_interior_um.png',
      'img/final_interior_tres.png',
      'img/final.png',
      'img/final_dois.png',
      'img/final_um.png',
    ];

    imagensExteriores = todas.where((e) => !e.contains('interior')).toList();
    imagensInteriores = todas.where((e) => e.contains('interior')).toList();
  }

  Widget _carrossel(List<String> imagens) {
    return CarouselSlider(
      options: CarouselOptions(
        autoPlay: true,
        height: 240,
        viewportFraction: 1.0,
        enableInfiniteScroll: true,
      ),
      items: imagens
          .map((img) => Image.asset(img, fit: BoxFit.contain, width: double.infinity))
          .toList(),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        backgroundColor: Colors.black,
        body: Center(child: CircularProgressIndicator(color: Colors.white)),
      );
    }

    if (_projeto == null || _projeto!.isEmpty) {
      return Scaffold(
        backgroundColor: Colors.black,
        body: Center(
          child: Text(
            'Projeto não encontrado',
            style: const TextStyle(color: Colors.white),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
                    onPressed: () => Navigator.pop(context),
                  ),
                  Text(
                    widget.modelo.toUpperCase(),
                    style: const TextStyle(
                        color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
                  ),
                  const SizedBox(width: 48),
                ],
              ),
              Center(
                child: Text(
                  '#${_projeto!['idProjeto']}',
                  style: const TextStyle(color: Colors.grey),
                ),
              ),
              const SizedBox(height: 20),

              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 4),
                child: Text('EXTERNO GERAL',
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              ),
              const SizedBox(height: 8),
              _carrossel(imagensExteriores),

              const SizedBox(height: 30),

              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 4),
                child: Text('INTERNO GERAL',
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              ),
              const SizedBox(height: 8),
              _carrossel(imagensInteriores),

              const SizedBox(height: 40),

              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}
