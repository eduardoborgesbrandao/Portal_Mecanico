import 'personalizacao.dart';

class Pedido {
  int idPedido;
  String statusPedido;
  DateTime dataPedido;
  double valorTotal;
  Personalizacao personalizacao;
  int idUsuario;

  Pedido({
    required this.idPedido,
    required this.statusPedido,
    required this.dataPedido,
    required this.valorTotal,
    required this.personalizacao,
    required this.idUsuario,
  });
}