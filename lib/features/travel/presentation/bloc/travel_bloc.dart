import 'package:flutter_bloc/flutter_bloc.dart';
import '../../data/repositories/travel_repository.dart';
import '../../../../core/services/offline_ticket_service.dart';
import 'travel_event.dart';
import 'travel_state.dart';

class TravelBloc extends Bloc<TravelEvent, TravelState> {
  final TravelRepository _travelRepository;
  final OfflineTicketService _offlineTicketService;

  TravelBloc({
    required TravelRepository travelRepository,
    OfflineTicketService? offlineTicketService,
  })  : _travelRepository = travelRepository,
        _offlineTicketService = offlineTicketService ?? OfflineTicketService(),
        super(TravelInitial()) {
    on<TravelSearchBusTrips>(_onSearchBusTrips);
    on<TravelSearchFlights>(_onSearchFlights);
    on<TravelFetchSeatLayout>(_onFetchSeatLayout);
    on<TravelSelectSeats>(_onSelectSeats);
    on<TravelBookBusTrip>(_onBookBusTrip);
    on<TravelFetchMyBookings>(_onFetchMyBookings);
  }

  Future<void> _onSearchBusTrips(TravelSearchBusTrips event, Emitter<TravelState> emit) async {
    emit(TravelSearchLoading());
    try {
      final trips = await _travelRepository.searchBusTrips(
        origin: event.origin,
        destination: event.destination,
        date: event.date,
        passengers: event.passengers,
      );
      emit(TravelBusSearchLoaded(trips));
    } catch (e) {
      emit(TravelError('Failed to search bus trips: ${e.toString()}'));
    }
  }

  Future<void> _onSearchFlights(TravelSearchFlights event, Emitter<TravelState> emit) async {
    emit(TravelSearchLoading());
    try {
      final flights = await _travelRepository.searchFlights(
        origin: event.origin,
        destination: event.destination,
        date: event.date,
        passengers: event.passengers,
      );
      emit(TravelFlightSearchLoaded(flights));
    } catch (e) {
      emit(TravelError('Failed to search flights: ${e.toString()}'));
    }
  }

  Future<void> _onFetchSeatLayout(TravelFetchSeatLayout event, Emitter<TravelState> emit) async {
    emit(TravelSeatLayoutLoading());
    try {
      final layout = await _travelRepository.getBusSeatLayout(event.tripId);
      emit(TravelSeatLayoutLoaded(layout: layout));
    } catch (e) {
      emit(TravelError('Failed to fetch seat layout: ${e.toString()}'));
    }
  }

  void _onSelectSeats(TravelSelectSeats event, Emitter<TravelState> emit) {
    if (state is TravelSeatLayoutLoaded) {
      final currentState = state as TravelSeatLayoutLoaded;
      emit(currentState.copyWith(selectedSeats: event.seatNumbers));
    }
  }

  Future<void> _onBookBusTrip(TravelBookBusTrip event, Emitter<TravelState> emit) async {
    emit(TravelBookingProcessing());
    try {
      final booking = await _travelRepository.bookBusTrip(
        tripId: event.tripId,
        seatNumbers: event.seatNumbers,
        pin: event.pin,
      );

      // Cache the ticket offline for access without network
      await _offlineTicketService.cacheTicket(booking);

      emit(TravelBookingSuccess(booking));
    } catch (e) {
      emit(TravelError('Booking failed: ${e.toString()}'));
    }
  }

  Future<void> _onFetchMyBookings(TravelFetchMyBookings event, Emitter<TravelState> emit) async {
    emit(TravelSearchLoading());
    try {
      // 1. Try to fetch from remote
      final remoteBookings = await _travelRepository.getMyBookings();
      if (remoteBookings.isNotEmpty) {
        // Update local cache with remote sync
        for (var booking in remoteBookings) {
          await _offlineTicketService.cacheTicket(booking);
        }
        emit(TravelMyBookingsLoaded(remoteBookings));
        return;
      }

      // 2. If remote fails or is empty, load from offline cache
      final cachedBookings = await _offlineTicketService.getCachedTickets();
      emit(TravelMyBookingsLoaded(cachedBookings));
    } catch (e) {
      // Fallback to cache immediately on network error
      final cachedBookings = await _offlineTicketService.getCachedTickets();
      if (cachedBookings.isNotEmpty) {
        emit(TravelMyBookingsLoaded(cachedBookings));
      } else {
        emit(TravelError('Failed to load bookings: ${e.toString()}'));
      }
    }
  }
}
