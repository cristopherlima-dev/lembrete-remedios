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
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadMedicamentos();
  }

  Future<void> _loadMedicamentos() async {
    setState(() => _isLoading = true);
    final medicamentos = await DatabaseHelper.instance.getActiveMedicamentos();
    setState(() {
      _medicamentos = medicamentos;
      _isLoading = false;
    });
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
                  return MedicamentoCard(
                    medicamento: _medicamentos[index],
                    onDelete: () =>
                        _deleteMedicamento(_medicamentos[index].id!),
                    onEdit: () async {
                      final result = await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => AddMedicamentoScreen(
                            medicamento: _medicamentos[index],
                          ),
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
