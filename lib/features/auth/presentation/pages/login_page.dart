import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import '../bloc/auth_bloc.dart';
import 'register_page.dart';
import 'otp_verification_page.dart';
import '../../../../features/wallet/presentation/pages/wallet_dashboard_page.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> with TickerProviderStateMixin {
  final _phoneCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  bool _obscurePassword = true;
  late AnimationController _fadeCtrl;
  late AnimationController _slideCtrl;
  late Animation<double> _fadeAnim;
  late Animation<Offset> _slideAnim;

  @override
  void initState() {
    super.initState();
    _fadeCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 700));
    _slideCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 600));
    _fadeAnim = CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeOut);
    _slideAnim = Tween<Offset>(begin: const Offset(0, 0.08), end: Offset.zero)
        .animate(CurvedAnimation(parent: _slideCtrl, curve: Curves.easeOutCubic));
    _fadeCtrl.forward();
    _slideCtrl.forward();
  }

  @override
  void dispose() {
    _phoneCtrl.dispose();
    _passwordCtrl.dispose();
    _fadeCtrl.dispose();
    _slideCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => AuthBloc(),
      child: _LoginView(
        phoneCtrl: _phoneCtrl,
        passwordCtrl: _passwordCtrl,
        obscurePassword: _obscurePassword,
        onToggleObscure: () => setState(() => _obscurePassword = !_obscurePassword),
        fadeAnim: _fadeAnim,
        slideAnim: _slideAnim,
      ),
    );
  }
}

class _LoginView extends StatelessWidget {
  final TextEditingController phoneCtrl;
  final TextEditingController passwordCtrl;
  final bool obscurePassword;
  final VoidCallback onToggleObscure;
  final Animation<double> fadeAnim;
  final Animation<Offset> slideAnim;

  const _LoginView({
    required this.phoneCtrl,
    required this.passwordCtrl,
    required this.obscurePassword,
    required this.onToggleObscure,
    required this.fadeAnim,
    required this.slideAnim,
  });

  static const _green = Color(0xff0b845c);
  static const _greenLight = Color(0xffe8f5f0);
  static const _ink = Color(0xff0d1b16);
  static const _muted = Color(0xff6b8078);

  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthBloc, AuthState>(
      listener: (context, state) {
        if (state is AuthLoginSuccess) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => const WalletDashboardPage()),
          );
        } else if (state is AuthFailure) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.message, style: TextStyle()),
              backgroundColor: Colors.red.shade700,
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
            // Decorative top arc
            Positioned(
              top: 0, left: 0, right: 0,
              child: Container(
                height: 260,
                decoration: const BoxDecoration(
                  color: _green,
                  borderRadius: BorderRadius.only(
                    bottomLeft: Radius.circular(48),
                    bottomRight: Radius.circular(48),
                  ),
                ),
                child: Stack(
                  children: [
                    // Subtle pattern circles
                    Positioned(top: -30, right: -30,
                      child: Container(width: 150, height: 150,
                        decoration: BoxDecoration(shape: BoxShape.circle,
                          border: Border.all(color: Colors.white.withValues(alpha: 0.08), width: 30)))),
                    Positioned(top: 60, right: 40,
                      child: Container(width: 70, height: 70,
                        decoration: BoxDecoration(shape: BoxShape.circle,
                          color: Colors.white.withValues(alpha: 0.06)))),
                    Positioned(bottom: 20, left: -20,
                      child: Container(width: 100, height: 100,
                        decoration: BoxDecoration(shape: BoxShape.circle,
                          border: Border.all(color: Colors.white.withValues(alpha: 0.06), width: 20)))),
                  ],
                ),
              ),
            ),

            SafeArea(
              child: FadeTransition(
                opacity: fadeAnim,
                child: SlideTransition(
                  position: slideAnim,
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 28),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 48),

                        // Logo / brand mark
                        Container(
                          width: 52, height: 52,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.12), blurRadius: 20, offset: const Offset(0, 4))],
                          ),
                          child: const Icon(Icons.bolt_rounded, color: _green, size: 30),
                        ),
                        const SizedBox(height: 20),

                        Text('Welcome back',
                          style: TextStyle(fontSize: 28, fontWeight: FontWeight.w800, color: Colors.white, height: 1.1)),
                        const SizedBox(height: 6),
                        Text('Sign in to your Flip Bills account',
                          style: TextStyle(fontSize: 14, color: Colors.white.withValues(alpha: 0.75))),

                        const SizedBox(height: 80),

                        // Card
                        Container(
                          padding: const EdgeInsets.all(28),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(24),
                            boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 40, offset: const Offset(0, 8))],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _label('Phone Number'),
                              const SizedBox(height: 8),
                              _phoneField(),
                              const SizedBox(height: 20),
                              _label('Password'),
                              const SizedBox(height: 8),
                              _passwordField(),
                              const SizedBox(height: 12),
                              Align(
                                alignment: Alignment.centerRight,
                                child: TextButton(
                                  onPressed: () {},
                                  style: TextButton.styleFrom(padding: EdgeInsets.zero, minimumSize: Size.zero),
                                  child: Text('Forgot password?',
                                    style: TextStyle(color: _green, fontWeight: FontWeight.w600, fontSize: 13)),
                                ),
                              ),
                              const SizedBox(height: 24),
                              _LoginButton(phoneCtrl: phoneCtrl, passwordCtrl: passwordCtrl),
                            ],
                          ),
                        ),

                        const SizedBox(height: 32),

                        // Divider
                        Row(children: [
                          Expanded(child: Divider(color: Colors.grey.shade200)),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            child: Text('or', style: TextStyle(color: _muted, fontSize: 13)),
                          ),
                          Expanded(child: Divider(color: Colors.grey.shade200)),
                        ]),

                        const SizedBox(height: 32),

                        // Register CTA
                        Center(
                          child: GestureDetector(
                            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const RegisterPage())),
                            child: RichText(
                              text: TextSpan(
                                text: "Don't have an account? ",
                                style: TextStyle(color: _muted, fontSize: 14),
                                children: [
                                  TextSpan(
                                    text: 'Create one',
                                    style: GoogleFonts.plusJakartaSans(
                                      color: _green, fontWeight: FontWeight.w700, fontSize: 14,
                                      decoration: TextDecoration.underline,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 40),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _label(String text) => Text(text,
    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: _ink));

  Widget _phoneField() => TextFormField(
    controller: phoneCtrl,
    keyboardType: TextInputType.phone,
    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
    style: TextStyle(fontSize: 15, fontWeight: FontWeight.w500, color: _ink),
    decoration: _inputDecoration(
      hint: '08012345678',
      prefixIcon: const Icon(Icons.phone_outlined, size: 20, color: _muted),
    ),
  );

  Widget _passwordField() => TextFormField(
    controller: passwordCtrl,
    obscureText: obscurePassword,
    style: TextStyle(fontSize: 15, fontWeight: FontWeight.w500, color: _ink),
    decoration: _inputDecoration(
      hint: '••••••••',
      prefixIcon: const Icon(Icons.lock_outline_rounded, size: 20, color: _muted),
      suffixIcon: GestureDetector(
        onTap: onToggleObscure,
        child: Icon(obscurePassword ? Icons.visibility_outlined : Icons.visibility_off_outlined, size: 20, color: _muted),
      ),
    ),
  );

  InputDecoration _inputDecoration({
    required String hint,
    Widget? prefixIcon,
    Widget? suffixIcon,
  }) => InputDecoration(
    hintText: hint,
    hintStyle: TextStyle(color: _muted, fontSize: 14),
    prefixIcon: prefixIcon,
    suffixIcon: suffixIcon != null ? Padding(padding: const EdgeInsets.only(right: 4), child: suffixIcon) : null,
    filled: true,
    fillColor: _greenLight,
    border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: const BorderSide(color: _green, width: 1.5),
    ),
    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
  );
}

class _LoginButton extends StatelessWidget {
  final TextEditingController phoneCtrl;
  final TextEditingController passwordCtrl;

  const _LoginButton({required this.phoneCtrl, required this.passwordCtrl});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, state) {
        final isLoading = state is AuthLoading;
        return SizedBox(
          width: double.infinity,
          height: 54,
          child: ElevatedButton(
            onPressed: isLoading ? null : () {
              final phone = phoneCtrl.text.trim();
              final pass = passwordCtrl.text.trim();
              if (phone.isEmpty || pass.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Please fill in all fields', style: TextStyle()),
                    backgroundColor: Colors.orange.shade700, behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                );
                return;
              }
              context.read<AuthBloc>().add(AuthLoginRequested(phone: phone, password: pass));
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xff0b845c),
              foregroundColor: Colors.white,
              disabledBackgroundColor: const Color(0xff0b845c).withValues(alpha: 0.6),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              elevation: 0,
            ),
            child: isLoading
              ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5))
              : Text('Sign In', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
          ),
        );
      },
    );
  }
}
