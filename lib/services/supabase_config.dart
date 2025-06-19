import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

Future<void> initSupabase() async {
  await dotenv.load();
  final url = dotenv.env['SUPABASE_URL'];
  final anonKey = dotenv.env['SUPABASE_ANON_KEY'];
  if (url == null || anonKey == null) {
    throw StateError(
      'Supabase configuration missing. Vérifiez le fichier .env',
    );
  }
  await Supabase.initialize(url: url, anonKey: anonKey);
}
