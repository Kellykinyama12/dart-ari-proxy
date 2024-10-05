import 'package:dart_ari_proxy/globals.dart';
import 'package:eloquent/eloquent.dart';

// Declarations

class DbQueries {
  static Future<Connection> getDbConnection() async {
    var manager = Manager();
    if (true) {
      manager.addConnection({
        'driver': 'mysql',
        'host': asteriskDbHost,
        'port': asteriskDbPort,
        'database': asteriskDbName,
        'username': asteriskDbUsername,
        'password': asteriskDbPassword,
      });
      manager.setAsGlobal();
    }
    final db = await manager.connection();
    return db;
  }

  static Future<void> updateAgentStatus(
      String endpoint, String state, String status) async {
    final db = await getDbConnection();

    try {
      await db
          .table('agents')
          .where('endpoint', '=', endpoint)
          .update({'state': state, 'status': status});
    } catch (e) {
      print('Error: $e');
      // Handle reconnection logic if needed
    } finally {
      await db.disconnect();
    }
  }
}
