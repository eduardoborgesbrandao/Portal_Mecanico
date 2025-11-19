import 'modelo.dart';
import 'peca.dart';

class Personalizacao {
  int idPersonalizacao;
  List<Peca> itens;
  Modelo carroAplicado;

  Personalizacao({
    required this.idPersonalizacao,
    required this.itens,
    required this.carroAplicado,
  });
}