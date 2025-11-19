import 'peca.dart';

class Teto extends Peca {
  int idTeto;
  String tipoTeto;

  Teto({
    required this.idTeto,
    required this.tipoTeto,
    required super.idPeca,
    required super.nome,
    required super.preco,
    required super.tipo,
  });
}
