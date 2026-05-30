import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import '../bloc/auth_bloc.dart';
import 'otp_verification_page.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> with TickerProviderStateMixin {
  final _firstNameCtrl = TextEditingController();
  final _lastNameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  bool _obscurePassword = true;
  int _currentStep = 0; // 0 = personal info, 1 = credentials
  late AnimationController _fadeCtrl;
  late Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _fadeCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 500));
    _fadeAnim = CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeOut);
    _fadeCtrl.forward();
  }

  @override
  void dispose() {
    _firstNameCtrl.dispose();
    _lastNameCtrl.dispose();
    _phoneCtrl.dispose();
    _passwordCtrl.dispose();
    _fadeCtrl.dispose();
    super.dispose();
  }

  void _nextStep() {
    if (_currentStep == 0) {
      if (_firstNameCtrl.text.trim().isEmpty || _lastNameCtrl.text.trim().isEmpty) {
        _showError('Please enter your full name.');
        return;
      }
      _fadeCtrl.reset();
      setState(() => _currentStep = 1);
      _fadeCtrl.forward();
    }
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg, style: GoogleFonts.plusJakartaSans()),
        backgroundColor: Colors.orange.shade700,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => AuthBloc(),
      child: BlocListener<AuthBloc, AuthState>(
        listener: (context, state) {
          if (state is AuthRegisterSuccess) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (_) => OTPVerificationPage(phone: state.phone, isPostRegister: true),
              ),
            );
          } else if (state is AuthFailure) {
            _showError(state.message);
          }
        },
        child: Scaffold(
          backgroundColor: Colors.white,
          body: Stack(
            children: [
              // Green top header
              Positioned(
                top: 0, left: 0, right: 0,
                child: Container(
                  height: 220,
                  decoration: const BoxDecoration(
                    color: Color(0xff0b845c),
                    borderRadius: BorderRadius.only(
                      bottomLeft: Radius.circular(48),
                      bottomRight: Radius.circular(48),
                    ),
                  ),
                  child: Stack(children: [
                    Positioned(top: -40, right: -40, child: _circle(160, 0.07)),
                    Positioned(bottom: 0, left: -20, child: _circle(90, 0.05)),
                  ]),
                ),
              ),

              SafeArea(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Back button
                    Padding(
                      padding: const EdgeInsets.only(left: 16, top: 8),
                      child: IconButton(
                        onPressed: () {
                          if (_currentStep == 1) {
                            _fadeCtrl.reset();
                            setState(() => _currentStep = 0);
                            _fadeCtrl.forward();
                          } else {
                            Navigator.pop(context);
                          }
                        },
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
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 8),
                          Text(_currentStep == 0 ? 'Create account' : 'Almost done',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 26, fontWeight: FontWeight.w800, color: Colors.white)),
                          const SizedBox(height: 4),
                          Text(_currentStep == 0 ? 'Start with your name' : 'Set your login details',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 13, color: Colors.white.withOpacity(0.75))),
                        ],
                      ),
                    ),

                    const SizedBox(height: 28),

                    // Step indicator
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 28),
                      child: Row(
                        children: [
                          _stepDot(0),
                          Container(margin: const EdgeInsets.symmetric(horizontal: 6),
                            width: 32, height: 2,
                            color: _currentStep >= 1 ? const Color(0xff0b845c) : Colors.grey.shade200),
                          _stepDot(1),
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Scrollable form
                    Expanded(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.symmetric(horizontal: 28),
                        child: FadeTransition(
                          opacity: _fadeAnim,
                          child: _currentStep == 0 ? _buildStep0() : _buildStep1(),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _stepDot(int step) {
    final isActive = _currentStep >= step;
    return Container(
      width: 28, height: 28,
      decoration: BoxDecoration(
        color: isActive ? const Color(0xff0b845c) : Colors.grey.shade200,
        shape: BoxShape.circle,
      ),
      child: Center(
        child: isActive && _currentStep > step
          ? const Icon(Icons.check_rounded, color: Colors.white, size: 14)
          : Text('${step + 1}',
              style: GoogleFonts.plusJakartaSans(
                color: isActive ? Colors.white : Colors.grey.shade400,
                fontSize: 12, fontWeight: FontWeight.w700)),
      ),
    );
  }

  Widget _buildStep0() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _label('First Name'),
        const SizedBox(height: 8),
        _textField(controller: _firstNameCtrl, hint: 'Ade', icon: Icons.person_outline_rounded),
        const SizedBox(height: 20),
        _label('Last Name'),
        const SizedBox(height: 8),
        _textField(controller: _lastNameCtrl, hint: 'Okafor', icon: Icons.person_outline_rounded),
        const SizedBox(height: 32),
        _nextButton(),
        const SizedBox(height: 32),
      ],
    );
  }

  Widget _buildStep1() {
    return Builder(builder: (context) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _label('Phone Number'),
          const SizedBox(height: 8),
          _textField(
            controller: _phoneCtrl,
            hint: '08012345678',
            icon: Icons.phone_outlined,
            keyboardType: TextInputType.phone,
            formatters: [FilteringTextInputFormatter.digitsOnly],
          ),
          const SizedBox(height: 20),
          _label('Password'),
          const SizedBox(height: 8),
          TextFormField(
            controller: _passwordCtrl,
            obscureText: _obscurePassword,
            style: GoogleFonts.plusJakartaSans(fontSize: 15, fontWeight: FontWeight.w500, color: const Color(0xff0d1b16)),
            decoration: _inputDeco(
              hint: '••••••••',
              icon: Icons.lock_outline_rounded,
              suffix: GestureDetector(
                onTap: () => setState(() => _obscurePassword = !_obscurePassword),
                child: Icon(
                  _obscurePassword ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                  size: 20, color: const Color(0xff6b8078),
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text('Minimum 8 characters',
            style: GoogleFonts.plusJakartaSans(fontSize: 12, color: const Color(0xff6b8078))),
          const SizedBox(height: 32),
          BlocBuilder<AuthBloc, AuthState>(
            builder: (context, state) {
              final loading = state is AuthLoading;
              return SizedBox(
                width: double.infinity, height: 54,
                child: ElevatedButton(
                  onPressed: loading ? null : () {
                    final phone = _phoneCtrl.text.trim();
                    final pass = _passwordCtrl.text.trim();
                    if (phone.isEmpty || pass.isEmpty) { _showError('Fill all fields.'); return; }
                    if (pass.length < 8) { _showError('Password must be at least 8 characters.'); return; }
                    context.read<AuthBloc>().add(AuthRegisterRequested(
                      phone: phone, password: pass,
                      firstName: _firstNameCtrl.text.trim(),
                      lastName: _lastNameCtrl.text.trim(),
                    ));
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xff0b845c),
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: const Color(0xff0b845c).withOpacity(0.6),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    elevation: 0,
                  ),
                  child: loading
                    ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5))
                    : Text('Create Account', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700, fontSize: 16)),
                ),
              );
            },
          ),
          const SizedBox(height: 40),
        ],
      );
    });
  }

  Widget _nextButton() => SizedBox(
    width: double.infinity, height: 54,
    child: ElevatedButton(
      onPressed: _nextStep,
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xff0b845c),
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        elevation: 0,
      ),
      child: Text('Continue', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700, fontSize: 16)),
    ),
  );

  Widget _label(String text) => Text(text,
    style: GoogleFonts.plusJakartaSans(fontSize: 13, fontWeight: FontWeight.w600, color: const Color(0xff0d1b16)));

  Widget _textField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    TextInputType? keyboardType,
    List<TextInputFormatter>? formatters,
  }) => TextFormField(
    controller: controller,
    keyboardType: keyboardType,
    inputFormatters: formatters,
    style: GoogleFonts.plusJakartaSans(fontSize: 15, fontWeight: FontWeight.w500, color: const Color(0xff0d1b16)),
    decoration: _inputDeco(hint: hint, icon: icon),
  );

  InputDecoration _inputDeco({required String hint, required IconData icon, Widget? suffix}) => InputDecoration(
    hintText: hint,
    hintStyle: GoogleFonts.plusJakartaSans(color: const Color(0xff6b8078), fontSize: 14),
    prefixIcon: Icon(icon, size: 20, color: const Color(0xff6b8078)),
    suffixIcon: suffix != null ? Padding(padding: const EdgeInsets.only(right: 4), child: suffix) : null,
    filled: true,
    fillColor: const Color(0xffe8f5f0),
    border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: const BorderSide(color: Color(0xff0b845c), width: 1.5),
    ),
    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
  );

  Widget _circle(double size, double opacity) => Container(
    width: size, height: size,
    decoration: BoxDecoration(shape: BoxShape.circle,
      color: Colors.white.withOpacity(opacity)),
  );
}
