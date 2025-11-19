import 'dart:convert';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'dart:html' as html;

class Assinatura extends StatefulWidget {
  final String idProjeto;
  final bool aprovado;
  final String emailUsuario;

  const Assinatura({
    super.key,
    required this.idProjeto,
    required this.aprovado,
    required this.emailUsuario,
  });

  @override
  State<Assinatura> createState() => _AssinaturaState();
}

class _AssinaturaState extends State<Assinatura> {
  final GlobalKey _repaintKey = GlobalKey();
  List<Offset?> _points = [];
  bool _salvando = false;

  Map<String, dynamic> _readLocalJson(String key) {
    final raw = html.window.localStorage[key];
    if (raw == null) return {};
    try {
      return json.decode(raw);
    } catch (_) {
      return {};
    }
  }

  void _writeLocalJson(String key, Map<String, dynamic> map) {
    html.window.localStorage[key] = json.encode(map);
  }

  Future<void> _salvarAssinatura() async {
    if (_points.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Faça sua assinatura antes")),
      );
      return;
    }

    setState(() => _salvando = true);

    try {
      final boundary = _repaintKey.currentContext!.findRenderObject()
          as RenderRepaintBoundary;

      final ui.Image image = await boundary.toImage(pixelRatio: 3.0);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      final pngBytes = byteData!.buffer.asUint8List();
      final assinaturaBase64 = base64Encode(pngBytes);

      Map<String, dynamic> logins = _readLocalJson("logins");

      logins["funcionarios"] ??= [];
      bool achou = false;

      for (var user in logins["funcionarios"]) {
        if (user["email"] == widget.emailUsuario) {
          user["assinaturaBase64"] = assinaturaBase64;

          if (widget.aprovado) {
            user["pedidosAprovados"] ??= [];
            if (!user["pedidosAprovados"].contains(widget.idProjeto)) {
              user["pedidosAprovados"].add(widget.idProjeto);
            }
          }
          achou = true;
          break;
        }
      }

      if (!achou) {
        logins["funcionarios"].add({
          "email": widget.emailUsuario,
          "assinaturaBase64": assinaturaBase64,
          "pedidosAprovados": widget.aprovado ? [widget.idProjeto] : [],
        });
      }

      _writeLocalJson("logins", logins);

      Map<String, dynamic> projetos =
          _readLocalJson("projetos"); 

      projetos["projetos"] ??= [];

      for (var p in projetos["projetos"]) {
        if (p["idProjeto"].toString() == widget.idProjeto.toString()) {
          p["status"] = widget.aprovado ? "EM ANDAMENTO" : "REPROVADO";
          p["assinaturaAprovador"] = assinaturaBase64;
          p["emailAprovador"] = widget.emailUsuario;
          break;
        }
      }

      _writeLocalJson("projetos", projetos); 

      if (mounted) {
        Navigator.pop(context, {
          "salvo": true,
          "aprovado": widget.aprovado,
          "idProjeto": widget.idProjeto,
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Erro ao salvar: $e")),
      );
    } finally {
      setState(() => _salvando = false);
    }
  }

  void _limpar() => setState(() => _points = []);

  @override
  Widget build(BuildContext context) {
    final titulo =
        widget.aprovado ? "Confirmar aprovação" : "Confirmar reprovação";

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: Text(widget.aprovado ? "Aprovação" : "Reprovação"),
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          const SizedBox(height: 10),
          Text(
            "Assine abaixo — usuário: ${widget.emailUsuario}",
            style: const TextStyle(color: Colors.white70),
          ),
          const SizedBox(height: 10),

          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: RepaintBoundary(
                key: _repaintKey,
                child: Container(
                  color: const ui.Color.fromARGB(255, 226, 225, 225),
                  child: GestureDetector(
                    behavior: HitTestBehavior.translucent,
                    onPanStart: (details) {
                      final box = _repaintKey.currentContext!
                          .findRenderObject() as RenderBox;
                      _points.add(
                          box.globalToLocal(details.globalPosition));
                      setState(() {});
                    },
                    onPanUpdate: (details) {
                      final box = _repaintKey.currentContext!
                          .findRenderObject() as RenderBox;
                      _points.add(
                          box.globalToLocal(details.globalPosition));
                      setState(() {});
                    },
                    onPanEnd: (_) {
                      _points.add(null);
                      setState(() {});
                    },
                    child: CustomPaint(
                      painter: _SignaturePainter(_points),
                      child: const SizedBox.expand(),
                    ),
                  ),
                ),
              ),
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: _salvarAssinatura,
                    style: OutlinedButton.styleFrom(
                      backgroundColor:
                          const ui.Color.fromARGB(255, 197, 196, 196),
                      side: const BorderSide(
                          color: Colors.black, width: 1.5),
                      shape: const RoundedRectangleBorder(
                          borderRadius: BorderRadius.zero),
                    ),
                    child: Text(
                      titulo,
                      style: const TextStyle(color: Colors.black),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                OutlinedButton(
                  onPressed: _limpar,
                  style: OutlinedButton.styleFrom(
                    backgroundColor:
                        const ui.Color.fromARGB(255, 197, 196, 196),
                    side: const BorderSide(
                        color: Colors.black, width: 1.5),
                    shape: const RoundedRectangleBorder(
                        borderRadius: BorderRadius.zero),
                  ),
                  child: const Text(
                    "Limpar",
                    style: TextStyle(color: Colors.black),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
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
      if (points[i] != null && points[i + 1] != null) {
        canvas.drawLine(points[i]!, points[i + 1]!, paint);
      }
    }
  }

  @override
  bool shouldRepaint(_) => true;
}