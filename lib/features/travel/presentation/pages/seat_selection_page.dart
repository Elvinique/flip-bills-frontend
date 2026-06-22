import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_theme.dart';
import '../../data/models/bus_trip.dart';
import '../bloc/travel_bloc.dart';
import '../bloc/travel_event.dart';
import '../bloc/travel_state.dart';

class SeatSelectionPage extends StatefulWidget {
  final BusTrip trip;

  const SeatSelectionPage({super.key, required this.trip});

  @override
  State<SeatSelectionPage> createState() => _SeatSelectionPageState();
}

class _SeatSelectionPageState extends State<SeatSelectionPage> {
  final List<String> _selectedSeats = [];

  void _toggleSeat(String seatId, bool isAvailable) {
    if (!isAvailable) return;
    setState(() {
      if (_selectedSeats.contains(seatId)) {
        _selectedSeats.remove(seatId);
      } else {
        if (_selectedSeats.length < 5) { // max 5 seats per booking
          _selectedSeats.add(seatId);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Maximum of 5 seats allowed per booking.')),
          );
        }
      }
    });
    context.read<TravelBloc>().add(TravelSelectSeats(_selectedSeats));
  }

  void _showCheckoutBottomSheet() {
    if (_selectedSeats.isEmpty) return;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _CheckoutBottomSheet(
        trip: widget.trip,
        seats: _selectedSeats,
        blocContext: context,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Select Seats - ${widget.trip.operatorName}'),
      ),
      body: BlocBuilder<TravelBloc, TravelState>(
        builder: (context, state) {
          if (state is TravelSeatLayoutLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          if (state is TravelError) {
            return Center(child: Text(state.message, style: AppText.body(color: AppColors.error)));
          }
          if (state is TravelSeatLayoutLoaded) {
            final layout = state.layout;
            
            return Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _buildLegendItem(AppColors.surface, 'Available'),
                      _buildLegendItem(AppColors.brand, 'Selected'),
                      _buildLegendItem(AppColors.textMuted, 'Booked'),
                    ],
                  ),
                ),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 20),
                    child: Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(32),
                        border: Border.all(color: AppColors.divider, width: 2),
                      ),
                      child: Column(
                        children: [
                          const Icon(Icons.drive_eta, size: 40, color: AppColors.textMuted), // driver seat
                          const SizedBox(height: 24),
                          // Build grid
                          for (int r = 1; r <= layout.rows; r++)
                            Padding(
                              padding: const EdgeInsets.only(bottom: 16.0),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  for (int c = 1; c <= layout.columns; c++)
                                    _buildSeat(
                                      seatId: '$r${String.fromCharCode(64 + c)}',
                                      layout: layout,
                                    ),
                                ],
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, -5))],
                  ),
                  child: SafeArea(
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text('${_selectedSeats.length} Seats Selected', style: AppText.body(color: AppColors.textSecondary)),
                              Text(
                                '₦${(_selectedSeats.length * (widget.trip.priceKobo / 100)).toStringAsFixed(0)}',
                                style: AppText.h2(),
                              ),
                            ],
                          ),
                        ),
                        ElevatedButton(
                          onPressed: _selectedSeats.isEmpty ? null : _showCheckoutBottomSheet,
                          child: const Text('Continue'),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            );
          }
          return const SizedBox.shrink();
        },
      ),
    );
  }

  Widget _buildLegendItem(Color color, String label) {
    return Row(
      children: [
        Container(width: 16, height: 16, decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(4), border: Border.all(color: AppColors.divider))),
        const SizedBox(width: 8),
        Text(label, style: AppText.caption()),
      ],
    );
  }

  Widget _buildSeat({required String seatId, required dynamic layout}) {
    // A simple mock logic to spread seats out in columns.
    // If it's a middle column and rows > some number, it might be an aisle.
    if (seatId.contains('B') && layout.columns == 3) {
      return const SizedBox(width: 40); // Aisle
    }

    final isBooked = layout.bookedSeats.contains(seatId);
    final isSelected = _selectedSeats.contains(seatId);

    Color bgColor = AppColors.surface;
    Color borderColor = AppColors.divider;
    Color textColor = AppColors.textPrimary;

    if (isBooked) {
      bgColor = AppColors.divider;
      textColor = AppColors.textMuted;
    } else if (isSelected) {
      bgColor = AppColors.brand;
      borderColor = AppColors.brand;
      textColor = Colors.white;
    }

    return GestureDetector(
      onTap: () => _toggleSeat(seatId, !isBooked),
      child: Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: borderColor, width: 1.5),
        ),
        alignment: Alignment.center,
        child: Text(seatId, style: AppText.label(color: textColor)),
      ),
    );
  }
}

class _CheckoutBottomSheet extends StatefulWidget {
  final BusTrip trip;
  final List<String> seats;
  final BuildContext blocContext;

  const _CheckoutBottomSheet({required this.trip, required this.seats, required this.blocContext});

  @override
  State<_CheckoutBottomSheet> createState() => _CheckoutBottomSheetState();
}

class _CheckoutBottomSheetState extends State<_CheckoutBottomSheet> {
  final _pinController = TextEditingController();

  void _confirmBooking() {
    if (_pinController.text.length != 4) {
      return;
    }
    // Cross-sell accepted or not, we fire booking.
    widget.blocContext.read<TravelBloc>().add(TravelBookBusTrip(
      tripId: widget.trip.tripId,
      seatNumbers: widget.seats,
      pin: _pinController.text,
    ));
    context.pop(); // close bottom sheet
    // We will listen to state in a wrapper or handle navigation there.
    widget.blocContext.push('/travel/tickets');
  }

  @override
  Widget build(BuildContext context) {
    final amount = widget.seats.length * (widget.trip.priceKobo / 100);

    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 24,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Confirm Booking', style: AppText.h2()),
              IconButton(icon: const Icon(Icons.close), onPressed: () => context.pop()),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            decoration: AppCard.standard(),
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Total Amount', style: AppText.body(color: AppColors.textSecondary)),
                    Text('₦${amount.toStringAsFixed(0)}', style: AppText.h3()),
                  ],
                ),
                const Divider(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Seats', style: AppText.body(color: AppColors.textSecondary)),
                    Text(widget.seats.join(', '), style: AppText.body()),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          // Cross-Sell Banner
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.info.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.info.withOpacity(0.3)),
            ),
            child: Row(
              children: [
                const Icon(Icons.lightbulb, color: AppColors.info),
                const SizedBox(width: 12),
                Expanded(
                  child: Text('Travelling to ${widget.trip.destination}? Pay your electricity bill now and get 5% cashback!', style: AppText.caption()),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          TextField(
            controller: _pinController,
            obscureText: true,
            keyboardType: TextInputType.number,
            maxLength: 4,
            decoration: AppInput.field(
              label: 'Enter 4-Digit Wallet PIN',
              prefix: const Icon(Icons.lock_outline),
            ).copyWith(counterText: ''),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: _confirmBooking,
            child: const Text('Authorize & Pay'),
          ),
        ],
      ),
    );
  }
}
