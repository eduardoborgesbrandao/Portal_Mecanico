class Projeto {
  final String idProjeto;
  final String status;
  final String fabricacao;
  final String potencia;
  final String aceleracao;
  final String velMax;
  final String fabricante;
  final String pais;
  final String cor;
  final String modelo;
  final String imagem;
  final bool mostrarAprovacao;

  final String assinaturaAprovador;
  final String emailAprovador;

  final String assinaturaFinal;


  Projeto({
    required this.idProjeto,
    required this.status,
    required this.fabricacao,
    required this.potencia,
    required this.aceleracao,
    required this.velMax,
    required this.fabricante,
    required this.pais,
    required this.cor,
    required this.modelo,
    required this.imagem,
    required this.mostrarAprovacao,

    this.assinaturaAprovador = '',
    this.emailAprovador = '',

    this.assinaturaFinal = '',
  });

  factory Projeto.fromJson(Map<String, dynamic> json) {
    return Projeto(
      idProjeto: (json['idProjeto'] ?? '').toString(),
      status: (json['status'] ?? '').toString(),
      fabricacao: (json['fabricacao'] ?? json['ano'] ?? '').toString(),
      potencia: (json['potencia'] ?? '').toString(),
      aceleracao: (json['aceleracao'] ?? '').toString(),
      velMax: (json['velMax'] ?? '').toString(),
      fabricante: (json['fabricante'] ?? '').toString(),
      pais: (json['pais'] ?? '').toString(),
      cor: (json['cor'] ?? '').toString(),
      modelo: (json['modelo'] ?? '').toString(),
      imagem: (json['imagem'] ?? '').toString(),
      mostrarAprovacao: json['mostrarAprovacao'] == true,

      assinaturaAprovador: (json['assinaturaAprovador'] ?? '').toString(),
      emailAprovador: (json['emailAprovador'] ?? '').toString(),

      assinaturaFinal: (json['assinaturaFinal'] ?? '').toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'idProjeto': idProjeto,
      'status': status,
      'fabricacao': fabricacao,
      'potencia': potencia,
      'aceleracao': aceleracao,
      'velMax': velMax,
      'fabricante': fabricante,
      'pais': pais,
      'cor': cor,
      'modelo': modelo,
      'imagem': imagem,
      'mostrarAprovacao': mostrarAprovacao,

      'assinaturaAprovador': assinaturaAprovador,
      'emailAprovador': emailAprovador,

      'assinaturaFinal': assinaturaFinal,
    };
  }
}
