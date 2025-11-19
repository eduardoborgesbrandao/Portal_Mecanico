import 'peca.dart';

class Vidro extends Peca {
  int idVidro;
  String transparenciaVidro;

  Vidro({
    required this.idVidro,
    required this.transparenciaVidro,
    required super.idPeca,
    required super.nome,
    required super.preco,
    required super.tipo,
  });
}
