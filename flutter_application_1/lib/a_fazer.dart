    import 'dart:convert';
    import 'dart:html' as html; 
    import 'package:flutter/material.dart';
    import 'classes/projeto.dart';
    import 'andamento.dart';
    import 'homologacao.dart';
    import 'maisdetalhes.dart';
    import 'perfil.dart';
    import 'assinatura.dart';

    class AFazer extends StatefulWidget {
      const AFazer({super.key});

      @override
      State<AFazer> createState() => _AFazerState();
    }

    class _AFazerState extends State<AFazer> {
      List<Projeto> _projetos = [];
      List<Projeto> _projetosFiltrados = [];
      bool _loading = true;
      bool _vazio = false;
      bool _loadError = false;

      int _index = 0;
      String? emailLogado;

      @override
      void initState() {
        super.initState();
        emailLogado = html.window.localStorage['emailLogado'];
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

          if (raw == null) {
            _vazio = true;
            setState(() => _loading = false);
            return;
          }

          final map = json.decode(raw);

          final list = (map["projetos"] as List)
              .map((j) => Projeto.fromJson(j))
              .where((p) => p.status.toUpperCase() == "A FAZER")
              .toList();

          _projetos = list;
          _projetosFiltrados = List.from(list);

          if (_projetos.isEmpty) _vazio = true;
        } catch (e) {
          _loadError = true;
        }

        if (mounted) setState(() => _loading = false);
      }

      void _atualizarProjetoLocal(String idProjeto, String novoStatus,
          String assinaturaBase64, String emailAprovador) {
        final raw = html.window.localStorage['projetos'];
        if (raw == null) return;

        final map = json.decode(raw);
        final List projetos = map["projetos"];

        for (var item in projetos) {
          if (item["idProjeto"].toString() == idProjeto) {
            item["status"] = novoStatus;
            item["mostrarAprovacao"] = false;
            item["assinaturaAprovador"] = assinaturaBase64;
            item["emailAprovador"] = emailAprovador;
            break;
          }
        }

        html.window.localStorage['projetos'] = json.encode({
          "projetos": projetos,
        });
      }

      Future<void> _abrirAssinatura(Projeto p, bool aprovado) async {
        final result = await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => Assinatura(
              idProjeto: p.idProjeto,
              aprovado: aprovado,
              emailUsuario: emailLogado ?? "",
            ),
          ),
        );

        if (result != null && result is Map && result['salvo'] == true) {
          final aprovadoResult = result['aprovado'] == true;

          final rawLocal = html.window.localStorage['projetos_local'];
          Map projetosMap;

          if (rawLocal != null) {
            projetosMap = json.decode(rawLocal);
          } else {
            final raw = html.window.localStorage['projetos'];
            projetosMap = raw != null ? json.decode(raw) : {"projetos": []};
          }

          String assinaturaBase64 = "";
          String emailAprovador = emailLogado ?? "";

          try {
            final pList = projetosMap['projetos'] as List;
            for (var item in pList) {
              if (item['idProjeto'].toString() == p.idProjeto) {
                assinaturaBase64 = item['assinaturaAprovador'] ?? "";
                emailAprovador = item['emailAprovador'] ?? emailAprovador;
                break;
              }
            }
          } catch (_) {}

          if (aprovadoResult) {
            _atualizarProjetoLocal(
                p.idProjeto, 'EM ANDAMENTO', assinaturaBase64, emailAprovador);

            if (mounted) {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (_) => const Andamento()),
              );
            }
          } else {
            _atualizarProjetoLocal(
                p.idProjeto, 'REPROVADO', assinaturaBase64, emailAprovador);
            await _loadProjetos();
          }
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
        });
      }

      @override
      Widget build(BuildContext context) {
        if (_loading) {
          return const Scaffold(
            backgroundColor: Colors.black,
            body: Center(
              child: CircularProgressIndicator(color: Colors.white),
            ),
          );
        }

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
                              icon: const Icon(Icons.arrow_back,
                                  color: Colors.white),
                              onPressed: null,
                            ),
                            const Text(
                              "A FAZER",
                              style: TextStyle(
                                  color: Colors.white, fontWeight: FontWeight.bold),
                            ),
                            IconButton(
                              icon: const Icon(Icons.arrow_forward,
                                  color: Colors.white),
                              onPressed: () => Navigator.pushReplacement(
                                context,
                                MaterialPageRoute(builder: (_) => const Andamento()),
                              ),
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
                              _linha("FABRICAÇÃO", p.fabricacao),
                              _linha("POTÊNCIA", p.potencia),
                              _linha("ACELERAÇÃO", p.aceleracao),
                              _linha("VEL. MÁXIMA", p.velMax),
                              _linha("FABRICANTE", p.fabricante),
                              _linha("PAÍS", p.pais),
                              _linha("COR", p.cor),
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

                        Text(
                          p.modelo,
                          style:
                              const TextStyle(color: Colors.white70, fontSize: 14),
                        ),
                        

                        const SizedBox(height: 20),

                        if (p.mostrarAprovacao)
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 32),
                            child: Column(
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      child: OutlinedButton(
                                        onPressed: () => _abrirAssinatura(p, true),
                                        style: OutlinedButton.styleFrom(
                                          backgroundColor: Colors.transparent,
                                          side: const BorderSide(
                                              color:
                                                  Color.fromARGB(255, 46, 204, 113),
                                              width: 2),
                                          padding: const EdgeInsets.symmetric(
                                              vertical: 14),
                                          shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(0)),
                                        ),
                                        child: const Text("APROVAR",
                                            style: TextStyle(
                                                color: Colors.white,
                                                fontWeight: FontWeight.bold)),
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: OutlinedButton(
                                        onPressed: () => _abrirAssinatura(p, false),
                                        style: OutlinedButton.styleFrom(
                                          backgroundColor: Colors.transparent,
                                          side: const BorderSide(
                                              color:
                                                  Color.fromARGB(255, 231, 76, 60),
                                              width: 2),
                                          padding: const EdgeInsets.symmetric(
                                              vertical: 14),
                                          shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(0)),
                                        ),
                                        child: const Text("REPROVAR",
                                            style: TextStyle(
                                                color: Colors.white,
                                                fontWeight: FontWeight.bold)),
                                      ),
                                    ),
                                  ],
                                ),

                                const SizedBox(height: 12),

                              Center(
                                child: SizedBox(
                                  width: 200.0, 
                                  child: ElevatedButton(
                                    style: _btnStyle(),
                                    onPressed: () => Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) => Detalhes(
                                          idProjeto: p.idProjeto,
                                          modelo: p.modelo,
                                        ),
                                      ),
                                    ),
                                    child: const Text(
                                      "MAIS DETALHES",
                                      style: TextStyle(color: Colors.white),
                                    ),
                                  ),
                                ),
                              ),
                              ],
                            ),
                          ),
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
                            _index = (_index - 1 + _projetosFiltrados.length) %
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
                            builder: (_) => Perfil(
                              emailLogado: emailLogado ?? "",
                            ),
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
          fillColor: Color.fromRGBO(80, 80, 80, 1),
          contentPadding: const EdgeInsets.symmetric(vertical: 3, horizontal: 15),

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
