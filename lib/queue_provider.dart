import 'dart:async';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'models/client.dart';

class QueueProvider extends ChangeNotifier {
  final List<Client> _clients = [];
  List<Client> get clients => List.unmodifiable(_clients);

  QueueProvider({List<Client>? initialClients}) {
    if (initialClients != null) {
      _clients.addAll(initialClients);
    }
    // Optionnel : on peut lancer Supabase seulement si initialClients == null
    if (initialClients == null) {
      _fetchInitialClients();
      _setupRealtimeSubscription();
    }
  }
  final SupabaseClient _supabase = Supabase.instance.client;
  late RealtimeChannel _channel;

  /// 🔹 Constructeur normal


  /// Récupère les clients existants au démarrage
  Future<void> _fetchInitialClients() async {
    try {
      final response =
      await _supabase.from('clients').select().order('created_at');

      final data = response as List<dynamic>;
      _clients
        ..clear()
        ..addAll(
          data.map((e) => Client.fromMap(Map<String, dynamic>.from(e))),
        );
      _clients.sort((a, b) => a.createdAt.compareTo(b.createdAt));
      notifyListeners();
    } catch (e) {
      debugPrint('Exception fetching clients: $e');
    }
  }

  /// Abonnement en temps réel aux changements dans la table `clients`
  void _setupRealtimeSubscription() {
    _channel = _supabase.channel('public:clients');

    // Insertions
    _channel.onPostgresChanges(
      event: PostgresChangeEvent.insert,
      schema: 'public',
      table: 'clients',
      callback: (payload) {
        final newRecord = payload.newRecord;
        if (newRecord.isNotEmpty) {
          final client =
          Client.fromMap(Map<String, dynamic>.from(newRecord));
          _clients.add(client);
          _clients.sort((a, b) => a.createdAt.compareTo(b.createdAt));
          notifyListeners();
        }
      },
    );

    // Suppressions
    _channel.onPostgresChanges(
      event: PostgresChangeEvent.delete,
      schema: 'public',
      table: 'clients',
      callback: (payload) {
        final oldRecord = payload.oldRecord;
        if (oldRecord.isNotEmpty) {
          final deletedId = oldRecord['id'] as String?;
          if (deletedId != null) {
            _clients.removeWhere((c) => c.id == deletedId);
            notifyListeners();
          }
        }
      },
    );

    _channel.subscribe();
  }

  /// Ajout d’un client
  Future<void> addClient(String name) async {
    final trimmed = name.trim();
    if (trimmed.isEmpty) return;
    try {
      await _supabase.from('clients').insert({'name': trimmed});
    } catch (e) {
      debugPrint('Failed to add client: $e');
    }
  }

  /// Suppression d’un client
  Future<void> removeClient(String id) async {
    try {
      await _supabase.from('clients').delete().match({'id': id});
    } catch (e) {
      debugPrint('Failed to remove client: $e');
    }
  }

  /// Passe au prochain client
  Future<void> nextClient() async {
    if (_clients.isEmpty) return;
    final first = _clients.first;
    await removeClient(first.id);
  }

  @override
  void dispose() {
    try {
      _channel.unsubscribe();
    } catch (_) {}
    super.dispose();
  }
}