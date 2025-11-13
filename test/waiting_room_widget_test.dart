// test/waiting_room_widget_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:provider/provider.dart';
import 'package:workshop5/main.dart'; // contains WaitingRoomPage
import 'package:mockito/annotations.dart';
import 'package:workshop5/queue_provider.dart';

import 'waiting_room_widget_test.mocks.dart';

@GenerateMocks([QueueProvider])
void main() {
  testWidgets('Displays location when available', (tester) async {
    // 1️⃣ Create the mock provider
    final provider = MockQueueProvider();

    // 2️⃣ Mock clients list
    when(provider.clients).thenReturn([
      {
        'id': '1',
        'name': 'Sam',
        'lat': 51.5074,
        'lng': -0.1278,
        'created_at': DateTime.now().toIso8601String(),
      }
    ]);

    // 3️⃣ Pump the widget (use WaitingRoomPage)
    await tester.pumpWidget(
      ChangeNotifierProvider<QueueProvider>.value(
        value: provider,
        child: const MaterialApp(home: WaitingRoomPage()),
      ),
    );

    // 4️⃣ Verify client name is displayed
    expect(find.text('Sam'), findsOneWidget);

    // 5️⃣ Verify the location is displayed
    expect(find.textContaining('51.5074'), findsOneWidget);
    expect(find.textContaining('-0.1278'), findsOneWidget);
  });
}
