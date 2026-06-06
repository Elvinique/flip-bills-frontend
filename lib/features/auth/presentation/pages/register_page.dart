import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import '../bloc/auth_bloc.dart';
import '../../../../features/wallet/presentation/pages/wallet_dashboard_page.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _firstNameCtrl = TextEditingController();
  final _lastNameCtrl  = TextEditingController();
  final _dobCtrl       = TextEditingController();
  final _phoneCtrl     = TextEditingController();
  final _passwordCtrl  = TextEditingController();
  final _confirmCtrl   = TextEditingController();

  bool _obscurePassword = true;
  bool _obscureConfirm  = true;
  int _currentStep = 0;
  DateTime? _selectedDob;

  late AnimationController _fadeCtrl;
  late Animation<double> _fadeAnim;

  static const _green      = Color(0xff0b845c);
  static const _greenLight = Color(0xffe8f5f0);
  static const _ink        = Color(0xff0d1b16);
  static const _muted      = Color(0xff6b8078);

  @override
  void initState() {
    super.initState();
    _fadeCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 400));
    _fadeAnim = CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeOut);
    _fadeCtrl.forward();
  }

  @override
  void dispose() {
    _firstNameCtrl.dispose();
    _lastNameCtrl.dispose();
    _dobCtrl.dispose();
    _phoneCtrl.dispose();
    _passwordCtrl.dispose();
    _confirmCtrl.dispose();
    _fadeCtrl.dispose();
    super.dispose();
  }

  void _goToStep(int step) {
    _fadeCtrl.reset();
    setState(() => _currentStep = step);
    _fadeCtrl.forward();
  }

  void _nextStep() {
    final first = _firstNameCtrl.text.trim();
    final last  = _lastNameCtrl.text.trim();
    if (first.isEmpty || last.isEmpty) {
      _showSnack('Please enter your full name.', isError: true); return;
    }
    if (first.length < 2 || last.length < 2) {
      _showSnack('Name must be at least 2 characters.', isError: true); return;
    }
    if (_selectedDob == null) {
      _showSnack('Please select your date of birth.', isError: true); return;
    }
    _goToStep(1);
  }

  Future<void> _pickDob() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDob ?? DateTime(now.year - 18, now.month, now.day),
      firstDate: DateTime(1920),
      lastDate: DateTime(now.year - 13, now.month, now.day),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: const ColorScheme.light(
            primary: _green,
            onPrimary: Colors.white,
            surface: Colors.white,
          ),
        ),
        child: child!,
      ),
    );
    if (picked != null) {
      setState(() {
        _selectedDob = picked;
        _dobCtrl.text =
            '${picked.day.toString().padLeft(2, '0')}/${picked.month.toString().padLeft(2, '0')}/${picked.year}';
      });
    }
  }

  void _showSnack(String msg, {bool isError = false}) {
    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(SnackBar(
        content: Text(msg,
            style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w500)),
        backgroundColor: isError ? Colors.red.shade700 : _green,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ));
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => AuthBloc(),
      child: BlocListener<AuthBloc, AuthState>(
        listener: (context, state) {
          if (state is AuthRegisterSuccess) {
            Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(
                builder: (_) => WalletDashboardPage(
                  initialFirstName: state.firstName,
                  initialLastName: state.lastName,
                  initialPhone: state.phone,
                  initialDob: state.dateOfBirth,
                ),
              ),
              (_) => false,
            );
          } else if (state is AuthFailure) {
            _showSnack(state.message, isError: true);
          }
        },
        child: Scaffold(
          backgroundColor: Colors.white,
          body: Stack(
            children: [
              // Green header
              Positioned(
                top: 0, left: 0, right: 0,
                child: Container(
                  height: 220,
                  decoration: const BoxDecoration(
                    color: _green,
                    borderRadius: BorderRadius.only(
                      bottomLeft: Radius.circular(48),
                      bottomRight: Radius.circular(48),
                    ),
                  ),
                  child: Stack(children: [
                    Positioned(top: -40, right: -40, child: _circle(160, 0.07)),
                    Positioned(bottom: 0,  left: -20, child: _circle(90,  0.05)),
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
                            _goToStep(0);
                          } else {
                            Navigator.pop(context);
                          }
                        },
                        icon: Container(
                          width: 38, height: 38,
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(Icons.arrow_back_ios_new_rounded,
                              color: Colors.white, size: 16),
                        ),
                      ),
                    ),

                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 28),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 4),
                          AnimatedSwitcher(
                            duration: const Duration(milliseconds: 300),
                            child: Text(
                              _currentStep == 0 ? 'Create Account' : 'Almost Done',
                              key: ValueKey(_currentStep),
                              style: GoogleFonts.plusJakartaSans(
                                  fontSize: 26,
                                  fontWeight: FontWeight.w800,
                                  color: Colors.white),
                            ),
                          ),
                          const SizedBox(height: 4),
                          AnimatedSwitcher(
                            duration: const Duration(milliseconds: 300),
                            child: Text(
                              _currentStep == 0
                                  ? 'Enter your personal details'
                                  : 'Set your phone & password',
                              key: ValueKey('sub$_currentStep'),
                              style: GoogleFonts.plusJakartaSans(
                                  fontSize: 13,
                                  color: Colors.white.withValues(alpha: 0.75)),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Step indicator
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 28),
                      child: Row(
                        children: [
                          _stepDot(0),
                          Container(
                            margin: const EdgeInsets.symmetric(horizontal: 6),
                            width: 32, height: 2,
                            color: _currentStep >= 1
                                ? _green
                                : Colors.grey.shade200,
                          ),
                          _stepDot(1),
                        ],
                      ),
                    ),

                    const SizedBox(height: 20),

                    Expanded(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.symmetric(horizontal: 28),
                        child: FadeTransition(
                          opacity: _fadeAnim,
                          child: Form(
                            key: _formKey,
                            child: _currentStep == 0
                                ? _buildStep0()
                                : _buildStep1(),
                          ),
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
        color: isActive ? _green : Colors.grey.shade200,
        shape: BoxShape.circle,
      ),
      child: Center(
        child: isActive && _currentStep > step
            ? const Icon(Icons.check_rounded, color: Colors.white, size: 14)
            : Text('${step + 1}',
                style: GoogleFonts.plusJakartaSans(
                    color: isActive ? Colors.white : Colors.grey.shade400,
                    fontSize: 12,
                    fontWeight: FontWeight.w700)),
      ),
    );
  }

  // ── Step 0: Name + Date of Birth ──────────────────────────────────────────
  Widget _buildStep0() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 8),
        _label('First Name'),
        const SizedBox(height: 8),
        _textField(
            controller: _firstNameCtrl,
            hint: 'Ade',
            icon: Icons.person_outline_rounded,
            textCapitalization: TextCapitalization.words),
        const SizedBox(height: 20),
        _label('Last Name'),
        const SizedBox(height: 8),
        _textField(
            controller: _lastNameCtrl,
            hint: 'Okafor',
            icon: Icons.person_outline_rounded,
            textCapitalization: TextCapitalization.words),
        const SizedBox(height: 20),
        _label('Date of Birth'),
        const SizedBox(height: 8),
        GestureDetector(
          onTap: _pickDob,
          child: AbsorbPointer(
            child: TextFormField(
              controller: _dobCtrl,
              style: GoogleFonts.plusJakartaSans(
                  fontSize: 15, fontWeight: FontWeight.w500, color: _ink),
              decoration: _inputDeco(
                hint: 'DD/MM/YYYY',
                icon: Icons.cake_outlined,
                suffix: const Icon(Icons.calendar_today_outlined,
                    size: 18, color: _muted),
              ),
            ),
          ),
        ),
        const SizedBox(height: 32),
        _continueButton(),
        const SizedBox(height: 32),
      ],
    );
  }

  // ── Step 1: Phone + password + confirm ────────────────────────────────────
  Widget _buildStep1() {
    return Builder(builder: (context) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 8),
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
            keyboardType: TextInputType.visiblePassword,
            style: GoogleFonts.plusJakartaSans(
                fontSize: 15,
                fontWeight: FontWeight.w500,
                color: _ink),
            decoration: _inputDeco(
              hint: 'At least 8 characters',
              icon: Icons.lock_outline_rounded,
              suffix: GestureDetector(
                onTap: () =>
                    setState(() => _obscurePassword = !_obscurePassword),
                child: Icon(
                  _obscurePassword
                      ? Icons.visibility_outlined
                      : Icons.visibility_off_outlined,
                  size: 20, color: _muted,
                ),
              ),
            ),
          ),
          const SizedBox(height: 20),
          _label('Confirm Password'),
          const SizedBox(height: 8),
          TextFormField(
            controller: _confirmCtrl,
            obscureText: _obscureConfirm,
            keyboardType: TextInputType.visiblePassword,
            style: GoogleFonts.plusJakartaSans(
                fontSize: 15,
                fontWeight: FontWeight.w500,
                color: _ink),
            decoration: _inputDeco(
              hint: 'Re-enter password',
              icon: Icons.lock_outline_rounded,
              suffix: GestureDetector(
                onTap: () =>
                    setState(() => _obscureConfirm = !_obscureConfirm),
                child: Icon(
                  _obscureConfirm
                      ? Icons.visibility_outlined
                      : Icons.visibility_off_outlined,
                  size: 20, color: _muted,
                ),
              ),
            ),
          ),
          const SizedBox(height: 32),
          BlocBuilder<AuthBloc, AuthState>(
            builder: (context, state) {
              final loading = state is AuthLoading;
              return SizedBox(
                width: double.infinity, height: 54,
                child: ElevatedButton(
                  onPressed:
                      loading ? null : () => _submitRegistration(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _green,
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: _green.withValues(alpha: 0.6),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16)),
                    elevation: 0,
                  ),
                  child: loading
                      ? const SizedBox(
                          width: 22, height: 22,
                          child: CircularProgressIndicator(
                              color: Colors.white, strokeWidth: 2.5))
                      : Text('Create Account',
                          style: GoogleFonts.plusJakartaSans(
                              fontWeight: FontWeight.w700, fontSize: 16)),
                ),
              );
            },
          ),
          const SizedBox(height: 40),
        ],
      );
    });
  }

  void _submitRegistration(BuildContext context) {
    final phone = _phoneCtrl.text.trim();
    final pass  = _passwordCtrl.text;
    final conf  = _confirmCtrl.text;

    if (phone.isEmpty) {
      _showSnack('Please enter your phone number.', isError: true); return;
    }
    if (phone.length < 10 || phone.length > 11) {
      _showSnack('Enter a valid Nigerian phone number (10 or 11 digits).', isError: true); return;
    }
    if (pass.length < 8) {
      _showSnack('Password must be at least 8 characters.', isError: true); return;
    }
    if (conf.length < 8) {
      _showSnack('Please confirm your password.', isError: true); return;
    }
    if (pass != conf) {
      _showSnack('Passwords do not match.', isError: true); return;
    }
    if (_selectedDob == null) {
      _showSnack('Please select your date of birth.', isError: true); return;
    }

    final dobStr =
        '${_selectedDob!.year}-${_selectedDob!.month.toString().padLeft(2, '0')}-${_selectedDob!.day.toString().padLeft(2, '0')}';

    context.read<AuthBloc>().add(AuthRegisterRequested(
      phone: phone,
      password: pass,
      firstName: _firstNameCtrl.text.trim(),
      lastName: _lastNameCtrl.text.trim(),
      dateOfBirth: dobStr,
    ));
  }

  Widget _continueButton() => SizedBox(
    width: double.infinity, height: 54,
    child: ElevatedButton(
      onPressed: _nextStep,
      style: ElevatedButton.styleFrom(
        backgroundColor: _green,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        elevation: 0,
      ),
      child: Text('Continue',
          style: GoogleFonts.plusJakartaSans(
              fontWeight: FontWeight.w700, fontSize: 16)),
    ),
  );

  Widget _label(String text) => Text(text,
      style: GoogleFonts.plusJakartaSans(
          fontSize: 13, fontWeight: FontWeight.w600, color: _ink));

  Widget _textField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    TextInputType? keyboardType,
    List<TextInputFormatter>? formatters,
    TextCapitalization textCapitalization = TextCapitalization.none,
  }) =>
      TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        inputFormatters: formatters,
        textCapitalization: textCapitalization,
        style: GoogleFonts.plusJakartaSans(
            fontSize: 15, fontWeight: FontWeight.w500, color: _ink),
        decoration: _inputDeco(hint: hint, icon: icon),
      );

  InputDecoration _inputDeco(
          {required String hint, required IconData icon, Widget? suffix}) =>
      InputDecoration(
        hintText: hint,
        hintStyle: GoogleFonts.plusJakartaSans(color: _muted, fontSize: 14),
        prefixIcon: Icon(icon, size: 20, color: _muted),
        suffixIcon: suffix != null
            ? Padding(
                padding: const EdgeInsets.only(right: 12), child: suffix)
            : null,
        suffixIconConstraints:
            const BoxConstraints(minWidth: 40, minHeight: 40),
        filled: true,
        fillColor: _greenLight,
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide.none),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: _green, width: 1.5),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      );

  Widget _circle(double size, double opacity) => Container(
        width: size, height: size,
        decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.white.withValues(alpha: opacity)),
      );
}