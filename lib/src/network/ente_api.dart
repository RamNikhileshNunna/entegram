import 'dart:typed_data';

import 'package:dio/dio.dart';

/// Thin wrapper over the Ente.io REST API. Returns **raw, still-encrypted**
/// JSON; nothing here decrypts. That keeps this class cheap to use from the
/// background isolate where the heavy libsodium work happens.
///
/// Endpoints/headers verified against the Ente Flutter client:
///   * base URL          https://api.ente.io
///   * auth header       `X-Auth-Token`
///   * SRP attributes    GET  /users/srp/attributes
///   * SRP handshake     POST /users/srp/create-session, /users/srp/verify-session
///   * collections       GET  /collections/v2, /collections/v2/diff
///   * person entities   GET  /user-entity/entity/diff, /user-entity/key
class EnteApi {
  EnteApi({
    String baseUrl = defaultBaseUrl,
    String clientPackage = 'com.entegram',
    String clientVersion = '1.0.0',
    Dio? dio,
  }) : _dio =
           dio ??
           Dio(
             BaseOptions(
               baseUrl: baseUrl,
               connectTimeout: const Duration(seconds: 15),
               receiveTimeout: const Duration(seconds: 30),
               headers: {
                 'X-Client-Package': clientPackage,
                 'X-Client-Version': clientVersion,
               },
             ),
           );

  static const String defaultBaseUrl = 'https://api.ente.io';

  /// Production API hosts that are fronted by Ente's CloudFlare CDN workers.
  /// Self-hosted endpoints are not, so we serve media directly from them.
  static const Set<String> _productionHosts = {
    'https://api.ente.io',
    'https://api.ente.com',
  };
  static const String _thumbnailWorker = 'https://thumbnails.ente.com';
  static const String _fileWorker = 'https://files.ente.com';

  final Dio _dio;
  String? _authToken;

  // Per-host CDN-worker circuit breaker. If a worker host fails this many times
  // in a row we stop routing to it for the rest of the session and go straight
  // to the API endpoint — so a worker that's bad for this account doesn't cost
  // a failover round-trip on every single image.
  static const int _maxWorkerFailures = 3;
  final Map<String, int> _workerFailures = {};
  final Set<String> _disabledWorkerHosts = {};

  /// The active server endpoint.
  String get baseUrl => _dio.options.baseUrl;

  /// True when the endpoint is official Ente production, so media can be served
  /// from the edge-cached CDN workers. Self-hosted instances have no workers —
  /// media is fetched from the endpoint directly.
  bool get _useWorker => _productionHosts.contains(baseUrl);

  /// Sets the `X-Auth-Token` used on authenticated requests (post-login).
  set authToken(String? token) => _authToken = token;

  // Authenticated options for metadata calls (collections, file/entity diffs).
  // These responses can be large for big libraries and routinely take longer
  // than the global 30s default, so give them a generous ceiling — it only
  // waits this long if the server is actually slow.
  Options get _authed => Options(
    headers: _authToken == null ? null : {'X-Auth-Token': _authToken},
    receiveTimeout: const Duration(seconds: 120),
    sendTimeout: const Duration(seconds: 60),
  );

  // ---------------------------------------------------------------------------
  // Auth / SRP
  // ---------------------------------------------------------------------------

  /// `GET /users/srp/attributes?email=` → srpUserID, srpSalt, mem/opsLimit, kekSalt.
  /// Some server versions wrap the payload in `{"attributes": {...}}`; others
  /// return it at the top level — tolerate both.
  Future<Map<String, dynamic>> srpAttributes(String email) async {
    final res = await _dio.get<dynamic>(
      '/users/srp/attributes',
      queryParameters: {'email': email},
    );
    final data = (res.data as Map).cast<String, dynamic>();
    final inner = data['attributes'];
    return (inner is Map ? inner : data).cast<String, dynamic>();
  }

  /// `POST /users/srp/create-session` → sessionID, srpB.
  Future<Map<String, dynamic>> srpCreateSession({
    required String srpUserID,
    required String srpA,
  }) async {
    final res = await _dio.post<Map<String, dynamic>>(
      '/users/srp/create-session',
      data: {'srpUserID': srpUserID, 'srpA': srpA},
    );
    return res.data!;
  }

  /// `POST /users/srp/verify-session` → token/encryptedToken, keyAttributes, …
  /// or, for 2FA accounts, twoFactorSessionID(V2)/passkeySessionID.
  Future<Map<String, dynamic>> srpVerifySession({
    required String srpUserID,
    required String sessionID,
    required String srpM1,
  }) async {
    final res = await _dio.post<Map<String, dynamic>>(
      '/users/srp/verify-session',
      data: {'srpUserID': srpUserID, 'sessionID': sessionID, 'srpM1': srpM1},
    );
    return res.data!;
  }

  /// `POST /users/two-factor/verify` → {id, keyAttributes, encryptedToken} once
  /// the TOTP [code] for [sessionID] checks out. 404 means the session expired.
  Future<Map<String, dynamic>> verifyTwoFactor({
    required String sessionID,
    required String code,
  }) async {
    final res = await _dio.post<Map<String, dynamic>>(
      '/users/two-factor/verify',
      data: {'sessionID': sessionID, 'code': code},
    );
    return res.data!;
  }

  // ---------------------------------------------------------------------------
  // Collections + files
  // ---------------------------------------------------------------------------

  /// `GET /collections/v2?sinceTime=` → list of (encrypted) collections changed
  /// since [sinceTime] (microseconds).
  Future<List<Map<String, dynamic>>> collections({int sinceTime = 0}) async {
    final res = await _dio.get<Map<String, dynamic>>(
      '/collections/v2',
      queryParameters: {'sinceTime': sinceTime, 'source': 'fg'},
      options: _authed,
    );
    final list = (res.data!['collections'] as List?) ?? const [];
    return list.cast<Map<String, dynamic>>();
  }

  /// `GET /collections/v2/diff?collectionID=&sinceTime=` → one page of
  /// (encrypted) file diffs plus `hasMore`.
  Future<EnteDiffPage> collectionDiff({
    required int collectionID,
    required int sinceTime,
  }) async {
    final res = await _dio.get<Map<String, dynamic>>(
      '/collections/v2/diff',
      queryParameters: {'collectionID': collectionID, 'sinceTime': sinceTime},
      options: _authed,
    );
    return EnteDiffPage(
      items: ((res.data!['diff'] as List?) ?? const [])
          .cast<Map<String, dynamic>>(),
      hasMore: res.data!['hasMore'] == true,
    );
  }

  // ---------------------------------------------------------------------------
  // ML / person entities
  // ---------------------------------------------------------------------------

  // ---------------------------------------------------------------------------
  // Media
  // ---------------------------------------------------------------------------

  /// Whether a [DioException] is worth retrying: network timeouts, dropped
  /// connections, and transient server errors (429 rate-limit, 5xx). A cancel
  /// or a 4xx (other than 429) is permanent and must not be retried.
  static bool isTransient(DioException e) {
    switch (e.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
      case DioExceptionType.connectionError:
        return true;
      case DioExceptionType.badResponse:
        final code = e.response?.statusCode ?? 0;
        return code == 429 || (code >= 500 && code <= 599);
      case DioExceptionType.unknown:
        // Usually a socket-level failure surfaced without a response.
        return e.error is! FormatException;
      default:
        return false;
    }
  }

  /// Downloads the *encrypted* full file bytes for [fileID].
  /// Pass [cancelToken] to abort the request (e.g. when the user navigates away).
  /// Pass [onReceiveProgress] to drive a download progress indicator.
  ///
  /// On production this fetches from the `files.ente.com` CDN worker and falls
  /// back to `$endpoint/files/download/{id}` on any non-cancel error. On a
  /// self-hosted endpoint it goes straight to the endpoint.
  Future<Uint8List> downloadFile(
    int fileID, {
    CancelToken? cancelToken,
    void Function(int received, int total)? onReceiveProgress,
  }) {
    return _downloadBytes(
      workerUrl: _useWorker ? '$_fileWorker/?fileID=$fileID' : null,
      directUrl: '/files/download/$fileID',
      cancelToken: cancelToken,
      onReceiveProgress: onReceiveProgress,
      receiveTimeout: const Duration(minutes: 10),
    );
  }

  /// Shared worker-with-fallback download used by [downloadFile] and
  /// [downloadThumbnail]. Tries [workerUrl] first (when non-null); on any error
  /// other than an explicit cancel it retries once against [directUrl].
  Future<Uint8List> _downloadBytes({
    required String? workerUrl,
    required String directUrl,
    CancelToken? cancelToken,
    void Function(int received, int total)? onReceiveProgress,
    required Duration receiveTimeout,
    Duration? workerReceiveTimeout,
  }) async {
    Future<Uint8List> fetch(String url, Duration rt) async {
      final res = await _dio.get<List<int>>(
        url,
        cancelToken: cancelToken,
        onReceiveProgress: onReceiveProgress,
        options: Options(
          responseType: ResponseType.bytes,
          headers: _authToken == null ? null : {'X-Auth-Token': _authToken},
          sendTimeout: const Duration(minutes: 5),
          receiveTimeout: rt,
        ),
      );
      return Uint8List.fromList(res.data!);
    }

    if (workerUrl == null) return fetch(directUrl, receiveTimeout);
    final host = Uri.parse(workerUrl).host;
    if (_disabledWorkerHosts.contains(host)) {
      return fetch(directUrl, receiveTimeout);
    }
    try {
      // The worker attempt gets a short timeout so a slow/stalled CDN edge
      // fails over to the direct endpoint quickly instead of blocking the
      // caller (and, for thumbnails, a download-concurrency slot).
      final bytes = await fetch(workerUrl, workerReceiveTimeout ?? receiveTimeout);
      _workerFailures.remove(host); // healthy again — reset the streak
      return bytes;
    } on DioException catch (e) {
      if (CancelToken.isCancel(e)) rethrow;
      final failures = (_workerFailures[host] ?? 0) + 1;
      _workerFailures[host] = failures;
      if (failures >= _maxWorkerFailures) _disabledWorkerHosts.add(host);
      return fetch(directUrl, receiveTimeout);
    }
  }

  /// Streams the encrypted full file directly to [savePath] on disk.
  /// Use this for large files (videos) to avoid OOM.
  Future<void> downloadFileToDisk(
    int fileID,
    String savePath, {
    void Function(int received, int total)? onProgress,
    CancelToken? cancelToken,
  }) async {
    await _dio.download(
      '/files/download/$fileID',
      savePath,
      cancelToken: cancelToken,
      onReceiveProgress: onProgress,
      options: Options(
        headers: _authToken == null ? null : {'X-Auth-Token': _authToken},
        sendTimeout: const Duration(minutes: 5),
        receiveTimeout: const Duration(minutes: 30),
      ),
    );
  }

  /// Downloads the *encrypted* thumbnail bytes for [fileID]. Decryption happens
  /// in the crypto isolate.
  ///
  /// On production this uses the `thumbnails.ente.com` CDN worker (edge-cached,
  /// fast) and falls back to `$endpoint/files/preview/{id}`. On a self-hosted
  /// endpoint it fetches `$endpoint/files/preview/{id}` directly.
  Future<Uint8List> downloadThumbnail(
    int fileID, {
    CancelToken? cancelToken,
  }) {
    return _downloadBytes(
      workerUrl: _useWorker ? '$_thumbnailWorker/?fileID=$fileID' : null,
      directUrl: '/files/preview/$fileID',
      cancelToken: cancelToken,
      // Thumbnails are tiny; a healthy fetch is sub-second. Keep timeouts short
      // so a bad worker edge fails over fast and never wedges the queue.
      workerReceiveTimeout: const Duration(seconds: 8),
      receiveTimeout: const Duration(seconds: 30),
    );
  }

  /// `GET /user-entity/key?type=person` → the entity key (encrypted with the
  /// master key) used to decrypt all person/cluster payloads.
  Future<Map<String, dynamic>> entityKey(String type) async {
    final res = await _dio.get<Map<String, dynamic>>(
      '/user-entity/key',
      queryParameters: {'type': type},
      options: _authed,
    );
    return res.data!;
  }

  /// `GET /user-entity/entity/diff?type=&sinceTime=&limit=` → page of encrypted
  /// person/cluster entities.
  Future<List<Map<String, dynamic>>> entityDiff({
    required String type,
    int sinceTime = 0,
    int limit = 500,
  }) async {
    final res = await _dio.get<Map<String, dynamic>>(
      '/user-entity/entity/diff',
      queryParameters: {'type': type, 'sinceTime': sinceTime, 'limit': limit},
      options: _authed,
    );
    return ((res.data!['diff'] as List?) ?? const [])
        .cast<Map<String, dynamic>>();
  }
}

/// One page of a collection diff.
class EnteDiffPage {
  EnteDiffPage({required this.items, required this.hasMore});

  final List<Map<String, dynamic>> items;
  final bool hasMore;
}
