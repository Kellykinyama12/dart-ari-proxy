import 'dart:convert';
//import 'dart:io';
import 'package:eloquent/eloquent.dart';

void main(List<String> args) async {
  final manager = Manager();
  manager.addConnection({
    'driver': 'mysql',
    'host': '10.44.0.55',
    'port': '3306',
    'database': 'asterisk',
    'username': 'dashboard',
    'password': 'dashboard.123',
    // 'pool': true,
    // 'poolsize': 2,
  });

  manager.setAsGlobal();

  var db = await manager.connection();
  await db.disconnect();
  db = await manager.connection();

//   await db.execute('DROP TABLE clients');
//   await db.execute(''' CREATE TABLE IF NOT EXISTS clients (
//     id int NOT NULL AUTO_INCREMENT,
//     name varchar(255) NOT NULL,
//     PRIMARY KEY (id)
// ); ''');

//   await db.execute('DROP TABLE contacts');
//   await db.execute(''' CREATE TABLE IF NOT EXISTS contacts (
//     id_client int NOT NULL ,
//     tel varchar(255) NOT NULL
// ); ''');

//   await db.table('clients').insert({'name': 'Isaque'});
//   await db.table('clients').insert({'name': 'John Doe'});
//   await db.table('clients').insert({'name': 'Jane Doe'});

//   await db
//       .table('clients')
//       .where('id', '=', 1)
//       .update({'name': 'Isaque update'});

//   // await db.table('clients').where('id', '=', 2).delete();

//   await db.table('contacts').insert({'id_client': 1, 'tel': '27772339'});
//   await db.table('contacts').insert({'id_client': 2, 'tel': '99705498'});

//   var res = await db
//       .table('agents')
// //       .selectRaw('id,name,tel')
// //       .join('contacts', 'contacts.id_client', '=', 'clients.id')
//       .get();
//   final resp = jsonEncode(res);

  //PDOResults;
  // print(resp);
//   //res: [{id: 1, name: Isaque update, tel: 27772339}, {id: 2, name: John Doe, tel: 99705498}]

  // await db.table('recordings').insert({
  //   "agent_number": "",
  //   "phone_number": "",
  //   "duration_number": "",
  //   "file_name": "",
  //   "file_path": "",
  //   //"transcription": "",
  //   "created_at": DateTime.now().toString(),
  //   "updated_at": DateTime.now().toString(),
  // });

  //await db.table('recordings').groupBy(column)

  await db.disconnect();

//   exit(0);
}
