import 'dart:convert';
import 'dart:html' as html;
import 'package:flutter/material.dart';
import 'classes/projeto.dart';
import 'a_fazer.dart';
import 'homologacao.dart';
import 'maisdetalhes.dart';
import 'perfil.dart';
import 'login.dart'; 

class Andamento extends StatefulWidget {
  final String? idInicial;

  const Andamento({super.key, this.idInicial});

  @override
  State<Andamento> createState() => _AndamentoState();
}

class _AndamentoState extends State<Andamento> {
  List<Projeto> _projetos = [];
  List<Projeto> _projetosFiltrados = [];

  List<Map<String, dynamic>> _todosProjetos = [];
  List<Map<String, dynamic>> _sugestoes = [];

  bool _loading = true;
  bool _vazio = false;
  bool _loadError = false;

  int _index = 0;

  @override
  void initState() {
    super.initState();
    _loadProjetos();
  }

  bool get isMecanico {
    final cargo = (html.window.localStorage['cargo'] ?? '').toString();
    return cargo.toLowerCase() == 'mecanico';
  }

  Future<void> _loadProjetos() async {
    setState(() {
      _loading = true;
      _vazio = false;
      _loadError = false;
      _sugestoes = [];
    });

    try {
      final raw = html.window.localStorage['projetos'];

      if (raw == null || raw.trim().isEmpty) {
        _todosProjetos = [];
        _projetos = [];
        _projetosFiltrados = [];
        _vazio = true;
        if (mounted) setState(() => _loading = false);
        return;
      }

      final decoded = json.decode(raw);
      final List lista = decoded is Map && decoded.containsKey('projetos')
          ? List.from(decoded['projetos'])
          : [];

      _todosProjetos =
          lista.map<Map<String, dynamic>>((e) => Map<String, dynamic>.from(e)).toList();

      final loaded = lista.map((j) {
        try {
          return Projeto.fromJson(Map<String, dynamic>.from(j));
        } catch (_) {
          return null;
        }
      }).whereType<Projeto>().toList();

      _projetos = loaded
          .where((p) => p.status.toString().toUpperCase().contains('ANDAMENTO'))
          .toList();

      _projetosFiltrados = List.from(_projetos);

      if (widget.idInicial != null && widget.idInicial!.trim().isNotEmpty) {
        final idNorm = widget.idInicial!.trim();
        final pos =
            _projetos.indexWhere((p) => p.idProjeto.toString().trim() == idNorm);

        if (pos != -1) {
          _index = pos;
        }
      }

      if (_projetos.isEmpty) _vazio = true;
    } catch (e) {
      _loadError = true;
    }

    if (mounted) setState(() => _loading = false);
  }

  void _filtrar(String valor) {
    final q = valor.trim();
    if (q.isEmpty) {
      setState(() {
        _sugestoes = [];
        _index = 0;
      });
      return;
    }

    final numero = int.tryParse(q);
    final idxLocal = _projetos.indexWhere((p) =>
        p.idProjeto.toString() == q ||
        (numero != null && p.idProjeto == numero));

    if (idxLocal != -1) {
      setState(() {
        _sugestoes = [];
        _index = idxLocal;
      });
      return;
    }

    final resultados = _todosProjetos.where((item) {
      final id = item['idProjeto']?.toString() ?? '';
      final modelo = item['modelo']?.toString() ?? '';
      return id.contains(q) ||
          modelo.toLowerCase().contains(q.toLowerCase());
    }).toList();

    setState(() {
      _sugestoes = resultados.take(8).toList();
    });
  }

  void _abrirSugestao(Map<String, dynamic> item) {
    setState(() => _sugestoes = []);
    final id = (item['idProjeto']?.toString() ?? '').trim();
    final status = (item['status']?.toString() ?? '').toUpperCase();

    if (status.contains("A FAZER")) {
      if (isMecanico) {
        setState(() => _sugestoes = []);
        return;
      }

      Navigator.pushReplacement(
          context, MaterialPageRoute(builder: (_) => AFazer(idInicial: id)));
      return;
    }

    if (status.contains("ANDAMENTO")) {
      final pos =
          _projetos.indexWhere((p) => p.idProjeto.toString().trim() == id);
      if (pos != -1) {
        setState(() => _index = pos);
      } else {
        Navigator.pushReplacement(context,
            MaterialPageRoute(builder: (_) => Andamento(idInicial: id)));
      }
      return;
    }

    if (status.contains("HOMOLOG")) {
      Navigator.pushReplacement(context,
          MaterialPageRoute(builder: (_) => Homologacao(idInicial: id)));
      return;
    }
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

    for (int i = 0; i < projetos.length; i++) {
      try {
        Map<String, dynamic> item = Map<String, dynamic>.from(projetos[i]);
        if (item['idProjeto'] == idProjeto) {
          Map<String, dynamic> atualizado = Map.from(item);
          atualizado['status'] = "HOMOLOGAÇÃO";
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
          break;
        }
      } catch (_) {}
    }

    html.window.localStorage['projetos'] =
        json.encode({'projetos': projetos});

    _loadProjetos().then((_) {
      if (isMecanico) {
        showDialog(
          context: context,
          builder: (_) => AlertDialog(
            backgroundColor: Colors.black,
            title: const Text(
              "Projeto enviado",
              style: TextStyle(color: Colors.white),
            ),
            content: const Text(
              "O projeto foi enviado para homologação.",
              style: TextStyle(color: Colors.white70),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text("OK", style: TextStyle(color: Colors.white)),
              ),
            ],
          ),
        );
      } else {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const Homologacao()),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        backgroundColor: Colors.black,
        body: Center(
            child: CircularProgressIndicator(
          color: Colors.white,
        )),
      );
    }


    _ajustarIndex();
    final p = _projetosFiltrados[_index];

    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 8),

            SizedBox(width: 340, height: 36, child: _barraPesquisa()),

            const SizedBox(height: 6),

            if (_sugestoes.isNotEmpty)
              Container(
                width: 340,
                constraints: const BoxConstraints(maxHeight: 220),
                decoration: BoxDecoration(
                    color: const Color(0xFF2E2E2E),
                    border: Border.all(color: Colors.white12)),
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: _sugestoes.length,
                  itemBuilder: (_, i) {
                    final item = _sugestoes[i];
                    final img = (item['imagem']?.toString() ?? '');
                    final id = (item['idProjeto']?.toString() ?? '');
                    final status = (item['status']?.toString() ?? '');

                    return ListTile(
                      leading: img.isNotEmpty
                          ? Image.asset(
                              img,
                              width: 52,
                              height: 36,
                              fit: BoxFit.cover,
                            )
                          : const Icon(Icons.image, color: Colors.white54),
                      title: Text('ID $id',
                          style: const TextStyle(color: Colors.white)),
                      subtitle: Text(status,
                          style: const TextStyle(
                              color: Colors.white54, fontSize: 12)),
                      onTap: () => _abrirSugestao(item),
                    );
                  },
                ),
              ),

            const SizedBox(height: 10),

            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (!isMecanico)
                  IconButton(
                    icon: const Icon(Icons.arrow_back, color: Colors.white),
                    onPressed: () => Navigator.pushReplacement(context,
                        MaterialPageRoute(builder: (_) => const AFazer())),
                  ),

                const Text(
                  'EM ANDAMENTO',
                  style: TextStyle(
                      color: Colors.white, fontWeight: FontWeight.bold),
                ),

                if (!isMecanico)
                  IconButton(
                    icon: const Icon(Icons.arrow_forward, color: Colors.white),
                    onPressed: () => Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                            builder: (_) => const Homologacao())),
                  ),
              ],
            ),

            const SizedBox(height: 12),

            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.only(bottom: 10),
                child: Column(
                  children: [
                    const SizedBox(height: 2),
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
                    ),

                    const SizedBox(height: 10),

                    Text(p.modelo,
                        style: const TextStyle(
                            color: Colors.white70, fontSize: 14)),
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
                                    builder: (_) => Detalhes(
                                        idProjeto: p.idProjeto,
                                        modelo: p.modelo)));
                          },
                          child: const Text('MAIS DETALHES',
                              style: TextStyle(color: Colors.white)),
                        ),
                      ),
                    ),

                    const SizedBox(height: 12),

                    ElevatedButton(
                      style: _btnStyle(),
                      onPressed: () => _marcarComoConcluido(p.idProjeto),
                      child: const Text('PROJETO CONCLUÍDO',
                          style: TextStyle(color: Colors.white)),
                    ),

                    const SizedBox(height: 12),
                  ],
                ),
              ),
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
                    onPressed: () {
                      final email = (html.window.localStorage['emailLogado'] ?? '').toString();
                      if (email.isEmpty) {
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(builder: (_) => const Login()),
                        );
                        return;
                      }
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => Perfil(emailLogado: email)),
                      );
                    },
                    icon: const Icon(Icons.person, color: Colors.white, size: 26),
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

            const SizedBox(height: 8),
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
            borderSide: const BorderSide(color: Colors.white)),
        enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.zero,
            borderSide: const BorderSide(color: Colors.white)),
        focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.zero,
            borderSide: const BorderSide(color: Colors.white)),
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
                style:
                    const TextStyle(color: Colors.white, fontSize: 13)),
          ]),
    );
  }

  ButtonStyle _btnStyle() {
    return ElevatedButton.styleFrom(
      backgroundColor: Colors.transparent,
      side: const BorderSide(color: Colors.white, width: 1.2),
      padding:
          const EdgeInsets.symmetric(horizontal: 30, vertical: 12),
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(5)),
    );
  }
}
