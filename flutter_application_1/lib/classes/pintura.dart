import 'peca.dart';

class Pintura extends Peca {
  int idPintura;
  String cor;
  String acabamento;

  Pintura({
    required this.idPintura,
    required this.cor,
    required this.acabamento,
    required super.idPeca,
    required super.nome,
    required super.preco,
    required super.tipo,
  });
}
