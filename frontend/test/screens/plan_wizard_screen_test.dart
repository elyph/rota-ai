import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/screens/plan_wizard_screen.dart';

/// shared_preferences platform kanalını mock'lar (Supabase'in ihtiyacı var).
void _mockSharedPreferences() {
  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      .setMockMethodCallHandler(
    const MethodChannel('plugins.flutter.io/shared_preferences'),
    (MethodCall methodCall) async {
      if (methodCall.method == 'getAll') return <String, Object>{};
      return null;
    },
  );
}

Widget _buildTestApp() {
  return const MaterialApp(home: PlanWizardScreen());
}

void main() {
  setUpAll(() {
    _mockSharedPreferences();
  });

  tearDownAll(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      const MethodChannel('plugins.flutter.io/shared_preferences'),
      null,
    );
  });

  group('PlanWizardScreen — adım 0 (Uçuş Bilgileri)', () {
    testWidgets('AppBar başlığı Uçuş Bilgileri gösterir', (tester) async {
      await tester.pumpWidget(_buildTestApp());
      await tester.pump();

      expect(find.text('Uçuş Bilgileri'), findsOneWidget);
    });

    testWidgets('Kalkış ve Varış dropdown etiketleri görünür', (tester) async {
      await tester.pumpWidget(_buildTestApp());
      await tester.pump();

      expect(find.text('Kalkış'), findsOneWidget);
      expect(find.text('Varış'), findsOneWidget);
    });

    testWidgets('Gidiş tarih butonu etiketi görünür', (tester) async {
      await tester.pumpWidget(_buildTestApp());
      await tester.pump();

      expect(find.text('Gidiş'), findsOneWidget);
    });

    testWidgets('Dönüş opsiyonel tarih etiketi görünür', (tester) async {
      await tester.pumpWidget(_buildTestApp());
      await tester.pump();

      expect(find.text('Dönüş (opsiyonel)'), findsOneWidget);
    });

    testWidgets('Bütçe TextField görünür', (tester) async {
      await tester.pumpWidget(_buildTestApp());
      await tester.pump();

      expect(find.widgetWithText(TextField, ''), findsWidgets);
      // labelText'i hint olarak ara
      expect(find.text('Bütçe (opsiyonel)'), findsOneWidget);
    });

    testWidgets('Uçuşları Ara butonu görünür', (tester) async {
      await tester.pumpWidget(_buildTestApp());
      await tester.pump();

      expect(find.text('Uçuşları Ara'), findsOneWidget);
    });

    testWidgets('eksik bilgiyle Uçuşları Ara tıklanınca snackbar gösterilir', (tester) async {
      await tester.pumpWidget(_buildTestApp());
      await tester.pump();

      await tester.tap(find.text('Uçuşları Ara'));
      await tester.pump();

      expect(find.text('Kalkış, varış ve gidiş tarihi seçin!'), findsOneWidget);
    });

    testWidgets('AppBar ortalanmış başlık içerir', (tester) async {
      await tester.pumpWidget(_buildTestApp());
      await tester.pump();

      final appBar = tester.widget<AppBar>(find.byType(AppBar));
      expect(appBar.centerTitle, true);
    });

    testWidgets('ekranın arka plan rengi doğru', (tester) async {
      await tester.pumpWidget(_buildTestApp());
      await tester.pump();

      final scaffold = tester.widget<Scaffold>(find.byType(Scaffold).first);
      expect(scaffold.backgroundColor, const Color(0xFFF8FAFC));
    });
  });

  group('PlanWizardScreen — geri navigasyonu', () {
    testWidgets('root route\'da AppBar leading gizlenir', (tester) async {
      // canPop false olduğunda AppBar'da leading (back arrow) gösterilmez
      await tester.pumpWidget(_buildTestApp());
      await tester.pump();

      final appBar = tester.widget<AppBar>(find.byType(AppBar));
      // leading null veya widget olmayan bir şey olmalı
      // (kod: Navigator.canPop false iken leading: null)
      expect(appBar.leading, isNull);
    });
  });

  group('PlanWizardScreen — bütçe alanı', () {
    testWidgets('bütçe alanına rakam girilince state güncellenir', (tester) async {
      await tester.pumpWidget(_buildTestApp());
      await tester.pump();

      // suffixText '₺' görünür olmalı
      expect(find.text('₺'), findsOneWidget);

      await tester.enterText(find.byType(TextField).last, '15000');
      await tester.pump();

      expect(find.text('15000'), findsOneWidget);
    });
  });
}
