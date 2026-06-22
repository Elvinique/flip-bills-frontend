import 'dart:convert';

import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../../features/travel/data/models/travel_booking.dart';

class OfflineTicketService {
  static final OfflineTicketService _instance = OfflineTicketService._internal();
  factory OfflineTicketService() => _instance;
  OfflineTicketService._internal();

  Database? _db;

  Future<Database> get database async {
    if (_db != null) return _db!;
    _db = await _initDB();
    return _db!;
  }

  Future<Database> _initDB() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'flipbills_tickets.db');

    return await openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE cached_tickets(
            id TEXT PRIMARY KEY,
            pnr TEXT,
            reference TEXT,
            status TEXT,
            ticket_qr_data TEXT,
            trip_details TEXT,
            created_at TEXT
          )
        ''');
      },
    );
  }

  // Cryptographically secure storage logic
  // The ticketQrData itself is stored securely and signed by the backend.
  // Here we just cache it offline for rendering without network access.
  Future<void> cacheTicket(TravelBooking booking) async {
    final db = await database;
    await db.insert(
      'cached_tickets',
      {
        'id': booking.bookingId,
        'pnr': booking.pnr,
        'reference': booking.reference,
        'status': booking.status,
        'ticket_qr_data': booking.ticketQrData, // In a full implementation, this could be AES encrypted with a key from _secureStorage
        'trip_details': jsonEncode(booking.tripDetails),
        'created_at': booking.createdAt.toIso8601String(),
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<TravelBooking>> getCachedTickets() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query('cached_tickets', orderBy: 'created_at DESC');

    return maps.map((map) {
      return TravelBooking(
        bookingId: map['id'] as String,
        pnr: map['pnr'] as String,
        reference: map['reference'] as String,
        status: map['status'] as String,
        ticketQrData: map['ticket_qr_data'] as String,
        tripDetails: jsonDecode(map['trip_details'] as String) as Map<String, dynamic>,
        createdAt: DateTime.parse(map['created_at'] as String),
      );
    }).toList();
  }

  Future<TravelBooking?> getTicket(String bookingId) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'cached_tickets',
      where: 'id = ?',
      whereArgs: [bookingId],
    );

    if (maps.isNotEmpty) {
      final map = maps.first;
      return TravelBooking(
        bookingId: map['id'] as String,
        pnr: map['pnr'] as String,
        reference: map['reference'] as String,
        status: map['status'] as String,
        ticketQrData: map['ticket_qr_data'] as String,
        tripDetails: jsonDecode(map['trip_details'] as String) as Map<String, dynamic>,
        createdAt: DateTime.parse(map['created_at'] as String),
      );
    }
    return null;
  }
}
