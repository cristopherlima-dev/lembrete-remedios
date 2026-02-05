// lib/database/database_helper.dart
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/medicamento.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('medicamentos.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(path, version: 1, onCreate: _createDB);
  }

  Future _createDB(Database db, int version) async {
    await db.execute('''
      CREATE TABLE medicamentos (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        nome TEXT NOT NULL,
        dosagem TEXT,
        horarios TEXT NOT NULL,
        ativo INTEGER NOT NULL,
        dataCriacao TEXT NOT NULL
      )
    ''');
  }

  // Inserir medicamento
  Future<int> insertMedicamento(Medicamento medicamento) async {
    final db = await database;
    return await db.insert('medicamentos', medicamento.toMap());
  }

  // Buscar todos os medicamentos
  Future<List<Medicamento>> getAllMedicamentos() async {
    final db = await database;
    final result = await db.query('medicamentos', orderBy: 'nome ASC');
    return result.map((map) => Medicamento.fromMap(map)).toList();
  }

  // Buscar medicamentos ativos
  Future<List<Medicamento>> getActiveMedicamentos() async {
    final db = await database;
    final result = await db.query(
      'medicamentos',
      where: 'ativo = ?',
      whereArgs: [1],
      orderBy: 'nome ASC',
    );
    return result.map((map) => Medicamento.fromMap(map)).toList();
  }

  // Atualizar medicamento
  Future<int> updateMedicamento(Medicamento medicamento) async {
    final db = await database;
    return await db.update(
      'medicamentos',
      medicamento.toMap(),
      where: 'id = ?',
      whereArgs: [medicamento.id],
    );
  }

  // Deletar medicamento
  Future<int> deleteMedicamento(int id) async {
    final db = await database;
    return await db.delete('medicamentos', where: 'id = ?', whereArgs: [id]);
  }

  // Fechar banco
  Future close() async {
    final db = await database;
    db.close();
  }
}
