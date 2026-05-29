import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'core/network/api_client.dart';
import 'features/checkout/presentation/bloc/checkout_bloc.dart';
import 'features/checkout/presentation/pages/search_aggregation_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const FlipBillsApp());
}

class FlipBillsApp extends StatelessWidget {
  const FlipBillsApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<CheckoutBloc>(
          create: (context) => CheckoutBloc(),
        ),
      ],
      child: MaterialApp(
        title: 'Flip Bills',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          useMaterial3: true,
          colorSchemeSeed: const Color(0xff0b845c),
          textTheme: GoogleFonts.plusJakartaSansTextTheme(
            Theme.of(context).textTheme,
          ),
          appBarTheme: const AppBarTheme(
            elevation: 0,
            centerTitle: false,
            backgroundColor: Color(0xff0b845c),
            foregroundColor: Colors.white,
          ),
        ),
        home: const AppEntryPoint(),
      ),
    );
  }
}

// Checks login state on startup and routes accordingly
class AppEntryPoint extends StatefulWidget {
  const AppEntryPoint({super.key});

  @override
  State<AppEntryPoint> createState() => _AppEntryPointState();
}

class _AppEntryPointState extends State<AppEntryPoint> {
  @override
  void initState() {
    super.initState();
    _checkAuth();
  }

  Future<void> _checkAuth() async {
    final isLoggedIn = await ApiClient.instance.isLoggedIn();
    if (mounted) {
      if (isLoggedIn) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const SearchAggregationPage()),
        );
      } else {
        // TODO: navigate to login screen when built
        // For now go straight to main screen
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const SearchAggregationPage()),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: Color(0xff0b845c),
      body: Center(
        child: CircularProgressIndicator(color: Colors.white),
      ),
    );
  }
}
