import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../core/network/api_client.dart';
import '../../features/auth/presentation/pages/login_page.dart';
import '../../features/auth/presentation/pages/register_page.dart';
import '../../features/wallet/presentation/pages/wallet_dashboard_page.dart';
import '../../features/wallet/presentation/pages/virtual_account_page.dart';
import '../../features/vas/presentation/bloc/vas_bloc.dart';
import '../../features/vas/presentation/pages/airtime_page.dart';
import '../../features/vas/presentation/pages/data_page.dart';
import '../../features/vas/presentation/pages/electricity_page.dart';
import '../../features/vas/presentation/pages/betting_page.dart';
import '../../features/vas/presentation/pages/tv_cable_page.dart';
import '../../features/vas/presentation/pages/vas_hub_page.dart';
import '../../features/transfer/presentation/bloc/transfer_bloc.dart';
import '../../features/transfer/presentation/pages/transfer_page.dart';
import '../../features/profile/presentation/pages/profile_page.dart';
import '../../features/profile/presentation/pages/change_password_page.dart';
import '../../features/profile/presentation/pages/help_support_page.dart';
import '../../features/wallet/presentation/pages/loyalty_rewards_page.dart';
import '../../features/travel/presentation/bloc/travel_bloc.dart';
import '../../features/travel/presentation/pages/travel_dashboard_page.dart';
import '../../features/travel/presentation/pages/bus_search_page.dart';
import '../../features/travel/presentation/pages/travel_results_page.dart';
import '../../features/travel/presentation/pages/seat_selection_page.dart';
import '../../features/travel/presentation/pages/ticket_wallet_page.dart';
import '../../features/travel/data/repositories/travel_repository.dart';
import '../../features/travel/data/models/bus_trip.dart';

// ─── Pre-seeded VAS catalog data ─────────────────────────────────────────────
const _airtimeNetworks = <Map<String, dynamic>>[
  {'code': 'MTN', 'name': 'MTN Nigeria'},
  {'code': 'GLO', 'name': 'Globacom'},
  {'code': 'AIRTEL', 'name': 'Airtel Nigeria'},
  {'code': '9MOBILE', 'name': '9mobile'},
];

const _dataPlans = <Map<String, dynamic>>[
  {'code': 'MTN_1GB_30D', 'network': 'MTN', 'name': '1GB', 'amount': 50000, 'validity': '30 days'},
  {'code': 'MTN_2GB_30D', 'network': 'MTN', 'name': '2GB', 'amount': 100000, 'validity': '30 days'},
  {'code': 'GLO_1GB_30D', 'network': 'GLO', 'name': '1GB', 'amount': 50000, 'validity': '30 days'},
  {'code': 'AIRTEL_1GB_30D', 'network': 'AIRTEL', 'name': '1GB', 'amount': 50000, 'validity': '30 days'},
  {'code': '9MOBILE_1GB_30D', 'network': '9MOBILE', 'name': '1GB', 'amount': 50000, 'validity': '30 days'},
];

const _electricityDiscos = <Map<String, dynamic>>[
  {'code': 'IKEDC', 'name': 'Ikeja Electric'},
  {'code': 'EKEDC', 'name': 'Eko Electricity'},
  {'code': 'AEDC', 'name': 'Abuja Electricity'},
  {'code': 'PHED', 'name': 'Port Harcourt Electricity'},
  {'code': 'KEDCO', 'name': 'Kano Electricity'},
  {'code': 'IBEDC', 'name': 'Ibadan Electricity'},
  {'code': 'BEDC', 'name': 'Benin Electricity'},
  {'code': 'EEDC', 'name': 'Enugu Electricity'},
];

const _bettingProviders = <Map<String, dynamic>>[
  {'code': 'BET9JA', 'name': 'Bet9ja'},
  {'code': 'SPORTYBET', 'name': 'SportyBet'},
  {'code': 'BETKING', 'name': 'BetKing'},
  {'code': 'NAIRABET', 'name': 'NairaBET'},
  {'code': '1XBET', 'name': '1xBet'},
];

const _tvProviders = <Map<String, dynamic>>[
  {'code': 'DSTV', 'name': 'DStv'},
  {'code': 'GOTV', 'name': 'GOtv'},
  {'code': 'STARTIMES', 'name': 'Startimes'},
  {'code': 'SHOWMAX', 'name': 'Showmax'},
];

// ─── App Router ───────────────────────────────────────────────────────────────

class AppRouter {
  static final GoRouter router = GoRouter(
    initialLocation: '/splash',
    redirect: _guard,
    routes: [
      GoRoute(
        path: '/splash',
        name: 'splash',
        builder: (context, state) => const _SplashPage(),
      ),
      GoRoute(
        path: '/auth/login',
        name: 'login',
        builder: (context, state) => const LoginPage(),
      ),
      GoRoute(
        path: '/auth/register',
        name: 'register',
        builder: (context, state) => const RegisterPage(),
      ),
      GoRoute(
        path: '/dashboard',
        name: 'dashboard',
        builder: (context, state) {
          final extra = state.extra as Map<String, dynamic>?;
          return WalletDashboardPage(
            initialFirstName: extra?['firstName'] as String?,
            initialLastName: extra?['lastName'] as String?,
            initialPhone: extra?['phone'] as String?,
            initialDob: extra?['dob'] as String?,
          );
        },
      ),
      GoRoute(
        path: '/transfer',
        name: 'transfer',
        builder: (context, state) => BlocProvider(
          create: (_) => TransferBloc(),
          child: const TransferPage(),
        ),
      ),
      GoRoute(
        path: '/virtual-account',
        name: 'virtual-account',
        builder: (context, state) => const VirtualAccountPage(),
      ),
      GoRoute(
        path: '/loyalty',
        name: 'loyalty',
        builder: (context, state) => const LoyaltyRewardsPage(),
      ),
      GoRoute(
        path: '/travel',
        name: 'travel',
        builder: (context, state) => const TravelDashboardPage(),
      ),
      GoRoute(
        path: '/travel/bus',
        name: 'bus-search',
        builder: (context, state) => const BusSearchPage(),
      ),
      GoRoute(
        path: '/travel/bus/results',
        name: 'bus-results',
        builder: (context, state) {
          final extra = state.extra as Map<String, dynamic>;
          return BlocProvider(
            create: (_) => TravelBloc(travelRepository: TravelRepository()),
            child: TravelResultsPage(
              origin: extra['origin'] as String,
              destination: extra['destination'] as String,
              date: extra['date'] as DateTime,
              passengers: extra['passengers'] as int,
            ),
          );
        },
      ),
      GoRoute(
        path: '/travel/bus/seats',
        name: 'bus-seats',
        builder: (context, state) {
          final extra = state.extra as Map<String, dynamic>;
          final trip = extra['trip'] as BusTrip;
          final bloc = extra['bloc'] as TravelBloc;
          return BlocProvider.value(
            value: bloc,
            child: SeatSelectionPage(trip: trip),
          );
        },
      ),
      GoRoute(
        path: '/travel/tickets',
        name: 'travel-tickets',
        builder: (context, state) => BlocProvider(
          create: (_) => TravelBloc(travelRepository: TravelRepository()),
          child: const TicketWalletPage(),
        ),
      ),
      GoRoute(
        path: '/vas',
        name: 'vas-hub',
        builder: (context, state) => const VasHubPage(),
      ),
      GoRoute(
        path: '/vas/airtime',
        name: 'airtime',
        builder: (context, state) => BlocProvider(
          create: (_) => VasBloc()..add(VasLoadCatalog()),
          child: const AirtimePage(networks: _airtimeNetworks),
        ),
      ),
      GoRoute(
        path: '/vas/data',
        name: 'data',
        builder: (context, state) => BlocProvider(
          create: (_) => VasBloc()..add(VasLoadCatalog()),
          child: const DataPage(networks: _airtimeNetworks, dataPlans: _dataPlans),
        ),
      ),
      GoRoute(
        path: '/vas/electricity',
        name: 'electricity',
        builder: (context, state) => BlocProvider(
          create: (_) => VasBloc()..add(VasLoadCatalog()),
          child: const ElectricityPage(discos: _electricityDiscos),
        ),
      ),
      GoRoute(
        path: '/vas/betting',
        name: 'betting',
        builder: (context, state) => BlocProvider(
          create: (_) => VasBloc()..add(VasLoadCatalog()),
          child: const BettingPage(providers: _bettingProviders),
        ),
      ),
      GoRoute(
        path: '/vas/tv-cable',
        name: 'tv-cable',
        builder: (context, state) => BlocProvider(
          create: (_) => VasBloc()..add(VasLoadCatalog()),
          child: const TvCablePage(providers: _tvProviders),
        ),
      ),
      GoRoute(
        path: '/profile',
        name: 'profile',
        builder: (context, state) {
          final extra = state.extra as Map<String, dynamic>?;
          return ProfilePage(
            seedFirstName: extra?['firstName'] as String? ?? '',
            seedLastName: extra?['lastName'] as String? ?? '',
            seedPhone: extra?['phone'] as String? ?? '',
            seedDob: extra?['dob'] as String? ?? '',
          );
        },
      ),
      GoRoute(
        path: '/profile/change-password',
        name: 'change-password',
        builder: (context, state) => const ChangePasswordPage(),
      ),
      GoRoute(
        path: '/support',
        name: 'support',
        builder: (context, state) => const HelpSupportPage(),
      ),
    ],
  );

  static Future<String?> _guard(BuildContext context, GoRouterState state) async {
    final isLoggedIn = await ApiClient.instance.isLoggedIn();
    final onAuth = state.matchedLocation.startsWith('/auth');
    final onSplash = state.matchedLocation == '/splash';

    if (onSplash) {
      return isLoggedIn ? '/dashboard' : '/auth/login';
    }
    if (!isLoggedIn && !onAuth) return '/auth/login';
    if (isLoggedIn && onAuth) return '/dashboard';
    return null;
  }
}

// ─── Minimal splash that resolves the guard immediately ──────────────────────

class _SplashPage extends StatelessWidget {
  const _SplashPage();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: Color(0xff0b845c),
      body: Center(child: CircularProgressIndicator(color: Colors.white)),
    );
  }
}
