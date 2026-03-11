import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/models.dart';
import '../providers/music_provider.dart';
import '../theme/app_theme.dart';

class PlaylistsScreen extends StatefulWidget {
  const PlaylistsScreen({super.key});

  @override
  State<PlaylistsScreen> createState() => _PlaylistsScreenState();
}

class _PlaylistsScreenState extends State<PlaylistsScreen> {
  final _nameController = TextEditingController();
  String? _selectedPlaylistId;

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  void _createPlaylist(MusicProvider provider) {
    final name = _nameController.text.trim();
    if (name.isEmpty) return;
    provider.addPlaylist(name);
    _nameController.clear();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<MusicProvider>();
    final playlists = provider.playlists;

    if (_selectedPlaylistId != null) {
      final pl = playlists.firstWhere(
        (p) => p.id == _selectedPlaylistId,
        orElse: () {
          _selectedPlaylistId = null;
          return Playlist(name: '');
        },
      );
      if (_selectedPlaylistId != null) {
        return _PlaylistDetailView(
          playlist: pl,
          provider: provider,
          onBack: () => setState(() => _selectedPlaylistId = null),
        );
      }
    }

    return SafeArea(
      bottom: false,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
            child: Text('Playlists',
                style: Theme.of(context).textTheme.headlineMedium),
          ),

          // ── Create new playlist ──────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    decoration: glassDecoration(),
                    child: TextField(
                      controller: _nameController,
                      style: const TextStyle(color: AppColors.onSurface),
                      decoration: const InputDecoration(
                        hintText: 'New playlist name…',
                        hintStyle:
                            TextStyle(color: AppColors.onSurfaceMuted),
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.symmetric(
                            horizontal: 16, vertical: 12),
                      ),
                      onSubmitted: (_) =>
                          _createPlaylist(context.read<MusicProvider>()),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: () =>
                      _createPlaylist(context.read<MusicProvider>()),
                  child: Container(
                    width: 44,
                    height: 44,
                    decoration: gradientDecoration(),
                    child: const Icon(Icons.add_rounded,
                        color: Colors.white, size: 22),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // ── Playlist list ────────────────────────────────────────────────
          Expanded(
            child: playlists.isEmpty
                ? _EmptyState()
                : ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 160),
                    itemCount: playlists.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (context, i) {
                      final pl = playlists[i];
                      return _PlaylistTile(
                        playlist: pl,
                        onTap: () =>
                            setState(() => _selectedPlaylistId = pl.id),
                        onDelete: () => provider.removePlaylist(pl.id),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

// ── Playlist tile ─────────────────────────────────────────────────────────────
class _PlaylistTile extends StatelessWidget {
  const _PlaylistTile({
    required this.playlist,
    required this.onTap,
    required this.onDelete,
  });

  final Playlist playlist;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: glassDecoration(),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: AppColors.surfaceElevated,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.queue_music_rounded,
                  color: AppColors.primary, size: 22),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(playlist.name,
                      style:
                          const TextStyle(fontWeight: FontWeight.w600)),
                  Text(
                      '${playlist.trackIds.length} track${playlist.trackIds.length == 1 ? '' : 's'}',
                      style: const TextStyle(
                          fontSize: 12, color: AppColors.onSurfaceMuted)),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded,
                color: AppColors.onSurfaceMuted),
            IconButton(
              icon: const Icon(Icons.delete_outline_rounded,
                  color: AppColors.onSurfaceMuted, size: 20),
              onPressed: onDelete,
            ),
          ],
        ),
      ),
    );
  }
}

// ── Playlist detail ───────────────────────────────────────────────────────────
class _PlaylistDetailView extends StatelessWidget {
  const _PlaylistDetailView({
    required this.playlist,
    required this.provider,
    required this.onBack,
  });

  final Playlist playlist;
  final MusicProvider provider;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    final allTracks = provider.tracks;
    final playlistTracks = playlist.trackIds
        .map((id) => allTracks.firstWhere(
              (t) => t.id == id,
              orElse: () => Track(name: '', duration: 0, filePath: ''),
            ))
        .where((t) => t.name.isNotEmpty)
        .toList();
    final availableTracks =
        allTracks.where((t) => !playlist.trackIds.contains(t.id)).toList();

    return SafeArea(
      bottom: false,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 20, 0),
            child: Row(
              children: [
                GestureDetector(
                  onTap: onBack,
                  child: const Row(
                    children: [
                      Icon(Icons.arrow_back_ios_new_rounded,
                          size: 16, color: AppColors.primary),
                      SizedBox(width: 4),
                      Text('Back',
                          style: TextStyle(
                              color: AppColors.primary,
                              fontWeight: FontWeight.w500)),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
            child: Text(playlist.name,
                style: Theme.of(context).textTheme.headlineMedium),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 160),
              children: [
                if (playlistTracks.isEmpty)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 12),
                    child: Text('No tracks in this playlist.',
                        style:
                            TextStyle(color: AppColors.onSurfaceMuted)),
                  )
                else ...[
                  ...playlistTracks.map((t) => Padding(
                        padding: const EdgeInsets.only(bottom: 4),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 12),
                          decoration: glassDecoration(),
                          child: Row(
                            children: [
                              Expanded(
                                child: Text(t.name,
                                    style: const TextStyle(
                                        fontWeight: FontWeight.w500)),
                              ),
                              IconButton(
                                icon: const Icon(Icons.remove_circle_outline,
                                    color: AppColors.destructive,
                                    size: 20),
                                onPressed: () =>
                                    provider.removeTrackFromPlaylist(
                                        playlist.id, t.id),
                              ),
                            ],
                          ),
                        ),
                      )),
                  const SizedBox(height: 16),
                ],
                if (availableTracks.isNotEmpty) ...[
                  const Text('ADD TRACKS',
                      style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: AppColors.onSurfaceMuted,
                          letterSpacing: 1.2)),
                  const SizedBox(height: 8),
                  ...availableTracks.map((t) => GestureDetector(
                        onTap: () =>
                            provider.addTrackToPlaylist(playlist.id, t.id),
                        child: Padding(
                          padding: const EdgeInsets.only(bottom: 4),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 12),
                            decoration: BoxDecoration(
                              color: AppColors.surfaceElevated
                                  .withOpacity(0.5),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.add_rounded,
                                    color: AppColors.primary, size: 18),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(t.name,
                                      style: const TextStyle(fontSize: 14)),
                                ),
                              ],
                            ),
                          ),
                        ),
                      )),
                ],
              ],
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
            child: const Icon(Icons.queue_music_rounded,
                size: 40, color: AppColors.onSurfaceMuted),
          ),
          const SizedBox(height: 16),
          const Text('No playlists yet',
              style: TextStyle(color: AppColors.onSurfaceMuted)),
        ],
      ),
    );
  }
}
