import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:local_auth/local_auth.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../bloc/checkout_bloc.dart';
import '../../../../core/database/offline_cache_handler.dart';

class ContextualCheckoutSheet extends StatefulWidget {
  final String destinationBoundary;
  final double baseSeatPrice;
  final List<int> selectedSeats;

  const ContextualCheckoutSheet({
    super.key,
    required this.destinationBoundary,
    required this.baseSeatPrice,
    required this.selectedSeats,
  });

  @override
  State<ContextualCheckoutSheet> createState() => _ContextualCheckoutSheetState();
}

class _ContextualCheckoutSheetState extends State<ContextualCheckoutSheet> {
  bool _addCrossSell = false;
  bool _isProcessing = false;
  final LocalAuthentication _auth = LocalAuthentication();

  final _nameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _pinCtrl = TextEditingController();

  static const _green = Color(0xff0b845c);
  static const _ink = Color(0xff0d1b16);
  static const _muted = Color(0xff6b8078);
  static const _greenLight = Color(0xffe8f5f0);

  @override
  void dispose() {
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    _pinCtrl.dispose();
    super.dispose();
  }

  double get _totalCost =>
      (widget.baseSeatPrice * widget.selectedSeats.length) + (_addCrossSell ? 4500 : 0);

  String? _validate() {
    if (_nameCtrl.text.trim().isEmpty) return 'Enter passenger full name';
    if (_phoneCtrl.text.trim().length < 10) return 'Enter a valid phone number';
    if (_pinCtrl.text.trim().length != 6) return 'Enter your 6-digit transaction PIN';
    return null;
  }

  Future<void> _processAuthorization() async {
    final error = _validate();
    if (error != null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(error, style: TextStyle()),
        backgroundColor: Colors.orange.shade700,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ));
      return;
    }

    setState(() => _isProcessing = true);

    bool authed = false;
    try {
      if (await _auth.canCheckBiometrics || await _auth.isDeviceSupported()) {
        authed = await _auth.authenticate(
          localizedReason: 'Confirm your bus ticket payment',
          options: const AuthenticationOptions(biometricOnly: false),
        );
      } else {
        // Device has no biometrics — PIN already validated above, proceed
        authed = true;
      }

      if (!mounted) return;

      if (!authed) {
        setState(() => _isProcessing = false);
        return;
      }

      // Cache ticket locally before network call so it's available offline
      await OfflineCacheHandler.instance.cacheTicket(
        ticketId: 'TXN-${DateTime.now().millisecondsSinceEpoch}',
        category: 'Bus Travel',
        departure: 'Lagos',
        destination: widget.destinationBoundary,
        travelDate: DateTime.now().toIso8601String(),
        seats: widget.selectedSeats,
        rawPayload: {'amount': _totalCost, 'cross_sell': _addCrossSell},
      );

      if (!mounted) return;

      // Fire the real booking event — bloc handles the API call
      context.read<CheckoutBloc>().add(ConfirmBusBooking(
        passengerName: _nameCtrl.text.trim(),
        passengerPhone: _phoneCtrl.text.trim(),
        transactionPin: _pinCtrl.text.trim(),
      ));

      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        setState(() => _isProcessing = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Authentication error. Please try again.',
              style: TextStyle()),
          backgroundColor: Colors.red.shade700,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(24, 24, 24, MediaQuery.of(context).viewInsets.bottom + 24),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Handle bar
            Center(
              child: Container(
                width: 40, height: 5,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
            const SizedBox(height: 18),

            // Title + price summary
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Confirm Booking',
                    style: GoogleFonts.plusJakartaSans(
                        fontSize: 18, fontWeight: FontWeight.w900, color: _ink)),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: _greenLight,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '₦${_totalCost.toStringAsFixed(0)}',
                    style: GoogleFonts.plusJakartaSans(
                        fontSize: 14, fontWeight: FontWeight.w800, color: _green),
                  ),
                ),
              ],
            ),
            Text(
              '${widget.selectedSeats.length} seat${widget.selectedSeats.length > 1 ? 's' : ''} · '
              'Seats ${widget.selectedSeats.join(', ')}',
              style: TextStyle(fontSize: 12, color: _muted),
            ),
            const SizedBox(height: 20),

            // Passenger name
            _label('Passenger Full Name'),
            const SizedBox(height: 8),
            _textField(
              controller: _nameCtrl,
              hint: 'Ada Okonkwo',
              icon: Icons.person_outline_rounded,
              keyboardType: TextInputType.name,
            ),
            const SizedBox(height: 16),

            // Passenger phone
            _label('Passenger Phone'),
            const SizedBox(height: 8),
            _textField(
              controller: _phoneCtrl,
              hint: '08012345678',
              icon: Icons.phone_outlined,
              keyboardType: TextInputType.phone,
              formatters: [FilteringTextInputFormatter.digitsOnly],
            ),
            const SizedBox(height: 16),

            // Transaction PIN
            _label('Transaction PIN'),
            const SizedBox(height: 8),
            _textField(
              controller: _pinCtrl,
              hint: '••••••',
              icon: Icons.lock_outline_rounded,
              keyboardType: TextInputType.number,
              formatters: [FilteringTextInputFormatter.digitsOnly],
              obscure: true,
              maxLength: 6,
            ),
            const SizedBox(height: 16),

            // Cross-sell checkbox
            Container(
              decoration: BoxDecoration(
                color: _greenLight,
                borderRadius: BorderRadius.circular(12),
              ),
              child: CheckboxListTile(
                title: Text(
                  'Pay your AEDC electricity bill now and get 5% cashback.',
                  style: GoogleFonts.plusJakartaSans(
                      fontSize: 12, fontWeight: FontWeight.w600, color: _ink),
                ),
                value: _addCrossSell,
                activeColor: _green,
                onChanged: (v) => setState(() => _addCrossSell = v ?? false),
                controlAffinity: ListTileControlAffinity.leading,
                contentPadding: const EdgeInsets.symmetric(horizontal: 8),
              ),
            ),
            const SizedBox(height: 24),

            // Pay button
            SizedBox(
              width: double.infinity,
              height: 54,
              child: ElevatedButton.icon(
                icon: _isProcessing
                    ? const SizedBox(
                        width: 20, height: 20,
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5))
                    : const Icon(Icons.fingerprint_rounded, color: Colors.white),
                label: Text(
                  _isProcessing ? 'Processing…' : 'PAY  ₦${_totalCost.toStringAsFixed(0)}',
                  style: GoogleFonts.plusJakartaSans(
                      color: Colors.white, fontWeight: FontWeight.w800, fontSize: 15),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _green,
                  disabledBackgroundColor: _green.withValues(alpha: 0.6),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  elevation: 0,
                ),
                onPressed: _isProcessing ? null : _processAuthorization,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _label(String text) => Text(text,
      style: GoogleFonts.plusJakartaSans(
          fontSize: 13, fontWeight: FontWeight.w600, color: _ink));

  Widget _textField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    TextInputType? keyboardType,
    List<TextInputFormatter>? formatters,
    bool obscure = false,
    int? maxLength,
  }) =>
      TextField(
        controller: controller,
        keyboardType: keyboardType,
        inputFormatters: formatters,
        obscureText: obscure,
        maxLength: maxLength,
        style: GoogleFonts.plusJakartaSans(
            fontSize: 15, fontWeight: FontWeight.w500, color: _ink),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: TextStyle(color: _muted, fontSize: 14),
          prefixIcon: Icon(icon, size: 20, color: _muted),
          filled: true,
          fillColor: _greenLight,
          counterText: '',
          border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: _green, width: 1.5),
          ),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        ),
      );
}
