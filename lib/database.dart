import 'package:path_provider/path_provider.dart';
import 'package:sqlite3/sqlite3.dart' as sqlite3;
import 'package:volt_vole/voltage_data.dart';

import 'logging.dart';

class Database {
  static Database? _instance;

  static Database get instance => _instance!;

  List<VoltageData> _voltages = [];
  List<VoltageData> get voltages => _voltages;

  String _databasePath = 'volt_vole.db';
  sqlite3.Database? db;

  Database(String path) {
    if (_instance != null) {
      throw Exception('Database already initialized');
    }

    _databasePath = path;
    _instance = this;
  }

  Future<bool> init() async {
    var directory = await getApplicationDocumentsDirectory();
    Log.debug('Database path: ${directory.path}/$_databasePath');
    try {
      db = sqlite3.sqlite3.open('${directory.path}/$_databasePath');
      db!.execute(
          'CREATE TABLE IF NOT EXISTS voltage_data (id INTEGER PRIMARY KEY AUTOINCREMENT, timestamp DATETIME, voltage REAL)');
      _getVoltagesFromDatabase();
    } catch (e) {
      Log.error('Error initializing database: $e');
      return false;
    }

    return db != null;
  }

  void dispose() {
    Log.debug('Disposing database', name: runtimeType.toString());
    _voltages.clear();

    db?.dispose();
    _instance = null;
  }

  void deleteAll() {
    db?.execute('DELETE FROM voltage_data');
    _voltages.clear();
  }

  void insert(VoltageData voltageData, {bool update = true}) {
    db?.execute('INSERT INTO voltage_data (timestamp, voltage) VALUES (?, ?)',
        [voltageData.timestamp.millisecondsSinceEpoch, voltageData.voltage]);
    if(db?.updatedRows != null && db!.updatedRows > 0) {
      Log.debug('Inserted voltage: ${voltageData.voltage}', name: runtimeType.toString());
    }

    if(update) {
      _getVoltagesFromDatabase();
    }
  }

  void insertAll(List<VoltageData> voltages) {
    for (var voltage in voltages) {
      insert(voltage, update: false);
    }

    _getVoltagesFromDatabase();
  }

  void update(VoltageData voltageData) {
    db?.execute('UPDATE voltage_data SET timestamp = ?, voltage = ? WHERE id = ?',
        [voltageData.timestamp.millisecondsSinceEpoch, voltageData.voltage, voltageData.id]);
    Log.debug('Updated voltage: ${voltageData.voltage}');
  }

  void delete(VoltageData voltageData) {
    db?.execute('DELETE FROM voltage_data WHERE id = ?', [voltageData.id]);
    Log.debug('Deleted voltage: ${voltageData.voltage}');

    _getVoltagesFromDatabase();
  }

  void _getVoltagesFromDatabase() {
    _voltages = db?.select('SELECT * FROM voltage_data ORDER BY timestamp DESC').map((sqlite3.Row row) {
      return VoltageData.fromRow(row);
    }).toList() ?? [];

    Log.debug('Loaded ${_voltages.length} voltages from database');
  }
}
