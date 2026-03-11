# 🎵 Audio Haven — Flutter

A mobile-first music player & voice recorder, ported from the original React/TypeScript web app to Flutter.

---

## ✅ Bugs Fixed from the React Original

### Bug 1 — Reminder Notification Loop (VoiceLabView.tsx)
**Original:** The reminder check called `setRecordingReminder()` to mark a reminder
as notified — but that function always set `notified: false`. The notification
fired every 30 seconds indefinitely after the scheduled time passed.

**Fix:** Added a dedicated `markReminderNotified()` method in `MusicProvider`
that explicitly sets `notified = true` and persists it via Hive.
`flutter_local_notifications` handles the actual OS notification scheduling
at the exact time, so the polling timer is only a fallback.

---

### Bug 2 — Stale Volume on Track Change (useAudioPlayer.ts)
**Original:** The `useEffect` that loaded a new track did not include `volume`
in its dependency array. If the user changed volume before starting a track,
the old volume value from the closure was applied.

**Fix:** `MusicProvider._setCurrentTrack()` explicitly calls
`_player.setVolume(_volume / 100)` using the current value of `_volume`
before calling `setFilePath()` — no closure capture issues possible.

---

### Bug 3 — Ephemeral Data (entire app)
**Original:** Everything (tracks, playlists, recordings) lived in React in-memory
state and was lost on every page refresh.

**Fix:** All data is persisted to Hive (a fast local key-value store).
Tracks and recordings survive app restarts.

---

## 🗂 Project Structure

```
lib/
├── main.dart                    # Entry point, Hive init, Provider setup
├── models/
│   ├── models.dart              # Track, Playlist, Recording, RecordingReminder
│   └── models.g.dart            # Hive type adapters (pre-generated)
├── providers/
│   └── music_provider.dart      # Central state (≈ Zustand musicStore.ts)
├── screens/
│   ├── home_screen.dart         # App shell + bottom nav
│   ├── library_screen.dart      # Track library + file picker
│   ├── playlists_screen.dart    # Playlist CRUD + track management
│   ├── voice_lab_screen.dart    # Recorder + playback + reminders
│   └── settings_screen.dart     # Volume, stats, clear data
├── widgets/
│   ├── mini_player.dart         # Persistent bottom-bar player
│   ├── now_playing_sheet.dart   # Full-screen player modal
│   └── track_tile.dart          # Shared track row + GradientButton
└── theme/
    └── app_theme.dart           # Colors, gradients, glass decorations
```

---

## 📦 Dependencies

| Package | Purpose |
|---|---|
| `just_audio` | Audio playback engine |
| `audio_session` | OS audio focus management |
| `record` | Voice recording (MediaRecorder equivalent) |
| `path_provider` | Device file paths |
| `permission_handler` | Runtime permission requests |
| `flutter_local_notifications` | Scheduled reminder notifications |
| `timezone` | Timezone-aware notification scheduling |
| `hive_flutter` | Persistent local storage |
| `provider` | State management (≈ Zustand) |
| `file_picker` | Audio file import dialog |
| `uuid` | ID generation |
| `animations` | Shared element transitions |

---

## 🚀 Getting Started

### Prerequisites
- Flutter SDK ≥ 3.3.0
- Dart ≥ 3.3.0
- For iOS: Xcode 15+, CocoaPods
- For Android: Android Studio, SDK 21+

### Setup

```bash
# 1. Install dependencies
flutter pub get

# 2. Generate Hive adapters (already included in models.g.dart,
#    but re-run if you change models.dart)
flutter pub run build_runner build --delete-conflicting-outputs

# 3. Run
flutter run

# Build release APK
flutter build apk --release

# Build iOS IPA
flutter build ipa --release
```

---

## 📱 Features

### Library
- Import local audio files (MP3, AAC, FLAC, WAV, OGG…)
- Tap to play, delete tracks
- Active track highlighted with purple glow
- Duration displayed for each track

### Playlists
- Create, rename, delete playlists
- Add/remove tracks from playlists
- Tracks persisted across sessions

### Voice Lab
- Tap-to-record with animated pulse button
- Live recording timer
- Playback with play/pause toggle
- Long-press a recording to rename it
- Set date/time reminders → triggers OS notification
- BUG FIXED: reminders no longer repeat indefinitely

### Now Playing
- Full-screen modal with rotating album art
- Seek bar with real elapsed/total time
- Skip forward/back
- Volume slider
- Mini player bar persists across all tabs

### Settings
- Live volume slider
- Library stats (track/playlist/recording counts)
- Clear all data with confirmation dialog

---

## 🎨 Design Notes

The Flutter app faithfully replicates the React app's visual language:

- **Dark glassmorphism** — `glassDecoration()` uses semi-transparent backgrounds + blur
- **Purple → Pink gradient** — `AppColors.gradientPrimary` applied to buttons, album art, progress bars
- **Animated transitions** — `AnimatedSwitcher` for tab changes, spring animations for sheets
- **Rotating disc** — `RotationTransition` in `NowPlayingSheet` synced to playback state

---

## 🔐 Permissions Required

| Permission | Reason |
|---|---|
| `RECORD_AUDIO` / `NSMicrophoneUsageDescription` | Voice Lab recording |
| `READ_MEDIA_AUDIO` / `READ_EXTERNAL_STORAGE` | Importing audio files |
| `POST_NOTIFICATIONS` / UNUserNotificationCenter | Recording reminders |
| `SCHEDULE_EXACT_ALARM` | Precise reminder times on Android |
| `FOREGROUND_SERVICE_MEDIA_PLAYBACK` | Background audio on Android |
| `UIBackgroundModes: audio` | Background audio on iOS |
