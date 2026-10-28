import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:video_player/video_player.dart';

import '../../db/models/ente_file.dart';
import '../../db/models/memory_cluster.dart';
import '../../memories/memory_catalog.dart';
import '../../memories/story_playback.dart';
import '../../providers.dart';
import 'fullscreen_viewer.dart';
import 'media_image.dart';

/// Overrideable at the media boundary, so real story timing/gestures can be
/// tested without a network connection or a crypto isolate.
final storyThumbnailLoaderProvider =
    Provider<Future<Uint8List?> Function(EnteFile)>((ref) {
      return (file) =>
          ref.read(thumbnailServiceProvider)?.get(file) ?? Future.value(null);
    });

void openStoryViewer(
  BuildContext context, {
  required List<MemoryCluster> memories,
  required int initialMemoryIndex,
  required WidgetRef ref,
}) {
  if (memories.isEmpty) return;
  Navigator.of(context).push(
    PageRouteBuilder<void>(
      transitionDuration: const Duration(milliseconds: 220),
      pageBuilder: (_, animation, _) => FadeTransition(
        opacity: animation,
        child: StoryViewer(
          memories: memories,
          initialMemoryIndex: initialMemoryIndex,
        ),
      ),
    ),
  );
}

class StoryViewer extends ConsumerStatefulWidget {
  const StoryViewer({
    super.key,
    required this.memories,
    this.initialMemoryIndex = 0,
  });
  final List<MemoryCluster> memories;
  final int initialMemoryIndex;
  @override
  ConsumerState<StoryViewer> createState() => _StoryViewerState();
}

class _StoryViewerState extends ConsumerState<StoryViewer>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  late final StoryPlayback _playback;
  late final AnimationController _timer;
  final _videoProgress = ValueNotifier<double>(0);
  bool _manualPause = false;
  bool _muted = true;
  bool _background = false;
  bool _holding = false;
  bool _zoomed = false;
  bool _presenting = false;
  bool _ready = false;
  bool _closing = false;
  bool _accessibilityInitialized = false;
  String? _slide;
  final _pointers = <int>{};
  Offset? _down;
  Duration? _downTime;
  bool _multiTouch = false;
  bool get _paused =>
      _manualPause ||
      _background ||
      _holding ||
      _zoomed ||
      _presenting ||
      !_ready;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _timer =
        AnimationController(vsync: this, duration: const Duration(seconds: 5))
          ..addStatusListener((status) {
            if (status == AnimationStatus.completed && !_paused) {
              unawaited(_playback.next());
            }
          });
    _playback = StoryPlayback(
      memories: widget.memories,
      initialMemoryIndex: widget.initialMemoryIndex,
      loadFiles: (memory) => ref.read(memoryFilesProvider(memory.id).future),
      onCompleted: (memory) =>
          ref.read(seenStoriesProvider.notifier).mark(memory),
    )..addListener(_changed);
    unawaited(_playback.start());
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_accessibilityInitialized) {
      _accessibilityInitialized = true;
      _manualPause =
          MediaQuery.accessibleNavigationOf(context) ||
          MediaQuery.disableAnimationsOf(context);
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (!mounted) return;
    setState(() => _background = state != AppLifecycleState.resumed);
    _syncTimer();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _playback.removeListener(_changed);
    _playback.dispose();
    _timer.dispose();
    _videoProgress.dispose();
    super.dispose();
  }

  void _changed() {
    if (!mounted) return;
    if (_playback.finished) {
      if (!_closing) {
        _closing = true;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) Navigator.of(context).maybePop();
        });
      }
      return;
    }
    if (_slide != _playback.slideKey || _playback.loading) {
      _slide = _playback.slideKey;
      _ready = false;
      _zoomed = false;
      _videoProgress.value = 0;
      _timer.reset();
    }
    setState(() {});
    _syncTimer();
  }

  void _syncTimer() {
    if (_paused || _playback.loading || _playback.file?.fileType == 1) {
      _timer.stop();
    } else if (_timer.value < 1) {
      _timer.forward();
    }
  }

  void _mediaReady() {
    if (!mounted) return;
    setState(() => _ready = true);
    _syncTimer();
    final next = _playback.photoIndex + 1;
    final files = _playback.files;
    ref.read(thumbnailServiceProvider)?.prefetch(files.skip(next).take(2));
    // Only the next original, never the entire memory/library.
    ref
        .read(fullResServiceProvider)
        ?.prefetchImages(files.skip(next).take(1), limit: 1);
  }

  void _pointerDown(PointerDownEvent event) {
    if (_pointers.isEmpty) {
      _down = event.localPosition;
      _downTime = event.timeStamp;
      _multiTouch = _zoomed;
    } else {
      _multiTouch = true;
    }
    _pointers.add(event.pointer);
    setState(() => _holding = true);
    _syncTimer();
  }

  void _pointerUp(PointerUpEvent event, Size size) {
    _pointers.remove(event.pointer);
    if (_pointers.isNotEmpty) return;
    setState(() => _holding = false);
    final down = _down;
    final duration = event.timeStamp - (_downTime ?? event.timeStamp);
    _down = null;
    if (down == null || _multiTouch || _zoomed) {
      _syncTimer();
      return;
    }
    final delta = event.localPosition - down;
    if (delta.dy > 90 && delta.dy.abs() > delta.dx.abs() * 1.4) {
      Navigator.of(context).maybePop();
    } else if (delta.dx.abs() > size.width * 0.2 &&
        delta.dx.abs() > delta.dy.abs() * 1.4) {
      unawaited(
        delta.dx < 0 ? _playback.nextMemory() : _playback.previousMemory(),
      );
    } else if (delta.distance < 18 && duration.inMilliseconds < 250) {
      unawaited(
        event.localPosition.dx < size.width / 3
            ? _playback.previous()
            : _playback.next(),
      );
    } else {
      _syncTimer();
    } // Releasing a hold never advances a slide.
  }

  void _pointerCancel(PointerCancelEvent event) {
    _pointers.remove(event.pointer);
    if (_pointers.isEmpty) {
      setState(() => _holding = false);
      _down = null;
      _syncTimer();
    }
  }

  Future<void> _viewOriginal() async {
    if (_playback.file == null) return;
    setState(() => _presenting = true);
    _syncTimer();
    await openFullscreenViewer(
      context,
      files: _playback.files,
      initialIndex: _playback.photoIndex,
      memory: _playback.memory!,
    );
    if (mounted) {
      setState(() => _presenting = false);
      _syncTimer();
    }
  }

  @override
  Widget build(BuildContext context) {
    final memory = _playback.memory;
    final file = _playback.file;
    // Keep the auto-disposed slide lookup alive throughout asynchronous loads.
    if (memory != null) ref.watch(memoryFilesProvider(memory.id));
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: const Color(0xFF080B0A),
        body: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 720),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final size = constraints.biggest;
                  return Stack(
                    fit: StackFit.expand,
                    children: [
                      Listener(
                        behavior: HitTestBehavior.opaque,
                        onPointerDown: _pointerDown,
                        onPointerUp: (event) => _pointerUp(event, size),
                        onPointerCancel: _pointerCancel,
                        child: _playback.loading
                            ? const Center(
                                child: CircularProgressIndicator(
                                  color: Colors.white70,
                                ),
                              )
                            : _playback.error != null
                            ? Center(
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Text(
                                      'This memory couldn’t be loaded.',
                                      style: TextStyle(color: Colors.white),
                                    ),
                                    TextButton(
                                      onPressed: _playback.retry,
                                      child: const Text('Retry'),
                                    ),
                                  ],
                                ),
                              )
                            : file == null
                            ? const SizedBox.shrink()
                            : StoryMedia(
                                key: ValueKey(_playback.slideKey),
                                file: file,
                                paused: _paused,
                                muted: _muted,
                                onReady: _mediaReady,
                                onUnavailable: () {
                                  setState(() => _ready = false);
                                  _syncTimer();
                                },
                                onVideoProgress: (value) =>
                                    _videoProgress.value = value,
                                onVideoEnded: () {
                                  if (!_paused) unawaited(_playback.next());
                                },
                                onZoomChanged: (zoomed) {
                                  setState(() => _zoomed = zoomed);
                                  _syncTimer();
                                },
                              ),
                      ),
                      Positioned(
                        top: 0,
                        left: 0,
                        right: 0,
                        child: DecoratedBox(
                          decoration: const BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [Colors.black87, Colors.transparent],
                            ),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.fromLTRB(12, 12, 8, 20),
                            child: Column(
                              children: [
                                Row(
                                  children: [
                                    for (
                                      var i = 0;
                                      i < _playback.files.length;
                                      i++
                                    )
                                      Expanded(
                                        child: Padding(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 2,
                                          ),
                                          child: i != _playback.photoIndex
                                              ? SizedBox(
                                                  height: 3,
                                                  child: ColoredBox(
                                                    color:
                                                        i < _playback.photoIndex
                                                        ? Colors.white
                                                        : Colors.white24,
                                                  ),
                                                )
                                              : ListenableBuilder(
                                                  listenable: Listenable.merge([
                                                    _timer,
                                                    _videoProgress,
                                                  ]),
                                                  builder: (_, _) => ClipRRect(
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                          4,
                                                        ),
                                                    child: LinearProgressIndicator(
                                                      minHeight: 3,
                                                      value:
                                                          i <
                                                              _playback
                                                                  .photoIndex
                                                          ? 1
                                                          : i >
                                                                _playback
                                                                    .photoIndex
                                                          ? 0
                                                          : file?.fileType == 1
                                                          ? _videoProgress.value
                                                          : _timer.value,
                                                      color: Colors.white,
                                                      backgroundColor:
                                                          Colors.white24,
                                                    ),
                                                  ),
                                                ),
                                        ),
                                      ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        memory?.categoryLabel ?? 'Memories',
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(
                                          color: Colors.white70,
                                        ),
                                      ),
                                    ),
                                    IconButton(
                                      tooltip: _manualPause
                                          ? 'Play story'
                                          : 'Pause story',
                                      onPressed: () {
                                        setState(
                                          () => _manualPause = !_manualPause,
                                        );
                                        _syncTimer();
                                      },
                                      icon: Icon(
                                        _manualPause
                                            ? Icons.play_arrow_rounded
                                            : Icons.pause_rounded,
                                        color: Colors.white,
                                      ),
                                    ),
                                    IconButton(
                                      tooltip: 'Close story',
                                      onPressed: () =>
                                          Navigator.of(context).maybePop(),
                                      icon: const Icon(
                                        Icons.close_rounded,
                                        color: Colors.white,
                                      ),
                                    ),
                                    if (file?.fileType == 1)
                                      IconButton(
                                        tooltip: _muted
                                            ? 'Unmute video'
                                            : 'Mute video',
                                        onPressed: () =>
                                            setState(() => _muted = !_muted),
                                        icon: Icon(
                                          _muted
                                              ? Icons.volume_off_outlined
                                              : Icons.volume_up_outlined,
                                          color: Colors.white,
                                        ),
                                      ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      Positioned(
                        left: 0,
                        right: 0,
                        bottom: 0,
                        child: DecoratedBox(
                          decoration: const BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.bottomCenter,
                              end: Alignment.topCenter,
                              colors: [Colors.black87, Colors.transparent],
                            ),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.fromLTRB(20, 40, 20, 16),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  memory?.title ?? '',
                                  maxLines: size.height < 420 ? 1 : 3,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 24,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  file != null
                                      ? memoryDate(file.creationTime)
                                      : 'Finding your moments…',
                                  style: const TextStyle(color: Colors.white70),
                                ),
                                const SizedBox(height: 8),
                                Row(
                                  children: [
                                    IconButton(
                                      tooltip: 'Previous moment',
                                      onPressed: _playback.previous,
                                      icon: const Icon(
                                        Icons.chevron_left,
                                        color: Colors.white,
                                      ),
                                    ),
                                    Expanded(
                                      child: Text(
                                        file == null
                                            ? ''
                                            : '${_playback.photoIndex + 1} / ${_playback.files.length}',
                                        style: const TextStyle(
                                          color: Colors.white70,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        textAlign: TextAlign.center,
                                      ),
                                    ),
                                    IconButton(
                                      tooltip: 'Next moment',
                                      onPressed: _playback.next,
                                      icon: const Icon(
                                        Icons.chevron_right,
                                        color: Colors.white,
                                      ),
                                    ),
                                    IconButton(
                                      tooltip: 'View original',
                                      onPressed: file == null
                                          ? null
                                          : _viewOriginal,
                                      icon: const Icon(
                                        Icons.open_in_full_rounded,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Keyed per slide. All media continuations belong to this state, so disposed
/// slides cannot update their replacements. Photo clocks start on a painted
/// frame; video progress comes exclusively from the player.
class StoryMedia extends ConsumerStatefulWidget {
  const StoryMedia({
    super.key,
    required this.file,
    required this.paused,
    required this.onReady,
    required this.onUnavailable,
    this.muted = true,
    required this.onVideoProgress,
    required this.onVideoEnded,
    required this.onZoomChanged,
  });
  final EnteFile file;
  final bool paused;
  final bool muted;
  final VoidCallback onReady;
  final VoidCallback onUnavailable;
  final ValueChanged<double> onVideoProgress;
  final VoidCallback onVideoEnded;
  final ValueChanged<bool> onZoomChanged;
  @override
  ConsumerState<StoryMedia> createState() => _StoryMediaState();
}

class _StoryMediaState extends ConsumerState<StoryMedia> {
  Uint8List? _bytes;
  VideoPlayerController? _video;
  final _transform = TransformationController();
  bool _ready = false;
  bool _failed = false;
  bool _ended = false;
  int _generation = 0;

  @override
  void initState() {
    super.initState();
    _transform.addListener(_zoom);
    unawaited(_load());
  }

  bool _lastZoomed = false;
  void _zoom() {
    final zoomed = _transform.value.getMaxScaleOnAxis() > 1.01;
    if (zoomed != _lastZoomed) {
      _lastZoomed = zoomed;
      widget.onZoomChanged(zoomed);
    }
  }

  @override
  void didUpdateWidget(StoryMedia old) {
    super.didUpdateWidget(old);
    if (old.paused != widget.paused) _updateVideo();
    if (old.muted != widget.muted) {
      _video?.setVolume(widget.muted ? 0 : 1).ignore();
    }
  }

  void _updateVideo() {
    final video = _video;
    if (video == null || !video.value.isInitialized) return;
    if (widget.paused) {
      unawaited(video.pause());
    } else {
      unawaited(video.play());
    }
  }

  void _painted() {
    if (_ready || !mounted) return;
    _ready = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) widget.onReady();
    });
  }

  Future<void> _load() async {
    final generation = ++_generation;
    final previous = _video;
    _video = null;
    previous?.removeListener(_videoChanged);
    await previous?.dispose();
    if (!mounted || generation != _generation) return;
    _ended = false;
    _ready = false;
    _failed = false;
    final file = widget.file;
    try {
      final bytes = await ref.read(storyThumbnailLoaderProvider)(file);
      if (!mounted || generation != _generation) return;
      setState(() => _bytes = bytes);
    } catch (_) {
      /* The original may still be available. */
    }
    if (!mounted || generation != _generation) return;
    final service = ref.read(fullResServiceProvider);
    if (file.fileType == 1) {
      if (service == null || !service.canDecrypt(file)) {
        setState(() => _failed = true);
        return;
      }
      VideoPlayerController? video;
      try {
        final path = await service.getVideoPath(file);
        if (!mounted || generation != _generation) return;
        video = VideoPlayerController.file(File(path));
        await video.initialize();
        if (!mounted || generation != _generation) {
          await video.dispose();
          return;
        }
        await video.setVolume(widget.muted ? 0 : 1);
        if (!mounted || generation != _generation) {
          _video = null;
          await video.dispose();
          return;
        }
        _video = video;
        video.addListener(_videoChanged);
        setState(() {});
        _painted();
        _updateVideo();
      } catch (_) {
        await video?.dispose();
        if (mounted && generation == _generation) {
          setState(() => _failed = true);
        }
      }
    } else if (service != null && service.canDecrypt(file)) {
      try {
        final bytes = await service.getImageBytes(file);
        if (!mounted || generation != _generation) return;
        // Validate the codec before replacing a perfectly usable thumbnail.
        if (!await canDisplayImage(bytes)) return;
        if (mounted && generation == _generation) {
          setState(() => _bytes = bytes);
        }
      } catch (_) {
        if (mounted && _bytes == null) setState(() => _failed = true);
      }
    } else if (_bytes == null) {
      setState(() => _failed = true);
    }
  }

  void _videoChanged() {
    final video = _video;
    if (!mounted || video == null) return;
    final value = video.value;
    if (value.hasError) {
      setState(() => _failed = true);
      return;
    }
    final duration = value.duration.inMilliseconds;
    if (duration > 0) {
      widget.onVideoProgress(
        (value.position.inMilliseconds / duration).clamp(0, 1),
      );
      if (!_ended &&
          !widget.paused &&
          !value.isBuffering &&
          value.position >= value.duration) {
        _ended = true;
        widget.onVideoEnded();
      }
    }
  }

  @override
  void dispose() {
    _generation++;
    _transform.removeListener(_zoom);
    _transform.dispose();
    _video?.removeListener(_videoChanged);
    unawaited(_video?.dispose());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_failed && _video != null) {
      final video = _video!;
      return Center(
        child: AspectRatio(
          aspectRatio: video.value.aspectRatio,
          child: VideoPlayer(video),
        ),
      );
    }
    if (_failed) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.photo_outlined, color: Colors.white38, size: 48),
            const SizedBox(height: 12),
            const Text(
              'This moment is unavailable.',
              style: TextStyle(color: Colors.white70),
            ),
            TextButton(
              onPressed: () {
                setState(() => _failed = false);
                unawaited(_load());
              },
              child: const Text('Retry media'),
            ),
          ],
        ),
      );
    }
    if (_bytes == null) {
      return const Center(
        child: CircularProgressIndicator(color: Colors.white54),
      );
    }
    final preview = InteractiveViewer(
      transformationController: _transform,
      minScale: 1,
      maxScale: 5,
      panEnabled: _transform.value.getMaxScaleOnAxis() > 1.01,
      child: SizedBox.expand(
        child: Image.memory(
          _bytes!,
          fit: BoxFit.contain,
          gaplessPlayback: true,
          cacheWidth:
              (MediaQuery.sizeOf(context).width *
                      MediaQuery.devicePixelRatioOf(context))
                  .round()
                  .clamp(512, 2048),
          frameBuilder: (_, child, frame, wasSync) {
            if (widget.file.fileType != 1 && (frame != null || wasSync)) {
              _painted();
            }
            return child;
          },
          errorBuilder: (_, _, _) {
            if (!_failed) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (!mounted) return;
                setState(() => _failed = true);
                widget.onUnavailable();
              });
            }
            return const Center(
              child: Icon(
                Icons.broken_image_outlined,
                color: Colors.white38,
                size: 48,
              ),
            );
          },
        ),
      ),
    );
    if (widget.file.fileType == 1) {
      return Stack(
        fit: StackFit.expand,
        children: [
          preview,
          const Center(child: CircularProgressIndicator(color: Colors.white54)),
        ],
      );
    }
    return preview;
  }
}
