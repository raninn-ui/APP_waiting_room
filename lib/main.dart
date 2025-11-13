// lib/main.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'queue_provider.dart';
import 'dart:io';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // ✅ Direct Supabase credentials (no .env)
  const supabaseUrl = 'https://eaclcnzyeczqigdidsmi.supabase.co';
  const supabaseAnonKey =
      'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImVhY2xjbnp5ZWN6cWlnZGlkc21pIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTkxNjY2NzMsImV4cCI6MjA3NDc0MjY3M30.grl9aPmXZO1P_38Og4V5VXOPqAGQ_P_aTloXRgeBaMc';

  // 🔍 Optional: check if Supabase host is reachable
  try {
    final result = await InternetAddress.lookup('eaclcnzyeczqigdidsmi.supabase.co');
    print('DNS lookup success: $result');
  } catch (e) {
    print('Impossible de résoudre l’hôte: $e');
  }

  // ✅ Initialize Supabase
  await Supabase.initialize(url: supabaseUrl, anonKey: supabaseAnonKey);

  // 🔑 Anonymous sign-in
  try {
    final authResponse = await Supabase.instance.client.auth.signInAnonymously();
    if (authResponse.user == null) {
      throw Exception('Failed to sign in anonymously');
    }
    print('✅ Anonymous sign-in successful');
  } catch (e) {
    throw Exception('Auth error: $e');
  }

  runApp(
    ChangeNotifierProvider(
      create: (_) => QueueProvider()..initialize(),
      child: const WaitingRoomApp(),
    ),
  );
}

class WaitingRoomApp extends StatelessWidget {
  const WaitingRoomApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Waiting Room',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: const WaitingRoomPage(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class WaitingRoomPage extends StatefulWidget {
  const WaitingRoomPage({super.key});

  @override
  State<WaitingRoomPage> createState() => _WaitingRoomPageState();
}

class _WaitingRoomPageState extends State<WaitingRoomPage> {
  final TextEditingController _controller = TextEditingController();

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<QueueProvider>();

    return Scaffold(
      appBar: AppBar(title: const Text('Waiting Room')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // 🔹 Input row
            Row(children: [
              Expanded(
                child: TextField(
                  controller: _controller,
                  decoration: const InputDecoration(hintText: 'Enter client name'),
                  onSubmitted: (v) {
                    context.read<QueueProvider>().addClient(v);
                    _controller.clear();
                  },
                ),
              ),
              const SizedBox(width: 8),
              ElevatedButton(
                onPressed: () {
                  final name = _controller.text;
                  context.read<QueueProvider>().addClient(name);
                  _controller.clear();
                },
                child: const Text('Add'),
              ),
            ]),
            const SizedBox(height: 20),

            // 🔹 Queue list
            Expanded(
              child: provider.clients.isEmpty
                  ? const Center(child: Text('No one in queue yet...'))
                  : ListView.builder(
                itemCount: provider.clients.length,
                itemBuilder: (context, i) {
                  final client = provider.clients[i];

                  return Card(
                    margin: const EdgeInsets.symmetric(vertical: 4),
                    child: ListTile(
                      title: Text(client['name'] ?? 'Unnamed'),
                      subtitle: Text(
                        client['lat'] == null
                            ? '📍 Location not captured'
                            : '📍 ${client['lat']?.toStringAsFixed(4)}, ${client['lng']?.toStringAsFixed(4)}',
                      ),
                      trailing: IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        onPressed: () =>
                            context.read<QueueProvider>().removeClient(client['id'] as String),
                      ),
                    ),
                  );
                },
              ),
            ),

            const SizedBox(height: 12),

            // 🔹 Next client button
            ElevatedButton.icon(
              onPressed: () => context.read<QueueProvider>().nextClient(),
              icon: const Icon(Icons.arrow_forward),
              label: const Text('Next Client'),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
            ),
          ],
        ),
      ),
    );
  }
}
