import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_theme.dart';
import '../bloc/travel_bloc.dart';
import '../bloc/travel_event.dart';
import '../bloc/travel_state.dart';

class TicketWalletPage extends StatefulWidget {
  const TicketWalletPage({super.key});

  @override
  State<TicketWalletPage> createState() => _TicketWalletPageState();
}

class _TicketWalletPageState extends State<TicketWalletPage> {
  @override
  void initState() {
    super.initState();
    context.read<TravelBloc>().add(TravelFetchMyBookings());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Tickets'),
      ),
      body: BlocBuilder<TravelBloc, TravelState>(
        buildWhen: (previous, current) => current is TravelMyBookingsLoaded || current is TravelSearchLoading,
        builder: (context, state) {
          if (state is TravelSearchLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          if (state is TravelMyBookingsLoaded) {
            final bookings = state.bookings;
            if (bookings.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.confirmation_num_outlined, size: 64, color: AppColors.textMuted),
                    const SizedBox(height: 16),
                    Text('No tickets found.', style: AppText.body()),
                  ],
                ),
              );
            }
            return ListView.separated(
              padding: const EdgeInsets.all(24),
              itemCount: bookings.length,
              separatorBuilder: (_, __) => const SizedBox(height: 24),
              itemBuilder: (context, index) {
                final booking = bookings[index];
                return Container(
                  decoration: AppCard.standard(),
                  child: Column(
                    children: [
                      // Top Half - Details
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: const BoxDecoration(
                          color: AppColors.brand,
                          borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('PNR: ${booking.pnr}', style: AppText.h3(color: Colors.white)),
                                const SizedBox(height: 4),
                                Text(DateFormat('MMM d, yyyy - hh:mm a').format(booking.createdAt), style: AppText.caption(color: Colors.white70)),
                              ],
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(20)),
                              child: Text(booking.status.toUpperCase(), style: AppText.caption(color: Colors.white)),
                            )
                          ],
                        ),
                      ),
                      // Bottom Half - QR Code (Cryptographic Offline Cache)
                      Container(
                        padding: const EdgeInsets.all(24),
                        color: Colors.white,
                        child: Column(
                          children: [
                            Text('Show this QR Code at the terminal', style: AppText.body(color: AppColors.textSecondary)),
                            const SizedBox(height: 24),
                            QrImageView(
                              data: booking.ticketQrData,
                              version: QrVersions.auto,
                              size: 200.0,
                              backgroundColor: Colors.white,
                            ),
                            const SizedBox(height: 16),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.offline_pin, color: AppColors.success, size: 16),
                                const SizedBox(width: 8),
                                Text('Available Offline', style: AppText.caption(color: AppColors.success)),
                              ],
                            )
                          ],
                        ),
                      )
                    ],
                  ),
                );
              },
            );
          }
          return const SizedBox.shrink();
        },
      ),
    );
  }
}
