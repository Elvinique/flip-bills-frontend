import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import '../bloc/vas_bloc.dart';
import '../widgets/vas_result_sheet.dart';

class AirtimePage extends StatefulWidget {
  final List<Map<String, dynamic>> networks;
  const AirtimePage({super.key, required this.networks});

  @override
  State<AirtimePage> createState() => _AirtimePageState();
}

class _AirtimePageState extends State<AirtimePage> {
  final _phoneCtrl = TextEditingController();
  final _amountCtrl = TextEditingController();
  String? _selectedNetwork;

  static const _brand = Color(0xff0b845c);
  static const _amounts = [100, 200, 500, 1000, 2000, 5000];

  @override
  void initState() {
    super.initState();
    if (widget.networks.isNotEmpty) {
      _selectedNetwork = widget.networks.first['code'] as String?;
    }
  }

  @override
  void dispose() {
    _phoneCtrl.dispose();
    _amountCtrl.dispose();
    super.dispose();
  }

  void _submit() {
    final phone = _phoneCtrl.text.trim();
    final amountText = _amountCtrl.text.trim().replaceAll(',', '');
    final amount = int.tryParse(amountText);

    if (phone.length < 11) {
      _showError('Enter a valid 11-digit phone number.');
      return;
    }
    if (amount == null || amount < 50) {
      _showError('Minimum airtime amount is ₦50.');
      return;
    }
    if (_selectedNetwork == null) {
      _showError('Please select a network.');
      return;
    }

    context.read<VasBloc>().add(VasBuyAirtime(
          phone: phone,
          amountKobo: amount * 100,
          network: _selectedNetwork!,
        ));
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<VasBloc, VasState>(
      listener: (context, state) {
        if (state is VasSuccess || state is VasFailure) {
          showModalBottomSheet(
            context: context,
            isScrollControlled: true,
            backgroundColor: Colors.transparent,
            builder: (_) => VasResultSheet(
              success: state is VasSuccess,
              message: state is VasSuccess
                  ? (state as VasSuccess).message
                  : (state as VasFailure).message,
              reference: state is VasSuccess ? (state as VasSuccess).reference : null,
              onDone: () {
                Navigator.pop(context); // close sheet
                if (state is VasSuccess) Navigator.pop(context); // back to dashboard
              },
            ),
          );
        }
      },
      child: Scaffold(
        backgroundColor: const Color(0xfff4f6f5),
        appBar: AppBar(
          title: Text(
            'Buy airtime',
            style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700),
          ),
          backgroundColor: _brand,
          foregroundColor: Colors.white,
          elevation: 0,
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Network selector
              _SectionLabel('Network'),
              const SizedBox(height: 10),
              _NetworkSelector(
                networks: widget.networks,
                selected: _selectedNetwork,
                onSelect: (code) => setState(() => _selectedNetwork = code),
              ),
              const SizedBox(height: 20),

              // Phone number
              _SectionLabel('Phone number'),
              const SizedBox(height: 10),
              _InputField(
                controller: _phoneCtrl,
                hint: '08012345678',
                keyboardType: TextInputType.phone,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(11),
                ],
              ),
              const SizedBox(height: 20),

              // Quick amounts
              _SectionLabel('Amount (₦)'),
              const SizedBox(height: 10),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: _amounts.map((amt) {
                  final selected = _amountCtrl.text == amt.toString();
                  return GestureDetector(
                    onTap: () => setState(() => _amountCtrl.text = amt.toString()),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      decoration: BoxDecoration(
                        color: selected ? _brand : Colors.white,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: selected ? _brand : Colors.grey.shade300,
                        ),
                      ),
                      child: Text(
                        '₦${amt.toString().replaceAllMapped(RegExp(r'(\d)(?=(\d{3})+(?!\d))'), (m) => '${m[1]},')}',
                        style: GoogleFonts.plusJakartaSans(
                          color: selected ? Colors.white : Colors.grey.shade700,
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 12),
              _InputField(
                controller: _amountCtrl,
                hint: 'Or enter custom amount',
                prefix: '₦',
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                onChanged: (_) => setState(() {}),
              ),
              const SizedBox(height: 32),

              // Submit
              BlocBuilder<VasBloc, VasState>(
                builder: (context, state) {
                  final loading = state is VasProcessing;
                  return SizedBox(
                    width: double.infinity,
                    height: 54,
                    child: ElevatedButton(
                      onPressed: loading ? null : _submit,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _brand,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: loading
                          ? const SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : Text(
                              'Buy airtime',
                              style: GoogleFonts.plusJakartaSans(
                                fontWeight: FontWeight.w700,
                                fontSize: 16,
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
}

// ── Shared sub-widgets ───────────────────────────────────────────────────────

class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: GoogleFonts.plusJakartaSans(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        color: Colors.grey.shade600,
      ),
    );
  }
}

class _InputField extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final String? prefix;
  final TextInputType keyboardType;
  final List<TextInputFormatter>? inputFormatters;
  final ValueChanged<String>? onChanged;

  const _InputField({
    required this.controller,
    required this.hint,
    this.prefix,
    required this.keyboardType,
    this.inputFormatters,
    this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: TextField(
        controller: controller,
        keyboardType: keyboardType,
        inputFormatters: inputFormatters,
        onChanged: onChanged,
        style: GoogleFonts.plusJakartaSans(fontSize: 15),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: GoogleFonts.plusJakartaSans(color: Colors.grey.shade400),
          prefixText: prefix,
          prefixStyle: GoogleFonts.plusJakartaSans(
            fontSize: 15,
            fontWeight: FontWeight.w600,
          ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        ),
      ),
    );
  }
}

class _NetworkSelector extends StatelessWidget {
  final List<Map<String, dynamic>> networks;
  final String? selected;
  final ValueChanged<String> onSelect;

  const _NetworkSelector({
    required this.networks,
    required this.selected,
    required this.onSelect,
  });

  static const Map<String, Color> _networkColors = {
    'MTN': Color(0xffffcc00),
    'GLO': Color(0xff4caf50),
    'AIRTEL': Color(0xffe53935),
    '9MOBILE': Color(0xff00897b),
  };

  @override
  Widget build(BuildContext context) {
    return Row(
      children: networks.map((n) {
        final code = n['code'] as String;
        final name = n['name'] as String;
        final isSelected = selected == code;
        final color = _networkColors[code] ?? const Color(0xff0b845c);
        return Expanded(
          child: GestureDetector(
            onTap: () => onSelect(code),
            child: Container(
              margin: const EdgeInsets.only(right: 8),
              padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: isSelected ? color.withOpacity(0.12) : Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isSelected ? color : Colors.grey.shade200,
                  width: isSelected ? 2 : 1,
                ),
              ),
              child: Column(
                children: [
                  Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      color: color,
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        code[0],
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    code,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: isSelected ? color : Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}
