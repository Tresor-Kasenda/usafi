import 'package:flutter/material.dart';
import 'package:projet_annuel/main.dart';
import 'package:projet_annuel/pages/auth/views/logger_page.dart';
import 'package:twilio_flutter/twilio_flutter.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

Future<void> main() async {
  await dotenv.load(fileName: ".env");
  runApp(MyApp());
}

class SmsService {
  late TwilioFlutter twilioFlutter;
  final SupabaseClient _client = Supabase.instance.client;

  SmsService() {
    if (dotenv.env['TWILIO_ACCOUNT_SID'] == null ||
        dotenv.env['TWILIO_AUTH_TOKEN'] == null ||
        dotenv.env['TWILIO_PHONE_NUMBER'] == null) {
      throw Exception('Missing Twilio credentials in .env file');
    }
    twilioFlutter = TwilioFlutter(
      accountSid: dotenv.env['TWILIO_ACCOUNT_SID']!,
      authToken: dotenv.env['TWILIO_AUTH_TOKEN']!,
      twilioNumber: dotenv.env['TWILIO_PHONE_NUMBER']!,
    );
  }

  Future<String> sendSms(String messageBody) async {
    try {
      final User? currentUser = _client.auth.currentUser;
      if (currentUser == null) {
        throw Exception('No authenticated user found');
      }

      final userData = await _client
          .from('utilisateurs')
          .select('telephone')
          .eq('id', currentUser.id)
          .single();

      var response = await twilioFlutter.sendSMS(
        toNumber: userData['telephone'],
        messageBody: messageBody,
      );
      logger.i('SMS envoyé avec succès. Statut : ${response}');
      return 'SMS envoyé avec succès. Statut : ${response}';
    } catch (e) {
      logger.e('Erreur lors de l\'envoi du SMS : $e');
      return 'Erreur lors de l\'envoi du SMS : $e';
    }
  }
}
