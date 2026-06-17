import 'dart:io';

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

  /// Opens the app-facing database in the platform documents directory.
  /// If the schema has changed and Isar cannot migrate, the database is
  /// deleted and recreated so the app can always open (data re-syncs from
  /// the server on next bootstrap).
  static Future<IsarDb> open({String? directoryOverride}) async {
    final dir =
        directoryOverride ?? (await getApplicationDocumentsDirectory()).path;
    try {
      final isar = await Isar.open(schemas, directory: dir, name: 'entegram');
      return IsarDb._(isar);
    } catch (_) {
      // Schema migration failed — wipe and reopen.
      final dbFile = '$dir/entegram.isar';
      final lockFile = '$dir/entegram.isar.lock';
      try { await File(dbFile).delete(); } catch (_) {}
      try { await File(lockFile).delete(); } catch (_) {}
      final isar = await Isar.open(schemas, directory: dir, name: 'entegram');
      return IsarDb._(isar);
    }
  }

  /// Opens an Isar instance pointed at an already-open database from a
  /// background isolate (same name + directory, so writes are shared).
  static Future<Isar> openInIsolate(String directory) async {
    final existing = Isar.getInstance('entegram');
    if (existing != null) return existing;
    return Isar.open(schemas, directory: directory, name: 'entegram');
  }
}
