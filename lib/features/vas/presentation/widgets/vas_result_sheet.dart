import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

class VasResultSheet extends StatelessWidget {
  final bool success;
  final String message;
  final String? reference;
  final String? token;
  final bool isReversal;
  final VoidCallback onDone;

  const VasResultSheet({
    super.key,
    required this.success,
    required this.message,
    this.reference,
    this.token,
    this.isReversal = false,
    required this.onDone,
  });

  static const _brand = Color(0xff0b845c);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: const EdgeInsets.fromLTRB(24, 12, 24, 36),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle bar
          Container(
            width: 40,
            height: 4,
            margin: const EdgeInsets.only(bottom: 28),
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // Icon
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: isReversal 
                  ? const Color(0xfffff4e6) 
                  : success
                      ? const Color(0xffe1f5ee)
                      : const Color(0xfffdecea),
              shape: BoxShape.circle,
            ),
            child: Icon(
              isReversal 
                  ? Icons.refresh_rounded 
                  : success ? Icons.check_rounded : Icons.error_outline_rounded,
              size: 36,
              color: isReversal 
                  ? Colors.orange.shade700 
                  : success ? _brand : const Color(0xffd32f2f),
            ),
          ),
          const SizedBox(height: 16),

          Text(
            isReversal 
                ? 'Transaction Reversed' 
                : success ? 'Transaction successful' : 'Transaction failed',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: isReversal 
                  ? Colors.orange.shade700 
                  : success ? _brand : const Color(0xffd32f2f),
            ),
          ),
          const SizedBox(height: 8),

          Text(
            message,
            textAlign: TextAlign.center,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 14,
              color: Colors.grey.shade600,
            ),
          ),

          // Electricity token card
          if (token != null) ...[
            const SizedBox(height: 20),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xffe1f5ee),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: _brand.withValues(alpha: 0.3)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Prepaid token',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 12,
                      color: _brand.withValues(alpha: 0.7),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          token!,
                          style: GoogleFonts.sourceCodePro(
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                            color: _brand,
                            letterSpacing: 2,
                          ),
                        ),
                      ),
                      IconButton(
                        onPressed: () {
                          Clipboard.setData(ClipboardData(text: token!));
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Token copied')),
                          );
                        },
                        icon: const Icon(Icons.copy_rounded, size: 20, color: _brand),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],

          // Reference
          if (reference != null) ...[
            const SizedBox(height: 12),
            Text(
              'Ref: $reference',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 12,
                color: Colors.grey.shade400,
              ),
            ),
          ],

          const SizedBox(height: 28),

          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              onPressed: onDone,
              style: ElevatedButton.styleFrom(
                backgroundColor: success ? _brand : Colors.grey.shade800,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: Text(
                'Done',
                style: GoogleFonts.plusJakartaSans(
                  fontWeight: FontWeight.w600,
                  fontSize: 16,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
