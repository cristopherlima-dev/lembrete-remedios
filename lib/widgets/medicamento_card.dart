// lib/widgets/medicamento_card.dart
import 'package:flutter/material.dart';
import '../models/medicamento.dart';

class MedicamentoCard extends StatelessWidget {
  final Medicamento medicamento;
  final VoidCallback onDelete;
  final VoidCallback onEdit;
  final Function(String) onCheck;
  final List<String> horariosTomados;

  const MedicamentoCard({
    super.key,
    required this.medicamento,
    required this.onDelete,
    required this.onEdit,
    required this.onCheck,
    required this.horariosTomados,
  });

  @override
  Widget build(BuildContext context) {
    // Verifica se todos os horários do dia foram cumpridos
    final bool diaCompleto =
        medicamento.horarios.isNotEmpty &&
        medicamento.horarios.every((h) => horariosTomados.contains(h));

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      // Fundo muda subtilmente para verde se o dia estiver completo
      color: diaCompleto ? Colors.green.shade50 : null,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Cabeçalho do Card (Ícone, Nome, Dosagem, Botões de Ação)
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: diaCompleto ? Colors.green[100] : Colors.teal[50],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.medical_services,
                    color: diaCompleto ? Colors.green : Colors.teal,
                    size: 28,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        medicamento.nome,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: diaCompleto ? Colors.grey[700] : Colors.black,
                          // Riscado apenas se o dia estiver completo
                          decoration: diaCompleto
                              ? TextDecoration.lineThrough
                              : null,
                        ),
                      ),
                      if (medicamento.dosagem != null &&
                          medicamento.dosagem!.isNotEmpty)
                        Text(
                          medicamento.dosagem!,
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[600],
                          ),
                        ),
                    ],
                  ),
                ),
                // Botões de Editar e Excluir
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.edit, color: Colors.blue),
                      tooltip: 'Editar',
                      onPressed: onEdit,
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete, color: Colors.red),
                      tooltip: 'Excluir',
                      onPressed: () {
                        showDialog(
                          context: context,
                          builder: (context) => AlertDialog(
                            title: const Text('Confirmar exclusão'),
                            content: Text(
                              'Deseja realmente excluir ${medicamento.nome}?',
                            ),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(context),
                                child: const Text('Cancelar'),
                              ),
                              TextButton(
                                onPressed: () {
                                  Navigator.pop(context);
                                  onDelete();
                                },
                                child: const Text(
                                  'Excluir',
                                  style: TextStyle(color: Colors.red),
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),
            const Divider(),
            const SizedBox(height: 8),
            // Secção de Horários (Check-in)
            Row(
              children: [
                Icon(Icons.access_time, size: 16, color: Colors.grey[600]),
                const SizedBox(width: 8),
                Text(
                  'Horários:',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey[700],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            // Lista de Chips Clicáveis
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: medicamento.horarios.map((horario) {
                final bool isTomado = horariosTomados.contains(horario);

                return ActionChip(
                  label: Text(horario),
                  // Estilo quando tomado: Verde Sólido
                  backgroundColor: isTomado ? Colors.green : Colors.white,
                  labelStyle: TextStyle(
                    color: isTomado ? Colors.white : Colors.teal,
                    fontWeight: FontWeight.bold,
                  ),
                  // Ícone de check ou relógio
                  avatar: Icon(
                    isTomado ? Icons.check : Icons.schedule,
                    color: isTomado ? Colors.white : Colors.teal,
                    size: 18,
                  ),
                  side: BorderSide(
                    color: isTomado ? Colors.green : Colors.teal.shade200,
                  ),
                  // Ação ao clicar (Chama a lógica da Home)
                  onPressed: () => onCheck(horario),
                  tooltip: isTomado ? 'Concluído' : 'Marcar como tomado',
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }
}
