import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import '../bloc/vas_bloc.dart';
import '../widgets/vas_result_sheet.dart';

class BettingPage extends StatefulWidget {
  final List<Map<String, dynamic>> providers;
  const BettingPage({super.key, required this.providers});

  @override
  State<BettingPage> createState() => _BettingPageState();
}

class _BettingPageState extends State<BettingPage> {
  final _customerIdCtrl = TextEditingController();
  final _amountCtrl = TextEditingController();
  String? _selectedProvider;

  static const _brand = Color(0xff0b845c);
  static const _amounts = [500, 1000, 2000, 5000, 10000, 20000];

  // Brand accent colours so each provider card feels distinct
  static const Map<String, Color> _providerAccents = {
    'BET9JA': Color(0xff1a7b3c),
    'SPORTYBET': Color(0xffe65100),
    'BETKING': Color(0xff1565c0),
    'NAIRABET': Color(0xff6a1b9a),
    '1XBET': Color(0xffb71c1c),
  };

  @override
  void initState() {
    super.initState();
    if (widget.providers.isNotEmpty) {
      _selectedProvider = widget.providers.first['code'] as String?;
    }
  }

  @override
  void dispose() {
    _customerIdCtrl.dispose();
    _amountCtrl.dispose();
    super.dispose();
  }

  void _submit() {
    final id = _customerIdCtrl.text.trim();
    final amountText = _amountCtrl.text.trim().replaceAll(',', '');
    final amount = int.tryParse(amountText);

    if (id.isEmpty) {
      _err('Enter your betting account ID / username.');
      return;
    }
    if (amount == null || amount < 100) {
      _err('Minimum funding amount is ₦100.');
      return;
    }
    if (_selectedProvider == null) {
      _err('Please select a betting platform.');
      return;
    }

    if (amount > 10000) {
      _showFrictionPrompt(amount);
      return;
    }

    context.read<VasBloc>().add(VasFundBetting(
          customerId: id,
          provider: _selectedProvider!,
          amountKobo: amount * 100,
        ));
  }

  void _showFrictionPrompt(int amount) {
    bool acknowledged = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Container(
              decoration: BoxDecoration(
                color: Theme.of(context).scaffoldBackgroundColor,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
              ),
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 36),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 40,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: 24),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  Container(
                    width: 72,
                    height: 72,
                    decoration: const BoxDecoration(
                      color: Color(0xfffff4e6),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.warning_amber_rounded, size: 36, color: Colors.orange.shade700),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'High Velocity Alert',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: Colors.orange.shade700,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'You are attempting to transfer ₦${amount.toString().replaceAllMapped(RegExp(r'(\d)(?=(\d{3})+(?!\d))'), (m) => '${m[1]},')}. This departs sharply from your weekly betting velocity.',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 14,
                      color: Colors.grey.shade800,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 24),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      border: Border.all(color: Colors.orange.shade300),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(
                          width: 24,
                          height: 24,
                          child: Checkbox(
                            value: acknowledged,
                            activeColor: Colors.orange.shade700,
                            onChanged: (val) {
                              setModalState(() {
                                acknowledged = val ?? false;
                              });
                            },
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'I acknowledge that betting deposits are final and cannot be easily reversed due to AML regulations.',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 12,
                              color: Colors.grey.shade700,
                              height: 1.4,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),
                  SizedBox(
                    width: double.infinity,
                    height: 54,
                    child: ElevatedButton.icon(
                      onPressed: acknowledged ? () {
                        Navigator.pop(context); // Dismiss the friction prompt
                        this.context.read<VasBloc>().add(VasFundBetting(
                          customerId: _customerIdCtrl.text.trim(),
                          provider: _selectedProvider!,
                          amountKobo: amount * 100,
                        ));
                      } : null,
                      icon: const Icon(Icons.fingerprint_rounded),
                      label: Text(
                        'Authorize Transfer',
                        style: GoogleFonts.plusJakartaSans(
                          fontWeight: FontWeight.w700,
                          fontSize: 16,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orange.shade700,
                        foregroundColor: Colors.white,
                        disabledBackgroundColor: Colors.grey.shade300,
                        disabledForegroundColor: Colors.grey.shade500,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
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
            'Fund betting wallet',
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
              // Provider cards
              _label('Select platform'),
              const SizedBox(height: 10),
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  mainAxisSpacing: 10,
                  crossAxisSpacing: 10,
                  childAspectRatio: 1.3,
                ),
                itemCount: widget.providers.length,
                itemBuilder: (_, i) {
                  final p = widget.providers[i];
                  final code = p['code'] as String;
                  final name = p['name'] as String;
                  final selected = _selectedProvider == code;
                  final accent =
                      _providerAccents[code] ?? const Color(0xff0b845c);

                  return GestureDetector(
                    onTap: () => setState(() => _selectedProvider = code),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: selected
                            ? accent.withValues(alpha: 0.1)
                            : Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: selected ? accent : Colors.grey.shade200,
                          width: selected ? 2 : 1,
                        ),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            width: 32,
                            height: 32,
                            decoration: BoxDecoration(
                              color: accent,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Center(
                              child: Text(
                                code[0],
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w800,
                                  fontSize: 14,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            name.replaceAll(
                                RegExp(r'^(Bet9ja|SportyBet|BetKing|NairaBET|1xBet)'),
                                name.split(' ').first),
                            textAlign: TextAlign.center,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: selected ? accent : Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(height: 20),

              // Customer ID
              _label('Betting account ID / username'),
              const SizedBox(height: 10),
              _field(
                controller: _customerIdCtrl,
                hint: 'Your username or customer ID',
                type: TextInputType.text,
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
                          color:
                              selected ? Colors.white : Colors.grey.shade700,
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
                              'Fund wallet',
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
