import 'dart:convert';
import 'dart:html' as html;
import 'package:flutter/material.dart';

import 'classes/projeto.dart';
import 'a_fazer.dart';
import 'homologacao.dart';
import 'maisdetalhes.dart';
import 'perfil.dart';

class Andamento extends StatefulWidget {
  const Andamento({super.key});

  @override
  State<Andamento> createState() => _AndamentoState();
}

class _AndamentoState extends State<Andamento> {
  List<Projeto> _projetos = [];
  List<Projeto> _projetosFiltrados = [];
  bool _loading = true;
  bool _vazio = false;
  bool _loadError = false;
  int _index = 0;

  @override
  void initState() {
    super.initState();
    _loadProjetos();
  }

  Future<void> _loadProjetos() async {
    setState(() {
      _loading = true;
      _vazio = false;
      _loadError = false;
    });

    try {
      final raw = html.window.localStorage['projetos'];

      if (raw == null || raw.isEmpty) {
        _projetos = [];
        _projetosFiltrados = [];
        _vazio = true;
        if (mounted) setState(() => _loading = false);
        return;
      }

      final decoded = json.decode(raw);

      final List list = decoded is Map && decoded.containsKey('projetos')
          ? decoded['projetos']
          : [];

      final loaded = list.map((j) {
        try {
          return Projeto.fromJson(j);
        } catch (e) {
          debugPrint('[load] Projeto.fromJson falhou: $e -- item: $j');
          return null;
        }
      }).whereType<Projeto>().toList();

      _projetos = loaded
          .where((p) => p.status.toUpperCase() == "EM ANDAMENTO")
          .toList();

      _projetosFiltrados = List.from(_projetos);

      if (_projetos.isEmpty) _vazio = true;
    } catch (e, st) {
      debugPrint('[load] erro ao carregar projetos: $e\n$st');
      _loadError = true;
      _projetos = [];
      _projetosFiltrados = [];
    }

    if (mounted) setState(() => _loading = false);
  }

  void _filtrar(String value) {
    value = value.trim();

    setState(() {
      _projetosFiltrados = _projetos
          .where((p) =>
              p.idProjeto.contains(value) ||
              p.modelo.toLowerCase().contains(value.toLowerCase()))
          .toList();

      _index = 0;
      _ajustarIndex();
    });
  }

  void _ajustarIndex() {
    if (_projetosFiltrados.isEmpty) {
      _index = 0;
      return;
    }
    if (_index >= _projetosFiltrados.length) {
      _index = _projetosFiltrados.length - 1;
    }
  }

  void _marcarComoConcluido(String idProjeto) {
    if (_projetosFiltrados.isEmpty) return;
    final Projeto pTela = _projetosFiltrados[_index];

    List projetos = [];
    try {
      final raw = html.window.localStorage['projetos'];
      if (raw != null && raw.trim().isNotEmpty) {
        final decoded = json.decode(raw);
        if (decoded is Map && decoded.containsKey('projetos')) {
          projetos = List.from(decoded['projetos']);
        }
      }
    } catch (_) {}

    bool encontrou = false;

    for (int i = 0; i < projetos.length; i++) {
      try {
        Map<String, dynamic> item = Map<String, dynamic>.from(projetos[i]);
        final id = item['idProjeto'];

        if (id == idProjeto) {
          Map<String, dynamic> atualizado =
              Map<String, dynamic>.from(item);

          atualizado['status'] = "HOMOLOGAÇÃO";
          atualizado['idProjeto'] = pTela.idProjeto;
          atualizado['fabricacao'] = pTela.fabricacao;
          atualizado['potencia'] = pTela.potencia;
          atualizado['aceleracao'] = pTela.aceleracao;
          atualizado['velMax'] = pTela.velMax;
          atualizado['fabricante'] = pTela.fabricante;
          atualizado['pais'] = pTela.pais;
          atualizado['cor'] = pTela.cor;
          atualizado['modelo'] = pTela.modelo;
          atualizado['imagem'] = pTela.imagem;
          atualizado['mostrarAprovacao'] = pTela.mostrarAprovacao;

          projetos[i] = atualizado;
          encontrou = true;
          break;
        }
      } catch (_) {}
    }

    html.window.localStorage['projetos'] =
        json.encode({'projetos': projetos});

    _loadProjetos().then((_) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const Homologacao()),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        backgroundColor: Colors.black,
        body: Center(child: CircularProgressIndicator(color: Colors.white)),
      );
    }

    if (_loadError) {
      return Scaffold(
        backgroundColor: Colors.black,
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Erro ao ler dados!',
                  style: TextStyle(color: Colors.redAccent)),
              const SizedBox(height: 12),
              ElevatedButton(onPressed: _loadProjetos, child: const Text('Tentar novamente')),
            ],
          ),
        ),
      );
    }

    if (_vazio || _projetosFiltrados.isEmpty) {
      return Scaffold(
        backgroundColor: Colors.black,
        body: SafeArea(
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('Nenhum projeto em andamento.',
                    style: TextStyle(color: Colors.white)),
                const SizedBox(height: 12),
                ElevatedButton(onPressed: _loadProjetos, child: const Text('Recarregar')),
              ],
            ),
          ),
        ),
      );
    }

    _ajustarIndex();
    final p = _projetosFiltrados[_index];

    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.only(bottom: 10),
                child: Column(
                  children: [
                    const SizedBox(height: 8),
                    SizedBox(width: 340, height: 33, child: _barraPesquisa()),
                    const SizedBox(height: 14),

                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.arrow_back, color: Colors.white),
                          onPressed: () => Navigator.pushReplacement(context,
                              MaterialPageRoute(builder: (_) => const AFazer())),
                        ),
                        const Text('EM ANDAMENTO',
                            style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold)),
                        IconButton(
                          icon: const Icon(Icons.arrow_forward, color: Colors.white),
                          onPressed: () => Navigator.pushReplacement(context,
                              MaterialPageRoute(builder: (_) => const Homologacao())),
                        ),
                      ],
                    ),

                    const SizedBox(height: 20),
                    Text('PROJETO ID #${p.idProjeto}',
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold)),
                    const SizedBox(height: 10),

                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 32),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _linha('FABRICAÇÃO', p.fabricacao),
                          _linha('POTÊNCIA', p.potencia),
                          _linha('ACELERAÇÃO', p.aceleracao),
                          _linha('VEL. MÁXIMA', p.velMax),
                          _linha('FABRICANTE', p.fabricante),
                          _linha('PAÍS', p.pais),
                          _linha('COR', p.cor),
                        ],
                      ),
                    ),

                    const SizedBox(height: 10),
                    Image.asset(
                      p.imagem,
                      height: 230,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) =>
                          const Icon(Icons.error, color: Colors.redAccent),
                    ),
                    const SizedBox(height: 10),
                    Text(p.modelo,
                        style:
                            const TextStyle(color: Colors.white70, fontSize: 14)),
                    const SizedBox(height: 12),

                    Center(
                      child: SizedBox(
                        width: 200,
                        child: ElevatedButton(
                          style: _btnStyle(),
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) =>
                                    Detalhes(idProjeto: p.idProjeto, modelo: p.modelo),
                              ),
                            );
                          },
                          child: const Text('MAIS DETALHES',
                              style: TextStyle(color: Colors.white)),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            ElevatedButton(
              style: _btnStyle(),
              onPressed: () => _marcarComoConcluido(p.idProjeto),
              child: const Text('PROJETO CONCLUÍDO',
                  style: TextStyle(color: Colors.white)),
            ),

            Padding(
              padding: const EdgeInsets.only(bottom: 15),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  IconButton(
                    onPressed: () {
                      setState(() {
                        _index =
                            (_index - 1 + _projetosFiltrados.length) %
                                _projetosFiltrados.length;
                      });
                    },
                    icon: const Icon(Icons.keyboard_arrow_up_outlined,
                        color: Colors.white),
                  ),
                  IconButton(
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const Perfil(
                            emailLogado: 'eduardo@portalsz.com'),
                      ),
                    ),
                    icon: const Icon(Icons.person,
                        color: Colors.white, size: 26),
                  ),
                  IconButton(
                    onPressed: () {
                      setState(() {
                        _index = (_index + 1) % _projetosFiltrados.length;
                      });
                    },
                    icon: const Icon(Icons.keyboard_arrow_down_outlined,
                        color: Colors.white),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _barraPesquisa() {
    return TextField(
      onChanged: _filtrar,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        hintText: "Pesquisar por ID",
        hintStyle: const TextStyle(color: Colors.white54, fontSize: 13),
        prefixIcon: const Icon(Icons.search, color: Colors.white, size: 16),
        filled: true,
        fillColor: const Color.fromRGBO(80, 80, 80, 1),
        contentPadding:
            const EdgeInsets.symmetric(vertical: 3, horizontal: 15),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.zero,
          borderSide: const BorderSide(color: Colors.white),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.zero,
          borderSide: const BorderSide(color: Colors.white),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.zero,
          borderSide: const BorderSide(color: Colors.white),
        ),
      ),
    );
  }

  Widget _linha(String titulo, String valor) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(titulo,
              style: const TextStyle(
                  color: Colors.white70,
                  fontWeight: FontWeight.bold,
                  fontSize: 13)),
          Text(valor,
              style: const TextStyle(color: Colors.white, fontSize: 13)),
        ],
      ),
    );
  }

  ButtonStyle _btnStyle() {
    return ElevatedButton.styleFrom(
      backgroundColor: Colors.transparent,
      side: const BorderSide(color: Colors.white, width: 1.2),
      padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(5)),
    );
  }
}
