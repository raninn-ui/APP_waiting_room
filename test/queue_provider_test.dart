import 'package:flutter_test/flutter_test.dart';
import 'package:waiting_room_app_workshop2/queue_provider.dart';
import 'package:waiting_room_app_workshop2/models/client.dart';

void main() {
  test('nextClient enlève le premier client de la file', () async {
    final provider = QueueProvider();

    // On simule des clients (sans passer par Supabase)
    provider.clients.addAll([
      Client(id: "1", name: "Alice", createdAt: DateTime.now()),
      Client(id: "2", name: "Bob", createdAt: DateTime.now().add(Duration(seconds: 1))),
    ]);

    expect(provider.clients.length, 2);

    // nextClient doit supprimer le premier (Alice)
    await provider.nextClient();

    expect(provider.clients.length, 1);
    expect(provider.clients.first.name, "Bob");
  });
}



