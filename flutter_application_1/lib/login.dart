import 'dart:convert';
import 'dart:html' as html; 
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;

import 'andamento.dart';

class Login extends StatefulWidget {
  const Login({super.key});

  @override
  State<Login> createState() => _LoginState();
}

class _LoginState extends State<Login> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _emailCtrl = TextEditingController();
  final TextEditingController _senhaCtrl = TextEditingController();

  bool _senhaVisivel = false;
  bool _isLoading = false;

  List<Map<String, dynamic>> _usuarios = [];
  bool _usuariosCarregados = false;

  @override
  void initState() {
    super.initState();
    _loadUsuarios();
  }

  Future<void> _loadUsuarios() async {
    try {
      print('[Login] carregando assets/logins.json...');
      final raw = await rootBundle.loadString('assets/logins.json');
      final data = json.decode(raw);

      if (data is Map && data['funcionarios'] is List) {
        _usuarios = List<Map<String, dynamic>>.from(data['funcionarios']);
      } else if (data is List) {
        _usuarios = List<Map<String, dynamic>>.from(data);
      } else {
        _usuarios = [];
      }

      _usuariosCarregados = true;
      print('[Login] usuários carregados: ${_usuarios.length}');
    } catch (e, s) {
      print('[Login] ERRO ao carregar usuários: $e');
      print(s);
      _usuariosCarregados = false;

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao carregar usuários: $e')),
        );
      }
    }
  }

  Future<void> _carregarProjetosNoLocalStorage() async {
    try {
      print('[Login] carregando assets/projeto.json...');
      final raw = await rootBundle.loadString('assets/projeto.json');

      html.window.localStorage['projetos'] = raw;

      print('[Login] projetos salvos no localStorage com sucesso!');
    } catch (e, s) {
      print('[Login] ERRO ao carregar projetos.json: $e');
      print(s);
    }
  }

  Future<void> _fazerLogin() async {
    if (!_formKey.currentState!.validate()) return;

    if (!_usuariosCarregados) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Aguarde o carregamento dos usuários...')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final email = _emailCtrl.text.trim().toLowerCase();
      final senha = _senhaCtrl.text.trim();

      print('[Login] Tentando login: $email');

      await Future.delayed(const Duration(milliseconds: 500)); // animação loader

      final usuario = _usuarios.firstWhere(
        (u) =>
            (u['email'] ?? '').toString().trim().toLowerCase() == email &&
            (u['senha'] ?? '').toString().trim() == senha,
        orElse: () => {},
      );

      if (usuario.isNotEmpty) {
        print('[Login] LOGIN OK → $usuario');

        await _carregarProjetosNoLocalStorage();

        if (!mounted) return;
        setState(() => _isLoading = false);

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const Andamento()),
        );
      } else {
        print('[Login] credenciais inválidas');

        if (!mounted) return;
        setState(() => _isLoading = false);

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Email ou senha incorretos')),
        );
      }
    } catch (e, s) {
      print('[Login] ERRO no login: $e');
      print(s);

      if (!mounted) return;
      setState(() => _isLoading = false);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro durante login: $e')),
      );
    }
  }

  @override
  void dispose() {
    _emailCtrl.dispose();
    _senhaCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final inputDeco = InputDecoration(
      filled: true,
      fillColor: Colors.grey[900],
      hintStyle: const TextStyle(color: Colors.grey),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(0),
        borderSide: BorderSide.none,
      ),
    );

    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 28),
          child: Center(
            child: SingleChildScrollView(
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    Image.asset('img/sz_1.png',
                        width: 120, height: 120, fit: BoxFit.contain),

                    const SizedBox(height: 20),

                    const Text(
                      'BEM-VINDO MECÂNICO',
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold),
                    ),

                    const SizedBox(height: 30),

                    TextFormField(
                      controller: _emailCtrl,
                      style: const TextStyle(color: Colors.white),
                      decoration: inputDeco.copyWith(hintText: 'Email'),
                      validator: (v) =>
                          v == null || v.isEmpty ? 'Informe o email' : null,
                    ),

                    const SizedBox(height: 14),

                    TextFormField(
                      controller: _senhaCtrl,
                      obscureText: !_senhaVisivel,
                      style: const TextStyle(color: Colors.white),
                      decoration: inputDeco.copyWith(
                        hintText: 'Senha',
                        suffixIcon: IconButton(
                          onPressed: () => setState(
                              () => _senhaVisivel = !_senhaVisivel),
                          icon: Icon(
                            _senhaVisivel
                                ? Icons.visibility
                                : Icons.visibility_off,
                            color: Colors.grey,
                          ),
                        ),
                      ),
                      validator: (v) =>
                          v == null || v.isEmpty ? 'Informe a senha' : null,
                    ),

                    const SizedBox(height: 20),

                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _fazerLogin,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: Colors.black,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(5),
                          ),
                        ),
                        child: _isLoading
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.black,
                                ))
                            : const Text(
                                'ENTRAR',
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                      ),
                    ),

                    const SizedBox(height: 12),

                    TextButton(
                      onPressed: () {},
                      child: const Text('Esqueci a senha',
                          style: TextStyle(color: Colors.grey)),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
