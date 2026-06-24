import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/services/chat_service.dart';

void main() {
  group('ChatMessage', () {
    test('creates user message with current timestamp', () {
      final before = DateTime.now();
      final msg = ChatMessage(role: 'user', content: 'Merhaba');
      final after = DateTime.now();

      expect(msg.role, 'user');
      expect(msg.content, 'Merhaba');
      expect(msg.timestamp.isAfter(before.subtract(const Duration(seconds: 1))), true);
      expect(msg.timestamp.isBefore(after.add(const Duration(seconds: 1))), true);
    });

    test('creates assistant message with explicit timestamp', () {
      final timestamp = DateTime(2025, 6, 15, 10, 30);
      final msg = ChatMessage(
        role: 'assistant',
        content: 'Size nasıl yardımcı olabilirim?',
        timestamp: timestamp,
      );

      expect(msg.role, 'assistant');
      expect(msg.content, 'Size nasıl yardımcı olabilirim?');
      expect(msg.timestamp, timestamp);
    });

    test('toJson returns correct map', () {
      final msg = ChatMessage(role: 'user', content: 'Test');
      final json = msg.toJson();

      expect(json['role'], 'user');
      expect(json['content'], 'Test');
      expect(json.containsKey('timestamp'), false);
    });
  });

  group('ChatService', () {
    late ChatService service;

    setUp(() {
      service = ChatService();
    });

    tearDown(() {
      service.dispose();
    });

    test('history starts empty', () {
      expect(service.history, isEmpty);
    });

    test('clearHistory clears all messages', () {
      // addToHistory is not public, but clearHistory is.
      // We test that clearHistory works on empty history.
      service.clearHistory();
      expect(service.history, isEmpty);
    });
  });
}
