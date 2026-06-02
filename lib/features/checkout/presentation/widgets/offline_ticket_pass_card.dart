import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class OfflineTicketPassCard extends StatelessWidget {
  final String ticketId;
  final String destination;
  final List<int> seats;

  const OfflineTicketPassCard({
    super.key,
    required this.ticketId,
    required this.destination,
    required this.seats,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xfffff9db), // Subtle warning alert layout backdrop
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xfff59f00), width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.signal_wifi_connected_no_internet_4_rounded, color: Color(0xfff59f00)),
              const SizedBox(width: 10),
              Text(
                "Offline Mode Enabled — Network Drop Detected",
                style: GoogleFonts.plusJakartaSans(
                  fontWeight: FontWeight.w800,
                  fontSize: 13,
                  color: const Color(0xfff59f00),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            "Your digital boarding pass has been decrypted from your device enclave secure cache. Present the pass token below to the terminal conductor.",
            style: TextStyle(fontSize: 11, color: Colors.black87, height: 1.4),
          ),
          const Divider(height: 24, color: Color(0xffffe066)),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("DESTINATION", style: TextStyle(fontSize: 9, color: Colors.black54, fontWeight: FontWeight.bold)),
                  Text(destination, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("ASSIGNED SEATS", style: TextStyle(fontSize: 9, color: Colors.black54, fontWeight: FontWeight.bold)),
                  Text(seats.join(', '), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Vector structural representation of the verification matrix pass
          Center(
            child: Container(
              padding: const EdgeInsets.all(12),
              color: Colors.white,
              child: Column(
                children: [
                  Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.black, width: 2),
                    ),
                    alignment: Alignment.center,
                    child: const Icon(Icons.qr_code_2_rounded, size: 100, color: Colors.black),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    ticketId,
                    style: const TextStyle(fontFamily: 'Courier', fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1),
                  )
                ],
              ),
            ),
          )
        ],
      ),
    );
  }
}