import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import '../bloc/vas_bloc.dart';
import '../widgets/vas_result_sheet.dart';

class ElectricityPage extends StatefulWidget {
  final List<Map<String, dynamic>> discos;
  const ElectricityPage({super.key, required this.discos});

  @override
  State<ElectricityPage> createState() => _ElectricityPageState();
}

class _ElectricityPageState extends State<ElectricityPage> {
  final _meterCtrl = TextEditingController();
  final _amountCtrl = TextEditingController();
  String? _selectedDisco;
  String _meterType = 'prepaid';

  static const _brand = Color(0xff0b845c);
  static const _amounts = [1000, 2000, 5000, 10000, 20000, 50000];

  @override
  void initState() {
    super.initState();
    if (widget.discos.isNotEmpty) {
      _selectedDisco = widget.discos.first['code'] as String?;
    }
  }

  @override
  void dispose() {
    _meterCtrl.dispose();
    _amountCtrl.dispose();
    super.dispose();
  }

  void _submit() {
    final meter = _meterCtrl.text.trim();
    final amountText = _amountCtrl.text.trim().replaceAll(',', '');
    final amount = int.tryParse(amountText);

    if (meter.length < 10) {
      _err('Enter a valid meter number (at least 10 digits).');
      return;
    }
    if (amount == null || amount < 500) {
      _err('Minimum electricity payment is ₦500.');
      return;
    }
    if (_selectedDisco == null) {
      _err('Please select a distribution company.');
      return;
    }

    context.read<VasBloc>().add(VasPayElectricity(
          meterNumber: meter,
          disco: _selectedDisco!,
          amountKobo: amount * 100,
          meterType: _meterType,
        ));
  }

  void _err(String msg) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));

  @override
  Widget build(BuildContext context) {
    return BlocListener<VasBloc, VasState>(
      listener: (context, state) {
        if (state is VasReconciling) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(state.message, style: const TextStyle(fontWeight: FontWeight.bold)),
            backgroundColor: Colors.orange.shade700,
            duration: const Duration(seconds: 4),
          ));
        } else if (state is VasSuccess || state is VasFailure || state is VasReversal) {
          showModalBottomSheet(
            context: context,
            isScrollControlled: true,
            backgroundColor: Colors.transparent,
            builder: (_) {
              final success = state is VasSuccess ? state : null;
              final failure = state is VasFailure ? state : null;
              final reversal = state is VasReversal ? state : null;
              return VasResultSheet(
                success: state is VasSuccess,
                isReversal: state is VasReversal,
                message: success?.message ?? failure?.message ?? reversal?.message ?? '',
                reference: success?.reference ?? reversal?.reference,
                token: success?.token,
                onDone: () {
                  Navigator.pop(context);
                  if (state is VasSuccess || state is VasReversal) Navigator.pop(context);
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
            'Pay electricity',
            style: TextStyle(fontWeight: FontWeight.w700),
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
              // Meter type toggle
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
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          decoration: BoxDecoration(
                            color: active ? Colors.white : Colors.transparent,
                            borderRadius: BorderRadius.circular(10),
                            boxShadow: active
                                ? [
                                    BoxShadow(
                                      color: Colors.black.withValues(alpha: 0.06),
                                      blurRadius: 4,
                                      offset: const Offset(0, 1),
                                    )
                                  ]
                                : [],
                          ),
                          child: Center(
                            child: Text(
                              type[0].toUpperCase() + type.substring(1),
                              style: GoogleFonts.plusJakartaSans(
                                fontWeight: FontWeight.w600,
                                fontSize: 14,
                                color: active
                                    ? Colors.grey.shade800
                                    : Colors.grey.shade500,
                              ),
                            ),
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
              const SizedBox(height: 20),

              // DISCO selector
              _label('Distribution company'),
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    isExpanded: true,
                    value: _selectedDisco,
                    style: GoogleFonts.plusJakartaSans(
                        fontSize: 15, color: Colors.grey.shade800),
                    icon: const Icon(Icons.keyboard_arrow_down_rounded),
                    items: widget.discos.map((d) {
                      return DropdownMenuItem<String>(
                        value: d['code'] as String,
                        child: Text(d['name'] as String),
                      );
                    }).toList(),
                    onChanged: (v) => setState(() => _selectedDisco = v),
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Meter number
              _label('Meter number'),
              const SizedBox(height: 10),
              _field(
                controller: _meterCtrl,
                hint: 'e.g. 0101234567890',
                type: TextInputType.number,
                formatters: [FilteringTextInputFormatter.digitsOnly],
              ),
              const SizedBox(height: 20),

              // Quick amounts
              _label('Amount (₦)'),
              const SizedBox(height: 10),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: _amounts.map((amt) {
                  final str = amt.toString();
                  final selected = _amountCtrl.text == str;
                  return GestureDetector(
                    onTap: () => setState(() => _amountCtrl.text = str),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 10),
                      decoration: BoxDecoration(
                        color: selected ? _brand : Colors.white,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: selected ? _brand : Colors.grey.shade300,
                        ),
                      ),
                      child: Text(
                        '₦${str.replaceAllMapped(RegExp(r'(\d)(?=(\d{3})+(?!\d))'), (m) => '${m[1]},')}',
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
              _field(
                controller: _amountCtrl,
                hint: 'Or enter custom amount',
                prefix: '₦',
                type: TextInputType.number,
                formatters: [FilteringTextInputFormatter.digitsOnly],
                onChanged: (_) => setState(() {}),
              ),
              const SizedBox(height: 32),

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
                                  strokeWidth: 2, color: Colors.white),
                            )
                          : Text(
                              'Pay electricity',
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
    String? prefix,
    required TextInputType type,
    List<TextInputFormatter>? formatters,
    ValueChanged<String>? onChanged,
  }) =>
      Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: TextField(
          controller: controller,
          keyboardType: type,
          inputFormatters: formatters,
          onChanged: onChanged,
          style: TextStyle(fontSize: 15),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle:
                TextStyle(color: Colors.grey.shade400),
            prefixText: prefix,
            prefixStyle: GoogleFonts.plusJakartaSans(
                fontSize: 15, fontWeight: FontWeight.w600),
            border: InputBorder.none,
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          ),
        ),
      );
}
