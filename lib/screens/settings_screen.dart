import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/music_provider.dart';
import '../theme/app_theme.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<MusicProvider>();

    return SafeArea(
      bottom: false,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 160),
        children: [
          Text('Settings', style: Theme.of(context).textTheme.headlineMedium),
          const SizedBox(height: 24),

          // ── Playback ──────────────────────────────────────────────────────
          _SectionHeader(label: 'PLAYBACK'),
          const SizedBox(height: 8),
          _SettingsTile(
            icon: Icons.volume_up_rounded,
            title: 'Default Volume',
            subtitle: '${provider.volume.round()}%',
            trailing: SizedBox(
              width: 160,
              child: SliderTheme(
                data: SliderTheme.of(context).copyWith(trackHeight: 2),
                child: Slider(
                  value: provider.volume,
                  min: 0,
                  max: 100,
                  onChanged: (v) => provider.setVolume(v),
                ),
              ),
            ),
          ),

          const SizedBox(height: 8),

          // ── Library stats ─────────────────────────────────────────────────
          _SectionHeader(label: 'LIBRARY'),
          const SizedBox(height: 8),
          _SettingsTile(
            icon: Icons.music_note_rounded,
            title: 'Tracks',
            subtitle: '${provider.tracks.length} imported',
          ),
          const SizedBox(height: 6),
          _SettingsTile(
            icon: Icons.queue_music_rounded,
            title: 'Playlists',
            subtitle: '${provider.playlists.length} created',
          ),
          const SizedBox(height: 6),
          _SettingsTile(
            icon: Icons.mic_rounded,
            title: 'Recordings',
            subtitle: '${provider.recordings.length} saved',
          ),

          const SizedBox(height: 16),

          // ── Privacy ───────────────────────────────────────────────────────
          _SectionHeader(label: 'PRIVACY & STORAGE'),
          const SizedBox(height: 8),
          _SettingsTile(
            icon: Icons.lock_outline_rounded,
            title: 'Local Storage Only',
            subtitle:
                'All tracks and recordings stay on your device. Nothing is uploaded.',
          ),
          const SizedBox(height: 6),
          _SettingsTile(
            icon: Icons.delete_forever_rounded,
            title: 'Clear All Data',
            subtitle: 'Remove all tracks, playlists, and recordings',
            trailing: TextButton(
              onPressed: () => _confirmClear(context, provider),
              child: const Text('Clear',
                  style: TextStyle(color: AppColors.destructive)),
            ),
          ),

          const SizedBox(height: 16),

          // ── About ─────────────────────────────────────────────────────────
          _SectionHeader(label: 'ABOUT'),
          const SizedBox(height: 8),
          _SettingsTile(
            icon: Icons.info_outline_rounded,
            title: 'Audio Haven',
            subtitle: 'Version 1.0.0 — Offline-first music & voice recorder',
          ),
        ],
      ),
    );
  }

  void _confirmClear(BuildContext context, MusicProvider provider) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: const Text('Clear All Data?'),
        content: const Text(
          'This will permanently delete all tracks, playlists, and recordings.',
          style: TextStyle(color: AppColors.onSurfaceMuted),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              for (final t in provider.tracks) {
                await provider.removeTrack(t.id);
              }
              for (final p in provider.playlists) {
                await provider.removePlaylist(p.id);
              }
              for (final r in provider.recordings) {
                await provider.removeRecording(r.id);
              }
              if (context.mounted) Navigator.pop(context);
            },
            child: const Text('Clear',
                style: TextStyle(color: AppColors.destructive)),
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: const TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w600,
        color: AppColors.onSurfaceMuted,
        letterSpacing: 1.2,
      ),
    );
  }
}

class _SettingsTile extends StatelessWidget {
  const _SettingsTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.trailing,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: glassDecoration(),
      child: Row(
        children: [
          Icon(icon, color: AppColors.primary, size: 22),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: const TextStyle(
                        fontWeight: FontWeight.w600, fontSize: 14)),
                const SizedBox(height: 2),
                Text(subtitle,
                    style: const TextStyle(
                        fontSize: 12, color: AppColors.onSurfaceMuted)),
              ],
            ),
          ),
          if (trailing != null) trailing!,
        ],
      ),
    );
  }
}
