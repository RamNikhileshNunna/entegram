// Opt-in live verification. No account values are embedded or written to disk.
import 'dart:convert';
import 'dart:ffi';
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:entegram/main.dart';
import 'package:entegram/src/auth/auth_models.dart';
import 'package:entegram/src/auth/auth_service.dart';
import 'package:entegram/src/db/isar_db.dart';
import 'package:entegram/src/db/models/ente_file.dart';
import 'package:entegram/src/db/models/memory_cluster.dart';
import 'package:entegram/src/db/models/person.dart';
import 'package:entegram/src/media/full_res_service.dart';
import 'package:entegram/src/media/thumbnail_service.dart';
import 'package:entegram/src/memories/memory_catalog.dart';
import 'package:entegram/src/memories/memory_mapper.dart';
import 'package:entegram/src/network/ente_api.dart';
import 'package:entegram/src/providers.dart';
import 'package:entegram/src/sync/crypto_isolate.dart';
import 'package:entegram/src/sync/sync_service.dart';
import 'package:entegram/src/ui/feed_screen.dart';
import 'package:entegram/src/ui/widgets/memory_card.dart';
import 'package:entegram/src/ui/widgets/media_image.dart';
import 'package:entegram/src/ui/widgets/story_viewer.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:isar_community/isar.dart';
import 'package:photo_view/photo_view.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _LiveHttp extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) {
    final trust = context ?? SecurityContext(withTrustedRoots: true);
    final ca = Platform.environment['SSL_CERT_FILE'];
    if (ca != null && File(ca).existsSync()) trust.setTrustedCertificates(ca);
    final client = super.createHttpClient(trust);
    client.findProxy = (uri) => HttpClient.findProxyFromEnvironment(
      uri,
      environment: Platform.environment,
    );
    return client;
  }
}

class _LiveApi extends EnteApi {
  _LiveApi(String url, Dio dio) : super(baseUrl: url, dio: dio);
  @override
  Future<void> downloadFileToDisk(
    int fileID,
    String savePath, {
    void Function(int received, int total)? onProgress,
    CancelToken? cancelToken,
  }) {
    final token = cancelToken ?? CancelToken();
    return super.downloadFileToDisk(
      fileID,
      savePath,
      cancelToken: token,
      onProgress: (received, total) {
        if (received > 96 * 1024 * 1024 || total > 96 * 1024 * 1024) {
          token.cancel('Live sample limit');
        }
        onProgress?.call(received, total);
      },
    );
  }
}

void checkpoint(String value) {
  final report = Platform.environment['ENTE_TEST_REPORT'];
  if (report != null) {
    File(report).writeAsStringSync(
      '${jsonEncode({'check': value})}\n',
      mode: FileMode.append,
    );
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  testWidgets(
    'live self-hosted sign-in, complete sync, curation and media',
    (tester) async {
      Directory? temporary;
      IsarDb? db;
      CryptoIsolate? crypto;
      ThumbnailService? thumbs;
      FullResService? originals;
      ProviderContainer? container;
      Dio? transport;
      var phase = 'LOGIN';
      final uiOnly = Platform.environment['ENTE_TEST_UI_SMOKE'] == '1';
      SharedPreferences? livePreferences;
      EnteApi? liveApi;
      Session? liveSession;
      final memberships = <int, Set<int>>{};
      final oldSyncIds = <int>{};
      final sizes = <int, int>{};
      var rawPeople = 0;
      Future<void> settleIo() async {
        for (var i = 0; i < 5; i++) {
          await tester.pump();
          await tester.runAsync(
            () => Future<void>.delayed(const Duration(milliseconds: 100)),
          );
          await tester.pump(const Duration(milliseconds: 50));
        }
      }

      try {
        await tester.runAsync(
          () => HttpOverrides.runWithHttpOverrides(() async {
            final url = Platform.environment['ENTE_TEST_URL']!;
            transport = Dio(
              BaseOptions(
                baseUrl: url,
                connectTimeout: const Duration(seconds: 20),
                receiveTimeout: const Duration(seconds: 120),
                headers: {
                  'X-Client-Package': 'com.entegram',
                  'X-Client-Version': '1.0.0',
                },
              ),
            );
            transport!.interceptors.add(
              InterceptorsWrapper(
                onResponse: (response, handler) {
                  final data = response.data;
                  if (data is Map && data['diff'] is List) {
                    final entries = (data['diff'] as List).whereType<Map>();
                    if (response.requestOptions.path ==
                        '/collections/v2/diff') {
                      for (final item in entries) {
                        final fileId = item['id'] as int;
                        final collectionId =
                            response
                                    .requestOptions
                                    .queryParameters['collectionID']
                                as int;
                        final links = memberships.putIfAbsent(fileId, () => {});
                        if (item['isDeleted'] == true) {
                          links.remove(collectionId);
                          oldSyncIds.remove(fileId);
                        } else {
                          links.add(collectionId);
                          oldSyncIds.add(fileId);
                        }
                        final size = (item['file'] as Map?)?['size'];
                        if (item['id'] is int && size is num) {
                          sizes[item['id'] as int] = size.toInt();
                        }
                      }
                    } else if (response.requestOptions.path ==
                        '/user-entity/entity/diff') {
                      rawPeople += entries.length;
                    }
                  }
                  handler.next(response);
                },
              ),
            );
            final api = _LiveApi(url, transport!);
            checkpoint('LOGIN_STARTED');
            final result = await AuthService(api).login(
              email: Platform.environment['ENTE_TEST_EMAIL']!,
              password: Platform.environment['ENTE_TEST_PASSWORD']!,
            );
            if (result is LoginTwoFactorRequired) {
              checkpoint('LOGIN_FACTOR_REQUIRED');
              fail('Additional authentication factor required');
            }
            final session = (result as LoginSuccess).session;
            expect(session.token.isNotEmpty, isTrue);
            expect(session.masterKey.length, 32);
            checkpoint('LOGIN_OK');
            phase = 'NATIVE_STORAGE';
            final configFile = File('.dart_tool/package_config.json').absolute;
            final config = jsonDecode(await configFile.readAsString()) as Map;
            final package = (config['packages'] as List)
                .cast<Map>()
                .singleWhere((p) => p['name'] == 'isar_community_flutter_libs');
            await Isar.initializeIsarCore(
              libraries: {
                Abi.current(): configFile.uri
                    .resolve('${package['rootUri']}/')
                    .resolve('linux/libisar.so')
                    .toFilePath(),
              },
            );
            temporary = Directory(Platform.environment['ENTE_TEST_STORAGE']!);
            await temporary!.create(recursive: true);
            TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
                .setMockMethodCallHandler(
                  const MethodChannel('plugins.flutter.io/path_provider'),
                  (_) async => temporary!.path,
                );
            SharedPreferences.setMockInitialValues({'ente_endpoint': url});
            final prefs = await SharedPreferences.getInstance();
            db = await IsarDb.open(directoryOverride: temporary!.path);
            crypto = await CryptoIsolate.spawn(
              masterKey: session.masterKey,
              secretKey: session.secretKey,
              publicKey: session.publicKey,
              currentUserID: session.userID,
            );
            final sync = SyncService(
              api: api,
              db: db!,
              crypto: crypto!,
              preferences: prefs,
              cursorNamespace: 'live-check-only',
            );
            phase = 'COLLECTIONS';
            await sync.syncCollections();
            checkpoint('COLLECTIONS_OK');
            phase = 'PEOPLE';
            final people = await sync.syncPersons();
            expect(
              people,
              rawPeople,
              reason: 'Every returned person entity must decrypt',
            );
            checkpoint('PEOPLE_OK count=$people');
            phase = 'ARCHIVE';
            var finished = false;
            var pages = 0;
            for (; pages < 2000; pages++) {
              final progress = await sync.syncNextFilesPage(
                prioritizeRecent: false,
              );
              if (pages % 10 == 0) {
                checkpoint(
                  'SYNC_PROGRESS pages=${pages + 1} files=${await db!.isar.enteFiles.count()}',
                );
              }
              if (!progress.hasMore || (uiOnly && pages >= 4)) {
                finished = true;
                break;
              }
            }
            expect(
              finished,
              isTrue,
              reason: 'Archive verification exceeded its page bound',
            );
            final files = await db!.isar.enteFiles.where().findAll();
            checkpoint(
              '${uiOnly ? 'PARTIAL_ARCHIVE_UI_ONLY' : 'ARCHIVE_OK'} files=${files.length} pages=${pages + 1}',
            );
            phase = 'ARCHIVE_MEMBERSHIPS';
            final expectedIds = memberships.entries
                .where((e) => e.value.isNotEmpty)
                .map((e) => e.key)
                .toSet();
            final actualIds = files.map((f) => f.id).toSet();
            checkpoint(
              'ARCHIVE_LINKS expected=${expectedIds.length} missing=${expectedIds.difference(actualIds).length} extra=${actualIds.difference(expectedIds).length}',
            );
            expect(
              actualIds,
              expectedIds,
              reason: 'LIVE_COLLECTION_MEMBERSHIP_MISMATCH',
            );
            for (final file in files) {
              expect(
                file.collectionKeys.map((k) => k.collectionID).toSet(),
                memberships[file.id],
                reason: 'LIVE_KEY_MEMBERSHIPS',
              );
              expect(
                memberships[file.id],
                contains(file.collectionID),
                reason: 'LIVE_ACTIVE_KEY',
              );
            }
            checkpoint(
              'ALBUM_KEYS_OK recovered=${actualIds.difference(oldSyncIds).length}',
            );
            phase = 'MEMORIES';
            await MemoryMapper(db!).rebuild();
            final memories = await db!.isar.memoryClusters.where().findAll();
            final byId = {for (final f in files) f.id: f};
            final today = DateTime.now();
            expect(memories.length, lessThanOrEqualTo(80));
            for (final m in memories) {
              expect(m.fileIds.toSet().length, m.fileIds.length);
              expect(m.fileIds, contains(m.coverFileId));
              expect(m.fileIds.every(byId.containsKey), isTrue);
              if (m.category == MemoryCategory.onThisDay) {
                for (final id in m.fileIds) {
                  final date = DateTime.fromMicrosecondsSinceEpoch(
                    byId[id]!.creationTime,
                  );
                  expect(date.month, today.month);
                  expect(date.day, today.day);
                  expect(date.year, lessThan(today.year));
                }
              }
            }
            checkpoint(
              'MEMORIES_OK count=${memories.length} people=${await db!.isar.persons.count()}',
            );
            thumbs = ThumbnailService(
              api: api,
              crypto: crypto!,
              cacheNamespace: 'live-check',
            );
            originals = FullResService(
              api: api,
              crypto: crypto!,
              cacheNamespace: 'live-check',
            );
            phase = 'THUMBNAILS';
            var decoded = 0;
            final thumbnailSamples = <int, EnteFile>{
              for (final file
                  in files
                      .where(
                        (f) =>
                            !oldSyncIds.contains(f.id) &&
                            f.thumbnailDecryptionHeader != null,
                      )
                      .take(2))
                file.id: file,
              for (final file
                  in files
                      .where((f) => f.thumbnailDecryptionHeader != null)
                      .take(3))
                file.id: file,
            }.values.take(3);
            for (final file in thumbnailSamples) {
              final bytes = await thumbs!.get(file);
              expect(bytes, isNotNull);
              expect(await canDisplayImage(bytes!), isTrue);
              decoded++;
            }
            if (files.isNotEmpty) expect(decoded, greaterThan(0));
            checkpoint('THUMBNAILS_OK decoded=$decoded');
            if (!uiOnly) {
              phase = 'ORIGINALS';
              var images = 0;
              final eligibleImages = files.where(
                (f) =>
                    f.fileType == 0 &&
                    originals!.canDecrypt(f) &&
                    RegExp(
                      r'\.(jpg|jpeg|png|webp)$',
                      caseSensitive: false,
                    ).hasMatch(f.title ?? ''),
              );
              for (final file in eligibleImages.take(2)) {
                final bytes = await originals!.getImageBytes(file);
                expect(await canDisplayImage(bytes), isTrue);
                images++;
              }
              checkpoint('ORIGINALS_OK decoded=$images');
              phase = 'VIDEO';
              final videos =
                  files
                      .where(
                        (f) =>
                            f.fileType == 1 &&
                            originals!.canDecrypt(f) &&
                            (sizes[f.id] ?? 0) > 0 &&
                            sizes[f.id]! <= 96 * 1024 * 1024,
                      )
                      .toList()
                    ..sort((a, b) => sizes[a.id]!.compareTo(sizes[b.id]!));
              final allVideos = files
                  .where((f) => f.fileType == 1 && originals!.canDecrypt(f))
                  .toList();
              checkpoint(
                'VIDEO_COUNTS total=${allVideos.length} sized=${videos.length}',
              );
              if (videos.isEmpty && allVideos.isNotEmpty) {
                videos.add(allVideos.first);
              }
              if (videos.isNotEmpty) {
                final path = await originals!.getVideoPath(videos.first);
                final probe = await Process.run('ffprobe', [
                  '-v',
                  'error',
                  '-select_streams',
                  'v:0',
                  '-show_entries',
                  'stream=codec_type,width,height',
                  '-of',
                  'json',
                  path,
                ]);
                expect(probe.exitCode, 0);
                final info = jsonDecode(probe.stdout as String) as Map;
                expect((info['streams'] as List).isNotEmpty, isTrue);
                final frame = await Process.run('ffmpeg', [
                  '-v',
                  'error',
                  '-i',
                  path,
                  '-t',
                  '1',
                  '-f',
                  'null',
                  '-',
                ]);
                expect(frame.exitCode, 0);
                checkpoint('VIDEO_DECRYPT_AND_DECODE_OK');
              } else {
                checkpoint('VIDEO_SAMPLE_UNAVAILABLE');
              }
            }
            livePreferences = prefs;
            liveApi = api;
            liveSession = session;
            checkpoint('LIVE_DATA_READY');
          }, _LiveHttp()),
        );
        final networkError = tester.takeException();
        if (networkError != null) throw networkError;
        container = ProviderContainer(
          overrides: [
            sharedPreferencesProvider.overrideWithValue(livePreferences!),
            isarDbProvider.overrideWith((_) async => db!),
            enteApiProvider.overrideWithValue(liveApi!),
            thumbnailServiceProvider.overrideWithValue(thumbs),
            fullResServiceProvider.overrideWithValue(originals),
            bootstrapProvider.overrideWith((_) async {}),
            loadMoreProvider.overrideWithValue(() async => false),
          ],
        );
        await container.read(sessionProvider.notifier).set(liveSession!);
        phase = 'FEED_UI';
        await tester.pumpWidget(
          UncontrolledProviderScope(
            container: container,
            child: MaterialApp(theme: enteTheme, home: const FeedScreen()),
          ),
        );
        await settleIo();
        expect(tester.takeException(), isNull);
        final memories = container.read(memoriesProvider).value ?? [];
        if (memories.isNotEmpty) {
          expect(find.byType(MemoryCard), findsWidgets);
          checkpoint('FEED_UI_OK');
          phase = 'STORY_UI';
          final files = await tester.runAsync(
            () => db!.isar.enteFiles.where().findAll(),
          );
          final byId = {for (final f in files!) f.id: f};
          final target = memories
              .where(
                (m) =>
                    m.fileIds.isNotEmpty &&
                    byId[m.fileIds.first]?.fileType == 0,
              )
              .first;
          phase = 'STORY_THUMBNAIL';
          await tester.runAsync(() async {
            final bytes = await thumbs!.get(byId[target.fileIds.first]!);
            expect(bytes, isNotNull, reason: 'LIVE_STORY_THUMB_MISSING');
            expect(
              await canDisplayImage(bytes!),
              isTrue,
              reason: 'LIVE_STORY_THUMB_DECODE',
            );
          });
          final thumbnailError = tester.takeException();
          if (thumbnailError != null) throw thumbnailError;
          checkpoint('STORY_THUMBNAIL_OK');
          phase = 'STORY_UI';
          final context = tester.element(find.byType(FeedScreen));
          final ref = tester
              .state<ConsumerState<FeedScreen>>(find.byType(FeedScreen))
              .ref;
          openStoryViewer(
            context,
            memories: [target],
            initialMemoryIndex: 0,
            ref: ref,
          );
          await tester.pump();
          await tester.pump(const Duration(milliseconds: 250));
          await tester.tap(find.byTooltip('Pause story'));
          await tester.pump();
          await settleIo();
          for (var attempt = 0; attempt < 12; attempt++) {
            if (tester
                .widgetList<RawImage>(
                  find.descendant(
                    of: find.byType(StoryMedia),
                    matching: find.byType(RawImage),
                  ),
                )
                .any((w) => w.image != null)) {
              break;
            }
            await settleIo();
          }
          expect(
            find.byType(StoryViewer),
            findsOneWidget,
            reason: 'LIVE_STORY_ROUTE',
          );
          expect(tester.takeException(), isNull);
          expect(
            tester
                .widgetList<RawImage>(
                  find.descendant(
                    of: find.byType(StoryMedia),
                    matching: find.byType(RawImage),
                  ),
                )
                .any((w) => w.image != null),
            isTrue,
            reason: 'LIVE_STORY_IMAGE_NOT_PAINTED',
          );
          checkpoint('STORY_UI_IMAGE_RENDER_OK');
          phase = 'GALLERY_UI';
          await tester.tap(find.byTooltip('View original'));
          await tester.pump();
          await tester.pump(const Duration(milliseconds: 300));
          await settleIo();
          expect(find.byType(PhotoView), findsWidgets);
          expect(tester.takeException(), isNull);
          for (var attempt = 0; attempt < 12; attempt++) {
            if (tester
                .widgetList<RawImage>(
                  find.descendant(
                    of: find.byType(PhotoView),
                    matching: find.byType(RawImage),
                  ),
                )
                .any((w) => w.image != null)) {
              break;
            }
            await settleIo();
          }
          expect(
            tester
                .widgetList<RawImage>(
                  find.descendant(
                    of: find.byType(PhotoView),
                    matching: find.byType(RawImage),
                  ),
                )
                .any((w) => w.image != null),
            isTrue,
            reason: 'LIVE_GALLERY_IMAGE_NOT_PAINTED',
          );
          checkpoint('ORIGINAL_GALLERY_UI_IMAGE_RENDER_OK');
        } else {
          checkpoint('MEMORY_UI_EMPTY_LIBRARY');
        }
        checkpoint(uiOnly ? 'UI_SMOKE_COMPLETE' : 'LIVE_VERIFICATION_COMPLETE');
      } catch (error) {
        if (error is DioException) {
          checkpoint(
            'FAILED_HTTP phase=$phase status=${error.response?.statusCode ?? 0} type=${error.type.name}',
          );
        } else {
          checkpoint('FAILED phase=$phase type=${error.runtimeType}');
          final message = error.toString();
          for (final code in [
            'LIVE_COLLECTION_MEMBERSHIP_MISMATCH',
            'LIVE_KEY_MEMBERSHIPS',
            'LIVE_ACTIVE_KEY',
            'LIVE_GALLERY_IMAGE_NOT_PAINTED',
            'LIVE_STORY_ROUTE',
            'LIVE_STORY_IMAGE_NOT_PAINTED',
            'LIVE_STORY_THUMB_MISSING',
            'LIVE_STORY_THUMB_DECODE',
          ]) {
            if (message.contains(code)) checkpoint('DETAIL code=$code');
          }
          if (message.contains('unsendable') ||
              message.contains('Illegal argument in isolate')) {
            checkpoint('DETAIL_ISOLATE_MESSAGE_NOT_SENDABLE');
          }
          if (message.contains('libsodium') ||
              message.contains('DynamicLibrary')) {
            checkpoint('DETAIL_NATIVE_LIBRARY');
          }
          if (message.contains('MissingPlugin')) {
            checkpoint('DETAIL_PLATFORM_PLUGIN');
          }
          if (message.contains('Email-based MFA')) {
            checkpoint('DETAIL_EMAIL_MFA_REQUIRED');
          }
        }
        if (phase == 'STORY_UI' || phase == 'GALLERY_UI') {
          checkpoint(
            'UI_COUNTS stories=${find.byType(StoryViewer).evaluate().length} media=${find.byType(StoryMedia).evaluate().length} frames=${tester.widgetList<RawImage>(find.byType(RawImage)).where((w) => w.image != null).length}',
          );
        }
        rethrow;
      } finally {
        checkpoint('CLEANUP_WIDGETS_STARTED');
        await tester.pumpWidget(const SizedBox.shrink());
        checkpoint('CLEANUP_WIDGETS_DONE');
        container?.dispose();
        await tester.runAsync(() async {
          thumbs?.dispose();
          originals?.dispose();
          transport?.close(force: true);
          crypto?.dispose();
          await Future<void>.delayed(const Duration(milliseconds: 200));
          try {
            await db?.isar
                .close(deleteFromDisk: true)
                .timeout(const Duration(seconds: 3));
          } catch (_) {
            checkpoint('CLEANUP_STORAGE_DEFERRED_TO_RUNNER');
          }
        });
        // Let the gallery's deferred neighbour prefetch return after unmount.
        // Network/media cleanup above has already stopped its services.
        await tester.pump(const Duration(seconds: 5));
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMethodCallHandler(
              const MethodChannel('plugins.flutter.io/path_provider'),
              null,
            );
        checkpoint('LOCAL_CLIENTS_DISPOSED');
      }
    },
    timeout: const Timeout(Duration(minutes: 20)),
    skip: Platform.environment['ENTE_TEST_PASSWORD'] == null,
  );
}
