import 'package:flutter/material.dart';
import '../models/models.dart';
import '../theme/app_theme.dart';
export 'gradient_button.dart'; // re-export so any file importing track_tile gets GradientButton too

// ── TrackTile ─────────────────────────────────────────────────────────────────
class TrackTile extends StatelessWidget {
  const TrackTile({
    super.key,
    required this.track,
    required this.isActive,
    required this.isPlaying,
    required this.onTap,
    required this.onDelete,
    this.trailing,
  });

  final Track track;
  final bool isActive;
  final bool isPlaying;
  final VoidCallback onTap;
  final VoidCallback onDelete;
  final Widget? trailing;

  String _fmtDuration(double s) {
    final m = s ~/ 60;
    final sec = (s % 60).round();
    return '$m:${sec.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: isActive
            ? BoxDecoration(
                color: AppColors.primary.withOpacity(0.12),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.primary.withOpacity(0.3)),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withOpacity(0.15),
                    blurRadius: 16,
                    spreadRadius: -4,
                  ),
                ],
              )
            : BoxDecoration(
                color: Colors.transparent,
                borderRadius: BorderRadius.circular(14),
              ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: gradientDecoration(radius: 10),
              child: Icon(
                isPlaying ? Icons.equalizer_rounded : Icons.play_arrow_rounded,
                color: Colors.white,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(track.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          fontWeight: FontWeight.w600, fontSize: 14)),
                  Text(track.artist,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          fontSize: 12, color: AppColors.onSurfaceMuted)),
                ],
              ),
            ),
            Text(
              _fmtDuration(track.duration),
              style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.onSurfaceMuted,
                  fontFamily: 'monospace'),
            ),
            const SizedBox(width: 4),
            if (trailing != null) trailing!,
            IconButton(
              icon: const Icon(Icons.delete_outline_rounded, size: 18),
              color: AppColors.onSurfaceMuted,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
              onPressed: onDelete,
            ),
          ],
        ),
      ),
    );
  }
}
