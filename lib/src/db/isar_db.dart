import 'package:isar_community/isar.dart';
import 'package:path_provider/path_provider.dart';

import 'models/ente_collection.dart';
import 'models/ente_file.dart';
import 'models/memory_cluster.dart';
import 'models/person.dart';

/// The single source of truth for the UI. Everything the Entegram feed shows
/// is read from this Isar instance — never from the network directly. The
/// background sync pipeline is the only writer.
class IsarDb {
  IsarDb._(this.isar);

  final Isar isar;

  static const List<CollectionSchema<dynamic>> schemas = [
    EnteCollectionSchema,
    EnteFileSchema,
    PersonSchema,
    MemoryClusterSchema,
  ];

  /// Opens the local library. Isar handles compatible migrations. An I/O or
  /// schema error must surface instead of silently deleting a user's database
  /// while leaving persisted sync cursors pointing beyond the lost history.
  static Future<IsarDb> open({String? directoryOverride}) async {
    final dir =
        directoryOverride ?? (await getApplicationDocumentsDirectory()).path;
    final isar = await Isar.open(schemas, directory: dir, name: 'entegram');
    return IsarDb._(isar);
  }

  /// Opens an Isar instance pointed at an already-open database from a
  /// background isolate (same name + directory, so writes are shared).
  static Future<Isar> openInIsolate(String directory) async {
    final existing = Isar.getInstance('entegram');
    if (existing != null) return existing;
    return Isar.open(schemas, directory: directory, name: 'entegram');
  }
}
