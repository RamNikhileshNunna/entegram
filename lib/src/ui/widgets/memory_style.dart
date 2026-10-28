import 'package:flutter/material.dart';
import '../../db/models/memory_cluster.dart';
import '../../memories/memory_catalog.dart';

IconData memoryIcon(MemoryCluster memory) => switch (memory.category) {
  MemoryCategory.onThisDay => Icons.history_rounded,
  MemoryCategory.flashback => Icons.auto_awesome_outlined,
  MemoryCategory.people => Icons.people_alt_outlined,
  MemoryCategory.trip => Icons.landscape_outlined,
  MemoryCategory.recent => Icons.wb_sunny_outlined,
  MemoryCategory.season => Icons.park_outlined,
  MemoryCategory.year => Icons.auto_stories_outlined,
  MemoryCategory.day => Icons.photo_library_outlined,
};

Color memoryColor(MemoryCluster memory) => switch (memory.category) {
  MemoryCategory.onThisDay ||
  MemoryCategory.flashback => const Color(0xFFBCC7FF),
  MemoryCategory.people => const Color(0xFFFFC7AF),
  MemoryCategory.trip => const Color(0xFFB1DAC7),
  _ => const Color(0xFFE6D7B8),
};
