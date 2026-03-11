import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';
import 'package:record/record.dart';
import 'package:just_audio/just_audio.dart' as ja;

import '../models/models.dart';
import '../providers/music_provider.dart';
import '../theme/app_theme.dart';

class VoiceLabScreen extends StatefulWidget {
  const VoiceLabScreen({super.key});

  @override
  State<VoiceLabScreen> createState() => _VoiceLabScreenState();
}

class _VoiceLabScreenState extends State<VoiceLabScreen>
    with TickerProviderStateMixin {
  final AudioRecorder _recorder = AudioRecorder();
  final ja.AudioPlayer _previewPlayer = ja.AudioPlayer();

  bool _isRecording = false;
  int _recordSeconds = 0;
  String? _currentRecordingPath;
  String? _playingId;

  late final AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _recorder.dispose();
    _previewPlayer.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  // ── Recording ──────────────────────────────────────────────────────────────
  Future<void> _startRecording() async {
    final micPermission = await Permission.microphone.request();
    if (!micPermission.isGranted) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Microphone permission denied')),
        );
      }
      return;
    }

    final dir = await getApplicationDocumentsDirectory();
    final path =
        '${dir.path}/recording_${DateTime.now().millisecondsSinceEpoch}.m4a';

    await _recorder.start(
      const RecordConfig(encoder: AudioEncoder.aacLc, bitRate: 128000),
      path: path,
    );

    setState(() {
      _isRecording = true;
      _recordSeconds = 0;
      _currentRecordingPath = path;
    });

    // Timer
    _tickTimer();
  }

  void _tickTimer() async {
    if (!_isRecording) return;
    await Future.delayed(const Duration(seconds: 1));
    if (!mounted || !_isRecording) return;
    setState(() => _recordSeconds++);
    _tickTimer();
  }

  Future<void> _stopRecording() async {
    final path = await _recorder.stop();
    if (path == null) return;

    final provider = context.read<MusicProvider>();
    final count = provider.recordings.length + 1;

    final rec = Recording(
      name: 'Recording $count',
      duration: _recordSeconds.toDouble(),
      filePath: path,
    );

    await provider.addRecording(rec);

    setState(() {
      _isRecording = false;
      _currentRecordingPath = null;
    });
  }

  // ── Playback ───────────────────────────────────────────────────────────────
  Future<void> _togglePlay(Recording rec) async {
    if (_playingId == rec.id) {
      await _previewPlayer.stop();
      setState(() => _playingId = null);
      return;
    }
    await _previewPlayer.setFilePath(rec.filePath);
    await _previewPlayer.play();
    setState(() => _playingId = rec.id);
    _previewPlayer.playerStateStream.listen((s) {
      if (s.processingState == ja.ProcessingState.completed) {
        if (mounted) setState(() => _playingId = null);
      }
    });
  }

  // ── Rename ─────────────────────────────────────────────────────────────────
  void _showRenameDialog(Recording rec) {
    final ctrl = TextEditingController(text: rec.name);
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: const Text('Rename Recording'),
        content: TextField(
          controller: ctrl,
          autofocus: true,
          decoration: const InputDecoration(hintText: 'Recording name'),
          style: const TextStyle(color: AppColors.onSurface),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel')),
          TextButton(
            onPressed: () {
              context.read<MusicProvider>().renameRecording(rec.id, ctrl.text.trim());
              Navigator.pop(context);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  // ── Reminder picker ────────────────────────────────────────────────────────
  Future<void> _showReminderPicker(Recording rec) async {
    final now = DateTime.now();
    final date = await showDatePicker(
      context: context,
      initialDate: now,
      firstDate: now,
      lastDate: now.add(const Duration(days: 365)),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: const ColorScheme.dark(primary: AppColors.primary),
        ),
        child: child!,
      ),
    );
    if (date == null || !mounted) return;

    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(now),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: const ColorScheme.dark(primary: AppColors.primary),
        ),
        child: child!,
      ),
    );
    if (time == null || !mounted) return;

    final scheduledAt = DateTime(
        date.year, date.month, date.day, time.hour, time.minute);

    await context.read<MusicProvider>().setRecordingReminder(rec.id, scheduledAt);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
              'Reminder set for ${_fmt(scheduledAt)}'),
          backgroundColor: AppColors.primary,
        ),
      );
    }
  }

  String _fmt(DateTime dt) =>
      '${dt.month}/${dt.day}/${dt.year} ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';

  String _fmtSecs(num s) {
    final m = s ~/ 60;
    final sec = (s % 60).round();
    return '$m:${sec.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<MusicProvider>();
    final recordings = provider.recordings;

    return SafeArea(
      bottom: false,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
            child: Text('Voice Lab',
                style: Theme.of(context).textTheme.headlineMedium),
          ),

          // ── Record button ─────────────────────────────────────────────────
          Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 32),
              child: Column(
                children: [
                  AnimatedBuilder(
                    animation: _pulseController,
                    builder: (_, child) {
                      final scale = _isRecording
                          ? 1.0 + (_pulseController.value * 0.08)
                          : 1.0;
                      return Transform.scale(scale: scale, child: child);
                    },
                    child: GestureDetector(
                      onTap: _isRecording ? _stopRecording : _startRecording,
                      child: Container(
                        width: 80,
                        height: 80,
                        decoration: _isRecording
                            ? BoxDecoration(
                                color: AppColors.destructive,
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: AppColors.destructive.withOpacity(0.4),
                                    blurRadius: 24,
                                    spreadRadius: -4,
                                  ),
                                ],
                              )
                            : BoxDecoration(
                                gradient: AppColors.gradientPrimary,
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: AppColors.primary.withOpacity(0.4),
                                    blurRadius: 24,
                                    spreadRadius: -4,
                                  ),
                                ],
                              ),
                        child: Icon(
                          _isRecording ? Icons.stop_rounded : Icons.mic_rounded,
                          color: Colors.white,
                          size: 36,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    _isRecording ? _fmtSecs(_recordSeconds) : 'Tap to record',
                    style: TextStyle(
                      fontFamily: 'monospace',
                      color: _isRecording
                          ? AppColors.onSurface
                          : AppColors.onSurfaceMuted,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // ── Recordings list ───────────────────────────────────────────────
          Expanded(
            child: recordings.isEmpty
                ? Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 80,
                          height: 80,
                          decoration: glassDecoration(),
                          child: const Icon(Icons.mic_none_rounded,
                              size: 40, color: AppColors.onSurfaceMuted),
                        ),
                        const SizedBox(height: 16),
                        const Text('No recordings yet',
                            style:
                                TextStyle(color: AppColors.onSurfaceMuted)),
                      ],
                    ),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 160),
                    itemCount: recordings.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (_, i) {
                      final rec = recordings[i];
                      return _RecordingTile(
                        recording: rec,
                        isPlaying: _playingId == rec.id,
                        onPlay: () => _togglePlay(rec),
                        onRename: () => _showRenameDialog(rec),
                        onDelete: () => provider.removeRecording(rec.id),
                        onSetReminder: () => _showReminderPicker(rec),
                        onRemoveReminder: () =>
                            provider.removeRecordingReminder(rec.id),
                        fmtSecs: _fmtSecs,
                        fmtDt: _fmt,
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

// ── Recording tile ────────────────────────────────────────────────────────────
class _RecordingTile extends StatelessWidget {
  const _RecordingTile({
    required this.recording,
    required this.isPlaying,
    required this.onPlay,
    required this.onRename,
    required this.onDelete,
    required this.onSetReminder,
    required this.onRemoveReminder,
    required this.fmtSecs,
    required this.fmtDt,
  });

  final Recording recording;
  final bool isPlaying;
  final VoidCallback onPlay;
  final VoidCallback onRename;
  final VoidCallback onDelete;
  final VoidCallback onSetReminder;
  final VoidCallback onRemoveReminder;
  final String Function(num) fmtSecs;
  final String Function(DateTime) fmtDt;

  @override
  Widget build(BuildContext context) {
    final hasReminder = recording.reminder != null;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: glassDecoration(),
      child: Row(
        children: [
          // Play button
          GestureDetector(
            onTap: onPlay,
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: isPlaying
                    ? AppColors.accent.withOpacity(0.2)
                    : AppColors.surfaceElevated,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                color: isPlaying ? AppColors.accent : AppColors.onSurface,
                size: 22,
              ),
            ),
          ),
          const SizedBox(width: 12),

          // Name + duration + reminder info
          Expanded(
            child: GestureDetector(
              onLongPress: onRename,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(recording.name,
                      style: const TextStyle(fontWeight: FontWeight.w600)),
                  Row(
                    children: [
                      Text(fmtSecs(recording.duration),
                          style: const TextStyle(
                              fontFamily: 'monospace',
                              fontSize: 11,
                              color: AppColors.onSurfaceMuted)),
                      if (hasReminder) ...[
                        const SizedBox(width: 8),
                        const Icon(Icons.notifications_active_rounded,
                            size: 11, color: AppColors.primary),
                        const SizedBox(width: 2),
                        Text(
                          fmtDt(recording.reminder!.scheduledAt),
                          style: const TextStyle(
                              fontSize: 10, color: AppColors.primary),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ),

          // Reminder toggle
          IconButton(
            icon: Icon(
              hasReminder
                  ? Icons.notifications_off_outlined
                  : Icons.notifications_none_rounded,
              size: 20,
              color: hasReminder
                  ? AppColors.primary
                  : AppColors.onSurfaceMuted,
            ),
            onPressed: hasReminder ? onRemoveReminder : onSetReminder,
          ),

          // Delete
          IconButton(
            icon: const Icon(Icons.delete_outline_rounded,
                size: 20, color: AppColors.onSurfaceMuted),
            onPressed: onDelete,
          ),
        ],
      ),
    );
  }
}
