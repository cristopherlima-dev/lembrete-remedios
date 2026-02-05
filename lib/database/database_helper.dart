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

    return await openDatabase(
      path,
      version: 3, // VERSÃO 3
      onCreate: _createDB,
      onUpgrade: _onUpgrade,
    );
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

    // Tabela Histórico já com a coluna horario
    await db.execute('''
      CREATE TABLE historico (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        medicamento_id INTEGER NOT NULL,
        horario TEXT, 
        data_hora TEXT NOT NULL,
        FOREIGN KEY (medicamento_id) REFERENCES medicamentos (id) ON DELETE CASCADE
      )
    ''');
  }

  Future _onUpgrade(Database db, int oldVersion, int newVersion) async {
    // Se vier da v1 (sem histórico)
    if (oldVersion < 2) {
      await db.execute('''
        CREATE TABLE historico (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          medicamento_id INTEGER NOT NULL,
          horario TEXT,
          data_hora TEXT NOT NULL,
          FOREIGN KEY (medicamento_id) REFERENCES medicamentos (id) ON DELETE CASCADE
        )
      ''');
    }
    // Se vier da v2 (já tem histórico, mas falta a coluna horario)
    else if (oldVersion < 3) {
      try {
        await db.execute('ALTER TABLE historico ADD COLUMN horario TEXT');
      } catch (e) {
        // Coluna já existe ou erro ignorável
        print("Erro ao migrar v2->v3: $e");
      }
    }
  }

  // --- CRUD Medicamentos (Inalterado) ---
  Future<int> insertMedicamento(Medicamento medicamento) async {
    final db = await database;
    return await db.insert('medicamentos', medicamento.toMap());
  }

  Future<List<Medicamento>> getAllMedicamentos() async {
    final db = await database;
    final result = await db.query('medicamentos', orderBy: 'nome ASC');
    return result.map((map) => Medicamento.fromMap(map)).toList();
  }

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

  Future<int> updateMedicamento(Medicamento medicamento) async {
    final db = await database;
    return await db.update(
      'medicamentos',
      medicamento.toMap(),
      where: 'id = ?',
      whereArgs: [medicamento.id],
    );
  }

  Future<int> deleteMedicamento(int id) async {
    final db = await database;
    await db.delete('historico', where: 'medicamento_id = ?', whereArgs: [id]);
    return await db.delete('medicamentos', where: 'id = ?', whereArgs: [id]);
  }

  // --- Novos Métodos para Histórico com Horário ---

  // Registra toma de um horário específico
  Future<int> registrarToma(
    int medicamentoId,
    String horario,
    DateTime dataHora,
  ) async {
    final db = await database;
    return await db.insert('historico', {
      'medicamento_id': medicamentoId,
      'horario': horario, // Salvamos qual horário foi clicado (ex: "08:00")
      'data_hora': dataHora.toIso8601String(),
    });
  }

  // Remove a toma (desmarcar o check, caso o usuário tenha clicado errado)
  Future<int> removerTomaHoje(int medicamentoId, String horario) async {
    final db = await database;
    final now = DateTime.now();
    final inicioDia = DateTime(now.year, now.month, now.day).toIso8601String();
    final fimDia = DateTime(
      now.year,
      now.month,
      now.day,
      23,
      59,
      59,
    ).toIso8601String();

    return await db.delete(
      'historico',
      where: 'medicamento_id = ? AND horario = ? AND data_hora BETWEEN ? AND ?',
      whereArgs: [medicamentoId, horario, inicioDia, fimDia],
    );
  }

  // Retorna LISTA de horários tomados hoje para este remédio
  Future<List<String>> getHorariosTomadosHoje(int medicamentoId) async {
    final db = await database;
    final now = DateTime.now();

    final inicioDia = DateTime(now.year, now.month, now.day).toIso8601String();
    final fimDia = DateTime(
      now.year,
      now.month,
      now.day,
      23,
      59,
      59,
    ).toIso8601String();

    final result = await db.query(
      'historico',
      columns: ['horario'],
      where: 'medicamento_id = ? AND data_hora BETWEEN ? AND ?',
      whereArgs: [medicamentoId, inicioDia, fimDia],
    );

    // Retorna uma lista de strings, ex: ["08:00", "20:00"]
    return result
        .where((row) => row['horario'] != null)
        .map((row) => row['horario'] as String)
        .toList();
  }

  Future close() async {
    final db = await database;
    db.close();
  }
}
