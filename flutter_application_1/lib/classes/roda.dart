import 'peca.dart';

class Roda extends Peca {
  int idRoda;
  String marcaRoda;

  Roda({
    required this.idRoda,
    required this.marcaRoda,
    required super.idPeca,
    required super.nome,
    required super.preco,
    required super.tipo,
  });
}
