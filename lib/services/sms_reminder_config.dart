import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class SmsReminderService {
  final SupabaseClient _client = Supabase.instance.client;

  Future<void> sendAwarenessReminders() async {
    final accountSid = dotenv.env['TWILIO_ACCOUNT_SID'];
    final authToken = dotenv.env['TWILIO_AUTH_TOKEN'];
    final fromNumber = dotenv.env['TWILIO_PHONE_NUMBER'];

    if (accountSid == null || authToken == null || fromNumber == null) {
      throw StateError('Twilio configuration missing');
    }

    final users = await _client.from('utilisateurs').select('telephone');
    final auth = base64Encode(utf8.encode('$accountSid:$authToken'));

    for (final row in users) {
      final to = row['telephone'];
      if (to == null || to.toString().isEmpty) continue;
      final uri = Uri.https(
        'api.twilio.com',
        '/2010-04-01/Accounts/$accountSid/Messages.json',
      );
      await http.post(
        uri,
        headers: {'Authorization': 'Basic $auth'},
        body: {'From': fromNumber, 'To': to.toString(), 'Body': _messageBody},
      );
    }
  }

  String get _messageBody =>
      'Bonjour, ceci est un rappel de sensibilisation à la gestion des déchets.';
}
