// test/waiting_room_widget_test.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:waiting_room_app_workshop2/queue_provider.dart';
import 'package:waiting_room_app_workshop2/main.dart';
void main() {
  testWidgets('should add a new client to the list on button tap', (WidgetTester tester)
  async {
    // ARRANGE
    await tester.pumpWidget(
      ChangeNotifierProvider(
        create: (context) => QueueProvider(),
        child: const WaitingRoomApp(),
      ),
    );

// ACT
    await tester.enterText(find.byType(TextField), 'Alice');
    await tester.tap(find.byType(ElevatedButton));
    await tester.pump(); // Rebuild the widget after state change
// ASSERT
    expect(find.text('Alice'), findsOneWidget);
    expect(find.text('Clients in Queue: 1'), findsOneWidget);
  });

  testWidgets('should remove a client from the list when the delete button is tapped',
          (WidgetTester tester) async {
            await tester.pumpWidget(
              ChangeNotifierProvider(
                create: (context) => QueueProvider(),
                child: const WaitingRoomApp(),
              ),
            );
// ARRANGE
        await tester.enterText(find.byType(TextField), 'Bob');
        await tester.tap(find.byType(ElevatedButton));
        await tester.pump();
// ACT
// Find the delete icon associated with 'Bob' and tap it.
        await tester.tap(find.byIcon(Icons.delete));
        await tester.pump();
// ASSERT
        expect(find.text('Bob'), findsNothing);
        expect(find.text('Clients in Queue: 0'), findsOneWidget);
      });

  testWidgets('should remove the first client from the list when "Next Client" is tapped', (WidgetTester
  tester) async {
// ARRANGE
// We need to provide the QueueProvider to our widget tree for the test.
    await tester.pumpWidget(
        ChangeNotifierProvider(
          create: (context) => QueueProvider(),
    child: const WaitingRoomApp(),
    ),
    );
// Add two clients to the list first
    await tester.enterText(find.byType(TextField), 'Client A');
    await tester.tap(find.byType(ElevatedButton));
    await tester.pump();
    await tester.enterText(find.byType(TextField), 'Client B');
    await tester.tap(find.byType(ElevatedButton));
    await tester.pump();
// ACT
    await tester.tap(find.byKey(const Key('nextClientButton'))); // Find and tap the new button
    await tester.pump();
// ASSERT
    expect(find.text('Client A'), findsNothing);
    expect(find.text('Client B'), findsOneWidget);
    expect(find.text('Clients in Queue: 1'), findsOneWidget);
  });
}