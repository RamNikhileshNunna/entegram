import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../db/models/ente_file.dart';
import '../../providers.dart';

/// Renders a single file's decrypted thumbnail. Fetch + decrypt happen lazily
/// via [ThumbnailService] (download → crypto isolate → cache); while that's in
/// flight a soft loading placeholder shows, and decode is downsampled to
/// [decodeWidth] so big grids stay smooth.
class ThumbnailImage extends ConsumerStatefulWidget {
  const ThumbnailImage({
    super.key,
    required this.file,
    this.fit = BoxFit.cover,
    this.decodeWidth = 512,
  });

  final EnteFile file;
  final BoxFit fit;

  /// Target decode width in pixels (passed to `Image.memory`'s `cacheWidth`).
  /// Ente thumbnails top out near 512 px, so this never upscales — it just
  /// avoids decoding a large bitmap into a small tile. Null = native size.
  final int? decodeWidth;

  @override
  ConsumerState<ThumbnailImage> createState() => _ThumbnailImageState();
}

class _ThumbnailImageState extends ConsumerState<ThumbnailImage> {
  Uint8List? _bytes;
  bool _failed = false;
  int _attempts = 0;
  Timer? _retryTimer;

  @override
  void initState() {
    super.initState();
    _resolve();
  }

  @override
  void dispose() {
    _retryTimer?.cancel();
    super.dispose();
  }

  @override
  void didUpdateWidget(ThumbnailImage old) {
    super.didUpdateWidget(old);
    if (old.file.id != widget.file.id) {
      _retryTimer?.cancel();
      _attempts = 0;
      setState(() {
        _bytes = null;
        _failed = false;
      });
      _resolve();
    } else if (_bytes == null && !_failed) {
      _resolve();
    } else if (_failed &&
        _bytes == null &&
        old.file.thumbnailDecryptionHeader == null &&
        widget.file.thumbnailDecryptionHeader != null) {
      // Sync has populated key material for this file — retry now.
      _retryTimer?.cancel();
      setState(() => _failed = false);
      _resolve();
    }
  }

  void _scheduleRetry(Duration delay) {
    _retryTimer?.cancel();
    _retryTimer = Timer(delay, () {
      if (!mounted) return;
      setState(() => _failed = false);
      _resolve();
    });
  }

  // Exponential backoff capped at 20 s: 2, 4, 8, 16, 20, 20… Quick enough to
  // recover from a transient blip, gentle enough not to hammer the server.
  Duration _backoff() {
    final secs = (1 << _attempts.clamp(0, 4)) * 2;
    return Duration(seconds: secs.clamp(2, 20));
  }

  Future<void> _resolve() async {
    final service = ref.read(thumbnailServiceProvider);
    if (service == null) {
      // SyncController hasn't finished initialising yet — retry shortly.
      _scheduleRetry(const Duration(seconds: 2));
      return;
    }
    try {
      final bytes = await service.get(widget.file);
      if (!mounted) return;
      if (bytes != null) {
        _attempts = 0;
        setState(() {
          _bytes = bytes;
          _failed = false;
        });
      } else {
        // thumbnailDecryptionHeader missing — retry after sync populates it.
        setState(() => _failed = true);
        _scheduleRetry(const Duration(seconds: 15));
      }
    } catch (_) {
      if (!mounted) return;
      _attempts++;
      setState(() => _failed = true);
      _scheduleRetry(_backoff());
    }
  }

  @override
  Widget build(BuildContext context) {
    final bytes = _bytes;
    if (bytes != null) {
      return _FadeIn(
        child: Image.memory(
          bytes,
          fit: widget.fit,
          gaplessPlayback: true,
          cacheWidth: widget.decodeWidth,
          filterQuality: FilterQuality.low,
        ),
      );
    }
    return _Placeholder(failed: _failed, seed: widget.file.id);
  }
}

/// One-shot opacity fade so freshly-decoded thumbnails appear smoothly instead
/// of popping in — cheap (no AnimationController) and runs once per image.
class _FadeIn extends StatelessWidget {
  const _FadeIn({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOut,
      child: child,
      builder: (_, value, child) => Opacity(opacity: value, child: child),
    );
  }
}

/// A deterministic gradient placeholder so the feed has structure before (or
/// without) decrypted pixels. Shows a small spinner while loading and a broken
/// icon once a fetch has failed (a retry is always scheduled in the background).
class _Placeholder extends StatelessWidget {
  const _Placeholder({required this.failed, required this.seed});

  final bool failed;
  final int seed;

  @override
  Widget build(BuildContext context) {
    final hue = (seed * 47) % 360;
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            HSLColor.fromAHSL(1, hue.toDouble(), 0.30, 0.26).toColor(),
            HSLColor.fromAHSL(1, (hue + 40) % 360, 0.30, 0.16).toColor(),
          ],
        ),
      ),
      child: Center(
        child: failed
            ? const Icon(
                Icons.broken_image_outlined,
                color: Colors.white24,
                size: 26,
              )
            : const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor:
                      AlwaysStoppedAnimation(Color.fromRGBO(255, 255, 255, 0.45)),
                ),
              ),
      ),
    );
  }
}
