import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/models.dart';
import '../providers/music_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/mini_player.dart';
import 'library_screen.dart';
import 'playlists_screen.dart';
import 'voice_lab_screen.dart';
import 'settings_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  static const _screens = [
    LibraryScreen(),
    PlaylistsScreen(),
    VoiceLabScreen(),
    SettingsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<MusicProvider>();
    final tabIndex = provider.activeTab.index;
    final hasTrack = provider.currentTrack != null;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          // ── Main content ────────────────────────────────────────────────
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 200),
            transitionBuilder: (child, anim) => FadeTransition(
              opacity: anim,
              child: SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(0, 0.03),
                  end: Offset.zero,
                ).animate(anim),
                child: child,
              ),
            ),
            child: KeyedSubtree(
              key: ValueKey(tabIndex),
              child: _screens[tabIndex],
            ),
          ),

          // ── Mini player (slides up when a track is loaded) ───────────────
          const Align(
            alignment: Alignment.bottomCenter,
            child: MiniPlayer(),
          ),
        ],
      ),

      // ── Bottom nav ──────────────────────────────────────────────────────
      bottomNavigationBar: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // space for mini player
          if (hasTrack) const SizedBox(height: 72),
          _BottomNav(currentIndex: tabIndex),
        ],
      ),

      // ── Now Playing full-screen sheet ───────────────────────────────────
      extendBody: true,
    );
  }
}

class _BottomNav extends StatelessWidget {
  const _BottomNav({required this.currentIndex});
  final int currentIndex;

  @override
  Widget build(BuildContext context) {
    final provider = context.read<MusicProvider>();

    return Container(
      decoration: glassDecoration(strong: true).copyWith(
        borderRadius: BorderRadius.zero,
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 64,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _NavItem(
                icon: Icons.music_note_rounded,
                label: 'Library',
                active: currentIndex == 0,
                onTap: () => provider.setActiveTab(AppTab.library),
              ),
              _NavItem(
                icon: Icons.queue_music_rounded,
                label: 'Playlists',
                active: currentIndex == 1,
                onTap: () => provider.setActiveTab(AppTab.playlists),
              ),
              _NavItem(
                icon: Icons.mic_rounded,
                label: 'Voice Lab',
                active: currentIndex == 2,
                onTap: () => provider.setActiveTab(AppTab.voiceLab),
              ),
              _NavItem(
                icon: Icons.settings_rounded,
                label: 'Settings',
                active: currentIndex == 3,
                onTap: () => provider.setActiveTab(AppTab.settings),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.icon,
    required this.label,
    required this.active,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        width: 72,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Animated indicator bar at top
            AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              curve: Curves.easeOut,
              height: 3,
              width: active ? 32 : 0,
              decoration: BoxDecoration(
                gradient: active ? AppColors.gradientPrimary : null,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 6),
            Icon(
              icon,
              size: 22,
              color: active ? AppColors.primary : AppColors.onSurfaceMuted,
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w500,
                color: active ? AppColors.primary : AppColors.onSurfaceMuted,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
