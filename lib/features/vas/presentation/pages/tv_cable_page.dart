import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import '../bloc/vas_bloc.dart';

// ─── Provider Brand Data ───────────────────────────────────────────────────────

class _TvProvider {
  final String code;
  final String name;
  final String shortLabel;
  final Color bgColor;
  final Color textColor;
  final Color accentColor;
  final IconData icon;

  const _TvProvider({
    required this.code,
    required this.name,
    required this.shortLabel,
    required this.bgColor,
    required this.textColor,
    required this.accentColor,
    required this.icon,
  });
}

const _providers = <_TvProvider>[
  _TvProvider(
    code: 'DSTV',
    name: 'DStv',
    shortLabel: 'DStv',
    bgColor: Color(0xff003087),
    textColor: Colors.white,
    accentColor: Color(0xff0057e7),
    icon: Icons.satellite_alt_rounded,
  ),
  _TvProvider(
    code: 'GOTV',
    name: 'GOtv',
    shortLabel: 'GOtv',
    bgColor: Color(0xffff6600),
    textColor: Colors.white,
    accentColor: Color(0xffff8c42),
    icon: Icons.wifi_tethering_rounded,
  ),
  _TvProvider(
    code: 'STARTIMES',
    name: 'StarTimes',
    shortLabel: 'StarTimes',
    bgColor: Color(0xffcc0000),
    textColor: Colors.white,
    accentColor: Color(0xffff3333),
    icon: Icons.star_rounded,
  ),
  _TvProvider(
    code: 'SHOWMAX',
    name: 'Showmax',
    shortLabel: 'Showmax',
    bgColor: Color(0xff1a1a2e),
    textColor: Colors.white,
    accentColor: Color(0xffe50914),
    icon: Icons.play_circle_filled_rounded,
  ),
];

// ─── Page ─────────────────────────────────────────────────────────────────────

class TvCablePage extends StatefulWidget {
  final List<Map<String, dynamic>> providers;
  const TvCablePage({super.key, required this.providers});

  @override
  State<TvCablePage> createState() => _TvCablePageState();
}

class _TvCablePageState extends State<TvCablePage> {
  static const _brand = Color(0xff0b845c);

  final _cardCtrl = TextEditingController();

  String? _selectedProviderCode;
  String? _selectedPlanCode;
  String? _selectedPlanName;
  int?    _selectedPlanAmount;
  bool    _isValidating = false;
  String? _validatedName;

  // ── Plan catalog ────────────────────────────────────────────────────────────
  static const _plans = <String, List<Map<String, dynamic>>>{
    'DSTV': [
      {'code': 'DSTV_PADI',    'name': 'DStv Padi',    'amount': 230000,  'desc': '30 channels · Basic entertainment'},
      {'code': 'DSTV_YANGA',   'name': 'DStv Yanga',   'amount': 290000,  'desc': '36 channels · More local content'},
      {'code': 'DSTV_CONFAM',  'name': 'DStv Confam',  'amount': 540000,  'desc': '45 channels · Popular value pack'},
      {'code': 'DSTV_COMPACT', 'name': 'DStv Compact', 'amount': 1050000, 'desc': '56 channels · Full entertainment'},
      {'code': 'DSTV_PREMIUM', 'name': 'DStv Premium', 'amount': 2950000, 'desc': '110+ channels · Sports & movies'},
    ],
    'GOTV': [
      {'code': 'GOTV_LITE',     'name': 'GOtv Lite',     'amount': 130000, 'desc': '23 channels · Starter pack'},
      {'code': 'GOTV_SMALLIE',  'name': 'GOtv Smallie',  'amount': 190000, 'desc': '34 channels · More value'},
      {'code': 'GOTV_JINJA',    'name': 'GOtv Jinja',    'amount': 270000, 'desc': '38 channels · Great choice'},
      {'code': 'GOTV_JOLLI',    'name': 'GOtv Jolli',    'amount': 380000, 'desc': '50 channels · Recommended'},
      {'code': 'GOTV_MAX',      'name': 'GOtv Max',      'amount': 490000, 'desc': '67 channels · Best value'},
    ],
    'STARTIMES': [
      {'code': 'STAR_NOVA',    'name': 'Nova',    'amount': 90000,  'desc': '40 channels · Starter'},
      {'code': 'STAR_BASIC',   'name': 'Basic',   'amount': 190000, 'desc': '60 channels · Popular'},
      {'code': 'STAR_SMART',   'name': 'Smart',   'amount': 290000, 'desc': '80 channels · Recommended'},
      {'code': 'STAR_CLASSIC', 'name': 'Classic', 'amount': 490000, 'desc': '100+ channels · Premium'},
      {'code': 'STAR_SUPER',   'name': 'Super',   'amount': 690000, 'desc': '120+ channels · Everything'},
    ],
    'SHOWMAX': [
      {'code': 'SHOWMAX_BASIC', 'name': 'Showmax Basic', 'amount': 120000, 'desc': 'Movies, series & Originals'},
      {'code': 'SHOWMAX_PRO',   'name': 'Showmax Pro',   'amount': 250000, 'desc': 'Everything + Premier League live'},
    ],
  };

  List<Map<String, dynamic>> get _currentPlans =>
      _selectedProviderCode != null
          ? (_plans[_selectedProviderCode] ?? [])
          : [];

  _TvProvider? get _selectedProvider =>
      _providers.where((p) => p.code == _selectedProviderCode).firstOrNull;

  Color get _activeColor => _selectedProvider?.bgColor ?? const Color(0xff16213e);

  @override
  void dispose() {
    _cardCtrl.dispose();
    super.dispose();
  }

  String _fmt(int kobo) {
    final ngn    = kobo / 100;
    final parts  = ngn.toStringAsFixed(0).split('.');
    final intPart = parts[0];
    final buf    = StringBuffer();
    for (var i = 0; i < intPart.length; i++) {
      if (i != 0 && (intPart.length - i) % 3 == 0) buf.write(',');
      buf.write(intPart[i]);
    }
    return '₦$buf';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xfff4f6f5),
      appBar: AppBar(
        backgroundColor: _activeColor,
        foregroundColor: Colors.white,
        title: Text(
          'TV / Cable',
          style: GoogleFonts.plusJakartaSans(
              fontWeight: FontWeight.w700, color: Colors.white),
        ),
        elevation: 0,
      ),
      body: BlocConsumer<VasBloc, VasState>(
        listener: (context, state) {
          if (state is VasSuccess)     _showSuccessSheet(context, state.data);
          if (state is VasFailure)     _snack(context, state.message, isError: true);
          if (state is VasReconciling) _snack(context, '⏳ Rerouting through backup provider…', isError: false);
        },
        builder: (context, state) {
          final isLoading = state is VasProcessing || state is VasReconciling;
          return SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 40),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [

                // ── Provider grid ──────────────────────────────────────────
                _sectionTitle('Select Provider'),
                const SizedBox(height: 14),
                _providerGrid(),
                const SizedBox(height: 24),

                // ── Selected provider banner ───────────────────────────────
                if (_selectedProvider != null) ...[
                  _ProviderBanner(provider: _selectedProvider!),
                  const SizedBox(height: 24),
                ],

                // ── Smart card number ──────────────────────────────────────
                _sectionTitle('Smart Card / IUC Number'),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _cardCtrl,
                        keyboardType: TextInputType.number,
                        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                        decoration: _dec(label: 'Enter smart card / IUC number'),
                        onChanged: (_) => setState(() {
                          _validatedName = null;
                          _isValidating  = false;
                        }),
                      ),
                    ),
                    const SizedBox(width: 10),
                    SizedBox(
                      height: 54,
                      child: ElevatedButton(
                        onPressed: (_selectedProviderCode == null ||
                                _cardCtrl.text.length < 8)
                            ? null
                            : _validateCard,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _activeColor,
                          disabledBackgroundColor: Colors.grey.shade300,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                          elevation: 0,
                        ),
                        child: _isValidating
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                    color: Colors.white, strokeWidth: 2))
                            : Text('Verify',
                                style: GoogleFonts.plusJakartaSans(
                                    fontWeight: FontWeight.w600,
                                    color: Colors.white)),
                      ),
                    ),
                  ],
                ),
                if (_validatedName != null) ...[
                  const SizedBox(height: 8),
                  _validatedChip(_validatedName!),
                ],
                const SizedBox(height: 24),

                // ── Plan selection ─────────────────────────────────────────
                if (_currentPlans.isNotEmpty) ...[
                  _sectionTitle('Choose a Plan'),
                  const SizedBox(height: 12),
                  ..._currentPlans.map((plan) => _PlanTile(
                        name:       plan['name']   as String,
                        desc:       plan['desc']   as String,
                        amount:     _fmt(plan['amount'] as int),
                        accentColor: _activeColor,
                        isSelected: _selectedPlanCode == plan['code'],
                        onTap: () => setState(() {
                          _selectedPlanCode   = plan['code']   as String;
                          _selectedPlanName   = plan['name']   as String;
                          _selectedPlanAmount = plan['amount'] as int;
                        }),
                      )),
                  const SizedBox(height: 28),
                ],

                // ── Pay button ─────────────────────────────────────────────
                AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: (isLoading ||
                            _selectedProviderCode == null ||
                            _selectedPlanCode == null ||
                            _cardCtrl.text.isEmpty)
                        ? null
                        : () => _submit(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _activeColor,
                      foregroundColor: Colors.white,
                      disabledBackgroundColor: Colors.grey.shade300,
                      minimumSize: const Size(double.infinity, 54),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14)),
                      elevation: 0,
                    ),
                    child: isLoading
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(
                                color: Colors.white, strokeWidth: 2.5))
                        : Text(
                            _selectedPlanAmount != null
                                ? 'Pay ${_fmt(_selectedPlanAmount!)} — ${_selectedPlanName ?? ''}'
                                : 'Select a plan to continue',
                            style: GoogleFonts.plusJakartaSans(
                                fontWeight: FontWeight.w700, fontSize: 14)),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  // ── Provider grid ────────────────────────────────────────────────────────────

  Widget _providerGrid() {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      childAspectRatio: 1.6,
      children: _providers.map((p) {
        final isSelected = _selectedProviderCode == p.code;
        return GestureDetector(
          onTap: () => setState(() {
            _selectedProviderCode = p.code;
            _selectedPlanCode     = null;
            _selectedPlanName     = null;
            _selectedPlanAmount   = null;
            _validatedName        = null;
          }),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOut,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: isSelected
                    ? [p.bgColor, p.accentColor]
                    : [Colors.white, Colors.white],
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isSelected ? p.bgColor : Colors.grey.shade200,
                width: isSelected ? 2 : 1,
              ),
              boxShadow: isSelected
                  ? [
                      BoxShadow(
                        color: p.bgColor.withValues(alpha: 0.35),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
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
            child: Stack(
              children: [
                // Background icon watermark
                Positioned(
                  right: -8,
                  bottom: -8,
                  child: Icon(
                    p.icon,
                    size: 52,
                    color: isSelected
                        ? Colors.white.withValues(alpha: 0.15)
                        : p.bgColor.withValues(alpha: 0.06),
                  ),
                ),
                // Content
                Padding(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Logo icon + check
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Container(
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? Colors.white.withValues(alpha: 0.2)
                                  : p.bgColor.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Icon(
                              p.icon,
                              size: 20,
                              color: isSelected ? Colors.white : p.bgColor,
                            ),
                          ),
                          if (isSelected)
                            Container(
                              width: 20,
                              height: 20,
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.25),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.check_rounded,
                                  color: Colors.white, size: 13),
                            ),
                        ],
                      ),
                      // Provider name
                      Text(
                        p.name,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          color: isSelected ? Colors.white : const Color(0xff1a1a1a),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  // ── Helpers ──────────────────────────────────────────────────────────────────

  void _validateCard() async {
    setState(() => _isValidating = true);
    await Future.delayed(const Duration(milliseconds: 800));
    if (mounted) {
      setState(() {
        _isValidating  = false;
        _validatedName = 'SUBSCRIBER VERIFIED';
      });
    }
  }

  void _submit(BuildContext context) {
    context.read<VasBloc>().add(VasPurchaseTvCable(
          smartCardNumber: _cardCtrl.text.trim(),
          provider:        _selectedProviderCode!,
          planCode:        _selectedPlanCode!,
        ));
  }

  void _showSuccessSheet(BuildContext context, Map<String, dynamic> data) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isDismissible: false,
      builder: (_) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                  color: _brand.withValues(alpha: 0.1),
                  shape: BoxShape.circle),
              child: const Icon(Icons.check_rounded, color: _brand, size: 36),
            ),
            const SizedBox(height: 20),
            Text('Subscription Activated!',
                style: GoogleFonts.plusJakartaSans(
                    fontSize: 20, fontWeight: FontWeight.w800)),
            const SizedBox(height: 8),
            Text(_selectedPlanName ?? 'Plan activated',
                style: GoogleFonts.plusJakartaSans(
                    color: Colors.grey.shade600, fontSize: 14)),
            const SizedBox(height: 28),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  Navigator.pop(context);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: _brand,
                  minimumSize: const Size(double.infinity, 50),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                  elevation: 0,
                ),
                child: Text('Done',
                    style: GoogleFonts.plusJakartaSans(
                        color: Colors.white, fontWeight: FontWeight.w700)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _snack(BuildContext ctx, String msg, {required bool isError}) {
    ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(
      content: Text(msg, style: const TextStyle(color: Colors.white)),
      backgroundColor: isError ? Colors.red.shade700 : _brand,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ));
  }

  Widget _sectionTitle(String text) => Text(
        text,
        style: GoogleFonts.plusJakartaSans(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: const Color(0xff1a1a1a)),
      );

  Widget _validatedChip(String name) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: _brand.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: _brand.withValues(alpha: 0.3)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.check_circle_rounded, color: _brand, size: 15),
            const SizedBox(width: 6),
            Text(name,
                style: GoogleFonts.plusJakartaSans(
                    color: _brand,
                    fontWeight: FontWeight.w700,
                    fontSize: 12)),
          ],
        ),
      );

  InputDecoration _dec({required String label}) => InputDecoration(
        labelText: label,
        filled: true,
        fillColor: Colors.white,
        labelStyle:
            GoogleFonts.plusJakartaSans(color: Colors.grey.shade600),
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none),
        enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.grey.shade200)),
        focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: _activeColor, width: 1.5)),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      );
}

// ─── Provider Banner (selected state) ─────────────────────────────────────────

class _ProviderBanner extends StatelessWidget {
  final _TvProvider provider;
  const _ProviderBanner({required this.provider});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            provider.bgColor.withValues(alpha: 0.12),
            provider.accentColor.withValues(alpha: 0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: provider.bgColor.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: provider.bgColor,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(provider.icon, color: Colors.white, size: 24),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  provider.name,
                  style: GoogleFonts.plusJakartaSans(
                    fontWeight: FontWeight.w800,
                    fontSize: 15,
                    color: const Color(0xff1a1a1a),
                  ),
                ),
                Text(
                  'Select a plan below',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12,
                    color: Colors.grey.shade500,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: provider.bgColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: provider.bgColor.withValues(alpha: 0.3)),
            ),
            child: Text(
              provider.code,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: provider.bgColor,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Plan tile ────────────────────────────────────────────────────────────────

class _PlanTile extends StatelessWidget {
  final String name;
  final String desc;
  final String amount;
  final Color  accentColor;
  final bool   isSelected;
  final VoidCallback onTap;

  const _PlanTile({
    required this.name,
    required this.desc,
    required this.amount,
    required this.accentColor,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: isSelected ? accentColor : Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected ? accentColor : Colors.grey.shade200,
            width: isSelected ? 2 : 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: accentColor.withValues(alpha: 0.25),
                    blurRadius: 10,
                    offset: const Offset(0, 3),
                  )
                ]
              : [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.03),
                    blurRadius: 4,
                    offset: const Offset(0, 1),
                  )
                ],
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: GoogleFonts.plusJakartaSans(
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                        color: isSelected
                            ? Colors.white
                            : const Color(0xff1a1a1a)),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    desc,
                    style: GoogleFonts.plusJakartaSans(
                        fontSize: 11,
                        color: isSelected
                            ? Colors.white.withValues(alpha: 0.75)
                            : Colors.grey.shade500),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Text(
              amount,
              style: GoogleFonts.plusJakartaSans(
                  fontWeight: FontWeight.w800,
                  fontSize: 14,
                  color: isSelected ? Colors.white : accentColor),
            ),
            const SizedBox(width: 8),
            Icon(
              isSelected
                  ? Icons.radio_button_checked
                  : Icons.radio_button_unchecked,
              color: isSelected
                  ? Colors.white
                  : Colors.grey.shade400,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }
}
