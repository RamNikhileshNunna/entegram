import 'dart:async';
import 'dart:io';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'package:photo_view/photo_view.dart';
import 'package:share_plus/share_plus.dart';
import 'package:video_player/video_player.dart';

import '../../db/models/ente_file.dart';
import '../../db/models/memory_cluster.dart';
import '../../providers.dart';
import 'person_chips.dart';

void openStoryViewer(
  BuildContext context, {
  required List<MemoryCluster> memories,
  required int initialMemoryIndex,
  required WidgetRef ref,
}) {
  Navigator.of(context).push(
    PageRouteBuilder<void>(
      opaque: false,
      barrierColor: Colors.black,
      transitionDuration: const Duration(milliseconds: 200),
      pageBuilder: (context, animation, _) => FadeTransition(
        opacity: animation,
        child: ProviderScope(
          overrides: [],
          child: _StoryViewer(
            memories: memories,
            initialMemoryIndex: initialMemoryIndex,
          ),
        ),
      ),
    ),
  );
}

class _StoryViewer extends ConsumerStatefulWidget {
  const _StoryViewer({
    required this.memories,
    required this.initialMemoryIndex,
  });

  final List<MemoryCluster> memories;
  final int initialMemoryIndex;

  @override
  ConsumerState<_StoryViewer> createState() => _StoryViewerState();
}

class _StoryViewerState extends ConsumerState<_StoryViewer>
    with TickerProviderStateMixin {
  late int _memoryIndex;
  int _photoIndex = 0;
  List<EnteFile> _files = [];
  bool _loading = true;
  bool _sharing = false;

  bool _isZoomed = false;
  bool _suppressNav = false; // set by button Listeners to block the next navigation
  int _activePointers = 0;
  bool _wasMultiTouch = false;
  Offset? _pointerDownPos;

  // Prevents the progress-bar status listener and the video-end listener from
  // both calling _advance() on the same slide.
  bool _hasAdvanced = false;

  late AnimationController _progressCtrl;

  PhotoViewController _photoViewController = PhotoViewController();
  final _scaleStateController = PhotoViewScaleStateController();
  Uint8List? _photoBytes;
  // Full-res bytes that arrived while the user was zoomed — applied once they
  // let go so the swap doesn't reset their zoom.
  Uint8List? _pendingFullRes;

  // ── Full-res image download state ─────────────────────────────────────────
  StreamSubscription<double>? _imageProgressSub;
  double? _imageDownloadProgress; // 0..1 while the crisp original downloads

  // ── Video state ─────────────────────────────────────────────────────────────
  VideoPlayerController? _videoCtrl;
  StreamSubscription<double>? _videoProgressSub;
  double? _videoDownloadProgress; // 0..0.99 while downloading
  bool _videoDecrypting = false;  // true during decrypt phase (progress == 1.0)
  // Token to detect stale _loadVideo completions after navigation.
  int _videoToken = 0;

  static const _storyDuration = Duration(seconds: 5);

  @override
  void initState() {
    super.initState();
    _memoryIndex = widget.initialMemoryIndex;
    _progressCtrl = AnimationController(vsync: this, duration: _storyDuration)
      ..addStatusListener((s) {
        if (s == AnimationStatus.completed && !_hasAdvanced) {
          _hasAdvanced = true;
          _advance();
        }
      });
    _loadMemory(_memoryIndex);
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
  }

  @override
  void dispose() {
    _progressCtrl.dispose();
    _cleanupImageProgress();
    _cleanupVideo();
    _photoViewController.dispose();
    _scaleStateController.dispose();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    super.dispose();
  }

  // ── Video helpers ────────────────────────────────────────────────────────────

  void _cleanupImageProgress() {
    _imageProgressSub?.cancel();
    _imageProgressSub = null;
    _imageDownloadProgress = null;
  }

  void _cleanupVideo() {
    _videoToken++;
    _videoProgressSub?.cancel();
    _videoProgressSub = null;
    final ctrl = _videoCtrl;
    _videoCtrl = null;
    if (ctrl != null) {
      ctrl.removeListener(_onVideoStateChanged);
      ctrl.pause().ignore();
      ctrl.dispose();
    }
    _videoDownloadProgress = null;
    _videoDecrypting = false;
  }

  void _onVideoStateChanged() {
    if (_videoCtrl == null || _hasAdvanced) return;
    final val = _videoCtrl!.value;
    if (val.duration.inMilliseconds > 0 &&
        val.position >= val.duration &&
        !val.isPlaying) {
      _hasAdvanced = true;
      _advance();
    }
  }

  // ── Memory / photo loading ───────────────────────────────────────────────────

  Future<void> _loadMemory(int idx) async {
    _hasAdvanced = false;
    _cleanupVideo();
    _progressCtrl
      ..stop()
      ..reset();

    // Fast path: the memory's files are almost always already resolved — the
    // feed and stories bar were built from the same provider. Use them
    // synchronously so the viewer opens straight onto the first slide instead
    // of flashing a full-screen spinner while a (cached) future resolves.
    final cached = ref.read(memoryFilesProvider(widget.memories[idx].id));
    if (cached.hasValue) {
      final files = cached.value!;
      if (files.isEmpty) {
        _nextMemory();
        return;
      }
      setState(() {
        _files = files;
        _photoIndex = 0;
        _photoBytes = null;
        _loading = false;
      });
      ref.read(thumbnailServiceProvider)?.prefetch(files);
      ref.read(fullResServiceProvider)?.prefetchImages(files, limit: 4);
      _loadPhoto(files[0]);
      return;
    }

    setState(() {
      _loading = true;
      _files = [];
      _photoIndex = 0;
      _photoBytes = null;
    });
    final files = await ref.read(
      memoryFilesProvider(widget.memories[idx].id).future,
    );
    if (!mounted) return;
    // A memory whose files all resolved away (deleted since it was built) would
    // otherwise hang on an infinite spinner. Skip past it to the next memory;
    // _nextMemory pops the viewer when there's nothing left.
    if (files.isEmpty) {
      _nextMemory();
      return;
    }
    setState(() {
      _files = files;
      _loading = false;
    });
    ref.read(thumbnailServiceProvider)?.prefetch(files);
    ref.read(fullResServiceProvider)?.prefetchImages(files, limit: 4);
    if (files.isNotEmpty) _loadPhoto(files[0]);
  }

  Future<void> _loadPhoto(EnteFile file) async {
    _hasAdvanced = false;
    _cleanupVideo();
    _cleanupImageProgress();
    _pendingFullRes = null; // per-photo; drop any stale pending upgrade
    _progressCtrl
      ..stop()
      ..reset();

    // Swap in a fresh controller so the new photo starts un-zoomed/centred, but
    // dispose the previous one only *after* this frame. Disposing it in place
    // while a mounted PhotoView is still bound to it makes photo_view's listener
    // cleanup null-crash when that core later unmounts.
    final oldController = _photoViewController;
    _photoViewController = PhotoViewController();
    WidgetsBinding.instance.addPostFrameCallback((_) => oldController.dispose());
    _scaleStateController.scaleState = PhotoViewScaleState.initial;

    // Paint the thumbnail instantly if it's already decrypted in memory (the
    // stories bar / feed warmed it), so the slide appears with no spinner.
    // Only fall back to the async fetch when it isn't cached yet.
    final thumbs = ref.read(thumbnailServiceProvider);
    Uint8List? bytes = thumbs?.cached(file);
    if (bytes != null) {
      setState(() {
        _photoBytes = bytes;
        _loading = false;
      });
    } else {
      try {
        bytes = await thumbs?.get(file);
      } catch (_) {}
      if (!mounted) return;
      setState(() {
        _photoBytes = bytes;
        _loading = false;  // Always unblock regardless of thumbnail outcome.
      });
    }

    if (file.fileType == 1) {
      _loadVideo(file); // async; timer starts once video is ready
    } else {
      _progressCtrl.duration = _storyDuration;
      _progressCtrl.forward();
      // Always fetch full-res in background. The thumbnail is low-res
      // (official Ente thumbnails are ~256 px); full-res is the crisp
      // original. When full-res bytes arrive, PhotoView swaps seamlessly
      // via gaplessPlayback — same progressive load the official app uses.
      _startFullResImage(file);
    }
  }

  /// Kicks off the full-res image fetch and surfaces its download progress so
  /// the viewer can show a determinate loading indicator over the thumbnail.
  void _startFullResImage(EnteFile file) {
    final svc = ref.read(fullResServiceProvider);
    if (svc == null || !svc.canDecrypt(file)) return;

    // Only show progress when there's an actual download to wait on — a cached
    // original swaps in instantly with no indicator.
    if (!svc.hasImageCached(file.id)) {
      svc.prepareImageProgressTracking(file.id);
      _imageDownloadProgress = 0.0;
      _imageProgressSub = svc.imageProgressStream(file.id).listen(
        (p) {
          if (!mounted ||
              _files.isEmpty ||
              _files[_photoIndex].id != file.id) {
            return;
          }
          setState(() => _imageDownloadProgress = p);
        },
        onDone: () {
          if (!mounted) return;
          setState(() => _imageDownloadProgress = null);
        },
      );
    }
    _fetchFullResBackground(file);
  }

  Future<void> _fetchFullResBackground(EnteFile file) async {
    try {
      final svc = ref.read(fullResServiceProvider);
      if (svc == null || !svc.canDecrypt(file)) return;
      final full = await svc.getImageBytes(file);
      if (!mounted) return;
      if (_files.isNotEmpty && _files[_photoIndex].id == file.id) {
        // Only upgrade to full-res if the format is one Flutter can decode.
        // HEIC/HEIF from older Ente uploads will fail ImageDecoder on most
        // Android devices — keep the thumbnail instead of showing an error.
        if (_isDisplayableImage(full)) {
          // While the user is pinch-zoomed, swapping the image would reset the
          // zoom — defer until they let go (handled in _onAllPointersLifted).
          if (_isZoomed) {
            _pendingFullRes = full;
          } else {
            setState(() => _photoBytes = full);
          }
        }
      }
    } catch (_) {}
  }

  /// Returns true for formats Flutter's ImageDecoder can handle on Android.
  /// Checks only the magic-byte signature — no full parse needed.
  static bool _isDisplayableImage(Uint8List bytes) {
    if (bytes.length < 12) return false;
    if (bytes[0] == 0xFF && bytes[1] == 0xD8) return true; // JPEG
    if (bytes[0] == 0x89 && bytes[1] == 0x50 && bytes[2] == 0x4E && bytes[3] == 0x47) {
      return true; // PNG
    }
    if (bytes[0] == 0x47 && bytes[1] == 0x49 && bytes[2] == 0x46) return true; // GIF
    // WebP: "RIFF" at 0 + "WEBP" at 8
    if (bytes[0] == 0x52 && bytes[1] == 0x49 && bytes[2] == 0x46 && bytes[3] == 0x46 &&
        bytes[8] == 0x57 && bytes[9] == 0x45 && bytes[10] == 0x42 && bytes[11] == 0x50) {
      return true;
    }
    return false; // HEIC/HEIF, AVIF, or unknown
  }

  Future<void> _loadVideo(EnteFile file) async {
    final token = ++_videoToken;
    final svc = ref.read(fullResServiceProvider);

    if (svc == null || !svc.canDecrypt(file)) {
      // No key available — treat like a 5-second image slide.
      _progressCtrl.duration = _storyDuration;
      _progressCtrl.forward();
      return;
    }

    // Register progress tracking BEFORE calling getVideoPath so the
    // StreamController exists when _fetchVideo starts pushing events.
    svc.prepareVideoProgressTracking(file.id);

    _videoProgressSub = svc.videoProgressStream(file.id).listen((progress) {
      if (!mounted || _videoToken != token) return;
      setState(() {
        if (progress < 1.0) {
          _videoDownloadProgress = progress;
          _videoDecrypting = false;
        } else {
          _videoDownloadProgress = null;
          _videoDecrypting = true;
        }
      });
    });

    String path;
    try {
      path = await svc.getVideoPath(file);
    } catch (_) {
      if (!mounted || _videoToken != token) return;
      _videoProgressSub?.cancel();
      _videoProgressSub = null;
      setState(() { _videoDownloadProgress = null; _videoDecrypting = false; });
      _progressCtrl.duration = const Duration(seconds: 3);
      _progressCtrl.forward();
      return;
    }

    _videoProgressSub?.cancel();
    _videoProgressSub = null;
    if (!mounted || _videoToken != token) return;

    setState(() { _videoDownloadProgress = null; _videoDecrypting = false; });

    final ctrl = VideoPlayerController.file(File(path));
    try {
      await ctrl.initialize();
    } catch (_) {
      ctrl.dispose();
      if (mounted && _videoToken == token) {
        _progressCtrl.duration = const Duration(seconds: 3);
        _progressCtrl.forward();
      }
      return;
    }

    if (!mounted || _videoToken != token) { ctrl.dispose(); return; }

    final durationMs = ctrl.value.duration.inMilliseconds.clamp(1000, 60000);

    ctrl.addListener(_onVideoStateChanged);
    setState(() => _videoCtrl = ctrl);

    _progressCtrl.duration = Duration(milliseconds: durationMs);
    _progressCtrl.reset();
    await ctrl.play();
    if (mounted && _activePointers == 0) _progressCtrl.forward();
  }

  // ── Navigation ──────────────────────────────────────────────────────────────

  void _advance() {
    _cleanupVideo();
    if (_photoIndex < _files.length - 1) {
      final next = _photoIndex + 1;
      setState(() { _photoIndex = next; _photoBytes = null; });
      _progressCtrl..reset()..stop();
      _loadPhoto(_files[next]);
    } else {
      _nextMemory();
    }
  }

  void _retreat() {
    _cleanupVideo();
    if (_photoIndex > 0) {
      final prev = _photoIndex - 1;
      setState(() { _photoIndex = prev; _photoBytes = null; });
      _progressCtrl..reset()..stop();
      _loadPhoto(_files[prev]);
    } else {
      _prevMemory();
    }
  }

  void _nextMemory() {
    if (_memoryIndex < widget.memories.length - 1) {
      _memoryIndex++;
      _loadMemory(_memoryIndex);
    } else {
      Navigator.of(context).pop();
    }
  }

  void _prevMemory() {
    if (_memoryIndex > 0) {
      _memoryIndex--;
      _loadMemory(_memoryIndex);
    }
  }

  Future<void> _shareCurrentPhoto() async {
    if (_loading || _files.isEmpty || _sharing) return;
    _progressCtrl.stop();
    _videoCtrl?.pause().ignore();
    setState(() => _sharing = true);

    try {
      final file = _files[_photoIndex];
      final svc = ref.read(fullResServiceProvider);
      final title = widget.memories[_memoryIndex].title;

      if (file.fileType == 1) {
        if (svc != null && svc.canDecrypt(file)) {
          final videoPath = await svc.getVideoPath(file);
          if (mounted) await Share.shareXFiles([XFile(videoPath)], text: title);
        }
      } else {
        if (svc != null && svc.canDecrypt(file)) {
          final bytes = await svc.getImageBytes(file);
          if (!mounted) return;
          final dir = await getTemporaryDirectory();
          final path = '${dir.path}/entegram_share.jpg';
          await File(path).writeAsBytes(bytes);
          await Share.shareXFiles([XFile(path)], text: title);
        }
      }
    } finally {
      if (mounted) {
        setState(() => _sharing = false);
        _progressCtrl.forward();
        if (_videoCtrl?.value.isInitialized == true) {
          _videoCtrl!.play().ignore();
        }
      }
    }
  }

  // ── Pointer / gesture handling ───────────────────────────────────────────────

  void _onPointerDown(PointerDownEvent e) {
    if (_activePointers == 0) {
      _pointerDownPos = e.localPosition;
      _wasMultiTouch = false;
    } else {
      _wasMultiTouch = true;
    }
    _activePointers++;
    _progressCtrl.stop();
    _videoCtrl?.pause().ignore();
  }

  void _onPointerUp(PointerUpEvent e) {
    _activePointers = max(0, _activePointers - 1);
    if (_activePointers == 0) _onAllPointersLifted(e.localPosition);
  }

  void _onPointerCancel(PointerCancelEvent e) {
    _activePointers = max(0, _activePointers - 1);
    if (_activePointers == 0) _onAllPointersLifted(null);
  }

  void _onAllPointersLifted(Offset? upPos) {
    if (_isZoomed) {
      _scaleStateController.scaleState = PhotoViewScaleState.initial;
      setState(() => _isZoomed = false);
    }

    // Apply any full-res upgrade that arrived while zoomed, now that we're back
    // at rest — the swap is seamless here instead of jolting the zoomed view.
    final pending = _pendingFullRes;
    if (pending != null) {
      _pendingFullRes = null;
      setState(() => _photoBytes = pending);
    }

    bool navigated = false;
    if (!_wasMultiTouch && upPos != null && _pointerDownPos != null) {
      navigated = _handleSingleFingerGesture(_pointerDownPos!, upPos);
    }

    if (mounted && !navigated) {
      _progressCtrl.forward();
      if (_videoCtrl?.value.isInitialized == true) {
        _videoCtrl!.play().ignore();
      }
    }
  }

  // Returns true if a navigation action was triggered.
  //
  // Instagram-style resolution: a *deliberate* horizontal drag (covering a
  // meaningful fraction of the screen) changes the story bundle; a strong
  // downward drag closes; anything else — including a tap that drifted a little
  // — is treated as a tap, where the left third steps back and the rest of the
  // screen advances to the next photo *within the current bundle*. This stops
  // small finger drift on a tap from being misread as a bundle swipe.
  bool _handleSingleFingerGesture(Offset down, Offset up) {
    if (_suppressNav) { _suppressNav = false; return false; }
    if (_isZoomed) return false;

    final size = MediaQuery.of(context).size;
    final delta = up - down;

    // Deliberate downward swipe → close.
    if (delta.dy > 100 && delta.dy.abs() > delta.dx.abs() * 1.2) {
      Navigator.of(context).pop();
      return true;
    }

    // Deliberate horizontal swipe (≥ ~22% of the screen width, clearly
    // sideways) → change story bundle.
    if (delta.dx.abs() > size.width * 0.22 &&
        delta.dx.abs() > delta.dy.abs() * 1.5) {
      if (delta.dx > 0) { _prevMemory(); } else { _nextMemory(); }
      return true;
    }

    // Otherwise it's a tap (forgiving of minor drift): advance within the bundle.
    if (up.dx < size.width / 3) { _retreat(); } else { _advance(); }
    return true;
  }

  // ── Build ────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final memory = widget.memories[_memoryIndex];
    return Scaffold(
      backgroundColor: Colors.black,
      body: Listener(
        behavior: HitTestBehavior.opaque,
        onPointerDown: _onPointerDown,
        onPointerUp: _onPointerUp,
        onPointerCancel: _onPointerCancel,
        child: Stack(
          children: [
            // ── Media ────────────────────────────────────────────────────────
            if (_loading)
              const Center(
                child: CircularProgressIndicator(color: Colors.white),
              )
            else if (_videoCtrl != null && _videoCtrl!.value.isInitialized)
              Positioned.fill(
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    const ColoredBox(color: Colors.black),
                    Center(
                      child: AspectRatio(
                        aspectRatio: _videoCtrl!.value.aspectRatio,
                        child: VideoPlayer(_videoCtrl!),
                      ),
                    ),
                  ],
                ),
              )
            else if (_photoBytes != null)
              Positioned.fill(
                child: PhotoView(
                  imageProvider: MemoryImage(_photoBytes!),
                  controller: _photoViewController,
                  scaleStateController: _scaleStateController,
                  scaleStateChangedCallback: (state) {
                    final zoomed = state != PhotoViewScaleState.initial;
                    if (zoomed != _isZoomed) setState(() => _isZoomed = zoomed);
                  },
                  minScale: PhotoViewComputedScale.contained,
                  maxScale: PhotoViewComputedScale.covered * 3.0,
                  backgroundDecoration:
                      const BoxDecoration(color: Colors.transparent),
                  gaplessPlayback: true,
                  filterQuality: FilterQuality.high,
                  errorBuilder: (_, _, _) => const Center(
                    child: Icon(
                      Icons.image_not_supported_outlined,
                      color: Colors.white24,
                      size: 64,
                    ),
                  ),
                ),
              )
            else
              const Center(
                child: Icon(Icons.photo_outlined, color: Colors.white24, size: 64),
              ),

            // ── Video download / decrypt progress ────────────────────────────
            if (_videoCtrl == null &&
                (_videoDownloadProgress != null || _videoDecrypting))
              IgnorePointer(
                child: Center(child: _buildVideoProgressOverlay()),
              ),

            // ── Full-res image download progress ─────────────────────────────
            // A small, unobtrusive indicator over the already-visible thumbnail
            // so it's clear the crisp original is still streaming in. Auto-hides
            // the moment full-res arrives (or for already-cached photos).
            if (!_loading && _videoCtrl == null && _imageDownloadProgress != null)
              Positioned(
                top: 0, left: 0,
                child: SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.only(top: 18, left: 12),
                    child: IgnorePointer(
                      child: _buildImageProgressIndicator(),
                    ),
                  ),
                ),
              ),

            // ── Progress segments ────────────────────────────────────────────
            Positioned(
              top: 0, left: 0, right: 0,
              child: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(8, 8, 8, 0),
                  child: Row(
                    children: List.generate(
                      _loading ? 1 : _files.length,
                      (i) => Expanded(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 1),
                          child: _ProgressSegment(
                            animation: _progressCtrl,
                            status: _loading
                                ? _SegmentStatus.empty
                                : i < _photoIndex
                                ? _SegmentStatus.full
                                : i == _photoIndex
                                ? _SegmentStatus.active
                                : _SegmentStatus.empty,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),

            // ── Hold-to-pause indicator ──────────────────────────────────────
            if (_activePointers > 0 && !_isZoomed)
              IgnorePointer(
                child: Center(
                  child: DecoratedBox(
                    decoration: const BoxDecoration(
                      color: Colors.black38,
                      shape: BoxShape.circle,
                    ),
                    child: const Padding(
                      padding: EdgeInsets.all(14),
                      child: Icon(Icons.pause, color: Colors.white70, size: 30),
                    ),
                  ),
                ),
              ),

            // ── Close button ─────────────────────────────────────────────────
            Positioned(
              top: 0, right: 0,
              child: Listener(
                behavior: HitTestBehavior.translucent,
                onPointerDown: (_) { _suppressNav = true; },
                child: SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.only(top: 24, right: 4),
                    child: IconButton(
                      icon: const Icon(Icons.close, color: Colors.white),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ),
                ),
              ),
            ),

            // ── Bottom info ──────────────────────────────────────────────────
            Positioned(
              bottom: 0, left: 0, right: 0,
              child: _BottomScrim(
                child: SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 4, 16),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                memory.title,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 18,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                _loading || _files.isEmpty
                                    ? _dateLabel(memory)
                                    : _fileDate(_files[_photoIndex]),
                                style: const TextStyle(
                                  color: Colors.white70,
                                  fontSize: 13,
                                ),
                              ),
                              if (!_loading && _files.isNotEmpty)
                                PersonChipsRow(
                                  fileId: _files[_photoIndex].id,
                                  overrideIds: (memory.kind ==
                                              MemoryKind.people &&
                                          memory.personIds.isNotEmpty)
                                      ? memory.personIds.join(',')
                                      : null,
                                ),
                              if (!_loading &&
                                  _files.isNotEmpty &&
                                  _files[_photoIndex].fileType == 1) ...[
                                const SizedBox(height: 6),
                                const Row(
                                  children: [
                                    Icon(Icons.videocam, color: Colors.white70, size: 15),
                                    SizedBox(width: 4),
                                    Text(
                                      'Video',
                                      style: TextStyle(color: Colors.white70, fontSize: 12),
                                    ),
                                  ],
                                ),
                              ],
                            ],
                          ),
                        ),
                        Listener(
                          behavior: HitTestBehavior.translucent,
                          onPointerDown: (_) { _suppressNav = true; },
                          child: SizedBox(
                            width: 44,
                            height: 44,
                            child: _sharing
                                ? const Center(
                                    child: SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: Colors.white70,
                                      ),
                                    ),
                                  )
                                : IconButton(
                                    icon: const Icon(
                                      Icons.ios_share_outlined,
                                      color: Colors.white,
                                      size: 22,
                                    ),
                                    onPressed: _loading || _files.isEmpty
                                        ? null
                                        : _shareCurrentPhoto,
                                    tooltip: 'Share',
                                  ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImageProgressIndicator() {
    final p = _imageDownloadProgress ?? 0.0;
    return Container(
      width: 34,
      height: 34,
      padding: const EdgeInsets.all(7),
      decoration: BoxDecoration(
        color: Colors.black54,
        borderRadius: BorderRadius.circular(17),
      ),
      child: CircularProgressIndicator(
        // Indeterminate until the first byte arrives (p == 0), then determinate.
        value: p > 0 ? p : null,
        backgroundColor: Colors.white24,
        valueColor: const AlwaysStoppedAnimation(Color(0xFF1DB954)),
        strokeWidth: 2.5,
        strokeCap: StrokeCap.round,
      ),
    );
  }

  Widget _buildVideoProgressOverlay() {
    return Container(
      width: 56,
      height: 56,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.black54,
        borderRadius: BorderRadius.circular(28),
      ),
      child: _videoDecrypting
          ? const CircularProgressIndicator(
              color: Colors.white70,
              strokeWidth: 2,
            )
          : Stack(
              alignment: Alignment.center,
              children: [
                CircularProgressIndicator(
                  value: _videoDownloadProgress,
                  backgroundColor: Colors.white24,
                  valueColor: const AlwaysStoppedAnimation(Color(0xFF00C853)),
                  strokeWidth: 2.5,
                  strokeCap: StrokeCap.round,
                ),
                if (_videoDownloadProgress != null)
                  Text(
                    '${(_videoDownloadProgress! * 100).toStringAsFixed(0)}%',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
              ],
            ),
    );
  }

  String _dateLabel(MemoryCluster m) => _formatDate(m.startTime);

  String _fileDate(EnteFile file) =>
      file.creationTime > 0 ? _formatDate(file.creationTime) : '';

  String _formatDate(int microseconds) {
    final dt = DateTime.fromMicrosecondsSinceEpoch(microseconds);
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    final day = dt.day.toString().padLeft(2, '0');
    return '$day ${months[dt.month - 1]} ${dt.year}';
  }
}

// ── Supporting widgets ─────────────────────────────────────────────────────────

enum _SegmentStatus { full, active, empty }

class _ProgressSegment extends StatelessWidget {
  const _ProgressSegment({required this.animation, required this.status});

  final AnimationController animation;
  final _SegmentStatus status;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(2),
      child: SizedBox(
        height: 2.5,
        child: switch (status) {
          _SegmentStatus.full => const ColoredBox(color: Colors.white),
          _SegmentStatus.empty => const ColoredBox(color: Colors.white38),
          _SegmentStatus.active => AnimatedBuilder(
            animation: animation,
            builder: (_, _) => LinearProgressIndicator(
              value: animation.value,
              backgroundColor: Colors.white38,
              valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
            ),
          ),
        },
      ),
    );
  }
}

class _BottomScrim extends StatelessWidget {
  const _BottomScrim({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.bottomCenter,
          end: Alignment.topCenter,
          colors: [Colors.black87, Colors.transparent],
          stops: [0.0, 1.0],
        ),
      ),
      child: child,
    );
  }
}
