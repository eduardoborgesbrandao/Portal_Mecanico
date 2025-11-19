import 'pedido.dart';

class Funcionario {
  int idFunc;
  int idRG;
  String cep;
  String numEnd;
  String compEnd;
  String nomeFunc;
  int cpf;
  DateTime dataNasc;
  String email;
  String senha;
  List<Pedido> pedidosAprovados;

  Funcionario({
    required this.idFunc,
    required this.idRG,
    required this.cep,
    required this.numEnd,
    required this.compEnd,
    required this.nomeFunc,
    required this.cpf,
    required this.dataNasc,
    required this.email,
    required this.senha,
    required this.pedidosAprovados,
  });
}