import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'dart:math';

class GeminiService {
  // TODO: Move this to a secure configuration file
  static const String apiKey = 'AIzaSyBH20wtLZLMRINuhlPoZNY4QOHjgP43Fls';
  static const String baseUrl = 'https://generativelanguage.googleapis.com/v1/models/gemini-pro:generateContent';

  // Temporary mock quotes for testing
  static final List<String> _mockQuotes = [
    "Success is not final, failure is not fatal: it is the courage to continue that counts.",
    "The only way to do great work is to love what you do.",
    "Believe you can and you're halfway there.",
    "The future belongs to those who believe in the beauty of their dreams.",
    "Everything you've ever wanted is on the other side of fear."
  ];

  static Future<String> fetchQuote(String query) async {
    try {
      // For testing UI, return a mock quote
      final random = Random();
      return _mockQuotes[random.nextInt(_mockQuotes.length)];

      /* Commented out API call for now
      final client = http.Client();
      try {
        print('Starting API request...');
        final Uri uri = Uri.parse('$baseUrl?key=$apiKey');
        
        final request = http.Request('POST', uri);
        request.headers['Content-Type'] = 'application/json';
        request.body = jsonEncode({
          "contents": [{
            "parts": [{
              "text": "Create an inspiring quote about $query. Keep it short and meaningful."
            }]
          }]
        });

        print('Sending request...');
        final streamedResponse = await client.send(request).timeout(
          const Duration(seconds: 30),
          onTimeout: () {
            print('Request timed out after 30 seconds');
            throw TimeoutException('Request timed out');
          },
        );

        final response = await http.Response.fromStream(streamedResponse);
        
        print('Response received:');
        print('Status code: ${response.statusCode}');
        print('Headers: ${response.headers}');
        print('Body: ${response.body}');

        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);
          if (data != null && 
              data["candidates"] != null && 
              data["candidates"].isNotEmpty &&
              data["candidates"][0]["content"] != null &&
              data["candidates"][0]["content"]["parts"] != null &&
              data["candidates"][0]["content"]["parts"].isNotEmpty) {
            String quote = data["candidates"][0]["content"]["parts"][0]["text"].toString().trim();
            if (quote.isEmpty) {
              return "Could not generate a quote. Please try again.";
            }
            return quote;
          }
        }
        return "Could not generate a quote at this time.";
      } finally {
        client.close();
      }
      */
    } catch (e) {
      print("Error: $e");
      return "An error occurred. Please try again.";
    }
  }
}
