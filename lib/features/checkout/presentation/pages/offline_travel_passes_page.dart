import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/database/offline_cache_handler.dart';
import '../widgets/offline_ticket_pass_card.dart';

class OfflineTravelPassesPage extends StatefulWidget {
  const OfflineTravelPassesPage({super.key});

  @override
  State<OfflineTravelPassesPage> createState() => _OfflineTravelPassesPageState();
}

class _OfflineTravelPassesPageState extends State<OfflineTravelPassesPage> {
  bool _isLoading = true;
  List<Map<String, dynamic>> _tickets = [];

  @override
  void initState() {
    super.initState();
    _loadTickets();
  }

  Future<void> _loadTickets() async {
    final tickets = await OfflineCacheHandler.instance.retrieveOfflineTickets();
    if (mounted) {
      setState(() {
        _tickets = tickets;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xfff8f9fa),
      appBar: AppBar(
        backgroundColor: const Color(0xff0b845c),
        elevation: 0,
        title: Text(
          'Offline Travel Passes',
          style: GoogleFonts.plusJakartaSans(
            fontWeight: FontWeight.w800,
            color: Colors.white,
            fontSize: 18,
          ),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xff0b845c)))
          : _tickets.isEmpty
              ? _buildEmptyState()
              : _buildTicketList(),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.airplane_ticket_outlined, size: 80, color: Colors.grey.shade400),
            const SizedBox(height: 20),
            Text(
              "No secure travel passes found.",
              style: GoogleFonts.plusJakartaSans(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: const Color(0xff1a1d20),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              "Book a transit trip to securely cache your boarding passes. They will automatically appear here for offline access.",
              style: GoogleFonts.plusJakartaSans(
                fontSize: 14,
                color: Colors.grey.shade600,
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTicketList() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _tickets.length,
      itemBuilder: (context, index) {
        final t = _tickets[index];
        final seatsList = List<int>.from(t['seats'] as List<dynamic>);
        return OfflineTicketPassCard(
          ticketId: t['id'] as String,
          destination: t['destination'] as String,
          seats: seatsList,
        );
      },
    );
  }
}
