import 'peca.dart';

class DesignInterior extends Peca {
  int idDesign;
  String material;
  String cor;

  DesignInterior({
    required this.idDesign,
    required this.material,
    required this.cor,
    required super.idPeca,
    required super.nome,
    required super.preco,
    required super.tipo,
  });
}
