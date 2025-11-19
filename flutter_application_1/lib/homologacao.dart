import 'dart:convert';
import 'dart:html' as html; 
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

import 'classes/projeto.dart';
import 'andamento.dart';
import 'perfil.dart';
import 'maisdetalhes.dart';
import 'a_fazer.dart';

class Homologacao extends StatefulWidget {
  const Homologacao({super.key});

  @override
  State<Homologacao> createState() => _HomologacaoState();
}

class _HomologacaoState extends State<Homologacao> {
  List<Projeto> _projetos = [];
  List<Projeto> _projetosFiltrados = [];
  bool _loading = true;
  bool _vazio = false;

  int _index = 0;

  
  final GlobalKey _repaintKeyFinal = GlobalKey();
  List<Offset?> _pointsFinal = [];
  bool _desenhando = false; 

  @override
  void initState() {
    super.initState();
    _loadProjetos();
  }

  Future<void> _loadProjetos() async {
    setState(() {
      _loading = true;
      _vazio = false;
    });

    try {
      final raw = html.window.localStorage['projetos'];
      if (raw == null || raw.isEmpty) {
        _projetos = [];
        _projetosFiltrados = [];
        _vazio = true;
        _loading = false;
        setState(() {});
        return;
      }

      final decoded = json.decode(raw);
      final List list = decoded["projetos"] ?? [];

      final loaded = list.map((j) {
        try {
          return Projeto.fromJson(j);
        } catch (_) {
          return null;
        }
      }).whereType<Projeto>().toList();

      _projetos = loaded.where((p) => p.status.toUpperCase() == "HOMOLOGAÇÃO").toList();
      _projetosFiltrados = List.from(_projetos);

      if (_projetosFiltrados.isEmpty) _vazio = true;
    } catch (_) {
      _vazio = true; 
    }

    _loading = false;
    setState(() {});
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

  Widget _campoAssinaturaFinal() {
    return Listener(
      onPointerDown: (details) {
        _desenhando = true;

        final box = _repaintKeyFinal.currentContext!.findRenderObject() as RenderBox;
        final localPos = box.globalToLocal(details.position);

        _pointsFinal.add(localPos);
        setState(() {});
      },
      onPointerMove: (details) {
        if (!_desenhando) return;

        final box = _repaintKeyFinal.currentContext!.findRenderObject() as RenderBox;
        final localPos = box.globalToLocal(details.position);

        _pointsFinal.add(localPos);
        setState(() {});
      },
      onPointerUp: (_) {
        _desenhando = false;
        _pointsFinal.add(null);
        setState(() {});
      },
      child: RepaintBoundary(
        key: _repaintKeyFinal,
        child: Container(
          height: 180,
          width: double.infinity,
          decoration: BoxDecoration(
            color: const Color.fromARGB(255, 226, 225, 225),
            border: Border.all(color: Colors.black54),
          ),
          child: CustomPaint(
            painter: _SignaturePainter(_pointsFinal),
            child: const SizedBox.expand(),
          ),
        ),
      ),
    );
  }

  void _limparAssinaturaFinal() {
    setState(() {
      _pointsFinal = [];
    });
  }

  Future<String?> _capturarAssinaturaFinalBase64() async {
    if (_pointsFinal.isEmpty) return null;

    try {
      final boundary =
          _repaintKeyFinal.currentContext!.findRenderObject() as RenderRepaintBoundary;

      final ui.Image image = await boundary.toImage(pixelRatio: 3.0);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      final pngBytes = byteData!.buffer.asUint8List();

      return base64Encode(pngBytes);
    } catch (e) {
      return null;
    }
  }

  Future<void> _finalizarHomologacao(String idProjeto) async {
    if (_pointsFinal.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Assine no campo antes de finalizar!")),
      );
      return;
    }

    final assinaturaBase64 = await _capturarAssinaturaFinalBase64();
    if (assinaturaBase64 == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Erro ao gerar assinatura.")),
      );
      return;
    }

    final raw = html.window.localStorage['projetos'];
    if (raw == null) return;

    final decoded = json.decode(raw);
    final List lista = decoded["projetos"] ?? [];

    for (int i = 0; i < lista.length; i++) {
      final item = Map<String, dynamic>.from(lista[i]);

      if (item["idProjeto"] == idProjeto) {
        item["assinaturaFinal"] = assinaturaBase64;
        item["status"] = "CONCLUÍDO";
        item["dataHomologacao"] = DateTime.now().toIso8601String();

        lista[i] = item;
        break;
      }
    }

    html.window.localStorage["projetos"] = json.encode({"projetos": lista});

    _limparAssinaturaFinal();
    await _loadProjetos();

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Homologação concluída!")),
    );
  }

  Widget _imgBase64(String base64str) {
    if (base64str.isEmpty) {
      return const Text(
        "Nenhuma assinatura.",
        style: TextStyle(color: Colors.white54),
      );
    }

    try {
      String raw = base64str.contains(",") ? base64str.split(",").last : base64str;
      final bytes = base64Decode(raw);

      return Container(
        width: 260,
        height: 120,
        decoration: BoxDecoration(border: Border.all(color: Colors.white70)),
        child: Image.memory(bytes, fit: BoxFit.contain),
      );
    } catch (e) {
      return const Text("Assinatura inválida", style: TextStyle(color: Colors.red));
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        backgroundColor: Colors.black,
        body: Center(child: CircularProgressIndicator(color: Colors.white)),
      );
    }

    if (_vazio || _projetosFiltrados.isEmpty) {
      return Scaffold(
        backgroundColor: Colors.black,
        body: SafeArea(
          child: Column(
            children: [
              const SizedBox(height: 10),
              SizedBox(width: 340, height: 33, child: _barraPesquisa()),
              const SizedBox(height: 15),
              _title(),
              const SizedBox(height: 20),
              const Expanded(
                child: Center(
                  child: Text(
                    "Nenhum projeto em homologação",
                    style: TextStyle(color: Colors.white, fontSize: 16),
                  ),
                ),
              ),

              Padding(
                padding: const EdgeInsets.only(bottom: 15),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    IconButton(
                      onPressed: () {},
                      icon: const Icon(Icons.keyboard_arrow_up_outlined, color: Colors.white),
                    ),
                    IconButton(
                      onPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const Perfil(emailLogado: 'eduardo@portalsz.com')),
                      ),
                      icon: const Icon(Icons.person, color: Colors.white, size: 26),
                    ),
                    IconButton(
                      onPressed: () {},
                      icon: const Icon(Icons.keyboard_arrow_down_outlined, color: Colors.white),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10),
            ],
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
                physics: _desenhando
                    ? const NeverScrollableScrollPhysics()
                    : const BouncingScrollPhysics(),
                padding: const EdgeInsets.only(bottom: 15),
                child: Column(
                  children: [
                    const SizedBox(height: 10),
                    SizedBox(width: 340, height: 33, child: _barraPesquisa()),
                    const SizedBox(height: 10),

                    _title(),

                    const SizedBox(height: 25),

                    _info(p),
                    const SizedBox(height: 20),

                    _foto(p),
                    const SizedBox(height: 20),

                    _btnDetalhes(p),

                    const SizedBox(height: 30),

                    const Text("Assinatura Administrador",
                        style: TextStyle(color: Colors.white70)),
                    const SizedBox(height: 10),
                    _imgBase64(p.assinaturaAprovador),

                    const SizedBox(height: 35),

                    const Text("Assinatura Final",
                        style: TextStyle(color: Colors.white70)),
                    const SizedBox(height: 12),

                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 32),
                      child: _campoAssinaturaFinal(),
                    ),

                    const SizedBox(height: 10),
                    TextButton(
                      onPressed: _limparAssinaturaFinal,
                      child: const Text("Limpar Assinatura",
                          style: TextStyle(color: Colors.white70)),
                    ),

                    if (p.assinaturaFinal.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      const Text("Assinatura Final (registrada):",
                          style: TextStyle(color: Colors.white70)),
                      const SizedBox(height: 8),
                      _imgBase64(p.assinaturaFinal),
                    ],

                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),

            _bottomButtons(p),
            const SizedBox(height: 10),
          ],
        ),
      ),
    );
  }

  Widget _bottomButtons(Projeto p) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            IconButton(
              onPressed: () {
                setState(() {
                  _index =
                      (_index - 1 + _projetosFiltrados.length) % _projetosFiltrados.length;
                });
              },
              icon: const Icon(Icons.keyboard_arrow_up_outlined,
                  color: Colors.white),
            ),
            IconButton(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (_) =>
                        const Perfil(emailLogado: "eduardo@portalsz.com"))),
              icon: const Icon(Icons.person, color: Colors.white, size: 28),
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
        const SizedBox(height: 10),
        SizedBox(
          width: 260,
          child: ElevatedButton(
            style: _btnStyle(),
            onPressed: () => _finalizarHomologacao(p.idProjeto),
            child: const Text(
              "FINALIZAR HOMOLOGAÇÃO",
              style: TextStyle(color: Colors.white),
            ),
          ),
        ),
      ],
    );
  }

  Widget _title() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (_) => const Andamento()),
            );
          },
        ),
        const Text(
          "HOMOLOGAÇÃO",
          style: TextStyle(
              color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
        ),
        IconButton(
          icon: const Icon(Icons.arrow_forward, color: Colors.white),
          onPressed: () {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (_) => const AFazer()),
            );
          },
        ),
      ],
    );
  }

  Widget _foto(Projeto p) {
    return Image.asset(
      p.imagem,
      height: 240,
      fit: BoxFit.cover,
      errorBuilder: (_, __, ___) =>
          const Icon(Icons.error, color: Colors.redAccent),
    );
  }

  Widget _info(Projeto p) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        children: [
          _linha("PROJETO ID", p.idProjeto),
          _linha("FABRICAÇÃO", p.fabricacao),
          _linha("POTÊNCIA", p.potencia),
          _linha("ACELERAÇÃO", p.aceleracao),
          _linha("VEL. MÁXIMA", p.velMax),
          _linha("FABRICANTE", p.fabricante),
          _linha("PAÍS", p.pais),
          _linha("COR", p.cor),
          _linha("MODELO", p.modelo),
        ],
      ),
    );
  }

  Widget _btnDetalhes(Projeto p) {
    return SizedBox(
      width: 200,
      child: ElevatedButton(
        style: _btnStyle(),
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
                builder: (_) =>
                    Detalhes(idProjeto: p.idProjeto, modelo: p.modelo)),
          );
        },
        child:
            const Text("MAIS DETALHES", style: TextStyle(color: Colors.white)),
      ),
    );
  }

  Widget _linha(String t, String v) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(t,
              style: const TextStyle(
                  color: Colors.white70,
                  fontWeight: FontWeight.bold,
                  fontSize: 13)),
          Text(v, style: const TextStyle(color: Colors.white, fontSize: 13)),
        ],
      ),
    );
  }

  Widget _barraPesquisa() {
    return TextField(
      onChanged: _filtrar,
      style: const TextStyle(color: Colors.white, fontSize: 13),
      decoration: InputDecoration(
        hintText: "Pesquisar por ID",
        hintStyle: const TextStyle(color: Colors.white54, fontSize: 12),
        prefixIcon: const Icon(Icons.search, color: Colors.white, size: 16),

        filled: true,
        fillColor: const Color.fromRGBO(80, 80, 80, 1),

        contentPadding: const EdgeInsets.symmetric(vertical: 2, horizontal: 10),

        border: OutlineInputBorder(
          borderRadius: BorderRadius.zero,
          borderSide: const BorderSide(color: Colors.white, width: 1),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.zero,
          borderSide: const BorderSide(color: Colors.white, width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.zero,
          borderSide: const BorderSide(color: Colors.white, width: 1),
        ),
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

class _SignaturePainter extends CustomPainter {
  final List<Offset?> points;

  _SignaturePainter(this.points);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.black
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;

    for (int i = 0; i < points.length - 1; i++) {
      final p1 = points[i];
      final p2 = points[i + 1];

      if (p1 != null && p2 != null) {
        canvas.drawLine(p1, p2, paint);
      }
    }
  }

  @override
  bool shouldRepaint(_) => true;
}
