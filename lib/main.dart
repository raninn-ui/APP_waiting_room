// lib/main.dart
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'queue_provider.dart';
import 'connectivity_service.dart';
import 'room_list_screen.dart';
import 'geolocation_service.dart';

Future<void> main() async {
  // Wrap everything in error handling to prevent crashes
  try {
    WidgetsFlutterBinding.ensureInitialized();

    const supabaseUrl = 'https://eaclcnzyeczqigdidsmi.supabase.co';
    const supabaseAnonKey =
        'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImVhY2xjbnp5ZWN6cWlnZGlkc21pIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTkxNjY2NzMsImV4cCI6MjA3NDc0MjY3M30.grl9aPmXZO1P_38Og4V5VXOPqAGQ_P_aTloXRgeBaMc';

    // ---------- SAFE SUPABASE INIT ----------
    try {
      print('🔧 Initializing Supabase...');
      await Supabase.initialize(url: supabaseUrl, anonKey: supabaseAnonKey);
      print('✅ Supabase initialized successfully');
    } catch (e, st) {
      print('❌ Supabase init error: $e\n$st');
    }

    // ---------- SAFE ANONYMOUS SIGN-IN ----------
    try {
      print('🔐 Signing in anonymously...');
      await Supabase.instance.client.auth.signInAnonymously();
      print('✅ Anonymous login OK');
    } catch (e) {
      print('⚠️ Anonymous login failed: $e');
    }

    // ---------- REQUEST LOCATION PERMISSION AT STARTUP ----------
    try {
      print('📍 Requesting location permission...');
      final geoService = GeolocationService();
      await geoService.requestPermissionAtStartup();
    } catch (e) {
      print('⚠️ Location permission request failed: $e');
    }

    runApp(
      MultiProvider(
        providers: [
          // Connectivity service
          ChangeNotifierProvider(
            create: (_) => ConnectivityService(),
          ),
          // Queue provider with connectivity listener
          ChangeNotifierProxyProvider<ConnectivityService, QueueProvider>(
            create: (_) {
              print('🏗️ Creating QueueProvider...');
              final provider = QueueProvider();
              provider.initialize().catchError((e) {
                print('⚠️ QueueProvider initialization error: $e');
              });
              return provider;
            },
            update: (context, connectivityService, queueProvider) {
              // Listen for connectivity changes
              if (queueProvider != null && connectivityService.isOnline) {
                // Trigger sync when coming back online
                queueProvider.onConnectivityRestored().catchError((e) {
                  print('⚠️ Sync error: $e');
                });
              }
              return queueProvider!;
            },
          ),
        ],
        child: const WaitingRoomApp(),
      ),
    );
  } catch (e, stackTrace) {
    print('❌ CRITICAL ERROR in main(): $e');
    print('Stack trace: $stackTrace');
    // Still try to run the app with a basic error screen
    runApp(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error, size: 64, color: Colors.red),
                  const SizedBox(height: 16),
                  const Text(
                    'App Initialization Error',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    e.toString(),
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 14),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class WaitingRoomApp extends StatelessWidget {
  const WaitingRoomApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Waiting Room',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: const RoomListScreen(), // Start with room selection (Part 3 of workshop)
      debugShowCheckedModeBanner: false,
    );
  }
}

class WaitingRoomPage extends StatefulWidget {
  final String? roomId;
  final String? roomName;

  const WaitingRoomPage({super.key, this.roomId, this.roomName});

  @override
  State<WaitingRoomPage> createState() => _WaitingRoomPageState();
}

class _WaitingRoomPageState extends State<WaitingRoomPage> {
  final TextEditingController _controller = TextEditingController();

  @override
  void initState() {
    super.initState();
    // Subscribe to the specific room if roomId is provided
    if (widget.roomId != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        await context.read<QueueProvider>().subscribeToRoom(widget.roomId!);
      });
    }
  }

  String _formatDateTime(String? isoString) {
    if (isoString == null) return '';
    try {
      final dateTime = DateTime.parse(isoString);
      final now = DateTime.now();
      final difference = now.difference(dateTime);

      if (difference.inMinutes < 1) {
        return 'just now';
      } else if (difference.inMinutes < 60) {
        return '${difference.inMinutes}m ago';
      } else if (difference.inHours < 24) {
        return '${difference.inHours}h ago';
      } else {
        return '${difference.inDays}d ago';
      }
    } catch (e) {
      return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<QueueProvider>();
    final connectivityService = context.watch<ConnectivityService>();

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.roomName ?? 'Waiting Room'),
      ),
      body: Column(
        children: [
          // Offline Banner
          if (!connectivityService.isOnline)
            Container(
              padding: const EdgeInsets.all(8),
              color: Colors.red[800],
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.cloud_off, color: Colors.white, size: 16),
                  SizedBox(width: 8),
                  Text(
                    'Offline Mode - Data will sync when connected.',
                    style: TextStyle(color: Colors.white),
                  ),
                ],
              ),
            ),
          // Main content
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Row(children: [
              Expanded(
                child: TextField(
                  controller: _controller,
                  decoration: const InputDecoration(hintText: 'Enter client name'),
                  onSubmitted: (v) async {
                    // Only use chosen room when offline
                    final roomName = await provider.addClient(
                      v,
                      chosenRoomId: connectivityService.isOnline ? null : widget.roomId,
                    );
                    _controller.clear();
                    if (roomName != null && mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('✅ Client ajouté dans $roomName!'),
                          backgroundColor: Colors.green,
                          duration: const Duration(seconds: 2),
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    }
                  },
                ),
              ),
              const SizedBox(width: 8),
              ElevatedButton(
                onPressed: () async {
                  // Only use chosen room when offline
                  final roomName = await provider.addClient(
                    _controller.text,
                    chosenRoomId: connectivityService.isOnline ? null : widget.roomId,
                  );
                  _controller.clear();
                  if (roomName != null && mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('✅ Client ajouté dans $roomName!'),
                        backgroundColor: Colors.green,
                        duration: const Duration(seconds: 2),
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  }
                },
                child: const Text('Add'),
              ),
            ]),
            const SizedBox(height: 20),

            Expanded(
              child: provider.clients.isEmpty
                  ? const Center(child: Text('No one in queue yet...'))
                  : ListView.builder(
                itemCount: provider.clients.length,
                itemBuilder: (context, i) {
                  final client = provider.clients[i];

                  final roomName = provider.getRoomName(client['waiting_room_id']);
                  final status = client['status'] ?? 'waiting';

                  // Determine status color and icon
                  Color statusColor;
                  IconData statusIcon;
                  String statusText;

                  switch (status) {
                    case 'called':
                      statusColor = Colors.orange;
                      statusIcon = Icons.phone_in_talk;
                      statusText = 'Called';
                      break;
                    case 'served':
                      statusColor = Colors.green;
                      statusIcon = Icons.check_circle;
                      statusText = 'Served';
                      break;
                    case 'no-show':
                      statusColor = Colors.red;
                      statusIcon = Icons.cancel;
                      statusText = 'No-show';
                      break;
                    default: // 'waiting'
                      statusColor = Colors.blue;
                      statusIcon = Icons.hourglass_empty;
                      statusText = 'Waiting';
                  }

                  return Card(
                    margin: const EdgeInsets.symmetric(vertical: 4),
                    child: ListTile(
                      leading: Icon(statusIcon, color: statusColor),
                      title: Row(
                        children: [
                          Expanded(child: Text(client['name'] ?? 'Unnamed')),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: statusColor.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: statusColor),
                            ),
                            child: Text(
                              statusText,
                              style: TextStyle(
                                color: statusColor,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '🏢 $roomName',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.green,
                            ),
                          ),
                          Text(
                            client['lat'] == null
                                ? '📍 Location not captured'
                                : '📍 ${client['lat']}, ${client['lng']}',
                          ),
                          if (client['called_at'] != null)
                            Text(
                              '📞 Called: ${_formatDateTime(client['called_at'])}',
                              style: const TextStyle(fontSize: 11, color: Colors.grey),
                            ),
                        ],
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (status == 'called')
                            IconButton(
                              icon: const Icon(Icons.check, color: Colors.green),
                              tooltip: 'Mark as Served',
                              onPressed: () => provider.markClientAsServed(client['id']),
                            ),
                          if (status == 'called')
                            IconButton(
                              icon: const Icon(Icons.cancel, color: Colors.orange),
                              tooltip: 'Mark as No-show',
                              onPressed: () => provider.markClientAsNoShow(client['id']),
                            ),
                          IconButton(
                            icon: const Icon(Icons.delete, color: Colors.red),
                            onPressed: () => provider.removeClient(client['id']),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),

            const SizedBox(height: 12),

                  ElevatedButton.icon(
                    onPressed: () async {
                      // Call the next waiting client
                      await provider.callNextClient();

                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('📞 Next client has been called!'),
                            backgroundColor: Colors.orange,
                            duration: Duration(seconds: 2),
                          ),
                        );
                      }
                    },
                    icon: const Icon(Icons.phone_in_talk),
                    label: const Text('Call Next Client'),
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
