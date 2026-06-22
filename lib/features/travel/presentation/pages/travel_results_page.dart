import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_theme.dart';
import '../bloc/travel_bloc.dart';
import '../bloc/travel_event.dart';
import '../bloc/travel_state.dart';

class TravelResultsPage extends StatefulWidget {
  final String origin;
  final String destination;
  final DateTime date;
  final int passengers;

  const TravelResultsPage({
    super.key,
    required this.origin,
    required this.destination,
    required this.date,
    required this.passengers,
  });

  @override
  State<TravelResultsPage> createState() => _TravelResultsPageState();
}

class _TravelResultsPageState extends State<TravelResultsPage> {
  @override
  void initState() {
    super.initState();
    context.read<TravelBloc>().add(
          TravelSearchBusTrips(
            origin: widget.origin,
            destination: widget.destination,
            date: widget.date,
            passengers: widget.passengers,
          ),
        );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('${widget.origin} → ${widget.destination}', style: AppText.h3(color: Colors.white)),
            Text(
              '${DateFormat('MMM d').format(widget.date)} • ${widget.passengers} Passenger(s)',
              style: AppText.caption(color: Colors.white70),
            ),
          ],
        ),
      ),
      body: BlocBuilder<TravelBloc, TravelState>(
        builder: (context, state) {
          if (state is TravelSearchLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          if (state is TravelError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Text(state.message, textAlign: TextAlign.center, style: AppText.body(color: AppColors.error)),
              ),
            );
          }
          if (state is TravelBusSearchLoaded) {
            if (state.trips.isEmpty) {
              return Center(child: Text('No buses found for this route.', style: AppText.h3()));
            }
            return ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: state.trips.length,
              separatorBuilder: (_, __) => const SizedBox(height: 16),
              itemBuilder: (context, index) {
                final trip = state.trips[index];
                return GestureDetector(
                  onTap: () {
                    context.read<TravelBloc>().add(TravelFetchSeatLayout(trip.tripId));
                    context.push('/travel/bus/seats', extra: {'trip': trip, 'bloc': context.read<TravelBloc>()});
                  },
                  child: Container(
                    decoration: AppCard.standard(),
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(trip.operatorName, style: AppText.h3(color: AppColors.brand)),
                            Text(
                              NumberFormat.currency(symbol: '₦', decimalDigits: 0).format(trip.priceKobo / 100),
                              style: AppText.h3(),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            const Icon(Icons.access_time, size: 16, color: AppColors.textSecondary),
                            const SizedBox(width: 4),
                            Text(DateFormat('hh:mm a').format(trip.departureTime), style: AppText.body()),
                            const Spacer(),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: AppColors.surface,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text('${trip.availableSeats} Seats Left', style: AppText.caption(color: AppColors.warning)),
                            ),
                          ],
                        ),
                        const Divider(height: 24),
                        Row(
                          children: [
                            Icon(Icons.commute, size: 16, color: AppColors.textMuted),
                            const SizedBox(width: 4),
                            Text(trip.vehicleType, style: AppText.caption()),
                            const Spacer(),
                            ...trip.amenities.take(3).map((a) => Padding(
                                  padding: const EdgeInsets.only(left: 8.0),
                                  child: Icon(
                                    a == 'AC' ? Icons.ac_unit : Icons.wifi,
                                    size: 16,
                                    color: AppColors.textMuted,
                                  ),
                                )),
                          ],
                        ),
                      ],
                    ),
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
