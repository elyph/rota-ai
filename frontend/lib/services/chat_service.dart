import 'dart:convert';
import 'package:http/http.dart' as http;

class ChatMessage {
  final String role; // 'user' veya 'assistant'
  final String content;
  final DateTime timestamp;

  ChatMessage({required this.role, required this.content, DateTime? timestamp})
      : timestamp = timestamp ?? DateTime.now();

  Map<String, dynamic> toJson() => {'role': role, 'content': content};
}

class ChatService {
  static const String _baseUrl = 'http://localhost:8004';
  final http.Client _client = http.Client();
  final List<ChatMessage> _history = [];

  List<ChatMessage> get history => _history;

  Future<String> sendMessage(String message, {List<Map<String, dynamic>>? userPlans}) async {
    // Kullanıcı mesajını geçmişe ekle
    _history.add(ChatMessage(role: 'user', content: message));

    try {
      final response = await _client.post(
        Uri.parse('$_baseUrl/chat'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'message': message,
          'history': _history.map((m) => m.toJson()).toList(),
          'user_plans': userPlans ?? [],
        }),
      );

      if (response.statusCode != 200) {
        throw Exception('Sunucu hatası: ${response.statusCode}');
      }

      final jsonResponse = jsonDecode(response.body);

      if (jsonResponse['status'] != 'success') {
        throw Exception(jsonResponse['message'] ?? 'Bilinmeyen hata');
      }

      final aiResponse = jsonResponse['response'] as String;

      // AI yanıtını geçmişe ekle
      _history.add(ChatMessage(role: 'assistant', content: aiResponse));

      return aiResponse;
    } catch (e) {
      _history.removeLast(); // Başarısız mesajı kaldır
      rethrow;
    }
  }

  void clearHistory() {
    _history.clear();
  }

  void dispose() {
    _client.close();
  }
}
