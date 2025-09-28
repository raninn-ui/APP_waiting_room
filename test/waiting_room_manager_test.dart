// test/waiting_room_manager_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:waiting_room_app_workshop2/queue_provider.dart';

void main() {
  test('should add a client to the waiting list', () {
// ARRANGE: Set up the necessary objects and variables.
    final manager = QueueProvider();
// ACT: Call the method you want to test.
    manager.addClient('John Doe');
// ASSERT: Verify that the result is what you expect.
    expect(manager.clients.length, 1);
    expect(manager.clients.first, 'John Doe');
  });

  test('should remove a client from the waiting list', () {
// ARRANGE
    final manager = QueueProvider();
    manager.addClient('John Doe');
    manager.addClient('Jane Doe');
// ACT
    manager.removeClient('John Doe');
// ASSERT
    expect(manager.clients.length, 1);
    expect(manager.clients.first, 'Jane Doe');
  });

  test('should remove the first client when nextClient() is called', () {
// ARRANGE
    final manager = QueueProvider();
    manager.addClient('Client A');
    manager.addClient('Client B');
// ACT
    manager.nextClient();
// ASSERT
    expect(manager.clients.length, 1);
    expect(manager.clients.first, 'Client B');
  });
}