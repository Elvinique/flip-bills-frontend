import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import '../bloc/vas_bloc.dart';
import '../widgets/vas_result_sheet.dart';

// ─── DisCo data model ─────────────────────────────────────────────────────────

class _Disco {
  final String code;
  final String name;
  final String shortName;
  final String region;
  final String asset; // assets/images/<asset>.png
  final Color accent;

  const _Disco({
    required this.code,
    required this.name,
    required this.shortName,
    required this.region,
    required this.asset,
    required this.accent,
  });
}

const _discos = <_Disco>[
  _Disco(
    code: 'IKEDC',
    name: 'Ikeja Electric',
    shortName: 'Ikeja',
    region: 'Lagos (North)',
    asset: 'ikedc',
    accent: Color(0xff1565c0),
  ),
  _Disco(
    code: 'EKEDC',
    name: 'Eko Electricity',
    shortName: 'Eko',
    region: 'Lagos (Island)',
    asset: 'ekedc',
    accent: Color(0xff00838f),
  ),
  _Disco(
    code: 'AEDC',
    name: 'Abuja Electricity',
    shortName: 'AEDC',
    region: 'Abuja & North',
    asset: 'aedc',
    accent: Color(0xff2e7d32),
  ),
  _Disco(
    code: 'PHED',
    name: 'Port Harcourt Elec.',
    shortName: 'PHED',
    region: 'South-South',
    asset: 'phed',
    accent: Color(0xffe65100),
  ),
  _Disco(
    code: 'KEDCO',
    name: 'Kano Electricity',
    shortName: 'KEDCO',
    region: 'North-West',
    asset: 'kedco',
    accent: Color(0xff6a1b9a),
  ),
  _Disco(
    code: 'IBEDC',
    name: 'Ibadan Electricity',
    shortName: 'IBEDC',
    region: 'South-West',
    asset: 'ibedc',
    accent: Color(0xfff57f17),
  ),
  _Disco(
    code: 'BEDC',
    name: 'Benin Electricity',
    shortName: 'BEDC',
    region: 'South-South',
    asset: 'bedc',
    accent: Color(0xffb71c1c),
  ),
  _Disco(
    code: 'EEDC',
    name: 'Enugu Electricity',
    shortName: 'EEDC',
    region: 'South-East',
    asset: 'eedc',
    accent: Color(0xff283593),
  ),
];

// ─── Page ─────────────────────────────────────────────────────────────────────

class ElectricityPage extends StatefulWidget {
  final List<Map<String, dynamic>> discos;
  const ElectricityPage({super.key, required this.discos});

  @override
  State<ElectricityPage> createState() => _ElectricityPageState();
}

class _ElectricityPageState extends State<ElectricityPage> {
  final _meterCtrl  = TextEditingController();
  final _amountCtrl = TextEditingController();
  final _pinCtrl    = TextEditingController();

  String? _selectedCode;
  String  _meterType = 'prepaid';
  bool    _obscurePin = true;

  static const _brand   = Color(0xff0b845c);
  static const _amounts = [1000, 2000, 5000, 10000, 20000, 50000];

  _Disco? get _selectedDisco =>
      _discos.where((d) => d.code == _selectedCode).firstOrNull;

  @override
  void initState() {
    super.initState();
    // Default to first disco passed from caller, or first in our list
    if (widget.discos.isNotEmpty) {
      _selectedCode = widget.discos.first['code'] as String?;
    }
    _selectedCode ??= _discos.first.code;
  }

  @override
  void dispose() {
    _meterCtrl.dispose();
    _amountCtrl.dispose();
    _pinCtrl.dispose();
    super.dispose();
  }

  void _submit() {
    final meter       = _meterCtrl.text.trim();
    final amountText  = _amountCtrl.text.trim().replaceAll(',', '');
    final amount      = int.tryParse(amountText);
    final pin         = _pinCtrl.text.trim();

    if (meter.length < 10) {
      _err('Enter a valid meter number (at least 10 digits).');
      return;
    }
    if (amount == null || amount < 500) {
      _err('Minimum electricity payment is ₦500.');
      return;
    }
    if (_selectedCode == null) {
      _err('Please select your distribution company.');
      return;
    }
    if (pin.length != 6) {
      _err('Enter your 6-digit transaction PIN.');
      return;
    }

    context.read<VasBloc>().add(VasPayElectricity(
      meterNumber: meter,
      disco: _selectedCode!,
      amountKobo: amount * 100,
      meterType: _meterType,
      transactionPin: pin,
    ));
  }

  void _err(String msg) =>
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(msg, style: const TextStyle(color: Colors.white)),
          backgroundColor: Colors.red.shade700,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );

  @override
  Widget build(BuildContext context) {
    final accent = _selectedDisco?.accent ?? _brand;

    return BlocListener<VasBloc, VasState>(
      listener: (context, state) {
        if (state is VasReconciling) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(state.message,
                style: const TextStyle(fontWeight: FontWeight.bold)),
            backgroundColor: Colors.orange.shade700,
            duration: const Duration(seconds: 4),
          ));
        } else if (state is VasSuccess ||
            state is VasFailure ||
            state is VasReversal) {
          showModalBottomSheet(
            context: context,
            isScrollControlled: true,
            backgroundColor: Colors.transparent,
            builder: (_) {
              final success  = state is VasSuccess  ? state : null;
              final failure  = state is VasFailure  ? state : null;
              final reversal = state is VasReversal ? state : null;
              return VasResultSheet(
                success: state is VasSuccess,
                isReversal: state is VasReversal,
                message: success?.message ??
                    failure?.message ??
                    reversal?.message ?? '',
                reference: success?.reference ?? reversal?.reference,
                token: success?.token,
                onDone: () {
                  Navigator.pop(context);
                  if (state is VasSuccess || state is VasReversal) {
                    Navigator.pop(context);
                  }
                },
              );
            },
          );
        }
      },
      child: Scaffold(
        backgroundColor: const Color(0xfff4f6f5),
        appBar: AppBar(
          title: Text(
            'Pay Electricity',
            style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700),
          ),
          backgroundColor: accent,
          foregroundColor: Colors.white,
          elevation: 0,
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 40),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [

              // ── Header summary card ──────────────────────────────────────
              if (_selectedDisco != null) ...[
                AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeOut,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        accent.withValues(alpha: 0.12),
                        accent.withValues(alpha: 0.04),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: accent.withValues(alpha: 0.25)),
                  ),
                  child: Row(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: Image.asset(
                          'assets/images/${_selectedDisco!.asset}.png',
                          width: 48,
                          height: 48,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Container(
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              color: accent,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(Icons.bolt_rounded,
                                color: Colors.white, size: 24),
                          ),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _selectedDisco!.name,
                              style: GoogleFonts.plusJakartaSans(
                                fontWeight: FontWeight.w700,
                                fontSize: 15,
                                color: const Color(0xff1a1a1a),
                              ),
                            ),
                            const SizedBox(height: 2),
                            Row(
                              children: [
                                Icon(Icons.location_on_rounded,
                                    size: 12,
                                    color: accent.withValues(alpha: 0.7)),
                                const SizedBox(width: 3),
                                Text(
                                  _selectedDisco!.region,
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 12,
                                    color: Colors.grey.shade600,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      TextButton(
                        onPressed: () => setState(() => _selectedCode = null),
                        child: Text('Change',
                            style: GoogleFonts.plusJakartaSans(
                              color: accent,
                              fontWeight: FontWeight.w600,
                              fontSize: 13,
                            )),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
              ],

              // ── DisCo grid (shown when none selected or on "Change") ─────
              if (_selectedCode == null) ...[
                _label('Select your distribution company'),
                const SizedBox(height: 12),
                GridView.count(
                  crossAxisCount: 2,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: 1.45,
                  children: _discos.map((disco) =>
                      _DiscoCard(
                        disco: disco,
                        selected: _selectedCode == disco.code,
                        onTap: () =>
                            setState(() => _selectedCode = disco.code),
                      )).toList(),
                ),
                const SizedBox(height: 24),
              ],

              // ── DisCo grid (always visible as scrollable row for quick switch) ─
              if (_selectedCode != null) ...[
                _label('Switch DisCo'),
                const SizedBox(height: 10),
                SizedBox(
                  height: 80,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: _discos.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 10),
                    itemBuilder: (_, i) {
                      final d = _discos[i];
                      final sel = _selectedCode == d.code;
                      return GestureDetector(
                        onTap: () => setState(() => _selectedCode = d.code),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 180),
                          width: 72,
                          decoration: BoxDecoration(
                            color: sel
                                ? d.accent.withValues(alpha: 0.1)
                                : Colors.white,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: sel ? d.accent : Colors.grey.shade200,
                              width: sel ? 2 : 1,
                            ),
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: Image.asset(
                                  'assets/images/${d.asset}.png',
                                  width: 36,
                                  height: 36,
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, __, ___) => Icon(
                                      Icons.bolt_rounded,
                                      color: d.accent,
                                      size: 28),
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                d.shortName,
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 9,
                                  fontWeight: FontWeight.w600,
                                  color: sel
                                      ? d.accent
                                      : Colors.grey.shade600,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 24),
              ],

              // ── Meter type toggle ────────────────────────────────────────
              _label('Meter type'),
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: Colors.grey.shade200,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: ['prepaid', 'postpaid'].map((type) {
                    final active = _meterType == type;
                    return Expanded(
                      child: GestureDetector(
                        onTap: () => setState(() => _meterType = type),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 150),
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          decoration: BoxDecoration(
                            color: active ? Colors.white : Colors.transparent,
                            borderRadius: BorderRadius.circular(10),
                            boxShadow: active
                                ? [
                                    BoxShadow(
                                      color: Colors.black
                                          .withValues(alpha: 0.06),
                                      blurRadius: 4,
                                      offset: const Offset(0, 1),
                                    )
                                  ]
                                : [],
                          ),
                          child: Center(
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  type == 'prepaid'
                                      ? Icons.electric_meter_rounded
                                      : Icons.receipt_long_rounded,
                                  size: 14,
                                  color: active
                                      ? accent
                                      : Colors.grey.shade500,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  type[0].toUpperCase() + type.substring(1),
                                  style: GoogleFonts.plusJakartaSans(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 14,
                                    color: active
                                        ? Colors.grey.shade800
                                        : Colors.grey.shade500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
              const SizedBox(height: 20),

              // ── Meter number ─────────────────────────────────────────────
              _label('Meter number'),
              const SizedBox(height: 10),
              _field(
                controller: _meterCtrl,
                hint: 'e.g. 01012345678901',
                icon: Icons.electric_meter_outlined,
                type: TextInputType.number,
                formatters: [FilteringTextInputFormatter.digitsOnly],
              ),
              const SizedBox(height: 20),

              // ── Amount ───────────────────────────────────────────────────
              _label('Amount (₦)'),
              const SizedBox(height: 10),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: _amounts.map((amt) {
                  final str     = amt.toString();
                  final sel     = _amountCtrl.text == str;
                  final display = amt >= 1000
                      ? '₦${(amt ~/ 1000)}k'
                      : '₦$amt';
                  return GestureDetector(
                    onTap: () => setState(() => _amountCtrl.text = str),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 10),
                      decoration: BoxDecoration(
                        color: sel ? accent : Colors.white,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: sel ? accent : Colors.grey.shade300,
                        ),
                      ),
                      child: Text(
                        display,
                        style: GoogleFonts.plusJakartaSans(
                          color: sel ? Colors.white : Colors.grey.shade700,
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 12),
              _field(
                controller: _amountCtrl,
                hint: 'Or enter custom amount',
                icon: Icons.payments_outlined,
                prefix: '₦',
                type: TextInputType.number,
                formatters: [FilteringTextInputFormatter.digitsOnly],
                onChanged: (_) => setState(() {}),
              ),
              const SizedBox(height: 20),

              // ── PIN ──────────────────────────────────────────────────────
              _label('Transaction PIN'),
              const SizedBox(height: 10),
              _field(
                controller: _pinCtrl,
                hint: '******',
                icon: Icons.lock_outline_rounded,
                type: TextInputType.number,
                isPassword: _obscurePin,
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscurePin ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                    color: Colors.grey.shade500,
                    size: 20,
                  ),
                  onPressed: () => setState(() => _obscurePin = !_obscurePin),
                ),
                formatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(6),
                ],
              ),
              const SizedBox(height: 32),

              // ── Submit ───────────────────────────────────────────────────
              BlocBuilder<VasBloc, VasState>(
                builder: (context, state) {
                  final loading = state is VasProcessing;
                  final amt     = int.tryParse(
                      _amountCtrl.text.trim().replaceAll(',', '')) ?? 0;

                  return SizedBox(
                    width: double.infinity,
                    height: 54,
                    child: ElevatedButton(
                      onPressed: loading ? null : _submit,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: accent,
                        foregroundColor: Colors.white,
                        disabledBackgroundColor: Colors.grey.shade300,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: loading
                          ? const SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2, color: Colors.white),
                            )
                          : Text(
                              amt >= 500
                                  ? 'Pay ₦${_fmt(amt)} to ${_selectedDisco?.shortName ?? ''}'
                                  : 'Pay electricity',
                              style: GoogleFonts.plusJakartaSans(
                                fontWeight: FontWeight.w700,
                                fontSize: 15,
                              ),
                            ),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ─────────────────────────────── helpers ─────────────────────────────────

  String _fmt(int ngn) => ngn
      .toString()
      .replaceAllMapped(
          RegExp(r'(\d)(?=(\d{3})+(?!\d))'), (m) => '${m[1]},');

  Widget _label(String text) => Text(
        text,
        style: GoogleFonts.plusJakartaSans(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: Colors.grey.shade600,
        ),
      );

  Widget _field({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    String? prefix,
    required TextInputType type,
    List<TextInputFormatter>? formatters,
    ValueChanged<String>? onChanged,
    bool isPassword = false,
    Widget? suffixIcon,
  }) =>
      Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Row(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14),
              child: Icon(icon, color: Colors.grey.shade400, size: 20),
            ),
            Expanded(
              child: TextField(
                controller: controller,
                keyboardType: type,
                inputFormatters: formatters,
                onChanged: onChanged,
                obscureText: isPassword,
                style: GoogleFonts.plusJakartaSans(fontSize: 15),
                decoration: InputDecoration(
                  hintText: hint,
                  hintStyle: TextStyle(
                      color: Colors.grey.shade400, fontSize: 14),
                  prefixText: prefix,
                  prefixStyle: GoogleFonts.plusJakartaSans(
                      fontSize: 15, fontWeight: FontWeight.w600),
                  suffixIcon: suffixIcon,
                  border: InputBorder.none,
                  contentPadding:
                      const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
            ),
          ],
        ),
      );
}

// ─── DisCo card (full grid view) ─────────────────────────────────────────────

class _DiscoCard extends StatelessWidget {
  final _Disco disco;
  final bool selected;
  final VoidCallback onTap;

  const _DiscoCard({
    required this.disco,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOut,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: selected
              ? disco.accent.withValues(alpha: 0.08)
              : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: selected ? disco.accent : Colors.grey.shade200,
            width: selected ? 2 : 1,
          ),
          boxShadow: selected
              ? [
                  BoxShadow(
                    color: disco.accent.withValues(alpha: 0.15),
                    blurRadius: 10,
                    offset: const Offset(0, 3),
                  )
                ]
              : [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.04),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  )
                ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: Image.asset(
                    'assets/images/${disco.asset}.png',
                    width: 44,
                    height: 44,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: disco.accent,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.bolt_rounded,
                          color: Colors.white, size: 24),
                    ),
                  ),
                ),
                if (selected)
                  Container(
                    width: 20,
                    height: 20,
                    decoration: BoxDecoration(
                      color: disco.accent,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.check_rounded,
                        color: Colors.white, size: 13),
                  ),
              ],
            ),
            const Spacer(),
            Text(
              disco.shortName,
              style: GoogleFonts.plusJakartaSans(
                fontWeight: FontWeight.w700,
                fontSize: 13,
                color: selected ? disco.accent : const Color(0xff1a1a1a),
              ),
            ),
            const SizedBox(height: 2),
            Text(
              disco.region,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 10,
                color: Colors.grey.shade500,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}
