import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/models.dart';
import '../providers/music_provider.dart';
import '../theme/app_theme.dart';

class NowPlayingSheet extends StatefulWidget {
  const NowPlayingSheet({super.key});

  @override
  State<NowPlayingSheet> createState() => _NowPlayingSheetState();
}

class _NowPlayingSheetState extends State<NowPlayingSheet>
    with SingleTickerProviderStateMixin {
  late final AnimationController _rotateController;

  @override
  void initState() {
    super.initState();
    _rotateController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 8),
    );
    final state = context.read<MusicProvider>().playerState;
    if (state == PlayerState.playing) _rotateController.repeat();
  }

  @override
  void dispose() {
    _rotateController.dispose();
    super.dispose();
  }

  String _fmtDuration(Duration d) {
    final m = d.inMinutes.remainder(60);
    final s = d.inSeconds.remainder(60);
    return '$m:${s.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<MusicProvider>();
    final track = provider.currentTrack;
    if (track == null) return const SizedBox.shrink();

    // Sync rotation with playback state
    if (provider.playerState == PlayerState.playing) {
      if (!_rotateController.isAnimating) _rotateController.repeat();
    } else {
      _rotateController.stop();
    }

    final elapsed = _fmtDuration(provider.currentPosition);
    final total = _fmtDuration(provider.totalDuration);

    return Container(
      height: MediaQuery.of(context).size.height * 0.92,
      decoration: const BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          // ── Drag handle ─────────────────────────────────────────────────
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: AppColors.border,
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // ── Header ───────────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.keyboard_arrow_down_rounded,
                      size: 28),
                  color: AppColors.onSurfaceMuted,
                  onPressed: () => Navigator.pop(context),
                ),
                const Expanded(
                  child: Text(
                    'NOW PLAYING',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: AppColors.onSurfaceMuted,
                      letterSpacing: 1.5,
                    ),
                  ),
                ),
                const SizedBox(width: 48), // balance
              ],
            ),
          ),

          // ── Rotating album art ────────────────────────────────────────────
          Expanded(
            child: Center(
              child: RotationTransition(
                turns: _rotateController,
                child: Container(
                  width: 240,
                  height: 240,
                  decoration: BoxDecoration(
                    gradient: AppColors.gradientPrimary,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primary.withOpacity(0.4),
                        blurRadius: 40,
                        spreadRadius: -8,
                      ),
                    ],
                  ),
                  child: Center(
                    child: Text(
                      track.name.substring(0, 1).toUpperCase(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 72,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),

          // ── Track info ───────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 0, 24, 8),
            child: Column(
              children: [
                Text(
                  track.name,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                      fontSize: 20, fontWeight: FontWeight.bold),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  track.artist,
                  style: const TextStyle(
                      fontSize: 14, color: AppColors.onSurfaceMuted),
                ),
              ],
            ),
          ),

          // ── Progress slider ──────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              children: [
                Slider(
                  value: provider.progress.clamp(0, 100),
                  min: 0,
                  max: 100,
                  onChanged: (v) => provider.seek(v),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(elapsed,
                        style: const TextStyle(
                            fontSize: 11,
                            color: AppColors.onSurfaceMuted,
                            fontFamily: 'monospace')),
                    Text(total,
                        style: const TextStyle(
                            fontSize: 11,
                            color: AppColors.onSurfaceMuted,
                            fontFamily: 'monospace')),
                  ],
                ),
              ],
            ),
          ),

          // ── Playback controls ────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 8, 24, 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                IconButton(
                  icon: const Icon(Icons.skip_previous_rounded, size: 36),
                  color: AppColors.onSurfaceMuted,
                  onPressed: () => provider.playPrev(),
                ),
                GestureDetector(
                  onTap: () => provider.togglePlayPause(),
                  child: Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      gradient: AppColors.gradientPrimary,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primary.withOpacity(0.4),
                          blurRadius: 20,
                          spreadRadius: -4,
                        ),
                      ],
                    ),
                    child: Icon(
                      provider.playerState == PlayerState.playing
                          ? Icons.pause_rounded
                          : Icons.play_arrow_rounded,
                      color: Colors.white,
                      size: 32,
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.skip_next_rounded, size: 36),
                  color: AppColors.onSurfaceMuted,
                  onPressed: () => provider.playNext(),
                ),
              ],
            ),
          ),

          // ── Volume ───────────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 0, 24, 32),
            child: Row(
              children: [
                const Icon(Icons.volume_down_rounded,
                    color: AppColors.onSurfaceMuted, size: 20),
                Expanded(
                  child: Slider(
                    value: provider.volume,
                    min: 0,
                    max: 100,
                    onChanged: (v) => provider.setVolume(v),
                  ),
                ),
                const Icon(Icons.volume_up_rounded,
                    color: AppColors.onSurfaceMuted, size: 20),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
