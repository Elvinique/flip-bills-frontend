// OTP verification page — kept for future use.
// The current registration flow goes directly to PIN setup (no OTP step).
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class OTPVerificationPage extends StatelessWidget {
  final String phone;
  const OTPVerificationPage({super.key, required this.phone});

  static const _green = Color(0xff0b845c);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.verified_user_outlined, color: _green, size: 64),
              const SizedBox(height: 24),
              Text('Phone Verification',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 24, fontWeight: FontWeight.w800, color: const Color(0xff0d1b16))),
              const SizedBox(height: 12),
              Text('OTP verification is not currently enabled.',
                textAlign: TextAlign.center,
                style: GoogleFonts.plusJakartaSans(fontSize: 15, color: const Color(0xff6b8078))),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity, height: 54,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _green,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    elevation: 0,
                  ),
                  child: Text('Go Back',
                    style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700, fontSize: 16)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
