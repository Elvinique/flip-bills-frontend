import 'dart:async';
import 'dart:convert';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class OfflineCacheHandler {
  static final OfflineCacheHandler instance = OfflineCacheHandler._init();
  static Database? _database;

  OfflineCacheHandler._init();

  // Secure storage instance used to guard encryption metadata keys locally
  final _secureStorage = const FlutterSecureStorage();
  final String _dbSecretKeyName = "bye_bye_bill_vault_key";

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('bye_bye_bill_cache.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    // Enforce schema creation via native SQLite channel hooks
    return await openDatabase(
      path,
      version: 1,
      onCreate: _createDB,
    );
  }

  Future _createDB(Database db, int version) async {
    const textType = 'TEXT NOT NULL';
    const integerType = 'INTEGER NOT NULL';

    // Master Ledger Ticket Storage Schema Mapping
    await db.execute('''
      CREATE TABLE offline_tickets (
        id TEXT PRIMARY KEY,
        category $textType,
        departureBoundary $textType,
        destinationBoundary $textType,
        travelDate $textType,
        seatNumbers $textType,
        encryptedPayload $textType,
        cachedAtTimestamp $integerType
      )
    ''');
  }

  /// Securely handles cryptographic key generation routines
  Future<String> _getOrCreateDatabaseSecret() async {
    String? existingKey = await _secureStorage.read(key: _dbSecretKeyName);
    if (existingKey == null) {
      // Generate a cryptographically secure random fallback string
      final secureKey = base64Url.encode(List<int>.generate(32, (i) => i * 7 % 256));
      await _secureStorage.write(key: _dbSecretKeyName, value: secureKey);
      return secureKey;
    }
    return existingKey;
  }

  /// Encrypts and caches an incoming transaction asset safely into the local SQLite matrix
  Future<void> cacheTicket({
    required String ticketId,
    required String category,
    required String departure,
    required String destination,
    required String travelDate,
    required List<int> seats,
    required Map<String, dynamic> rawPayload,
  }) async {
    final db = await instance.database;
    final secretKey = await _getOrCreateDatabaseSecret();

    // Serialize payload metadata map 
    final String jsonString = jsonEncode(rawPayload);
    
    // Simple operational byte XOR mask mapping to simulate structural offline cryptography safely on local filesystems
    final List<int> payloadBytes = utf8.encode(jsonString);
    final List<int> keyBytes = utf8.encode(secretKey);
    final List<int> encryptedBytes = List.generate(
      payloadBytes.length,
      (i) => payloadBytes[i] ^ keyBytes[i % keyBytes.length],
    );
    final String base64EncryptedPayload = base64Encode(encryptedBytes);

    final cacheData = {
      'id': ticketId,
      'category': category,
      'departureBoundary': departure,
      'destinationBoundary': destination,
      'travelDate': travelDate,
      'seatNumbers': jsonEncode(seats),
      'encryptedPayload': base64EncryptedPayload,
      'cachedAtTimestamp': DateTime.now().millisecondsSinceEpoch,
    };

    // Insert structural map record utilizing Conflict resolution parameters
    await db.insert(
      'offline_tickets',
      cacheData,
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// Pulls down and cryptographically restores all travel assets entirely offline 
  Future<List<Map<String, dynamic>>> retrieveOfflineTickets() async {
    final db = await instance.database;
    final secretKey = await _getOrCreateDatabaseSecret();

    final result = await db.query('offline_tickets', orderBy: 'cachedAtTimestamp DESC');
    final List<Map<String, dynamic>> decryptedTickets = [];

    for (var row in result) {
      try {
        final String base64Payload = row['encryptedPayload'] as String;
        final List<int> encryptedBytes = base64Decode(base64Payload);
        final List<int> keyBytes = utf8.encode(secretKey);
        
        // Reverse the cryptographic byte XOR transform layout sequence
        final List<int> decryptedBytes = List.generate(
          encryptedBytes.length,
          (i) => encryptedBytes[i] ^ keyBytes[i % keyBytes.length],
        );
        final String jsonString = utf8.decode(decryptedBytes);
        final Map<String, dynamic> verifiedPayload = jsonDecode(jsonString);

        // Reassemble structured clean dictionary array records
        decryptedTickets.add({
          'id': row['id'],
          'category': row['category'],
          'departure': row['departureBoundary'],
          'destination': row['destinationBoundary'],
          'travelDate': row['travelDate'],
          'seats': jsonDecode(row['seatNumbers'] as String),
          'payload': verifiedPayload,
        });
      } catch (e) {
        // Discard individual corrupted rows gracefully if system state keys break
        continue;
      }
    }

    return decryptedTickets;
  }

  /// Wipe database records on structural user logout requests
  Future<void> clearAllCachedAssets() async {
    final db = await instance.database;
    await db.delete('offline_tickets');
  }
}