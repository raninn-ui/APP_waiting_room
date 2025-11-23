// lib/room_list_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'queue_provider.dart';
import 'main.dart';

class RoomListScreen extends StatefulWidget {
  const RoomListScreen({super.key});

  @override
  State<RoomListScreen> createState() => _RoomListScreenState();
}

class _RoomListScreenState extends State<RoomListScreen> {
  @override
  void initState() {
    super.initState();
    // Fetch rooms when screen loads
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<QueueProvider>().fetchWaitingRooms();
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<QueueProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Select Waiting Room'),
        centerTitle: true,
      ),
      body: provider.rooms.isEmpty
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Loading waiting rooms...'),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16.0),
              itemCount: provider.rooms.length,
              itemBuilder: (context, index) {
                final room = provider.rooms[index];
                return _buildRoomCard(context, room);
              },
            ),
    );
  }

  Widget _buildRoomCard(BuildContext context, Map<String, dynamic> room) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      child: ListTile(
        leading: Icon(
          Icons.local_hospital,
          size: 40,
          color: Theme.of(context).primaryColor,
        ),
        title: Text(
          room['name'] as String,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        subtitle: Text(
          'Lat: ${(room['latitude'] as double).toStringAsFixed(4)}, Lng: ${(room['longitude'] as double).toStringAsFixed(4)}',
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
          ),
        ),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => WaitingRoomPage(
                roomId: room['id'] as String,
                roomName: room['name'] as String,
              ),
            ),
          );
        },
      ),
    );
  }
}

