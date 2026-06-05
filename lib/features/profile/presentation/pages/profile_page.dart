import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../data/repositories/profile_repository.dart';

class ProfilePage extends StatefulWidget {
  final String? seedFirstName;
  final String? seedLastName;
  final String? seedPhone;
  final String? seedDob;

  const ProfilePage({
    super.key,
    this.seedFirstName,
    this.seedLastName,
    this.seedPhone,
    this.seedDob,
  });

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  static const _brand = Color(0xff0b845c);
  static const _surface = Color(0xfff4f6f5);

  final _repo = ProfileRepository();
  final _formKey = GlobalKey<FormState>();

  final _firstNameCtrl = TextEditingController();
  final _lastNameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();

  bool _loading = true;
  bool _saving = false;
  bool _edited = false;

  Map<String, dynamic>? _profile;

  @override
  void initState() {
    super.initState();
    _fetchProfile();
    _firstNameCtrl.addListener(_onChanged);
    _lastNameCtrl.addListener(_onChanged);
    _emailCtrl.addListener(_onChanged);
  }

  @override
  void dispose() {
    _firstNameCtrl.dispose();
    _lastNameCtrl.dispose();
    _emailCtrl.dispose();
    super.dispose();
  }

  void _onChanged() {
    if (!_edited) setState(() => _edited = true);
  }

  Future<void> _fetchProfile() async {
    // Pre-fill with seed data immediately so screen isn't blank
    _firstNameCtrl.text = widget.seedFirstName ?? '';
    _lastNameCtrl.text  = widget.seedLastName  ?? '';
    setState(() => _loading = true);

    final data = await _repo.getProfile();
    if (!mounted) return;
    if (data != null) {
      _profile = data;
      _firstNameCtrl.text = data['first_name']?.toString().isNotEmpty == true
          ? data['first_name'].toString()
          : (widget.seedFirstName ?? '');
      _lastNameCtrl.text  = data['last_name']?.toString().isNotEmpty == true
          ? data['last_name'].toString()
          : (widget.seedLastName  ?? '');
      _emailCtrl.text     = data['email']?.toString() ?? '';
    } else {
      // API unavailable — fall back entirely to seed data
      _firstNameCtrl.text = widget.seedFirstName ?? '';
      _lastNameCtrl.text  = widget.seedLastName  ?? '';
    }
    setState(() {
      _loading = false;
      _edited  = false;
    });
  }

  Future<void> _saveProfile() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() => _saving = true);

    final result = await _repo.updateProfile(
      firstName: _firstNameCtrl.text.trim(),
      lastName: _lastNameCtrl.text.trim(),
      email: _emailCtrl.text.trim().isEmpty ? null : _emailCtrl.text.trim(),
    );

    if (!mounted) return;
    setState(() {
      _saving = false;
      if (result['success'] == true) _edited = false;
    });

    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(
        result['message'] as String,
        style: const TextStyle(color: Colors.white),
      ),
      backgroundColor:
          result['success'] == true ? _brand : Colors.red.shade700,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final phone = _profile?['phone']?.toString().isNotEmpty == true
        ? _profile!['phone'].toString()
        : (widget.seedPhone ?? '');
    final dob = _profile?['date_of_birth']?.toString().isNotEmpty == true
        ? _profile!['date_of_birth'].toString()
        : (widget.seedDob ?? '');
    final tier = _profile?['tier']?.toString() ?? 'basic';
    final initials = _initials();

    return Scaffold(
      backgroundColor: _surface,
      appBar: AppBar(
        backgroundColor: _brand,
        systemOverlayStyle: SystemUiOverlayStyle.light,
        title: Text(
          'My Profile',
          style: GoogleFonts.plusJakartaSans(
            fontWeight: FontWeight.w700,
            fontSize: 18,
            color: Colors.white,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          if (_edited && !_loading)
            TextButton(
              onPressed: _saving ? null : _saveProfile,
              child: _saving
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white),
                    )
                  : Text(
                      'Save',
                      style: GoogleFonts.plusJakartaSans(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                      ),
                    ),
            ),
        ],
      ),
      body: _loading
          ? const Center(
              child: CircularProgressIndicator(color: _brand))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    const SizedBox(height: 12),
                    // Avatar
                    Center(
                      child: Stack(
                        children: [
                          CircleAvatar(
                            radius: 46,
                            backgroundColor: _brand.withValues(alpha: 0.15),
                            child: Text(
                              initials,
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 28,
                                fontWeight: FontWeight.w800,
                                color: _brand,
                              ),
                            ),
                          ),
                          Positioned(
                            bottom: 0,
                            right: 0,
                            child: Container(
                              width: 30,
                              height: 30,
                              decoration: BoxDecoration(
                                color: _brand,
                                shape: BoxShape.circle,
                                border: Border.all(color: Colors.white, width: 2),
                              ),
                              child: const Icon(Icons.edit_rounded,
                                  color: Colors.white, size: 14),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 10),
                    // Tier badge
                    _TierChip(tier: tier),
                    const SizedBox(height: 28),
                    // Phone (read-only)
                    _SectionLabel(label: 'Phone Number'),
                    const SizedBox(height: 8),
                    _ReadOnlyField(
                      value: phone.isEmpty ? 'Not set' : phone,
                      icon: Icons.phone_outlined,
                      hint: 'Phone cannot be changed',
                    ),
                    const SizedBox(height: 20),
                    // Date of Birth (read-only)
                    _SectionLabel(label: 'Date of Birth'),
                    const SizedBox(height: 8),
                    _ReadOnlyField(
                      value: dob.isEmpty ? 'Not set' : _formatDob(dob),
                      icon: Icons.cake_outlined,
                      hint: 'Cannot be changed',
                    ),
                    const SizedBox(height: 20),
                    // First name
                    _SectionLabel(label: 'First Name'),
                    const SizedBox(height: 8),
                    _InputField(
                      controller: _firstNameCtrl,
                      hint: 'Enter first name',
                      icon: Icons.person_outline_rounded,
                      validator: (v) =>
                          (v == null || v.trim().isEmpty) ? 'First name is required' : null,
                    ),
                    const SizedBox(height: 20),
                    // Last name
                    _SectionLabel(label: 'Last Name'),
                    const SizedBox(height: 8),
                    _InputField(
                      controller: _lastNameCtrl,
                      hint: 'Enter last name',
                      icon: Icons.person_outline_rounded,
                      validator: (v) =>
                          (v == null || v.trim().isEmpty) ? 'Last name is required' : null,
                    ),
                    const SizedBox(height: 20),
                    // Email
                    _SectionLabel(label: 'Email Address (Optional)'),
                    const SizedBox(height: 8),
                    _InputField(
                      controller: _emailCtrl,
                      hint: 'Enter email address',
                      icon: Icons.email_outlined,
                      keyboardType: TextInputType.emailAddress,
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) return null;
                        final emailRegex = RegExp(r'^[^@]+@[^@]+\.[^@]+$');
                        if (!emailRegex.hasMatch(v.trim())) {
                          return 'Enter a valid email';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 32),
                    if (_edited)
                      SizedBox(
                        width: double.infinity,
                        height: 52,
                        child: ElevatedButton(
                          onPressed: _saving ? null : _saveProfile,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _brand,
                            foregroundColor: Colors.white,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                          child: _saving
                              ? const SizedBox(
                                  width: 22,
                                  height: 22,
                                  child: CircularProgressIndicator(
                                      strokeWidth: 2, color: Colors.white),
                                )
                              : Text(
                                  'Save Changes',
                                  style: GoogleFonts.plusJakartaSans(
                                    fontWeight: FontWeight.w700,
                                    fontSize: 16,
                                  ),
                                ),
                        ),
                      ),
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
    );
  }

  String _formatDob(String raw) {
    // Accept yyyy-MM-dd or dd/MM/yyyy
    try {
      if (raw.contains('-')) {
        final parts = raw.split('-');
        if (parts.length == 3) {
          return '${parts[2].padLeft(2, '0')}/${parts[1].padLeft(2, '0')}/${parts[0]}';
        }
      }
    } catch (_) {}
    return raw;
  }

  String _initials() {
    final first = _firstNameCtrl.text.isNotEmpty
        ? _firstNameCtrl.text[0].toUpperCase()
        : '';
    final last = _lastNameCtrl.text.isNotEmpty
        ? _lastNameCtrl.text[0].toUpperCase()
        : '';
    if (first.isEmpty && last.isEmpty) return '?';
    return '$first$last';
  }
}

// ─── Sub-widgets ──────────────────────────────────────────────────────────────

class _SectionLabel extends StatelessWidget {
  final String label;
  const _SectionLabel({required this.label});

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Text(
        label,
        style: GoogleFonts.plusJakartaSans(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: Colors.grey.shade500,
          letterSpacing: 0.4,
        ),
      ),
    );
  }
}

class _ReadOnlyField extends StatelessWidget {
  final String value;
  final IconData icon;
  final String hint;
  const _ReadOnlyField(
      {required this.value, required this.icon, required this.hint});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          Icon(icon, color: Colors.grey.shade400, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              value,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 14,
                color: Colors.grey.shade500,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Icon(Icons.lock_outline_rounded,
              size: 16, color: Colors.grey.shade400),
        ],
      ),
    );
  }
}

class _InputField extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final IconData icon;
  final TextInputType keyboardType;
  final String? Function(String?)? validator;
  const _InputField({
    required this.controller,
    required this.hint,
    required this.icon,
    this.keyboardType = TextInputType.text,
    this.validator,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      validator: validator,
      style: GoogleFonts.plusJakartaSans(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: const Color(0xff1a1a1a),
      ),
      decoration: InputDecoration(
        prefixIcon: Icon(icon, size: 20, color: Colors.grey.shade500),
        hintText: hint,
        hintStyle: GoogleFonts.plusJakartaSans(
          color: Colors.grey.shade400,
          fontSize: 14,
        ),
        filled: true,
        fillColor: Colors.white,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: Colors.grey.shade200),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: Colors.grey.shade200),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide:
              const BorderSide(color: Color(0xff0b845c), width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: Colors.red.shade400),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: Colors.red.shade400, width: 1.5),
        ),
      ),
    );
  }
}

class _TierChip extends StatelessWidget {
  final String tier;
  const _TierChip({required this.tier});

  @override
  Widget build(BuildContext context) {
    final isPremium = tier == 'premium';
    final isStandard = tier == 'standard';
    final label = isPremium
        ? '⭐ Premium'
        : isStandard
            ? '✦ Standard'
            : 'Basic';
    final color = isPremium
        ? const Color(0xfff39c12)
        : isStandard
            ? const Color(0xff8e44ad)
            : const Color(0xff0b845c);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(
        label,
        style: GoogleFonts.plusJakartaSans(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
