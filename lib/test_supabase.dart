// Test script to verify Supabase connection and permissions
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

Future<void> main() async {
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

  runApp(const SupabaseTestApp());
}

class SupabaseTestApp extends StatelessWidget {
  const SupabaseTestApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Supabase Test',
      home: const SupabaseTestPage(),
    );
  }
}

class SupabaseTestPage extends StatefulWidget {
  const SupabaseTestPage({super.key});

  @override
  State<SupabaseTestPage> createState() => _SupabaseTestPageState();
}

class _SupabaseTestPageState extends State<SupabaseTestPage> {
  final _supabase = Supabase.instance.client;
  final List<String> _logs = [];
  bool _testing = false;

  void _addLog(String message) {
    setState(() {
      _logs.add(message);
    });
    print(message);
  }

  Future<void> _runTests() async {
    setState(() {
      _testing = true;
      _logs.clear();
    });

    _addLog('🧪 Starting Supabase tests...');

    // Test 1: Read from table
    try {
      _addLog('📖 Test 1: Reading from clients table...');
      final response = await _supabase.from('clients').select();
      _addLog('✅ Read successful! Found ${(response as List).length} clients');
    } catch (e) {
      _addLog('❌ Read failed: $e');
    }

    // Test 2: Insert a test client
    try {
      _addLog('➕ Test 2: Inserting test client...');
      final testId = const Uuid().v4();
      final testClient = {
        'id': testId,
        'name': 'Test Client ${DateTime.now().millisecondsSinceEpoch}',
        'lat': 48.8566,
        'lng': 2.3522,
        'created_at': DateTime.now().toIso8601String(),
      };
      await _supabase.from('clients').insert(testClient);
      _addLog('✅ Insert successful!');

      // Test 3: Delete the test client
      _addLog('🗑️ Test 3: Deleting test client...');
      await _supabase.from('clients').delete().eq('id', testId);
      _addLog('✅ Delete successful!');
    } catch (e) {
      _addLog('❌ Insert/Delete failed: $e');
    }

    _addLog('🎉 Tests completed!');
    setState(() {
      _testing = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Supabase Connection Test'),
        backgroundColor: Colors.blue,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ElevatedButton(
              onPressed: _testing ? null : _runTests,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.all(16),
                backgroundColor: Colors.blue,
              ),
              child: _testing
                  ? const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        ),
                        SizedBox(width: 12),
                        Text('Testing...', style: TextStyle(fontSize: 18)),
                      ],
                    )
                  : const Text('Run Supabase Tests', style: TextStyle(fontSize: 18)),
            ),
            const SizedBox(height: 20),
            const Text(
              'Test Logs:',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.black87,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: _logs.isEmpty
                    ? const Center(
                        child: Text(
                          'Click "Run Supabase Tests" to start',
                          style: TextStyle(color: Colors.white70),
                        ),
                      )
                    : ListView.builder(
                        itemCount: _logs.length,
                        itemBuilder: (context, index) {
                          final log = _logs[index];
                          Color color = Colors.white;
                          if (log.contains('✅')) {
                            color = Colors.green;
                          } else if (log.contains('❌')) {
                            color = Colors.red;
                          } else if (log.contains('⚠️')) {
                            color = Colors.orange;
                          }
                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 2),
                            child: Text(
                              log,
                              style: TextStyle(
                                color: color,
                                fontFamily: 'monospace',
                                fontSize: 12,
                              ),
                            ),
                          );
                        },
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

