import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'package:photo_view/photo_view.dart';
import 'package:share_plus/share_plus.dart';
import 'package:video_player/video_player.dart';

import '../../db/models/ente_file.dart';
import '../../db/models/memory_cluster.dart';
import '../../media/full_res_service.dart';
import '../../providers.dart';
import 'person_chips.dart';
import 'thumbnail_image.dart';

void openFullscreenViewer(
  BuildContext context, {
  required List<EnteFile> files,
  required int initialIndex,
  required MemoryCluster memory,
}) {
  Navigator.of(context).push(
    PageRouteBuilder<void>(
      opaque: false,
      barrierColor: Colors.black,
      transitionDuration: const Duration(milliseconds: 220),
      pageBuilder: (context, animation, _) => FadeTransition(
        opacity: animation,
        child: _FullscreenViewer(
          files: files,
          initialIndex: initialIndex,
          memory: memory,
        ),
      ),
    ),
  );
}

class _FullscreenViewer extends ConsumerStatefulWidget {
  const _FullscreenViewer({
    required this.files,
    required this.initialIndex,
    required this.memory,
  });

  final List<EnteFile> files;
  final int initialIndex;
  final MemoryCluster memory;

  @override
  ConsumerState<_FullscreenViewer> createState() => _FullscreenViewerState();
}

class _FullscreenViewerState extends ConsumerState<_FullscreenViewer> {
  late int _index;
  late PageController _page;
  bool _showUI = true;
  bool _isZoomed = false;
  bool _sharing = false;

  @override
  void initState() {
    super.initState();
    _index = widget.initialIndex;
    _page = PageController(initialPage: widget.initialIndex);
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    WidgetsBinding.instance.addPostFrameCallback((_) => _prefetchAround(_index));
  }

  @override
  void dispose() {
    _page.dispose();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    super.dispose();
  }

  void _toggleUI() => setState(() => _showUI = !_showUI);

  Future<void> _shareCurrentFile() async {
    if (_sharing) return;
    setState(() => _sharing = true);
    try {
      final file = widget.files[_index];
      final svc = ref.read(fullResServiceProvider);
      if (svc == null || !svc.canDecrypt(file)) return;

      if (file.fileType == 1) {
        final videoPath = await svc.getVideoPath(file);
        if (mounted) await Share.shareXFiles([XFile(videoPath)], text: widget.memory.title);
      } else {
        final bytes = await svc.getImageBytes(file);
        if (!mounted) return;
        final dir = await getTemporaryDirectory();
        final path = '${dir.path}/entegram_share.jpg';
        await File(path).writeAsBytes(bytes);
        await Share.shareXFiles([XFile(path)], text: widget.memory.title);
      }
    } finally {
      if (mounted) setState(() => _sharing = false);
    }
  }

  void _prefetchAround(int index) {
    final thumbs = ref.read(thumbnailServiceProvider);
    final fullRes = ref.read(fullResServiceProvider);

    // Thumbnails: prefetch all (small, fast, no priority issue).
    if (thumbs != null) thumbs.prefetch(widget.files);

    if (fullRes == null) return;

    // Cancel any full-res downloads outside the ±1 window — they compete for
    // bandwidth with the photo the user is actually looking at.
    final keepIds = <int>{
      if (index > 0) widget.files[index - 1].id,
      widget.files[index].id,
      if (index < widget.files.length - 1) widget.files[index + 1].id,
    };
    fullRes.cancelAllImagesExcept(keepIds);

    // Current photo: start immediately (highest priority).
    final current = widget.files[index];
    if (current.fileType == 0 && fullRes.canDecrypt(current)) {
      fullRes.getImageBytes(current).ignore();
    }

    // Adjacent photos: defer by 1 s so the current download gets a head start.
    Future.delayed(const Duration(seconds: 1), () {
      if (!mounted) return;
      for (final i in [index + 1, index - 1]) {
        if (i < 0 || i >= widget.files.length) continue;
        final f = widget.files[i];
        if (f.fileType == 0 && fullRes.canDecrypt(f)) {
          fullRes.getImageBytes(f).ignore();
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final file = widget.files[_index];
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          PageView.builder(
            controller: _page,
            // Block horizontal page swipe while zoomed so the user can pan
            // within the image freely.
            physics: _isZoomed
                ? const NeverScrollableScrollPhysics()
                : const PageScrollPhysics(),
            onPageChanged: (i) {
              setState(() { _index = i; _isZoomed = false; });
              _prefetchAround(i);
            },
            itemCount: widget.files.length,
            itemBuilder: (_, i) {
              final f = widget.files[i];
              return f.fileType == 1
                  ? _VideoViewer(
                      file: f,
                      onTap: _toggleUI,
                      onZoomChanged: (z) => setState(() => _isZoomed = z),
                    )
                  : _ZoomableImage(
                      file: f,
                      onTap: _toggleUI,
                      onZoomChanged: (z) => setState(() => _isZoomed = z),
                    );
            },
          ),
          AnimatedOpacity(
            opacity: _showUI ? 1.0 : 0.0,
            duration: const Duration(milliseconds: 180),
            child: IgnorePointer(
              ignoring: !_showUI,
              child: Stack(
                children: [
                  // Top bar
                  Positioned(
                    top: 0, left: 0, right: 0,
                    child: _Scrim(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      child: SafeArea(
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(4, 4, 4, 12),
                          child: Row(
                            children: [
                              IconButton(
                                icon: const Icon(Icons.close, color: Colors.white, size: 26),
                                onPressed: () => Navigator.of(context).pop(),
                              ),
                              const Spacer(),
                              if (widget.files.length > 1)
                                Text(
                                  '${_index + 1} / ${widget.files.length}',
                                  style: const TextStyle(color: Colors.white),
                                ),
                              SizedBox(
                                width: 44,
                                height: 44,
                                child: _sharing
                                    ? const Center(
                                        child: SizedBox(
                                          width: 18,
                                          height: 18,
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
                                        onPressed: _shareCurrentFile,
                                        tooltip: 'Share',
                                      ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                  // Bottom bar
                  Positioned(
                    bottom: 0, left: 0, right: 0,
                    child: _Scrim(
                      begin: Alignment.bottomCenter,
                      end: Alignment.topCenter,
                      child: SafeArea(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                widget.memory.title,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                _fileDate(file),
                                style: const TextStyle(color: Colors.white70, fontSize: 13),
                              ),
                              if (file.title != null) ...[
                                const SizedBox(height: 2),
                                Text(
                                  file.title!,
                                  style: const TextStyle(color: Colors.white70, fontSize: 13),
                                ),
                              ],
                              PersonChipsRow(
                                fileId: file.id,
                                overrideIds: (widget.memory.kind ==
                                            MemoryKind.people &&
                                        widget.memory.personIds.isNotEmpty)
                                    ? widget.memory.personIds.join(',')
                                    : null,
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
          ),
        ],
      ),
    );
  }
}

// ── Zoomable image (InteractiveViewer; thumbnail upgrades to original in place)

class _ZoomableImage extends ConsumerStatefulWidget {
  const _ZoomableImage({
    required this.file,
    required this.onTap,
    this.onZoomChanged,
  });

  final EnteFile file;
  final VoidCallback onTap;
  final ValueChanged<bool>? onZoomChanged;

  @override
  ConsumerState<_ZoomableImage> createState() => _ZoomableImageState();
}

class _ZoomableImageState extends ConsumerState<_ZoomableImage> {
  // PhotoView gives the reliable pinch-zoom + PageView coordination (via
  // PhotoViewGestureDetectorScope). Using `customChild` with a *fixed* child
  // size (the viewport) means the zoom scale no longer depends on the image's
  // pixel dimensions — so swapping the thumbnail for the original underneath
  // keeps the exact zoom/pan, no reset, even mid-zoom.
  final _scaleStateController = PhotoViewScaleStateController();
  bool _isZoomed = false;

  Uint8List? _thumbBytes;
  Uint8List? _fullResBytes;
  bool _fullResLoading = false;

  @override
  void initState() {
    super.initState();
    _loadImages();
  }

  @override
  void dispose() {
    _scaleStateController.dispose();
    super.dispose();
  }

  void _onScaleStateChanged(PhotoViewScaleState state) {
    final zoomed = state != PhotoViewScaleState.initial;
    if (zoomed == _isZoomed) return;
    setState(() => _isZoomed = zoomed);
    widget.onZoomChanged?.call(zoomed);
  }

  Future<void> _loadImages() async {
    // Thumbnail first — it's immediately zoomable; the original replaces it in
    // place the instant it arrives. Swallow thumbnail errors.
    try {
      final thumb = await ref.read(thumbnailServiceProvider)?.get(widget.file);
      if (mounted && thumb != null && _fullResBytes == null) {
        setState(() => _thumbBytes = thumb);
      }
    } catch (_) {}

    final svc = ref.read(fullResServiceProvider);
    if (svc == null || !svc.canDecrypt(widget.file)) return;

    // Show loading bar only if the image isn't already cached.
    if (mounted && !svc.hasImageCached(widget.file.id)) {
      setState(() => _fullResLoading = true);
    }

    try {
      final bytes = await svc.getImageBytes(widget.file);
      if (mounted) {
        setState(() {
          _fullResBytes = bytes;
          _fullResLoading = false;
        });
      }
    } on ImageDownloadCancelledException {
      // The prefetch for this file was cancelled when the user was elsewhere.
      // Now that this widget is active, retry immediately.
      if (mounted) _loadImages();
    } catch (_) {
      if (mounted) setState(() => _fullResLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bytes = _fullResBytes ?? _thumbBytes;

    if (bytes == null) {
      return Stack(
        alignment: Alignment.center,
        children: [
          ThumbnailImage(file: widget.file, fit: BoxFit.contain),
          const CircularProgressIndicator(color: Colors.white54, strokeWidth: 2),
        ],
      );
    }

    final size = MediaQuery.sizeOf(context);
    return Stack(
      children: [
        PhotoViewGestureDetectorScope(
          // axis vertical (not zoomed) → horizontal swipes reach the parent
          // PageView; axis null (zoomed) → PhotoView captures gestures for pan.
          axis: _isZoomed ? null : Axis.vertical,
          child: PhotoView.customChild(
            // Fixed child size = the viewport, so the scale reference is stable
            // across the thumbnail→original swap (no reset).
            childSize: size,
            minScale: PhotoViewComputedScale.contained,
            maxScale: PhotoViewComputedScale.contained * 8,
            initialScale: PhotoViewComputedScale.contained,
            scaleStateController: _scaleStateController,
            scaleStateChangedCallback: _onScaleStateChanged,
            backgroundDecoration: const BoxDecoration(color: Colors.black),
            onTapUp: (_, _, _) => widget.onTap(),
            child: Image(
              image: MemoryImage(bytes),
              fit: BoxFit.contain,
              gaplessPlayback: true,
              filterQuality: FilterQuality.high,
            ),
          ),
        ),
        if (_fullResLoading)
          const Positioned(
            bottom: 0, left: 0, right: 0,
            child: LinearProgressIndicator(
              value: null,
              backgroundColor: Colors.transparent,
              color: Color.fromRGBO(29, 185, 84, 0.8),
              minHeight: 2,
            ),
          ),
      ],
    );
  }
}

// ── Video viewer ──────────────────────────────────────────────────────────────

class _VideoViewer extends ConsumerStatefulWidget {
  const _VideoViewer({required this.file, required this.onTap, this.onZoomChanged});

  final EnteFile file;
  final VoidCallback onTap;
  final ValueChanged<bool>? onZoomChanged;

  @override
  ConsumerState<_VideoViewer> createState() => _VideoViewerState();
}

class _VideoViewerState extends ConsumerState<_VideoViewer> {
  VideoPlayerController? _controller;
  StreamSubscription<double>? _progressSub;
  double? _downloadProgress; // 0..0.99 downloading; null = done or not started
  bool _decrypting = false;
  String? _error;

  // Pinch-to-zoom for the video frame.
  final TransformationController _transform = TransformationController();
  bool _isZoomed = false;

  @override
  void initState() {
    super.initState();
    _transform.addListener(_onTransform);
    _initVideo();
  }

  @override
  void dispose() {
    _transform.removeListener(_onTransform);
    _transform.dispose();
    _progressSub?.cancel();
    _controller?.dispose();
    super.dispose();
  }

  void _onTransform() {
    final zoomed = _transform.value.getMaxScaleOnAxis() > 1.01;
    if (zoomed != _isZoomed) {
      setState(() => _isZoomed = zoomed);
      widget.onZoomChanged?.call(zoomed);
    }
  }

  Future<void> _initVideo() async {
    final svc = ref.read(fullResServiceProvider);
    if (svc == null || !svc.canDecrypt(widget.file)) {
      if (mounted) setState(() => _error = 'No decryption key');
      return;
    }

    svc.prepareVideoProgressTracking(widget.file.id);
    _progressSub = svc.videoProgressStream(widget.file.id).listen((progress) {
      if (!mounted) return;
      setState(() {
        if (progress < 1.0) {
          _downloadProgress = progress;
          _decrypting = false;
        } else {
          _downloadProgress = null;
          _decrypting = true;
        }
      });
    });

    try {
      final path = await svc.getVideoPath(widget.file);
      _progressSub?.cancel();
      _progressSub = null;
      if (!mounted) return;
      setState(() { _downloadProgress = null; _decrypting = false; });

      final ctrl = VideoPlayerController.file(File(path));
      await ctrl.initialize();
      if (!mounted) { ctrl.dispose(); return; }
      setState(() => _controller = ctrl);
      ctrl.play().ignore();
      ctrl.setLooping(true);
    } catch (e) {
      _progressSub?.cancel();
      _progressSub = null;
      if (mounted) setState(() { _downloadProgress = null; _decrypting = false; _error = e.toString(); });
    }
  }

  @override
  Widget build(BuildContext context) {
    // Error state
    if (_error != null) {
      return Stack(
        alignment: Alignment.center,
        children: [
          ThumbnailImage(file: widget.file, fit: BoxFit.contain),
          const Icon(Icons.error_outline, color: Colors.white54, size: 48),
        ],
      );
    }

    // Video ready — show player
    if (_controller != null) {
      final ctrl = _controller!;
      return Stack(
        alignment: Alignment.center,
        children: [
          // Full-screen zoom viewport (like the photo viewer) so the video can
          // zoom to fill the screen instead of being clipped to its letterbox.
          Positioned.fill(
            child: GestureDetector(
              onTap: widget.onTap,
              onDoubleTap: () {
                ctrl.value.isPlaying ? ctrl.pause() : ctrl.play();
                setState(() {});
              },
              child: InteractiveViewer(
                transformationController: _transform,
                minScale: 1,
                maxScale: 8,
                // Pan only once zoomed in, so at rest horizontal drags still
                // reach the parent PageView for swiping between media.
                panEnabled: _isZoomed,
                child: Center(
                  child: AspectRatio(
                    aspectRatio: ctrl.value.aspectRatio,
                    child: VideoPlayer(ctrl),
                  ),
                ),
              ),
            ),
          ),
          ValueListenableBuilder(
              valueListenable: ctrl,
              builder: (_, VideoPlayerValue val, _) {
                return AnimatedOpacity(
                  opacity: val.isPlaying ? 0.0 : 1.0,
                  duration: const Duration(milliseconds: 200),
                  child: GestureDetector(
                    onTap: () { ctrl.play(); setState(() {}); },
                    child: Container(
                      width: 64,
                      height: 64,
                      decoration: BoxDecoration(
                        color: Colors.black54,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white60, width: 2),
                      ),
                      child: const Icon(Icons.play_arrow, color: Colors.white, size: 36),
                    ),
                  ),
                );
              },
            ),
          ],
        );
    }

    // Loading — thumbnail + Ente-style circular progress
    return Stack(
      alignment: Alignment.center,
      children: [
        ThumbnailImage(file: widget.file, fit: BoxFit.contain),
        Container(
          width: 56,
          height: 56,
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: Colors.black54,
            borderRadius: BorderRadius.circular(28),
          ),
          child: _decrypting
              ? const CircularProgressIndicator(
                  color: Colors.white70,
                  strokeWidth: 2,
                )
              : Stack(
                  alignment: Alignment.center,
                  children: [
                    CircularProgressIndicator(
                      value: _downloadProgress,
                      backgroundColor: Colors.white24,
                      valueColor: const AlwaysStoppedAnimation(Color(0xFF00C853)),
                      strokeWidth: 2.5,
                      strokeCap: StrokeCap.round,
                    ),
                    if (_downloadProgress != null)
                      Text(
                        '${(_downloadProgress! * 100).toStringAsFixed(0)}%',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                  ],
                ),
        ),
      ],
    );
  }
}

String _fileDate(EnteFile file) {
  if (file.creationTime <= 0) return '';
  final dt = DateTime.fromMicrosecondsSinceEpoch(file.creationTime);
  const months = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
  ];
  final day = dt.day.toString().padLeft(2, '0');
  return '$day ${months[dt.month - 1]} ${dt.year}';
}

class _Scrim extends StatelessWidget {
  const _Scrim({required this.begin, required this.end, required this.child});

  final Alignment begin;
  final Alignment end;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: begin,
          end: end,
          colors: [Colors.black.withValues(alpha: 0.6), Colors.transparent],
        ),
      ),
      child: child,
    );
  }
}
