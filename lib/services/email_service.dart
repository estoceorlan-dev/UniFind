import 'dart:convert';

import 'package:http/http.dart' as http;

class EmailService {
  static const String _apiKey = String.fromEnvironment('SENDGRID_API_KEY');
  static const String _sender = String.fromEnvironment(
    'SENDGRID_SENDER_EMAIL',
    defaultValue: 'aunifind@gmail.com',
  );

  Future<void> sendResetEmail(String toEmail, String htmlContent) async {
    if (_apiKey.isEmpty) {
      throw StateError(
        'Missing SENDGRID_API_KEY. Run with --dart-define=SENDGRID_API_KEY=...',
      );
    }

    final response = await http.post(
      Uri.parse('https://api.sendgrid.com/v3/mail/send'),
      headers: {
        'Authorization': 'Bearer $_apiKey',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'personalizations': [
          {
            'to': [
              {'email': toEmail}
            ],
            'subject': 'Password Reset Code',
          }
        ],
        'from': {'email': _sender},
        'content': [
          {'type': 'text/html', 'value': htmlContent}
        ],
      }),
    );

    if (response.statusCode != 202) {
      throw Exception('Failed to send email: ${response.body}');
    }
  }
}
