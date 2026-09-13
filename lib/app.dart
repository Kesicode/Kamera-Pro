import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'ui/camera/camera_screen.dart';
import 'ui/gallery/gallery_screen.dart';
import 'ui/settings/settings_screen.dart';
import 'ui/debug/debug_screen.dart';

/// The root Kamera Pro application widget.
class KameraProApp extends StatelessWidget {
  const KameraProApp({super.key});

  @override
  Widget build(BuildContext context) {
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);

    return MaterialApp(
      title: 'Kamera Pro',
      debugShowCheckedModeBanner: false,
      theme: _buildDarkTheme(),
      home: const CameraScreen(),
      routes: {
        '/gallery': (_) => const GalleryScreen(),
        '/settings': (_) => const SettingsScreen(),
        '/debug': (_) => const DebugScreen(),
      },
    );
  }

  ThemeData _buildDarkTheme() {
    const primaryColor = Color(0xFFE8C547);
    const backgroundColor = Color(0xFF0A0A0A);
    const surfaceColor = Color(0xFF1A1A1A);
    const onSurface = Color(0xFFEEEEEE);

    return ThemeData(
      brightness: Brightness.dark,
      useMaterial3: true,
      colorScheme: const ColorScheme.dark(
        primary: primaryColor,
        secondary: primaryColor,
        surface: surfaceColor,
        onSurface: onSurface,
        onPrimary: Colors.black,
      ),
      scaffoldBackgroundColor: backgroundColor,
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: onSurface,
        systemOverlayStyle: SystemUiOverlayStyle.light,
      ),
      cardTheme: CardThemeData(
        color: surfaceColor,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(color: Color(0xFF2A2A2A)),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryColor,
          foregroundColor: Colors.black,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      ),
      iconTheme: const IconThemeData(color: onSurface),
      sliderTheme: SliderThemeData(
        activeTrackColor: primaryColor,
        thumbColor: primaryColor,
        inactiveTrackColor: const Color(0xFF333333),
        trackHeight: 2,
        thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 8),
      ),
      textTheme: const TextTheme(
        headlineMedium:
            TextStyle(color: onSurface, fontWeight: FontWeight.bold, fontSize: 24),
        bodyMedium: TextStyle(color: onSurface, fontSize: 14),
        bodySmall: TextStyle(color: Color(0xFFAAAAAA), fontSize: 12),
        labelSmall: TextStyle(
          color: primaryColor,
          fontSize: 10,
          fontWeight: FontWeight.bold,
          letterSpacing: 1.2,
        ),
      ),
    );
  }
}
