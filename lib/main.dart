import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'features/checkout/presentation/bloc/checkout_bloc.dart';
import 'features/checkout/presentation/pages/search_aggregation_page.dart';

void main() {
  // Ensure native hardware, database platforms, and plugins are properly initialized
  WidgetsFlutterBinding.ensureInitialized();
  
  runApp(const ByeByeBillApp());
}

class ByeByeBillApp extends StatelessWidget {
  const ByeByeBillApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Inject the CheckoutBloc stream container globally at the root of the widget tree
    return MultiBlocProvider(
      providers: [
        BlocProvider<CheckoutBloc>(
          create: (BuildContext context) => CheckoutBloc(),
        ),
      ],
      child: MaterialApp(
        title: 'Flip Bills', // UPDATED BRAND ENTRY
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
        home: const SearchAggregationPage(),
      ),
    );
  }
}