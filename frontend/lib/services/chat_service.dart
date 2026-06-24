import 'dart:convert';
import 'package:http/http.dart' as http;

class ChatMessage {
  final String role; // 'user' veya 'assistant'
  final String content;
  final DateTime timestamp;
  final Map<String, dynamic>? planData; // /plan komutu sonucu

  ChatMessage({
    required this.role,
    required this.content,
    DateTime? timestamp,
    this.planData,
  }) : timestamp = timestamp ?? DateTime.now();

  Map<String, dynamic> toJson() => {'role': role, 'content': content};
}

class ChatService {
  static const String _baseUrl = 'http://localhost:8004';
  final http.Client _client = http.Client();
  final List<ChatMessage> _history = [];

  List<ChatMessage> get history => _history;

  Future<ChatMessage> sendMessage(
    String message, {
    List<Map<String, dynamic>>? userPlans,
  }) async {
    final isPlanCommand = message.trim().toLowerCase().startsWith('/plan');

    _history.add(ChatMessage(role: 'user', content: message));

    try {
      final historyJson = _history
          .where((m) => m.role != 'user' || m.content != message)
          .map((m) => m.toJson())
          .toList();

      if (isPlanCommand) {
        return await _sendPlanCommand(message, historyJson, userPlans);
      } else {
        return await _sendChat(message, historyJson, userPlans);
      }
    } catch (e) {
      _history.removeLast();
      rethrow;
    }
  }

  Future<ChatMessage> _sendChat(
    String message,
    List<Map<String, dynamic>> historyJson,
    List<Map<String, dynamic>>? userPlans,
  ) async {
    final response = await _client.post(
      Uri.parse('$_baseUrl/chat'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'message': message,
        'history': historyJson,
        'user_plans': userPlans ?? [],
      }),
    );

    if (response.statusCode != 200) {
      throw Exception('Sunucu hatası: ${response.statusCode}');
    }

    final json = jsonDecode(response.body);
    if (json['status'] != 'success') {
      throw Exception(json['message'] ?? 'Bilinmeyen hata');
    }

    final aiMessage = ChatMessage(role: 'assistant', content: json['response'] as String);
    _history.add(aiMessage);
    return aiMessage;
  }

  Future<ChatMessage> _sendPlanCommand(
    String message,
    List<Map<String, dynamic>> historyJson,
    List<Map<String, dynamic>>? userPlans,
  ) async {
    final response = await _client.post(
      Uri.parse('$_baseUrl/plan'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'message': message,
        'history': historyJson,
        'user_plans': userPlans ?? [],
      }),
    );

    if (response.statusCode != 200) {
      throw Exception('Sunucu hatası: ${response.statusCode}');
    }

    final json = jsonDecode(response.body);

    if (json['status'] == 'error') {
      throw Exception(json['message'] ?? 'Bilinmeyen hata');
    }

    final aiMessage = ChatMessage(
      role: 'assistant',
      content: json['response'] as String,
      planData: json['status'] == 'success'
          ? Map<String, dynamic>.from(json['plan_data'] as Map)
          : null,
    );
    _history.add(aiMessage);
    return aiMessage;
  }

  void clearHistory() {
    _history.clear();
  }

  void dispose() {
    _client.close();
  }
}
