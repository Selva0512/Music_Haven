import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:just_audio/just_audio.dart' as ja;
import 'package:provider/provider.dart';

import '../models/models.dart';
import '../providers/music_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/track_tile.dart';

class LibraryScreen extends StatelessWidget {
  const LibraryScreen({super.key});

  Future<void> _pickFiles(BuildContext context) async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.audio,
      allowMultiple: true,
    );
    if (result == null || result.files.isEmpty) return;

    final provider = context.read<MusicProvider>();
    final newTracks = <Track>[];

    for (final f in result.files) {
      if (f.path == null) continue;

      // Resolve duration using just_audio
      double duration = 0;
      try {
        final probe = ja.AudioPlayer();
        final d = await probe.setFilePath(f.path!);
        duration = d?.inSeconds.toDouble() ?? 0;
        await probe.dispose();
      } catch (_) {}

      final name = f.name.replaceAll(RegExp(r'\.[^.]+$'), '');
      newTracks.add(Track(
        name: name,
        duration: duration,
        filePath: f.path!,
      ));
    }

    if (newTracks.isNotEmpty) await provider.addTracks(newTracks);
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<MusicProvider>();
    final tracks = provider.tracks;

    return SafeArea(
      bottom: false,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header ──────────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('My Music',
                          style: Theme.of(context).textTheme.headlineMedium),
                      Text(
                        '${tracks.length} track${tracks.length == 1 ? '' : 's'}',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
                GradientButton(
                  label: 'Add Files',
                  icon: Icons.folder_open_rounded,
                  onTap: () => _pickFiles(context),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // ── Track list ──────────────────────────────────────────────────
          Expanded(
            child: tracks.isEmpty
                ? _EmptyState()
                : ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 160),
                    itemCount: tracks.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 4),
                    itemBuilder: (context, i) {
                      final track = tracks[i];
                      final isPlaying =
                          provider.currentTrack?.id == track.id &&
                              provider.playerState == PlayerState.playing;
                      return TrackTile(
                        track: track,
                        isActive: provider.currentTrack?.id == track.id,
                        isPlaying: isPlaying,
                        onTap: () => provider.setCurrentTrack(track),
                        onDelete: () => provider.removeTrack(track.id),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: glassDecoration(),
            child: const Icon(Icons.music_note_rounded,
                size: 40, color: AppColors.onSurfaceMuted),
          ),
          const SizedBox(height: 16),
          const Text('No tracks yet',
              style: TextStyle(color: AppColors.onSurfaceMuted)),
          const SizedBox(height: 4),
          const Text('Tap "Add Files" to load your music',
              style: TextStyle(fontSize: 12, color: AppColors.onSurfaceMuted)),
        ],
      ),
    );
  }
}
