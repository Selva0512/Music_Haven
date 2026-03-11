import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:provider/provider.dart';
import 'package:timezone/data/latest_all.dart' as tz;

import 'models/models.dart';
import 'providers/music_provider.dart';
import 'screens/home_screen.dart';
import 'theme/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Timezone for scheduled notifications
  tz.initializeTimeZones();

  // Lock to portrait
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // Transparent status bar
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.light,
  ));

  // Hive init + adapter registration
  await Hive.initFlutter();
  Hive.registerAdapter(TrackAdapter());
  Hive.registerAdapter(PlaylistAdapter());
  Hive.registerAdapter(RecordingAdapter());
  Hive.registerAdapter(RecordingReminderAdapter());

  // Init provider (opens Hive boxes, sets up audio player)
  final musicProvider = MusicProvider();
  await musicProvider.init();

  runApp(
    ChangeNotifierProvider.value(
      value: musicProvider,
      child: const AudioHavenApp(),
    ),
  );
}

class AudioHavenApp extends StatelessWidget {
  const AudioHavenApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Audio Haven',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.dark,
      home: const HomeScreen(),
    );
  }
}
