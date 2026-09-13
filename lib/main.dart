import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'app.dart';
import 'core/logging/app_logger.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Load environment variables
  try {
    await dotenv.load(fileName: '.env');
    log.app('.env loaded successfully');
  } catch (e) {
    log.warning('Could not load .env: $e — AI features may be unavailable');
  }

  // Initialize Hive for local persistence
  await Hive.initFlutter();
  log.app('Hive initialized');

  log.app('Kamera Pro starting...');

  runApp(
    // Riverpod provider scope wraps the entire app
    const ProviderScope(
      child: KameraProApp(),
    ),
  );
}
