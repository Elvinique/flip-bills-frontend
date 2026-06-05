import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'core/network/api_client.dart';
import 'features/auth/presentation/bloc/auth_bloc.dart';
import 'features/auth/presentation/pages/login_page.dart';
import 'features/checkout/presentation/bloc/checkout_bloc.dart';
import 'features/wallet/presentation/pages/wallet_dashboard_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  GoogleFonts.config.allowRuntimeFetching = false;
  runApp(const FlipBillsApp());
}

class FlipBillsApp extends StatelessWidget {
  const FlipBillsApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        // AuthBloc at root — shared across all pages so auth state
        // (e.g. auto-logout on 401) is accessible anywhere in the tree.
        BlocProvider<AuthBloc>(
          create: (_) => AuthBloc(),
        ),
        BlocProvider<CheckoutBloc>(
          create: (_) => CheckoutBloc(),
        ),
      ],
      child: MaterialApp(
        title: 'Flip Bills',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          useMaterial3: true,
          colorSchemeSeed: const Color(0xff0b845c),
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

/// Checks token on startup — routes to WalletDashboard or Login
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
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => isLoggedIn
              ? const WalletDashboardPage()
              : const LoginPage(),
        ),
      );
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
