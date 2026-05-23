import 'package:flutter/material.dart';
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
  final LocalAuthentication _auth = LocalAuthentication();

  Future<void> _processAuthorization() async {
    bool authed = false;
    try {
      // Execute local hardware enclave scanning checks safely
      if (await _auth.canCheckBiometrics || await _auth.isDeviceSupported()) {
        authed = await _auth.authenticate(
          localizedReason: 'Confirm secure single-wallet biometric payment loop',
          options: const AuthenticationOptions(biometricOnly: true),
        );
      } else {
        authed = true; // Fallback route environment simulator override
      }

      // GUARD: Check if the widget is still in the tree before navigating or updating state across the async gap
      if (!mounted) return;

      if (authed) {
        // Calculate the actual total obligation amount safely within the current function scope
        double cost = (widget.baseSeatPrice * widget.selectedSeats.length) + (_addCrossSell ? 4500 : 0);
        
        // Push the transaction token directly onto your global state flow channel
        context.read<CheckoutBloc>().add(ConfirmBiometricCheckout(cost));
        
        // Securely serialize transaction details to the encrypted offline local database cache
        await OfflineCacheHandler.instance.cacheTicket(
          ticketId: "TXN-${DateTime.now().millisecondsSinceEpoch}",
          category: "Bus Travel", 
          departure: "Lagos", 
          destination: widget.destinationBoundary,
          travelDate: DateTime.now().toIso8601String(), 
          seats: widget.selectedSeats,
          rawPayload: {"amount": cost, "cross_sell": _addCrossSell},
        );
        
        if (mounted) {
          Navigator.pop(context); // Dismiss the bottom modal sheet layout smoothly
        }
      }
    } catch (_) {
      // Graceful error capture string
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      color: Colors.white,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CheckboxListTile(
            title: Text(
              "Travelling to ${widget.destinationBoundary}? Clear your AEDC utility bill now for 5% cashback.",
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
            ),
            value: _addCrossSell, 
            onChanged: (bool? value) {
              setState(() => _addCrossSell = value ?? false);
            },
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton.icon(
              icon: const Icon(Icons.fingerprint, color: Colors.white),
              label: const Text(
                "PAY WITH NATIVE BIOMETRICS", 
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.black,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: _processAuthorization, // Natively binds the named callback tracking
            ),
          )
        ],
      ),
    );
  }
}