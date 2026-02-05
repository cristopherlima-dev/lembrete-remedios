// lib/models/medicamento.dart
class Medicamento {
  int? id;
  String nome;
  String? dosagem;
  List<String> horarios; // Horários no formato "HH:mm"
  bool ativo;
  DateTime dataCriacao;

  Medicamento({
    this.id,
    required this.nome,
    this.dosagem,
    required this.horarios,
    this.ativo = true,
    DateTime? dataCriacao,
  }) : dataCriacao = dataCriacao ?? DateTime.now();

  // Converter para Map (para salvar no banco)
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'nome': nome,
      'dosagem': dosagem,
      'horarios': horarios.join(','), // Salva como string separada por vírgula
      'ativo': ativo ? 1 : 0,
      'dataCriacao': dataCriacao.toIso8601String(),
    };
  }

  // Criar objeto a partir do Map (ler do banco)
  factory Medicamento.fromMap(Map<String, dynamic> map) {
    return Medicamento(
      id: map['id'],
      nome: map['nome'],
      dosagem: map['dosagem'],
      horarios: (map['horarios'] as String).split(','),
      ativo: map['ativo'] == 1,
      dataCriacao: DateTime.parse(map['dataCriacao']),
    );
  }
}
