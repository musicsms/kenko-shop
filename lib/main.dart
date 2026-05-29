import 'package:flutter/material.dart';
import 'package:kenko_shop/app/kenko_app.dart';
import 'package:kenko_shop/config/app_config.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final config = AppConfig.fromEnvironment;
  if (config.hasSupabaseConfig) {
    await Supabase.initialize(
      url: config.supabaseUrl,
      anonKey: config.supabaseAnonKey,
    );
  }
  runApp(KenkoApp(config: config));
}
