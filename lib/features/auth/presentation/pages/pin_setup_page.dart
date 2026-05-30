import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import '../bloc/auth_bloc.dart';
import '../../../../features/checkout/presentation/pages/search_aggregation_page.dart';

class PINSetupPage extends StatefulWidget {
  const PINSetupPage({super.key});

  @override
  State<PINSetupPage> createState() => _PINSetupPageState();
}

class _PINSetupPageState extends State<PINSetupPage> with TickerProviderStateMixin {
  String _pin = '';
  String _confirmPin = '';
  bool _isConfirming = false; // false = enter PIN, true = confirm PIN
  late AnimationController _shakeCtrl;
  late Animation<double> _shakeAnim;
  late AnimationController _successCtrl;
  late Animation<double> _successScaleAnim;
  late Animation<double> _successFadeAnim;

  @override
  void initState() {
    super.initState();
    _shakeCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 500));
    _shakeAnim = Tween<double>(begin: 0, end: 1).animate(_shakeCtrl);

    _successCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 800));
    _successScaleAnim = CurvedAnimation(parent: _successCtrl, curve: Curves.elasticOut);
    _successFadeAnim = CurvedAnimation(parent: _successCtrl, curve: Curves.easeIn);
  }

  @override
  void dispose() {
    _shakeCtrl.dispose();
    _successCtrl.dispose();
    super.dispose();
  }

  void _onKeyTap(String digit) {
    setState(() {
      if (!_isConfirming) {
        if (_pin.length < 4) {
          _pin += digit;
          if (_pin.length == 6) {
            Future.delayed(const Duration(milliseconds: 150), () {
              setState(() => _isConfirming = true);
            });
          }
        }
      } else {
        if (_confirmPin.length < 4) {
          _confirmPin += digit;
          if (_confirmPin.length == 6) {
            Future.delayed(const Duration(milliseconds: 150), _checkConfirm);
          }
        }
      }
    });
  }

  void _onDelete() {
    setState(() {
      if (!_isConfirming) {
        if (_pin.isNotEmpty) _pin = _pin.substring(0, _pin.length - 1);
      } else {
        if (_confirmPin.isNotEmpty) _confirmPin = _confirmPin.substring(0, _confirmPin.length - 1);
      }
    });
  }

  void _checkConfirm() {
    if (_pin == _confirmPin) {
      // PINs match — dispatch
      context.read<AuthBloc>().add(AuthSetPINRequested(pin: _pin, confirmPin: _confirmPin));
    } else {
      _shakeCtrl.reset();
      _shakeCtrl.forward();
      setState(() {
        _confirmPin = '';
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("PINs don't match. Try again.", style: GoogleFonts.plusJakartaSans()),
          backgroundColor: Colors.red.shade700,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => AuthBloc(),
      child: BlocListener<AuthBloc, AuthState>(
        listener: (context, state) {
          if (state is AuthPINSet) {
            _successCtrl.forward();
            Future.delayed(const Duration(milliseconds: 1200), () {
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (_) => const SearchAggregationPage()),
                (_) => false,
              );
            });
          } else if (state is AuthFailure) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message, style: GoogleFonts.plusJakartaSans()),
                backgroundColor: Colors.red.shade700,
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            );
          }
        },
        child: Scaffold(
          backgroundColor: const Color(0xff0b845c),
          body: SafeArea(
            child: Stack(
              children: [
                // Background decorations
                Positioned(top: -60, right: -60, child: _circle(200, 0.07)),
                Positioned(bottom: 100, left: -40, child: _circle(150, 0.05)),

                BlocBuilder<AuthBloc, AuthState>(
                  builder: (context, state) {
                    final isPINSet = state is AuthPINSet;
                    final isLoading = state is AuthLoading;

                    return Column(
                      children: [
                        const SizedBox(height: 48),

                        // Title section
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 32),
                          child: Column(children: [
                            AnimatedSwitcher(
                              duration: const Duration(milliseconds: 300),
                              child: isPINSet
                                ? ScaleTransition(
                                    scale: _successScaleAnim,
                                    child: FadeTransition(
                                      opacity: _successFadeAnim,
                                      child: Container(
                                        width: 72, height: 72,
                                        decoration: BoxDecoration(
                                          color: Colors.white,
                                          shape: BoxShape.circle,
                                          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.15), blurRadius: 24, offset: const Offset(0, 8))],
                                        ),
                                        child: const Icon(Icons.check_rounded, color: Color(0xff0b845c), size: 40),
                                      ),
                                    ),
                                  )
                                : Container(
                                    width: 60, height: 60,
                                    decoration: BoxDecoration(
                                      color: Colors.white.withOpacity(0.15),
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(Icons.lock_rounded, color: Colors.white, size: 28),
                                  ),
                            ),
                            const SizedBox(height: 20),
                            Text(
                              isPINSet ? 'PIN Created!' : (_isConfirming ? 'Confirm your PIN' : 'Create your PIN'),
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 26, fontWeight: FontWeight.w800, color: Colors.white),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              isPINSet
                                ? 'You\'re all set. Welcome to Flip Bills!'
                                : (_isConfirming ? 'Enter your 6-digit PIN again' : 'Enter a 6-digit transaction PIN'),
                              style: GoogleFonts.plusJakartaSans(fontSize: 14, color: Colors.white.withOpacity(0.75)),
                              textAlign: TextAlign.center,
                            ),
                          ]),
                        ),

                        const SizedBox(height: 56),

                        // PIN dots
                        AnimatedBuilder(
                          animation: _shakeAnim,
                          builder: (ctx, child) {
                            final dx = _shakeAnim.value < 0.5
                              ? -12 * (_shakeAnim.value / 0.5)
                              : 12 * ((_shakeAnim.value - 0.5) / 0.5) - 12;
                            return Transform.translate(offset: Offset(dx * 2, 0), child: child);
                          },
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: List.generate(6, (i) {
                              final currentPin = _isConfirming ? _confirmPin : _pin;
                              final filled = i < currentPin.length;
                              return Container(
                                margin: const EdgeInsets.symmetric(horizontal: 10),
                                width: 18, height: 18,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: filled ? Colors.white : Colors.white.withOpacity(0.25),
                                  border: Border.all(color: Colors.white.withOpacity(0.5), width: 1.5),
                                ),
                              );
                            }),
                          ),
                        ),

                        const Spacer(),

                        // Numpad
                        if (!isPINSet && !isLoading) ...[
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 40),
                            child: Column(
                              children: [
                                _buildNumRow(['1', '2', '3']),
                                const SizedBox(height: 16),
                                _buildNumRow(['4', '5', '6']),
                                const SizedBox(height: 16),
                                _buildNumRow(['7', '8', '9']),
                                const SizedBox(height: 16),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    _emptyKey(),
                                    _numKey('0'),
                                    _deleteKey(),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],

                        if (isLoading) ...[
                          const SizedBox(
                            width: 36, height: 36,
                            child: CircularProgressIndicator(color: Colors.white, strokeWidth: 3),
                          ),
                        ],

                        const SizedBox(height: 48),
                      ],
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNumRow(List<String> digits) => Row(
    mainAxisAlignment: MainAxisAlignment.spaceBetween,
    children: digits.map(_numKey).toList(),
  );

  Widget _numKey(String digit) => GestureDetector(
    onTap: () => _onKeyTap(digit),
    child: Container(
      width: 72, height: 72,
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.12),
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white.withOpacity(0.15), width: 1),
      ),
      child: Center(
        child: Text(digit,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 24, fontWeight: FontWeight.w700, color: Colors.white)),
      ),
    ),
  );

  Widget _deleteKey() => GestureDetector(
    onTap: _onDelete,
    child: Container(
      width: 72, height: 72,
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.08),
        shape: BoxShape.circle,
      ),
      child: const Center(
        child: Icon(Icons.backspace_outlined, color: Colors.white, size: 22),
      ),
    ),
  );

  Widget _emptyKey() => const SizedBox(width: 72, height: 72);

  Widget _circle(double size, double opacity) => Container(
    width: size, height: size,
    decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.white.withOpacity(opacity)),
  );
}
