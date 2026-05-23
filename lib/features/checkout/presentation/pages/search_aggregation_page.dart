import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import '../bloc/checkout_bloc.dart';
import '../bloc/checkout_state.dart';
import '../widgets/bus_seat_grid.dart';
import '../widgets/contextual_checkout_sheet.dart';
import '../widgets/offline_ticket_pass_card.dart';

class SearchAggregationPage extends StatefulWidget {
  const SearchAggregationPage({super.key});

  @override
  State<SearchAggregationPage> createState() => _SearchAggregationPageState();
}

class _SearchAggregationPageState extends State<SearchAggregationPage> {
  final TextEditingController _toController = TextEditingController(text: 'Abuja');
  DateTime _travelDate = DateTime.now();

  @override
  void dispose() {
    _toController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xfff8f9fa),
      appBar: AppBar(
        backgroundColor: const Color(0xff0b845c),
        title: Text(
          'Flip Bills',
          style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w800, color: Colors.white),
        ),
      ),
      body: BlocConsumer<CheckoutBloc, CheckoutState>(
        listener: (context, state) {
          if (state is CheckoutFailureReversal) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message), 
                backgroundColor: Colors.orangeAccent.shade700,
                duration: const Duration(seconds: 4),
              ),
            );
          }
        },
        builder: (context, state) {
          return SingleChildScrollView(
            padding: const EdgeInsets.all(18.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("One app, one wallet.", style: GoogleFonts.plusJakartaSans(fontSize: 22, fontWeight: FontWeight.w800)),
                const SizedBox(height: 20),
                _buildSearchFormCard(),
                const SizedBox(height: 24),
                
                // Natively captures connection degradation metrics and surfaces local backup ledger records
                if (state is CheckoutFailureReversal) ...[
                  OfflineTicketPassCard(
                    ticketId: "FLIP-SECURE-849204",
                    destination: _toController.text,
                    seats: const [5, 6],
                  ),
                  const SizedBox(height: 16),
                  // Reset Button to exit simulation state cleanly
                  SizedBox(
                    width: double.infinity,
                    child: TextButton.icon(
                      icon: const Icon(Icons.refresh_rounded, color: Color(0xff0b845c)),
                      label: const Text("Reset to Live Mode", style: TextStyle(color: Color(0xff0b845c), fontWeight: FontWeight.bold)),
                      // OPTIMIZED: Prepend const keyword here to resolve the linter performance info entry
                      onPressed: () => context.read<CheckoutBloc>().add(const UpdateSeatSelection([])),
                    ),
                  ),
                ],

                if (state is CheckoutSelectionActive) ...[
                  Text("Select Seats (Click 2)", style: GoogleFonts.plusJakartaSans(fontSize: 16, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 10),
                  SizedBox(
                    height: 200,
                    child: BusSeatGrid(
                      totalRows: 4,
                      seatsPerRow: 4,
                      occupiedSeats: const [3, 7],
                      onSeatsChanged: (seats) {
                        context.read<CheckoutBloc>().add(UpdateSeatSelection(seats));
                      },
                    ),
                  ),
                  const SizedBox(height: 20),
                  if (state.selectedSeats.isNotEmpty)
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(backgroundColor: const Color(0xff1a1d20)),
                        onPressed: () {
                          showModalBottomSheet(
                            context: context,
                            builder: (_) => BlocProvider.value(
                              value: context.read<CheckoutBloc>(),
                              child: ContextualCheckoutSheet(
                                destinationBoundary: _toController.text,
                                baseSeatPrice: 12000.0,
                                selectedSeats: state.selectedSeats,
                              ),
                            ),
                          );
                        },
                        child: const Text("PROCEED TO NATIVE CHECKOUT", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                      ),
                    ),
                ] else if (state is! CheckoutFailureReversal) ...[
                  Column(
                    children: [
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(backgroundColor: const Color(0xff0b845c)),
                          onPressed: () => context.read<CheckoutBloc>().add(TriggerParallelSearch()),
                          child: state is CheckoutQueryingWorkers 
                              ? const CircularProgressIndicator(color: Colors.white)
                              : const Text("SEARCH ROUTES (CLICK 1)", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                        ),
                      ),
                      const SizedBox(height: 14),
                      
                      // Professional Simulation Trigger Interface Action Block
                      SizedBox(
                        width: double.infinity,
                        height: 48,
                        child: OutlinedButton.icon(
                          style: OutlinedButton.styleFrom(
                            side: BorderSide(color: Colors.red.shade300, width: 1.5),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                          icon: Icon(Icons.signal_wifi_off_rounded, color: Colors.red.shade700),
                          label: Text(
                            "FORCE EXPRESSWAY SIGNAL DROP (TEST SHIELD)", 
                            style: TextStyle(color: Colors.red.shade800, fontWeight: FontWeight.bold, fontSize: 12),
                          ),
                          onPressed: () {
                            // Enforces the error layout path cleanly by matching structural catch block exceptions
                            context.read<CheckoutBloc>().add(const ConfirmBiometricCheckout(-1.0));
                          },
                        ),
                      ),
                    ],
                  ),
                ]
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildSearchFormCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            // OPTIMIZED: Replaced deprecated withOpacity with accurate withAlpha conversion parameters
            color: Colors.black.withAlpha(10),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          TextField(
            readOnly: true,
            controller: TextEditingController(text: 'Lagos'),
            decoration: const InputDecoration(labelText: 'From', prefixIcon: Icon(Icons.radio_button_checked, color: Color(0xff0b845c))),
          ),
          TextField(
            controller: _toController,
            decoration: const InputDecoration(labelText: 'To', prefixIcon: Icon(Icons.location_on, color: Colors.orange)),
          ),
          const Divider(height: 32),
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: Container(
              padding: const EdgeInsets.all(8),
              decoration: const BoxDecoration(color: Color(0xfff8f9fa), shape: BoxShape.circle),
              child: const Icon(Icons.calendar_today_rounded, color: Colors.blueAccent, size: 20),
            ),
            title: const Text("Departure Date"),
            subtitle: Text(
              "${_travelDate.day}/${_travelDate.month}/${_travelDate.year}",
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            onTap: () async {
              DateTime? picked = await showDatePicker(
                context: context,
                initialDate: _travelDate,
                firstDate: DateTime.now(),
                lastDate: DateTime.now().add(const Duration(days: 60)),
              );
              if (picked != null) setState(() => _travelDate = picked);
            },
          ),
        ],
      ),
    );
  }
}