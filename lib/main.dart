import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'core/router/app_router.dart';
import 'core/services/notification_service.dart';
import 'features/auth/presentation/bloc/auth_bloc.dart';
import 'features/checkout/presentation/bloc/checkout_bloc.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  GoogleFonts.config.allowRuntimeFetching = false;
  await NotificationService.instance.init();
  runApp(const FlipBillsApp());
}

class FlipBillsApp extends StatelessWidget {
  const FlipBillsApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<AuthBloc>(create: (_) => AuthBloc()),
        BlocProvider<CheckoutBloc>(create: (_) => CheckoutBloc()),
      ],
      child: MaterialApp.router(
        title: 'Flip Bills',
        debugShowCheckedModeBanner: false,
        routerConfig: AppRouter.router,
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
      ),
    );
  }
}
