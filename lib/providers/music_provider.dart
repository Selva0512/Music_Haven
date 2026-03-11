import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:just_audio/just_audio.dart' as ja;
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import '../models/models.dart';

/// Central state manager — equivalent to musicStore.ts (Zustand).
///
/// BUG FIXES vs the original React implementation:
///
/// 1. REMINDER NOTIFICATION LOOP — markReminderNotified() correctly sets
///    notified=true instead of resetting it to false on every check.
/// 2. VOLUME STALE ON TRACK CHANGE — volume is applied explicitly on each load.
/// 3. EPHEMERAL DATA — all data persisted via Hive across restarts.
class MusicProvider extends ChangeNotifier {
  // ── Hive boxes ───────────────────────────────────────────────────────────────
  late Box<Track> _trackBox;
  late Box<Playlist> _playlistBox;
  late Box<Recording> _recordingBox;

  // ── just_audio player ────────────────────────────────────────────────────────
  final ja.AudioPlayer _player = ja.AudioPlayer();
  StreamSubscription? _playerStateSub;
  StreamSubscription? _positionSub;
  StreamSubscription? _durationSub;

  // ── Notifications ────────────────────────────────────────────────────────────
  final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();
  Timer? _reminderTimer;

  // ── UI state ──────────────────────────────────────────────────────────────────
  AppTab _activeTab = AppTab.library;
  bool _isPlayerExpanded = false;

  // ── Playback state ────────────────────────────────────────────────────────────
  Track? _currentTrack;
  PlayerState _playerState = PlayerState.idle;
  double _progress = 0.0;
  double _volume = 80.0;
  Duration _currentPosition = Duration.zero;
  Duration _totalDuration = Duration.zero;

  // ── Getters ───────────────────────────────────────────────────────────────────
  AppTab get activeTab => _activeTab;
  bool get isPlayerExpanded => _isPlayerExpanded;
  Track? get currentTrack => _currentTrack;
  PlayerState get playerState => _playerState;
  double get progress => _progress;
  double get volume => _volume;
  Duration get currentPosition => _currentPosition;
  Duration get totalDuration => _totalDuration;

  List<Track> get tracks => _trackBox.values.toList();
  List<Playlist> get playlists => _playlistBox.values.toList();
  List<Recording> get recordings => _recordingBox.values.toList()
    ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

  // ── Init ──────────────────────────────────────────────────────────────────────
  Future<void> init() async {
    _trackBox = await Hive.openBox<Track>('tracks');
    _playlistBox = await Hive.openBox<Playlist>('playlists');
    _recordingBox = await Hive.openBox<Recording>('recordings');

    await _initNotifications();

    _playerStateSub = _player.playerStateStream.listen(_onPlayerState);
    _positionSub = _player.positionStream.listen(_onPosition);
    _durationSub = _player.durationStream.listen(_onDuration);

    _reminderTimer = Timer.periodic(
      const Duration(seconds: 30),
      (_) => _checkReminders(),
    );

    notifyListeners();
  }

  Future<void> _initNotifications() async {
    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const ios = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );
    // v17+ API: named 'settings:' parameter
    await _notifications.initialize(
      settings: const InitializationSettings(android: android, iOS: ios),
    );
  }

  // ── Player stream handlers ────────────────────────────────────────────────────
  void _onPlayerState(ja.PlayerState state) {
    if (state.processingState == ja.ProcessingState.completed) {
      playNext();
      return;
    }
    _playerState = state.playing ? PlayerState.playing : PlayerState.paused;
    notifyListeners();
  }

  void _onPosition(Duration pos) {
    _currentPosition = pos;
    if (_totalDuration.inMilliseconds > 0) {
      _progress =
          (pos.inMilliseconds / _totalDuration.inMilliseconds * 100)
              .clamp(0, 100);
    }
    notifyListeners();
  }

  void _onDuration(Duration? dur) {
    _totalDuration = dur ?? Duration.zero;
    notifyListeners();
  }

  // ── Navigation ────────────────────────────────────────────────────────────────
  void setActiveTab(AppTab tab) {
    _activeTab = tab;
    notifyListeners();
  }

  void setPlayerExpanded(bool v) {
    _isPlayerExpanded = v;
    notifyListeners();
  }

  // ── Track management ──────────────────────────────────────────────────────────
  Future<void> addTracks(List<Track> newTracks) async {
    for (final t in newTracks) {
      await _trackBox.put(t.id, t);
    }
    notifyListeners();
  }

  Future<void> removeTrack(String id) async {
    await _trackBox.delete(id);
    for (final pl in playlists) {
      if (pl.trackIds.contains(id)) {
        pl.trackIds.remove(id);
        await _playlistBox.put(pl.id, pl);
      }
    }
    if (_currentTrack?.id == id) await _setCurrentTrack(null);
    notifyListeners();
  }

  // ── Playback control ──────────────────────────────────────────────────────────
  Future<void> setCurrentTrack(Track? track) async => _setCurrentTrack(track);

  Future<void> _setCurrentTrack(Track? track) async {
    _currentTrack = track;
    _progress = 0;
    _currentPosition = Duration.zero;

    if (track == null) {
      await _player.stop();
      _playerState = PlayerState.idle;
    } else {
      await _player.setVolume(_volume / 100);
      await _player.setFilePath(track.filePath);
      await _player.play();
      _playerState = PlayerState.playing;
    }
    notifyListeners();
  }

  Future<void> togglePlayPause() async {
    if (_playerState == PlayerState.playing) {
      await _player.pause();
      _playerState = PlayerState.paused;
    } else {
      await _player.play();
      _playerState = PlayerState.playing;
    }
    notifyListeners();
  }

  Future<void> seek(double pct) async {
    if (_totalDuration == Duration.zero) return;
    final ms = (pct / 100 * _totalDuration.inMilliseconds).round();
    await _player.seek(Duration(milliseconds: ms));
    _progress = pct;
    notifyListeners();
  }

  Future<void> setVolume(double v) async {
    _volume = v.clamp(0, 100);
    await _player.setVolume(_volume / 100);
    notifyListeners();
  }

  Future<void> playNext() async {
    final list = tracks;
    if (list.isEmpty || _currentTrack == null) return;
    final idx = list.indexWhere((t) => t.id == _currentTrack!.id);
    final next = list[(idx + 1) % list.length];
    await _setCurrentTrack(next);
  }

  Future<void> playPrev() async {
    final list = tracks;
    if (list.isEmpty || _currentTrack == null) return;
    final idx = list.indexWhere((t) => t.id == _currentTrack!.id);
    final prev = list[(idx - 1 + list.length) % list.length];
    await _setCurrentTrack(prev);
  }

  // ── Playlist management ───────────────────────────────────────────────────────
  Future<void> addPlaylist(String name) async {
    final pl = Playlist(name: name);
    await _playlistBox.put(pl.id, pl);
    notifyListeners();
  }

  Future<void> removePlaylist(String id) async {
    await _playlistBox.delete(id);
    notifyListeners();
  }

  Future<void> renamePlaylist(String id, String name) async {
    final pl = _playlistBox.get(id);
    if (pl == null) return;
    pl.name = name;
    await _playlistBox.put(id, pl);
    notifyListeners();
  }

  Future<void> addTrackToPlaylist(String playlistId, String trackId) async {
    final pl = _playlistBox.get(playlistId);
    if (pl == null || pl.trackIds.contains(trackId)) return;
    pl.trackIds.add(trackId);
    await _playlistBox.put(playlistId, pl);
    notifyListeners();
  }

  Future<void> removeTrackFromPlaylist(
      String playlistId, String trackId) async {
    final pl = _playlistBox.get(playlistId);
    if (pl == null) return;
    pl.trackIds.remove(trackId);
    await _playlistBox.put(playlistId, pl);
    notifyListeners();
  }

  Future<void> reorderPlaylist(
      String playlistId, List<String> trackIds) async {
    final pl = _playlistBox.get(playlistId);
    if (pl == null) return;
    pl.trackIds
      ..clear()
      ..addAll(trackIds);
    await _playlistBox.put(playlistId, pl);
    notifyListeners();
  }

  // ── Recording management ──────────────────────────────────────────────────────
  Future<void> addRecording(Recording rec) async {
    await _recordingBox.put(rec.id, rec);
    notifyListeners();
  }

  Future<void> removeRecording(String id) async {
    await _recordingBox.delete(id);
    notifyListeners();
  }

  Future<void> renameRecording(String id, String name) async {
    final rec = _recordingBox.get(id);
    if (rec == null) return;
    rec.name = name;
    await _recordingBox.put(id, rec);
    notifyListeners();
  }

  Future<void> setRecordingReminder(String id, DateTime scheduledAt) async {
    final rec = _recordingBox.get(id);
    if (rec == null) return;
    rec.reminder = RecordingReminder(scheduledAt: scheduledAt);
    await _recordingBox.put(id, rec);

    // v17+ API: all named parameters, no uiLocalNotificationDateInterpretation
    await _notifications.zonedSchedule(
      id: id.hashCode,
      title: 'Voice Lab Reminder',
      body: rec.name,
      scheduledDate: tz.TZDateTime.from(scheduledAt, tz.local),
      notificationDetails: const NotificationDetails(
        android: AndroidNotificationDetails(
          'reminders',
          'Recording Reminders',
          channelDescription: 'Reminders for voice recordings',
          importance: Importance.high,
          priority: Priority.high,
        ),
        iOS: DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
    );

    notifyListeners();
  }

  Future<void> removeRecordingReminder(String id) async {
    final rec = _recordingBox.get(id);
    if (rec == null) return;
    rec.reminder = null;
    await _recordingBox.put(id, rec);
    // v17+ API: named 'id:' parameter
    await _notifications.cancel(id: id.hashCode);
    notifyListeners();
  }

  /// Correctly flips notified=true (React bug: it was always reset to false).
  Future<void> markReminderNotified(String id) async {
    final rec = _recordingBox.get(id);
    if (rec?.reminder == null) return;
    rec!.reminder!.notified = true;
    await _recordingBox.put(id, rec);
    notifyListeners();
  }

  void _checkReminders() {
    final now = DateTime.now();
    for (final rec in recordings) {
      final r = rec.reminder;
      if (r != null && !r.notified && now.isAfter(r.scheduledAt)) {
        markReminderNotified(rec.id);
      }
    }
  }

  // ── Dispose ───────────────────────────────────────────────────────────────────
  @override
  void dispose() {
    _playerStateSub?.cancel();
    _positionSub?.cancel();
    _durationSub?.cancel();
    _reminderTimer?.cancel();
    _player.dispose();
    super.dispose();
  }
}
