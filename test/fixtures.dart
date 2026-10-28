import 'package:entegram/src/db/models/ente_file.dart';
import 'package:entegram/src/db/models/memory_cluster.dart';
import 'package:entegram/src/db/models/person.dart';

EnteFile photo(
  int id,
  DateTime date, {
  double? lat,
  double? lon,
  String? hash,
  String? title,
  List<String> people = const [],
}) => EnteFile()
  ..id = id
  ..collectionID = 1
  ..ownerID = 1
  ..fileType = 0
  ..creationTime = date.microsecondsSinceEpoch
  ..modificationTime = 0
  ..updationTime = date.microsecondsSinceEpoch
  ..latitude = lat
  ..longitude = lon
  ..width = 2400
  ..height = 1600
  ..hash = hash
  ..title = title
  ..personIds = people;

Person person(String id, String name, List<int> files, {bool hidden = false}) =>
    Person()
      ..remoteID = id
      ..name = name
      ..fileIds = files
      ..isHidden = hidden
      ..updationTime = 0;

MemoryCluster memory(int id, {String? signature, List<int>? files}) =>
    MemoryCluster()
      ..id = id
      ..signature = signature ?? 'v2:day:$id'
      ..title = 'Memory $id'
      ..kind = MemoryKind.trip
      ..startTime = DateTime(2020, 1, id.clamp(1, 28)).microsecondsSinceEpoch
      ..endTime = DateTime(2020, 1, id.clamp(1, 28)).microsecondsSinceEpoch
      ..fileIds = files ?? [id * 10, id * 10 + 1]
      ..coverFileId = files?.first ?? id * 10
      ..generatedAt = 0;
