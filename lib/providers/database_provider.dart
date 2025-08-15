import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sembast/sembast.dart';
import 'package:sembast/sembast_io.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart';

final databaseProvider = FutureProvider<Database>((ref) async {
  final appDir = await getApplicationDocumentsDirectory();
  final dbPath = join(appDir.path, 'decaf_app.db');
  final dbFactory = databaseFactoryIo;
  return await dbFactory.openDatabase(dbPath);
});