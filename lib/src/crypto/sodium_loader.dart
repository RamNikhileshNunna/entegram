import 'package:flutter_sodium/flutter_sodium.dart';

/// Initialises libsodium for the calling isolate. Safe to call multiple times.
void initSodiumSync() => Sodium.init();
