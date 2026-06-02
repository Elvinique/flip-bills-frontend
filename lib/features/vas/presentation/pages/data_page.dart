import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import '../bloc/vas_bloc.dart';
import '../widgets/vas_result_sheet.dart';

class DataPage extends StatefulWidget {
  final List<Map<String, dynamic>> networks;
  final List<Map<String, dynamic>> dataPlans;
  const DataPage({super.key, required this.networks, required this.dataPlans});

  @override
  State<DataPage> createState() => _DataPageState();
}

class _DataPageState extends State<DataPage> {
  final _phoneCtrl = TextEditingController();
  String? _selectedNetwork;
  Map<String, dynamic>? _selectedPlan;

  static const _brand = Color(0xff0b845c);

  List<Map<String, dynamic>> get _filteredPlans {
    if (_selectedNetwork == null) return widget.dataPlans;
    return widget.dataPlans
        .where((p) => (p['network'] as String?) == _selectedNetwork)
        .toList();
  }

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
    super.dispose();
  }

  void _submit() {
    final phone = _phoneCtrl.text.trim();
    if (phone.length < 11) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Enter a valid 11-digit number.')));
      return;
    }
    if (_selectedPlan == null) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Please select a data plan.')));
      return;
    }

    context.read<VasBloc>().add(VasBuyData(
          phone: phone,
          network: _selectedNetwork!,
          planCode: _selectedPlan!['code'] as String,
        ));
  }

  String _formatAmount(dynamic raw) {
    final kobo = (raw as num?)?.toInt() ?? 0;
    final ngn = kobo / 100;
    return '₦${ngn.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d)(?=(\d{3})+(?!\d))'), (m) => '${m[1]},')}';
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
                Navigator.pop(context);
                if (state is VasSuccess) Navigator.pop(context);
              },
            ),
          );
        }
      },
      child: Scaffold(
        backgroundColor: const Color(0xfff4f6f5),
        appBar: AppBar(
          title: Text(
            'Buy data',
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
              // Network tabs
              _label('Network'),
              const SizedBox(height: 10),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: widget.networks.map((n) {
                    final code = n['code'] as String;
                    final selected = _selectedNetwork == code;
                    return GestureDetector(
                      onTap: () => setState(() {
                        _selectedNetwork = code;
                        _selectedPlan = null;
                      }),
                      child: Container(
                        margin: const EdgeInsets.only(right: 10),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 18, vertical: 10),
                        decoration: BoxDecoration(
                          color: selected ? _brand : Colors.white,
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(
                            color: selected ? _brand : Colors.grey.shade300,
                          ),
                        ),
                        child: Text(
                          code,
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
              ),
              const SizedBox(height: 20),

              // Phone number
              _label('Phone number'),
              const SizedBox(height: 10),
              _phoneField(),
              const SizedBox(height: 20),

              // Plans grid
              _label('Select plan'),
              const SizedBox(height: 10),
              if (_filteredPlans.isEmpty)
                Text(
                  'No plans available for this network.',
                  style: TextStyle(color: Colors.grey),
                )
              else
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    mainAxisSpacing: 10,
                    crossAxisSpacing: 10,
                    childAspectRatio: 1.5,
                  ),
                  itemCount: _filteredPlans.length,
                  itemBuilder: (_, i) {
                    final plan = _filteredPlans[i];
                    final selected = _selectedPlan?['code'] == plan['code'];
                    return GestureDetector(
                      onTap: () => setState(() => _selectedPlan = plan),
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: selected
                              ? _brand.withValues(alpha: 0.08)
                              : Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: selected ? _brand : Colors.grey.shade200,
                            width: selected ? 2 : 1,
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              plan['name'] as String? ?? '',
                              style: GoogleFonts.plusJakartaSans(
                                fontWeight: FontWeight.w700,
                                fontSize: 16,
                                color: selected ? _brand : Colors.grey.shade800,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              plan['validity'] as String? ?? '',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 11,
                                color: Colors.grey.shade500,
                              ),
                            ),
                            const Spacer(),
                            Text(
                              _formatAmount(plan['amount']),
                              style: GoogleFonts.plusJakartaSans(
                                fontWeight: FontWeight.w600,
                                fontSize: 13,
                                color: selected ? _brand : Colors.grey.shade700,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
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
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : Text(
                              _selectedPlan != null
                                  ? 'Buy ${_selectedPlan!['name']} for ${_formatAmount(_selectedPlan!['amount'])}'
                                  : 'Select a plan',
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

  Widget _label(String text) => Text(
        text,
        style: GoogleFonts.plusJakartaSans(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: Colors.grey.shade600,
        ),
      );

  Widget _phoneField() => Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: TextField(
          controller: _phoneCtrl,
          keyboardType: TextInputType.phone,
          inputFormatters: [
            FilteringTextInputFormatter.digitsOnly,
            LengthLimitingTextInputFormatter(11),
          ],
          style: TextStyle(fontSize: 15),
          decoration: InputDecoration(
            hintText: '08012345678',
            hintStyle: TextStyle(color: Colors.grey.shade400),
            border: InputBorder.none,
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          ),
        ),
      );
}
