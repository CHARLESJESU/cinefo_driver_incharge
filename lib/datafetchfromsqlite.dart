// ...existing code...

import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart' as path;
import 'variables.dart';

/// Opens the local `production_login.db` and fetches the first row from
/// `login_data`. It reads the `production_type_id` column and assigns it to
/// the global `productionTypeId` variable in `variables.dart`.
///
/// Usage:
/// await fetchProductionTypeFromSqlite();
Future<void> fetchloginDataFromSqlite() async {
  try {
    final dbPath = path.join(await getDatabasesPath(), 'production_login.db');
    final Database db = await openDatabase(dbPath);

    final List<Map<String, dynamic>> rows = await db.query(
      'login_data',
      orderBy: 'id ASC',
      limit: 1,
    );
      final Map<String, dynamic> first = rows.first;
        if(first['production_type_id'] is int){
          print("❌❌❌❌❌❌ int");
        }
        else{
          print("❌❌❌❌❌❌ String");
        }
      productionTypeId = first['production_type_id'] ?? 0;
    vmid = first['vmid'];
    unitid = first['unitid'];
    projectId=first['project_id'];
    vsid=first['vsid'];
  } catch (e) {
    print('❌ Error fetching productionTypeId from SQLite: $e');
  }
}

