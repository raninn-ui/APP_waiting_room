// Simplified version without location services
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

Future<void> main() async {
  try {
    WidgetsFlutterBinding.ensureInitialized();

    const supabaseUrl = 'https://eaclcnzyeczqigdidsmi.supabase.co';
    const supabaseAnonKey =
        'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImVhY2xjbnp5ZWN6cWlnZGlkc21pIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTkxNjY2NzMsImV4cCI6MjA3NDc0MjY3M30.grl9aPmXZO1P_38Og4V5VXOPqAGQ_P_aTloXRgeBaMc';

    print('🔧 Initializing Supabase...');
    await Supabase.initialize(url: supabaseUrl, anonKey: supabaseAnonKey);
    print('✅ Supabase initialized');

    print('🔐 Signing in anonymously...');
    await Supabase.instance.client.auth.signInAnonymously();
    print('✅ Signed in');

    runApp(
      ChangeNotifierProvider(
        create: (_) => SimpleQueueProvider(),
        child: const SimpleWaitingRoomApp(),
      ),
    );
  } catch (e, stackTrace) {
    print('❌ Error in main: $e');
    print('Stack: $stackTrace');
    runApp(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: Text('Error: $e'),
          ),
        ),
      ),
    );
  }
}

class SimpleQueueProvider extends ChangeNotifier {
  final List<Map<String, dynamic>> _clients = [];
  List<Map<String, dynamic>> get clients => _clients;

  final _supabase = Supabase.instance.client;

  SimpleQueueProvider() {
    _loadClients();
  }

  Future<void> _loadClients() async {
    try {
      print('📥 Loading clients...');
      final response = await _supabase.from('clients').select().order('created_at');
      _clients.clear();
      _clients.addAll((response as List).cast<Map<String, dynamic>>());
      print('✅ Loaded ${_clients.length} clients');
      notifyListeners();
    } catch (e) {
      print('⚠️ Error loading clients: $e');
    }
  }

  Future<void> addClient(String name) async {
    if (name.trim().isEmpty) return;

    final newClient = {
      'id': const Uuid().v4(),
      'name': name.trim(),
      'created_at': DateTime.now().toIso8601String(),
    };

    try {
      print('➕ Adding client: $name');
      await _supabase.from('clients').insert(newClient);
      _clients.add(newClient);
      notifyListeners();
      print('✅ Client added');
    } catch (e) {
      print('❌ Error adding client: $e');
    }
  }

  Future<void> removeClient(String id) async {
    try {
      await _supabase.from('clients').delete().eq('id', id);
      _clients.removeWhere((c) => c['id'] == id);
      notifyListeners();
    } catch (e) {
      print('❌ Error removing client: $e');
    }
  }
}

class SimpleWaitingRoomApp extends StatelessWidget {
  const SimpleWaitingRoomApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Waiting Room (Simple)',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: const SimpleWaitingRoomPage(),
    );
  }
}

class SimpleWaitingRoomPage extends StatefulWidget {
  const SimpleWaitingRoomPage({super.key});

  @override
  State<SimpleWaitingRoomPage> createState() => _SimpleWaitingRoomPageState();
}

class _SimpleWaitingRoomPageState extends State<SimpleWaitingRoomPage> {
  final TextEditingController _controller = TextEditingController();

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<SimpleQueueProvider>();

    return Scaffold(
      appBar: AppBar(title: const Text('Waiting Room (Simple)')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    decoration: const InputDecoration(hintText: 'Enter name'),
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: () {
                    provider.addClient(_controller.text);
                    _controller.clear();
                  },
                  child: const Text('Add'),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Expanded(
              child: provider.clients.isEmpty
                  ? const Center(child: Text('No clients'))
                  : ListView.builder(
                      itemCount: provider.clients.length,
                      itemBuilder: (context, i) {
                        final client = provider.clients[i];
                        return ListTile(
                          title: Text(client['name'] ?? 'Unknown'),
                          trailing: IconButton(
                            icon: const Icon(Icons.delete),
                            onPressed: () => provider.removeClient(client['id']),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

