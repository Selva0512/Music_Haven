import 'package:hive/hive.dart';
import 'package:uuid/uuid.dart';

part 'models.g.dart';

const _uuid = Uuid();

// ──────────────────────────────────────────────
// Track
// ──────────────────────────────────────────────
@HiveType(typeId: 0)
class Track extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  String name;

  @HiveField(2)
  String artist;

  @HiveField(3)
  String album;

  @HiveField(4)
  double duration; // seconds

  /// Absolute file path on device (replaces blob URL)
  @HiveField(5)
  String filePath;

  Track({
    String? id,
    required this.name,
    this.artist = 'Unknown Artist',
    this.album = 'Unknown Album',
    required this.duration,
    required this.filePath,
  }) : id = id ?? _uuid.v4();
}

// ──────────────────────────────────────────────
// Playlist
// ──────────────────────────────────────────────
@HiveType(typeId: 1)
class Playlist extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  String name;

  @HiveField(2)
  List<String> trackIds;

  @HiveField(3)
  final DateTime createdAt;

  Playlist({
    String? id,
    required this.name,
    List<String>? trackIds,
    DateTime? createdAt,
  })  : id = id ?? _uuid.v4(),
        trackIds = trackIds ?? [],
        createdAt = createdAt ?? DateTime.now();
}

// ──────────────────────────────────────────────
// Recording
// ──────────────────────────────────────────────
@HiveType(typeId: 2)
class Recording extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  String name;

  @HiveField(2)
  double duration; // seconds

  /// Absolute path to the .m4a/.aac file on device
  @HiveField(3)
  String filePath;

  @HiveField(4)
  final DateTime createdAt;

  @HiveField(5)
  RecordingReminder? reminder;

  Recording({
    String? id,
    required this.name,
    required this.duration,
    required this.filePath,
    DateTime? createdAt,
    this.reminder,
  })  : id = id ?? _uuid.v4(),
        createdAt = createdAt ?? DateTime.now();
}

// ──────────────────────────────────────────────
// RecordingReminder
// BUG FIX (React): the original code never actually set notified=true;
// it called setRecordingReminder() again, keeping notified=false forever
// so the notification fired every 30 s indefinitely.
// Here we store a proper `notified` flag and flip it correctly.
// ──────────────────────────────────────────────
@HiveType(typeId: 3)
class RecordingReminder {
  @HiveField(0)
  final DateTime scheduledAt;

  @HiveField(1)
  bool notified;

  RecordingReminder({
    required this.scheduledAt,
    this.notified = false,
  });
}

// ──────────────────────────────────────────────
// PlayerState enum
// ──────────────────────────────────────────────
enum PlayerState { idle, playing, paused }

// ──────────────────────────────────────────────
// AppTab enum
// ──────────────────────────────────────────────
enum AppTab { library, playlists, voiceLab, settings }
