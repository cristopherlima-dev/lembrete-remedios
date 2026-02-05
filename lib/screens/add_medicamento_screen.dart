// lib/screens/add_medicamento_screen.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/medicamento.dart';
import '../database/database_helper.dart';
import '../services/notification_service.dart';

class AddMedicamentoScreen extends StatefulWidget {
  final Medicamento? medicamento;

  const AddMedicamentoScreen({super.key, this.medicamento});

  @override
  State<AddMedicamentoScreen> createState() => _AddMedicamentoScreenState();
}

class _AddMedicamentoScreenState extends State<AddMedicamentoScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nomeController = TextEditingController();
  final _dosagemController = TextEditingController();
  final List<TimeOfDay> _horarios = [];

  @override
  void initState() {
    super.initState();
    if (widget.medicamento != null) {
      _nomeController.text = widget.medicamento!.nome;
      _dosagemController.text = widget.medicamento!.dosagem ?? '';
      for (var horario in widget.medicamento!.horarios) {
        final parts = horario.split(':');
        if (parts.length == 2) {
          _horarios.add(
            TimeOfDay(hour: int.parse(parts[0]), minute: int.parse(parts[1])),
          );
        }
      }
    }
  }

  @override
  void dispose() {
    _nomeController.dispose();
    _dosagemController.dispose();
    super.dispose();
  }

  Future<void> _adicionarHorario() async {
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(primary: Colors.teal),
          ),
          child: child!,
        );
      },
    );

    if (time != null) {
      setState(() {
        _horarios.add(time);
        _horarios.sort(
          (a, b) => (a.hour * 60 + a.minute).compareTo(b.hour * 60 + b.minute),
        );
      });
    }
  }

  void _removerHorario(int index) {
    setState(() {
      _horarios.removeAt(index);
    });
  }

  String _formatTimeOfDay(TimeOfDay time) {
    final now = DateTime.now();
    final dt = DateTime(now.year, now.month, now.day, time.hour, time.minute);
    return DateFormat('HH:mm').format(dt);
  }

  Future<void> _salvarMedicamento() async {
    if (!_formKey.currentState!.validate()) return;
    if (_horarios.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Adicione pelo menos um horário')),
      );
      return;
    }

    try {
      final novoMedicamento = Medicamento(
        id: widget.medicamento?.id,
        nome: _nomeController.text.trim(),
        dosagem: _dosagemController.text.trim(),
        horarios: _horarios.map(_formatTimeOfDay).toList(),
        ativo: widget.medicamento?.ativo ?? true,
        dataCriacao: widget.medicamento?.dataCriacao,
      );

      int id;
      if (widget.medicamento == null) {
        id = await DatabaseHelper.instance.insertMedicamento(novoMedicamento);
      } else {
        id = novoMedicamento.id!;
        await DatabaseHelper.instance.updateMedicamento(novoMedicamento);
        // Limpar notificações antigas
        try {
          for (int i = 0; i < 20; i++) {
            await NotificationService.instance.cancelNotification(id * 100 + i);
          }
        } catch (e) {
          print("Erro ao limpar notificações: $e");
        }
      }

      // Agendar notificações (Agora passando apenas Hora e Minuto)
      try {
        for (int i = 0; i < _horarios.length; i++) {
          final time = _horarios[i];

          await NotificationService.instance.scheduleNotification(
            id: id * 100 + i,
            title: 'Hora do remédio! 💊',
            body: '${novoMedicamento.nome} - ${novoMedicamento.dosagem ?? ""}',
            hour: time.hour, // Passa hora direta
            minute: time.minute, // Passa minuto direto
          );
        }
      } catch (e) {
        print("Erro agendamento: $e");
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              // Mostra o erro real para facilitar o debug
              content: Text('Salvo, mas erro no alarme: $e'),
              backgroundColor: Colors.orange,
              duration: const Duration(seconds: 4),
            ),
          );
        }
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              widget.medicamento == null
                  ? 'Medicamento cadastrado!'
                  : 'Medicamento atualizado!',
            ),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      print("Erro crítico: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao salvar: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.medicamento == null
              ? 'Adicionar Medicamento'
              : 'Editar Medicamento',
        ),
        backgroundColor: Colors.teal,
        foregroundColor: Colors.white,
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(
              controller: _nomeController,
              decoration: const InputDecoration(
                labelText: 'Nome do Medicamento',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.medical_services),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Por favor, insira o nome do medicamento';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _dosagemController,
              decoration: const InputDecoration(
                labelText: 'Dosagem (opcional)',
                hintText: 'Ex: 500mg, 2 comprimidos',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.medication),
              ),
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Horários',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                TextButton.icon(
                  onPressed: _adicionarHorario,
                  icon: const Icon(Icons.add),
                  label: const Text('Adicionar'),
                ),
              ],
            ),
            const SizedBox(height: 8),
            if (_horarios.isEmpty)
              Container(
                padding: const EdgeInsets.all(32),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey[300]!),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Center(
                  child: Text(
                    'Nenhum horário adicionado',
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                ),
              )
            else
              ...List.generate(_horarios.length, (index) {
                return Card(
                  child: ListTile(
                    leading: const Icon(Icons.access_time, color: Colors.teal),
                    title: Text(
                      _horarios[index].format(context),
                      style: const TextStyle(fontSize: 18),
                    ),
                    trailing: IconButton(
                      icon: const Icon(Icons.delete, color: Colors.red),
                      onPressed: () => _removerHorario(index),
                    ),
                  ),
                );
              }),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _salvarMedicamento,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.teal,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: Text(
                widget.medicamento == null
                    ? 'Salvar Medicamento'
                    : 'Atualizar Medicamento',
                style: const TextStyle(fontSize: 16),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
