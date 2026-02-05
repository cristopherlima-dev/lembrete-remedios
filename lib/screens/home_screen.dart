// lib/screens/home_screen.dart
import 'package:flutter/material.dart';
import '../models/medicamento.dart';
import '../database/database_helper.dart';
import '../widgets/medicamento_card.dart';
import 'add_medicamento_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<Medicamento> _medicamentos = [];
  Map<int, List<String>> _horariosTomados = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadMedicamentos();
  }

  Future<void> _loadMedicamentos() async {
    setState(() => _isLoading = true);
    final medicamentos = await DatabaseHelper.instance.getActiveMedicamentos();

    final Map<int, List<String>> status = {};
    for (var med in medicamentos) {
      if (med.id != null) {
        status[med.id!] = await DatabaseHelper.instance.getHorariosTomadosHoje(
          med.id!,
        );
      }
    }

    setState(() {
      _medicamentos = medicamentos;
      _horariosTomados = status;
      _isLoading = false;
    });
  }

  // NOVA LÓGICA: Confirmar e Marcar (Irreversível)
  Future<void> _onHorarioClicado(int id, String horario) async {
    final tomados = _horariosTomados[id] ?? [];

    // Se já foi tomado, não permite desmarcar.
    if (tomados.contains(horario)) {
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Esta dose já foi confirmada hoje.'),
          backgroundColor: Colors.grey,
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }

    // Se não foi tomado, pede confirmação
    final bool? confirmar = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmar dose'),
        content: Text(
          'Confirma que tomou o medicamento às $horario?\n\n'
          'Por segurança, esta ação não pode ser desfeita até amanhã.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text(
              'Confirmar',
              style: TextStyle(
                color: Colors.green,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );

    // Se confirmou, salva no banco
    if (confirmar == true) {
      await DatabaseHelper.instance.registrarToma(id, horario, DateTime.now());

      // Atualiza a interface
      await _loadMedicamentos();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Dose das $horario registrada! ✅'),
            backgroundColor: Colors.green,
          ),
        );
      }
    }
  }

  Future<void> _deleteMedicamento(int id) async {
    await DatabaseHelper.instance.deleteMedicamento(id);
    _loadMedicamentos();
    if (mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Medicamento removido')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Meus Medicamentos'),
        backgroundColor: Colors.teal,
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _medicamentos.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.medical_services_outlined,
                    size: 80,
                    color: Colors.grey[400],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Nenhum medicamento cadastrado',
                    style: TextStyle(fontSize: 18, color: Colors.grey[600]),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Toque no + para adicionar',
                    style: TextStyle(fontSize: 14, color: Colors.grey[500]),
                  ),
                ],
              ),
            )
          : RefreshIndicator(
              onRefresh: _loadMedicamentos,
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: _medicamentos.length,
                itemBuilder: (context, index) {
                  final medicamento = _medicamentos[index];
                  return MedicamentoCard(
                    medicamento: medicamento,
                    horariosTomados: _horariosTomados[medicamento.id] ?? [],
                    // Passamos a nova função de lógica segura
                    onCheck: (horario) =>
                        _onHorarioClicado(medicamento.id!, horario),
                    onDelete: () => _deleteMedicamento(medicamento.id!),
                    onEdit: () async {
                      final result = await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              AddMedicamentoScreen(medicamento: medicamento),
                        ),
                      );
                      if (result == true) {
                        _loadMedicamentos();
                      }
                    },
                  );
                },
              ),
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const AddMedicamentoScreen(),
            ),
          );
          if (result == true) {
            _loadMedicamentos();
          }
        },
        backgroundColor: Colors.teal,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}
