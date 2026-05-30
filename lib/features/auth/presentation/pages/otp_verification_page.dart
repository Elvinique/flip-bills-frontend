import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import '../bloc/auth_bloc.dart';
import 'pin_setup_page.dart';
import '../../../../features/checkout/presentation/pages/search_aggregation_page.dart';

class OTPVerificationPage extends StatefulWidget {
  final String phone;
  final bool isPostRegister; // true = go to PIN setup after, false = go to home

  const OTPVerificationPage({
    super.key,
    required this.phone,
    this.isPostRegister = false,
  });

  @override
  State<OTPVerificationPage> createState() => _OTPVerificationPageState();
}

class _OTPVerificationPageState extends State<OTPVerificationPage> with TickerProviderStateMixin {
  final List<TextEditingController> _ctrls = List.generate(6, (_) => TextEditingController());
  final List<FocusNode> _focusNodes = List.generate(6, (_) => FocusNode());

  int _resendCooldown = 60;
  Timer? _timer;
  late AnimationController _shakeCtrl;
  late Animation<double> _shakeAnim;
  late AnimationController _successCtrl;
  late Animation<double> _successAnim;

  @override
  void initState() {
    super.initState();
    _startCooldown();

    _shakeCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 500));
    _shakeAnim = Tween<double>(begin: 0, end: 1).animate(_shakeCtrl);

    _successCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 600));
    _successAnim = CurvedAnimation(parent: _successCtrl, curve: Curves.elasticOut);

    // Auto-focus first field
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusNodes[0].requestFocus();
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    for (final c in _ctrls) c.dispose();
    for (final f in _focusNodes) f.dispose();
    _shakeCtrl.dispose();
    _successCtrl.dispose();
    super.dispose();
  }

  void _startCooldown() {
    _timer?.cancel();
    setState(() => _resendCooldown = 60);
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (_resendCooldown == 0) {
        t.cancel();
      } else {
        setState(() => _resendCooldown--);
      }
    });
  }

  String get _otp => _ctrls.map((c) => c.text).join();

  void _onDigitInput(int index, String value) {
    if (value.isNotEmpty && index < 5) {
      _focusNodes[index + 1].requestFocus();
    }
    if (_otp.length == 6) {
      // All digits filled — auto submit
      Future.microtask(() => _submit());
    }
  }

  void _onBackspace(int index) {
    if (_ctrls[index].text.isEmpty && index > 0) {
      _focusNodes[index - 1].requestFocus();
      _ctrls[index - 1].clear();
    }
  }

  void _submit() {
    if (_otp.length < 6) return;
    context.read<AuthBloc>().add(AuthVerifyOTPRequested(phone: widget.phone, otp: _otp));
  }

  void _triggerShake() {
    _shakeCtrl.reset();
    _shakeCtrl.forward();
    for (final c in _ctrls) c.clear();
    _focusNodes[0].requestFocus();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => AuthBloc(),
      child: _OTPView(
        phone: widget.phone,
        isPostRegister: widget.isPostRegister,
        ctrls: _ctrls,
        focusNodes: _focusNodes,
        resendCooldown: _resendCooldown,
        shakeAnim: _shakeAnim,
        successAnim: _successAnim,
        onDigitInput: _onDigitInput,
        onBackspace: _onBackspace,
        onSubmit: _submit,
        onResend: () {
          _startCooldown();
          context.read<AuthBloc>().add(AuthResendOTPRequested(phone: widget.phone));
        },
        onShake: _triggerShake,
        successCtrl: _successCtrl,
      ),
    );
  }
}

class _OTPView extends StatelessWidget {
  final String phone;
  final bool isPostRegister;
  final List<TextEditingController> ctrls;
  final List<FocusNode> focusNodes;
  final int resendCooldown;
  final Animation<double> shakeAnim;
  final Animation<double> successAnim;
  final Function(int, String) onDigitInput;
  final Function(int) onBackspace;
  final VoidCallback onSubmit;
  final VoidCallback onResend;
  final VoidCallback onShake;
  final AnimationController successCtrl;

  const _OTPView({
    required this.phone,
    required this.isPostRegister,
    required this.ctrls,
    required this.focusNodes,
    required this.resendCooldown,
    required this.shakeAnim,
    required this.successAnim,
    required this.onDigitInput,
    required this.onBackspace,
    required this.onSubmit,
    required this.onResend,
    required this.onShake,
    required this.successCtrl,
  });

  static const _green = Color(0xff0b845c);
  static const _ink = Color(0xff0d1b16);
  static const _muted = Color(0xff6b8078);

  String _maskedPhone(String p) {
    if (p.length > 6) return '${p.substring(0, 4)}****${p.substring(p.length - 2)}';
    return p;
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthBloc, AuthState>(
      listener: (context, state) {
        if (state is AuthOTPVerified) {
          successCtrl.forward();
          Future.delayed(const Duration(milliseconds: 700), () {
            if (isPostRegister) {
              Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const PINSetupPage()));
            } else {
              Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const SearchAggregationPage()));
            }
          });
        } else if (state is AuthFailure) {
          onShake();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.message, style: GoogleFonts.plusJakartaSans()),
              backgroundColor: Colors.red.shade700,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          );
        } else if (state is AuthOTPResent) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('OTP resent to ${_maskedPhone(phone)}', style: GoogleFonts.plusJakartaSans()),
              backgroundColor: _green,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          );
        }
      },
      child: Scaffold(
        backgroundColor: Colors.white,
        body: Stack(
          children: [
            Positioned(
              top: 0, left: 0, right: 0,
              child: Container(
                height: 200,
                decoration: const BoxDecoration(
                  color: _green,
                  borderRadius: BorderRadius.only(
                    bottomLeft: Radius.circular(48),
                    bottomRight: Radius.circular(48),
                  ),
                ),
                child: Stack(children: [
                  Positioned(top: -30, right: -30,
                    child: _circle(140, 0.07)),
                ]),
              ),
            ),

            SafeArea(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(left: 16, top: 8),
                    child: IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: Container(
                        width: 38, height: 38,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 16),
                      ),
                    ),
                  ),

                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 28),
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      const SizedBox(height: 4),
                      Text('Verify your number',
                        style: GoogleFonts.plusJakartaSans(fontSize: 24, fontWeight: FontWeight.w800, color: Colors.white)),
                      const SizedBox(height: 4),
                      Text('Code sent to ${_maskedPhone(phone)}',
                        style: GoogleFonts.plusJakartaSans(fontSize: 13, color: Colors.white.withOpacity(0.75))),
                    ]),
                  ),

                  const SizedBox(height: 48),

                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 28),
                    child: Column(
                      children: [
                        // OTP boxes with shake animation
                        AnimatedBuilder(
                          animation: shakeAnim,
                          builder: (context, child) {
                            final dx = shakeAnim.value < 0.5
                              ? -8 * (shakeAnim.value / 0.5)
                              : 8 * ((shakeAnim.value - 0.5) / 0.5) - 8;
                            return Transform.translate(offset: Offset(dx * 3, 0), child: child);
                          },
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: List.generate(6, (i) => _OTPBox(
                              controller: ctrls[i],
                              focusNode: focusNodes[i],
                              onChanged: (v) => onDigitInput(i, v),
                              onBackspace: () => onBackspace(i),
                            )),
                          ),
                        ),

                        const SizedBox(height: 40),

                        // Success check animation
                        ScaleTransition(
                          scale: successAnim,
                          child: Container(
                            width: 64, height: 64,
                            decoration: const BoxDecoration(color: _green, shape: BoxShape.circle),
                            child: const Icon(Icons.check_rounded, color: Colors.white, size: 32),
                          ),
                        ),

                        const SizedBox(height: 32),

                        // Submit button
                        BlocBuilder<AuthBloc, AuthState>(
                          builder: (context, state) {
                            final loading = state is AuthLoading;
                            return SizedBox(
                              width: double.infinity, height: 54,
                              child: ElevatedButton(
                                onPressed: loading ? null : onSubmit,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: _green,
                                  foregroundColor: Colors.white,
                                  disabledBackgroundColor: _green.withOpacity(0.6),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                  elevation: 0,
                                ),
                                child: loading
                                  ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5))
                                  : Text('Verify', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700, fontSize: 16)),
                              ),
                            );
                          },
                        ),

                        const SizedBox(height: 28),

                        // Resend
                        resendCooldown > 0
                          ? RichText(
                              text: TextSpan(
                                text: 'Resend code in ',
                                style: GoogleFonts.plusJakartaSans(color: _muted, fontSize: 14),
                                children: [
                                  TextSpan(
                                    text: '${resendCooldown}s',
                                    style: GoogleFonts.plusJakartaSans(color: _green, fontWeight: FontWeight.w700),
                                  ),
                                ],
                              ),
                            )
                          : GestureDetector(
                              onTap: onResend,
                              child: Text('Resend OTP',
                                style: GoogleFonts.plusJakartaSans(
                                  color: _green, fontWeight: FontWeight.w700, fontSize: 14,
                                  decoration: TextDecoration.underline,
                                )),
                            ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _circle(double size, double opacity) => Container(
    width: size, height: size,
    decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.white.withOpacity(opacity)),
  );
}

class _OTPBox extends StatelessWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final Function(String) onChanged;
  final VoidCallback onBackspace;

  const _OTPBox({
    required this.controller,
    required this.focusNode,
    required this.onChanged,
    required this.onBackspace,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 48, height: 56,
      child: RawKeyboardListener(
        focusNode: FocusNode(),
        onKey: (event) {
          if (event is RawKeyDownEvent &&
              event.logicalKey == LogicalKeyboardKey.backspace &&
              controller.text.isEmpty) {
            onBackspace();
          }
        },
        child: TextField(
          controller: controller,
          focusNode: focusNode,
          textAlign: TextAlign.center,
          keyboardType: TextInputType.number,
          maxLength: 1,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          style: GoogleFonts.plusJakartaSans(
            fontSize: 22, fontWeight: FontWeight.w800, color: const Color(0xff0d1b16)),
          decoration: InputDecoration(
            counterText: '',
            filled: true,
            fillColor: focusNode.hasFocus ? const Color(0xffe8f5f0) : const Color(0xfff5f5f5),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: Color(0xff0b845c), width: 2),
            ),
            contentPadding: EdgeInsets.zero,
          ),
          onChanged: onChanged,
        ),
      ),
    );
  }
}
